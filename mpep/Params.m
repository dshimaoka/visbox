classdef Params < handle
    % This class alows youto load, edit and save .p files.
    % Additionally it provides a mechanism to set the variabless
    % in the .p file prior to running the experiment.
    properties(SetAccess = private)
        xFile;
        % keep track of variables
        variableMap;
    end
    
    properties
        % name of pfile - not including extension
        name;
        
        % TODO: Make setter check dim
        stimuli;
        
        % for matrix commands
        numRow = 0;
        numCol = 0;
        
        % can be one of {'regular', 'adapt', 'sequence', 'updown'}
        experimentType = 'regular';
        
        % Minimum amount of time that must pass after showing a stimulus
        % before showing the next one (to allow data acquisition hosts to
        % save data). If all hosts are bidirectional then this can be 0.
        % (In seconds)
        minimumWait = 1.0; %20/3/20
        
        % Dead time - amount of time between StimStart being sent to dat
        % hosts and StimStart being sent to stim server.
        deadTime = 0.0;
        
        % Old format, if it had ADAPT/PRIMING keyword before stim instead
        % of after on load.
        oldExperimentFlag = false;
        
        % Delay between the last BlockEnd and ExpEnd to e.g. allow data 
        % acquisition of a post stimulus baseline period
        expEndDelay = 0;
        
        % Delay between the last BlockEnd to next BlockStart to e.g. allow
        % data acquisition of post stimulus baseline period
        blockEndDelay = 3;
    end
    
    properties(Dependent = true)
        numStim;
        numParam;
    end
    
    properties(Constant = true)
        validExperiementTypes = {'regular', 'adapt', 'priming', 'sequence', 'updown'};
        experimentTypeLabels =  {'Regular', 'Adaptation', 'Priming', 'Sequence', 'Up/Down'};
        repNumMagic = int64(2^62); % repeat num flag is a "special" int64 value
    end
    
    events
        variableMapChanged;
        stimsChanged;
        experimentPropertiesChanged;
    end
    
    methods
        % Given 1 arg:
        % create a new Params object from an xfile (with no stimuli)
        % Given 2 args:
        % create a new Params object from a pfile path and a path to the
        % directory of xfiles.
        function self = Params(varargin)
            if nargin == 1
                self.xFile = XFile(varargin{1});
                self.addDefaultStim();
                self.variableMap = self.createEmptyVarMap();
            elseif nargin == 2 % load from file
                pfilePath = varargin{1};
                xFileDir  = varargin{2};
                
                % set name
                [~,fname,~] = fileparts(pfilePath);
                self.name = fname;
                
                self.loadFromFile(pfilePath, xFileDir);

            else
                error('Wrong number of arguments.');
            end
            
        end
        
        function loadFromFile(self, pfilePath, xFileDir)
            [fid message] = fopen(pfilePath);
            if fid == -1
                error(['Error on opening pfile "' filepath '" : ' message]);
            end
            
            % xfile name should be on first line of file
            xFileName = fgetl(fid);
            xFilePath = fullfile(xFileDir, xFileName);
            try
                self.xFile = XFile(xFilePath);
            catch e
                error('Unable to find or open xfile');
            end
            
            % second line can be experiment type, try to read it
            lcells = textscan(fgetl(fid) ,'%s');
            if iscell(lcells{1}) && isvarname(lcells{1}{1})
                flag = lcells{1}{1};
                % set experiment flag
                switch lower(flag)
                    case {'regular', 'priming', 'adapt', 'sequence', 'updown'}
                        self.experimentType = lower(flag);
                        self.oldExperimentFlag = true;
                    otherwise
                        error('Error opening pfile, unknown experiment type');
                end
            else
                % otherwise "unread" line
                frewind(fid);
                fgetl(fid)
            end
            
            % now lets load up first two "setup" lines and check
            % everything is consistent
            
            setupLines = textscan(fid, '%d %d %d', 2);
            specifiedNumStim = setupLines{1}(1);
            specifiedNumParam = setupLines{2}(1);
            self.numRow = setupLines{2}(2);
            self.numCol = setupLines{3}(2);
            
            if specifiedNumParam ~= self.xFile.numParams
                error(['Number of params in pfile does not ' ...
                    'match number of params in xfile.']);
            end
            
            lineFormatString = repmat('%s ', 1, specifiedNumParam);
            lineFormatString = lineFormatString(1:end-1);
            
            stimuliLines = textscan(fid, lineFormatString, specifiedNumStim);
            
            if length(stimuliLines{1}) ~= specifiedNumStim
                error('specified number of simuli does not match actual number');
            end
            
            % put into resonably shaped cell array
            self.stimuli = cell(specifiedNumStim, specifiedNumParam);
            for i = 1:specifiedNumParam
                for j = 1:specifiedNumStim
                    self.stimuli{j,i} =  stimuliLines{i}{j};
                end
            end
            
            if ~self.checkUnrenderedStimuliValid();
                error('Not all stimuli params valid for xfile.')
            end
            
            self.variableMap = self.createEmptyVarMap();
          
            % read optional experiment type/timing info (not supported in
            % zpep)
            line = [];
            if ~feof(fid)
                line = fgetl(fid);
            end
            if ~feof(fid) && isempty(line)
                line = fgetl(fid);
            end
            if ~isempty(line)
%                 lcells = textscan(line ,'%s %s %f %s %f %s %f');
                flag = regexp(line, '^\w+', 'match', 'once');
                % set experiment flag
                switch lower(flag)
                    case {'regular', 'priming', 'adapt', 'sequence', 'updown'}
                        if strcmpi(flag, 'priming')
                            flag = 'adapt';
                        end
                        self.experimentType = lower(flag);
                    otherwise
                        error('Error opening pfile, unknown experiment type');
                end
                minwait = regexpi(line, 'MINWAIT ([0-9\.])+\s+([0-9\.])*', 'tokens', 'once');
                minwait = str2double(minwait(~cellfun(@isempty, minwait)));
                if numel(minwait) >= 1
                    self.minimumWait = minwait;
                end
                deadtime = str2double(regexpi(line, 'DEADTIME ([0-9\.])+', 'tokens', 'once'));
                if numel(deadtime) > 0
                    self.deadTime = deadtime;
                end
                expenddelay = str2double(regexpi(line, 'EXPENDD?ELAY ([0-9\.])+', 'tokens', 'once'));
                if numel(expenddelay) > 0
                    self.expEndDelay = expenddelay;  
                end
                blockenddelay = str2double(regexpi(line, 'BLOCKENDD?ELAY ([0-9\.])+', 'tokens', 'once'));%6/10/19
                if numel(blockenddelay) > 0
                    self.blockEndDelay = blockenddelay;  
                end
            end
            
            fclose(fid);
            Logger.singleton.pfileOpened(pfilePath);
        end
        
        % Check if a string is valid for a certain parameter
        % Either it parses into an int that is in range
        % or it has to be a valid variable name.
        function r = checkStringValid(self, paramIndex, string)
            if isvarname(string) || strcmp(string, '#')
                r = true;
                return;
            end
            i = str2double(string);
            if ~isreal(i) || isnan(i)
                r = false;
                return;
            end
            r = self.xFile.paramValid(paramIndex, i);
        end
        
        function [r i j] = checkUnrenderedStimuliValid(self)
            i = 0;
            j = 0;
            r = true;
            for i = 1:self.numStim
                for j = 1:self.xFile.numParams
                    if ~self.checkStringValid(j, self.stimuli{i,j})
                        r = false;
                        return;
                    end
                end
            end
        end
        
        function r = getDefaultStim(self)
            r = arrayfun(@num2str, self.xFile.paramDefaults, 'UniformOutput', false);
        end
        
        function addDefaultStim(self)
            newRow = self.getDefaultStim();
            self.stimuli = [self.stimuli; newRow];
        end
        
        function addDefaultStimTop(self)
            newRow = self.getDefaultStim();
            self.stimuli = [newRow; self.stimuli];
        end
        
        % add a default stimulus at index
        function insertDefaultStim(self, index)
            newRow = self.getDefaultStim();
            top = self.stimuli(1:index-1, 1:end);
            bottom = self.stimuli(index:end, 1:end);
            self.stimuli = [top; newRow; bottom];
        end
        
        
        function insertAt(self, index, stimList)
            top = self.stimuli(1:index-1, 1:end);
            bottom = self.stimuli(index:end, 1:end);
            self.stimuli = [top; stimList; bottom];
        end
        
        function removeStim(self, stimNum)
            self.stimuli = self.stimuli([1:stimNum-1 stimNum+1:end], 1:end);
            self.updateVarMap();
            self.notify('stimsChanged', StimChangeEvent(-stimNum, 1:self.numParam));
            if self.numStim-1 < (self.numRow*self.numCol)
                self.numRow = 1; self.numCol = 1;
            end
        end
        
        function r = get.numStim(self)
            r = size(self.stimuli, 1);
        end
        
        function r = get.numParam(self)
            r = size(self.stimuli, 2);
        end
        
        function set.experimentType(self, type)
            type = lower(type);
            if ~strcmp(type, self.experimentType) &&...
                    ismember(type, Params.validExperiementTypes)
                self.experimentType = type;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function set.numRow(self, n)
            changed = self.numRow ~= n;
            if changed
                self.numRow = n;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function set.numCol(self, n)
            changed = self.numCol ~= n;
            if changed
                self.numCol = n;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function set.minimumWait(self, t)
            changed = ~isequal(self.minimumWait, t);
            if changed
                self.minimumWait = t;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function set.deadTime(self, t)
            changed = self.deadTime ~= t;
            if changed
                self.deadTime = t;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function t = get.expEndDelay(self)
            if isempty(self.expEndDelay)
              t = 0; % default value of zero
            else
              t = self.expEndDelay;
            end
        end
        
        function set.expEndDelay(self, t)
            changed = self.expEndDelay ~= t;
            if changed
                self.expEndDelay = t;
                self.notify('experimentPropertiesChanged');
            end
        end
        
         function t = get.blockEndDelay(self)
            if isempty(self.blockEndDelay)
              t = 0; % default value of zero
            else
              t = self.blockEndDelay;
            end
        end
        
        function set.blockEndDelay(self, t)
            changed = self.blockEndDelay ~= t;
            if changed
                self.blockEndDelay = t;
                self.notify('experimentPropertiesChanged');
            end
        end
        
        function map = createEmptyVarMap(self)
            map = containers.Map();
            for i = 1:self.numStim
                for j = 1:self.xFile.numParams
                    if isvarname(self.stimuli{i,j})
                        map(self.stimuli{i,j})= [];
                    end
                end
            end
        end
        
        function clearVarMap(self)
            self.variableMap = self.createEmptyVarMap();
            self.notify('variableMapChanged');
        end
        
        function updateVarMap(self)
            % create a new map
            map = createEmptyVarMap(self);
            
            % copy over old set values into new map
            vars = map.keys();
            for i = 1:length(vars)
                k = vars{i};
                if self.variableMap.isKey(k)
                    map(vars{i}) = self.variableMap(vars{i});
                end
            end
            
            self.variableMap = map;
            self.notify('variableMapChanged');
        end
        
        function setValue(self, stim, param, str)
            if self.checkStringValid(param, str) &&...
                    ~(stim == 1 && strcmp(str, '#')) % disallow rep num in test
                % prune extra 0s
                if ~isvarname(str) && ~strcmp(str, '#')
                   str = num2str(str2double(str)); 
                end
                changed = ~strcmp(self.stimuli{stim,param}, str);
                self.stimuli{stim,param} = str;
                if changed
                    self.notify('stimsChanged', StimChangeEvent(stim, param));
                end
                self.updateVarMap();
            else
                error('mpep:badvalue', 'Invalid value');
            end
        end
        
        function setParamCol(self, param, values)
            for i = 1:self.numStim
                if ~self.checkStringValid(param, values{i})
                    error(['Invalid value at stimulus ' num2str(i) '.']);
                end
                % prune extra 0s
                if ~isvarname(values{i}) && ~strcmp(values{i},'#')
                    values{i} = num2str(str2double(values{i})); 
                end
            end
            self.stimuli(1:end,param) = values;
            evt = StimChangeEvent(1:self.numStim, param);
            self.notify('stimsChanged', evt);
            self.updateVarMap();
        end
        
        function r = getVariableNames(self)
            r = self.variableMap.keys;
        end
        
        function setVariable(self, name, value)
            if int64(value) ~= value
                error('Variables must be set to scalar integer values')
            end
            if self.variableMap.isKey(name)
                self.variableMap(name) = value;
            else
                error('invalid name');
            end
            
            self.notify('variableMapChanged');
        end
        
        % create a rendered params from this object
        % if any entry is out of the bounds defined in xfile r = 0,
        % then i j = index of erroneous entry.
        % otherwise r is a RenderedParams
        function [r i j] = render(self)
            mat = self.renderStimuliRaw();
            [r i j] = checkRenderedStimuliValid(self, mat);
            if ~r
                r = [];
                return;
            end
            r = RenderedParams(self.name, self.xFile, mat, self.numRow, self.numCol, ...
                keys(self.variableMap), values(self.variableMap), self.experimentType,...
                self.minimumWait, self.deadTime, self.expEndDelay, self.blockEndDelay);
        end
        
        % render a subset of the stimuli
        function [r i j] = renderSubset(self, indices)
            allStim = self.stimuli;
            originalVar = self.variableMap;
            try
                self.stimuli = self.stimuli(indices', :);
                self.updateVarMap(); % prune uneeded vars
                [r i j] = render(self);
            catch e
                self.stimuli = allStim;
                rethrow(e);
            end
            self.stimuli = allStim;
            self.variableMap = originalVar;
        end
        
        % Find variables which are needed to render a given subset of stimuli.
        function vars = requiredVariables(self, indices)
            allStim = self.stimuli;
            originalVar = self.variableMap;
            try
                self.stimuli = self.stimuli(indices', :);
                self.updateVarMap(); % prune uneeded vars
                vars = self.variableMap.keys();
            catch e
                self.stimuli = allStim;
                self.variableMap = originalVar;
                rethrow(e);
            end
            self.stimuli = allStim;
            self.variableMap = originalVar;
        end
        
        % Write this object to a file, so we can load it with the
        % constructor - Params(path, xFilePath);
        % Will throw any file related errors
        % Discards variable assignments
        function writeToFile(self, path)
            fid = fopen(path, 'wt');
            [s, p] = size(self.stimuli);
            fprintf(fid, [self.xFile.name '.x\n']);
            fprintf(fid, '%d %d %d\n', s, p, 0);
            fprintf(fid, '%d %d %d\n', 0, self.numRow, self.numCol); % find out what 0 is
            for i = 1:s
                for j = 1:p
                    if j ~= p
                        fwrite(fid, [self.stimuli{i,j} ' ']);
                    else
                        fwrite(fid, self.stimuli{i,j});
                    end
                end
                fprintf(fid, '\n');
            end
            fprintf(fid, [upper(self.experimentType) ...
              ' MINWAIT ' num2str(self.minimumWait, '%g ') ...
              ' DEADTIME ' num2str(self.deadTime) ...
              ' EXPENDDELAY ' num2str(self.expEndDelay) ...
              ' BLOCKENDDELAY ' num2str(self.blockEndDelay) '\n']);
            fclose(fid);
        end
    end
    
    methods (Access = private)
        
        % render params - no error checking - produces an int matrix
        function r = renderStimuliRaw(self)
            if length(cell2mat(self.variableMap.values)) ~= self.variableMap.length
                error('Not all variables set!');
            end
            r = cellfun(@(str) stringToValue(self, str), self.stimuli, 'UniformOutput', false);
            r = cell2mat(r);
            % convert to int64 and make sure NaNs go to Params.repNumMagic
            rDoubles = r;
            r = int64(r);
            r(isnan(rDoubles)) = Params.repNumMagic;
        end
        
        % check if the givien stimuliMatrix has all its parameters in the
        % bounds defined by the xfile.
        % returns true if all in bounds
        % [true stimNum paramNum] if out of bounds value found
        function [r badStimNum badStimParam] = checkRenderedStimuliValid(self, stimuliMatrix)
            [numStim numParam] = size(stimuliMatrix);
            badStimNum = -1;
            badStimParam = -1;
            r = true;
            for i = 1:numStim
                for j = 1:numParam
                    if stimuliMatrix(i, j) ~= Params.repNumMagic...
                            && ~self.xFile.paramValid(j, stimuliMatrix(i, j))
                        r = false;
                        badStimNum = i;
                        badStimParam = j;
                        return;
                    end
                end
            end
        end
        
        %
        function r = stringToValue(self, string)
            if self.variableMap.isKey(string)
                r = self.variableMap(string);
            elseif strcmp(string, '#')
                r = NaN;
            else
                r = sscanf(string, '%d', 1);
            end
        end
    end
    
end

