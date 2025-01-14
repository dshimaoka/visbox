classdef Protocol < handle
    % PROTOCOL Represents an experiment. Contains the stiumuli of the
    % experiment, order they were run, repeats, animal/seires and other
    % information.
    % i.e. All the data required to run the experiment, and the data that
    % should be recorderd.
    %
    % When a protocol is constructed all of these are set, and none of them will
    % change - it's immutable. (This means the sequence is generated on construction)
    %
    % A protocol can be run, this will run the experiment. An error will be
    % thrown if you attempt to run it more than once.
    %
    % When running the experement the protocol object will record the
    % relevant logs, save a protocol structure and a "rendered" pfile.
    
    properties
        animal;
        series;
        experimentNumber;
        
        params; % type: RenderedParams
        sequence; % type: array of ints
        repeats = 1;
        preMake = 0; % make stimuli first
        comment;
        
        lastStimEndTime = [];
    end
    properties (SetAccess = private)
        hasRun = false;
    end
    
    methods
        function self = Protocol(animal, series, expNum, rParams, repeats, preMake, comment)
            self.repeats = repeats;
            self.animal = animal;
            self.series = series;
            self.preMake = preMake;
            self.experimentNumber = expNum;
            %self.experimentNumber = findNextExpNumber(animal, series);
            self.params = rParams;
            self.comment = comment;
            switch rParams.experimentType
                case 'regular'
                    % each repeat is just a rand perm
                    self.sequence = zeros(self.params.numStim, self.repeats);
                    for i = 1:self.repeats
                        self.sequence(1:end, i) = randperm(self.params.numStim);
                    end
                case 'adapt'
                    % 1 - numstim-2 are test stimuli.
                    numStim = self.params.numStim;
                    if numStim < 3
                        error('Too few stimuli for adaptation experiment, need at least 3.');
                    end
                    self.sequence = zeros(self.params.numStim-2, self.repeats);
                    for i = 1:self.repeats
                        self.sequence(1:end, i) = randperm(self.params.numStim-2);
                    end
                case 'priming'
                    % 1 - numstim-2 are test stimuli.
                    numStim = self.params.numStim;
                    if numStim < 2
                        error('Too few stimuli for adaptation experiment, need at least 2.');
                    end
                    self.sequence = zeros(self.params.numStim-1, self.repeats);
                    for i = 1:self.repeats
                        self.sequence(1:end, i) = randperm(self.params.numStim-1);
                    end
                case 'sequence'
                    self.sequence = repmat((1:self.params.numStim)', 1, self.repeats);
                case 'updown'
                    odd = (1:self.params.numStim)';
                    even = (self.params.numStim:-1:1)';
                    self.sequence = repmat(odd, 1, self.repeats);
                    for i = 2:2:self.repeats
                        self.sequence(:, i) = even;
                    end
                otherwise
                    error(['Unspported experiment type: ' rParams.type]);
            end
        end
        
        
        % Run the experiment
        % progressFun(num, repeat) called on each stim
        % r = true if completed, false if interuppted
        function r = run(self, stimulus, communicator, progressFun, getReason)
            if ~stimulus.ping()
                error('Can not contact stimulus maker.')
            end
            Logger.singleton.start(self.series, self.experimentNumber, self.params, self.comment);
            
            % record .p and Protocol.mat
            self.record();
            
            stimulus.stimInitialize(self.params.xFile.name);
            stimulus.infoSave(self.animal, self.series, self.experimentNumber);
            communicator.startExperiment(self.animal, self.series, self.experimentNumber);
            
            [seqLength, ~] = size(self.sequence);
            
            if self.preMake && ~self.canPreMake
                error('Can not pre make stimuli since there are repeat number placeholders (# symbols in grid).');
            end
            
            if self.preMake
                for i = 1:self.params.numStim
                    if nargin >= 4
                        progressFun(0, i, self.sequence);
                    end
                    stimulus.makeStim(self.params.stimuli(i, 1:end));
                    stimulus.holdStim();
                end
            end
            
            % fill up stim
            if strcmp(self.params.experimentType, 'adapt')
                self.minWait();
                progressFun(0,0,[]);
                stim = self.params.stimuli;
                stim(stim == Params.repNumMagic) = 0;
                stimulus.makeStim(stim(end, 1:end));
                communicator.startZeroBlock();
                % delay before showing each stimulus
                communicator.stimStart(self.params.numStim,...
                    self.params.getDuration(self.params.numStim)+self.params.deadTime);
                % 'deadtime' between telling data hosts and stim server
                pause(self.params.deadTime); 
                stimulus.showStim(stim(end, 1:end));
                self.lastStimEnd();
                communicator.stimEnd();
                communicator.endZeroBlock();
            end
            
            
            for n = 1:self.repeats
                communicator.startBlock();
                
                stim = self.params.stimuli;
                % Set "repeat num" placeholders to repeat number
                stim(stim == Params.repNumMagic) = n;
                
                pause(self.params.minimumWait); %19/3/20
                
                for i = 1:seqLength
                    %show top up
                    if strcmp(self.params.experimentType, 'adapt')...
                            || strcmp(self.params.experimentType, 'priming')
                        self.minWait();
                        progressFun(-1,0,[]);
                        if(strcmp(self.params.experimentType, 'priming'))
                            topUp = self.params.numStim;
                        else
                            topUp = self.params.numStim-1;
                        end
                        stimulus.makeStim(stim(topUp, 1:end));
                        communicator.stimStart(-self.sequence(i,n), self.params.getDuration(self.params.numStim-1));
                        pause(self.params.deadTime); % deadtime between telling dat hosts and stim server
                        stimulus.showStim(stim(topUp, 1:end));
                        self.lastStimEnd();
                        communicator.stimEnd();
                    end
                    
                    self.minWait();
                    % tell progress function where we are
                    if nargin >= 4
                        interrupt = progressFun(n, i, self.sequence);
                        if(interrupt)
                            communicator.interruptExperiment();
                            if nargin == 4
                                Logger.singleton.interrupt(n);
                            else
                                Logger.singleton.interrupt(n, getReason())
                            end
                            r = false;
                            return;
                        end
                    end
                    stimIndex = self.sequence(i,n);
                    stimulus.makeStim(stim(stimIndex, 1:end));
                    communicator.stimStart(self.sequence(i,n), self.params.getDuration(stimIndex));
                    pause(self.params.deadTime); % deadtime between telling dat hosts and stim server
                    stimulus.showStim(stim(stimIndex, 1:end));
                    self.lastStimEnd();
                    communicator.stimEnd();
                end
                
                pause(self.params.minimumWait); %19/3/20
                
                communicator.endBlock()
                pause(self.params.blockEndDelay); %6/10/19
            end
            pause(self.params.expEndDelay);
            communicator.endExperiment();
            r = true;
        end
        
        % timing functions
        function minWait(self)
            if isempty(self.lastStimEndTime)
                return;
            end
            waittime = self.params.minimumWait;
            if numel(waittime) == 2
                %two elements signifies a range to sample uniformly from
                waittime = waittime(1) + diff(waittime)*rand;
            end
            waittime
            passed = toc(self.lastStimEndTime);
            
            if passed < waittime
                pause(waittime-passed);
            end
        end
        
        function lastStimEnd(self)
            self.lastStimEndTime = tic;
        end
        
        % Create a non OO protocol structure, as used in spike
        function p = getProtocolStructure(self)
            p = ProtocolInitialize([], 'quiet');
            p.nrepeats = self.repeats;
            p.animal = self.animal;
            p.iseries = self.series;
            p.iexp = self.experimentNumber;
            p.npars = self.params.numParam;
            p.npfilestimuli = self.params.numStim;
            p.xfile = [self.params.xFile.name '.x'];
            p.adapt.flag = strcmp(self.params.experimentType, 'adapt');
            p.pars = double(self.params.stimuli');
            % Set "repeat num" placeholders to NaN
            p.pars(p.pars == double(Params.repNumMagic)) = nan;
            p.parnames = self.params.xFile.paramNames';
            p.pardefs = self.params.xFile.paramDescriptions';
            p.seqnums = self.sequence;
            [n m] = size(p.seqnums);
            for i = 1:n
                for j = 1:m
                    p.seqnums(i,j) = find(self.sequence(:,j)==i)+(n*(j-1));
                end
            end
            
            %% delay parameters 26/3/20
            p.minWait = self.params.minimumWait;
            p.deadTime = self.params.deadTime;
            p.expEndDelay = self.params.expEndDelay;
            p.blockEndDelay = self.params.blockEndDelay;
        end
        
        % Write protocol structure and a .pfile (from params) to the
        % correct location on the dataPath as a record of this experiment
        % being run.
        % RenderdParams into (plaintext):
        % dataPath/animal/series/expNum/animal_series_expNum.p
        % getProtocolStructure into:
        % dataPath/animal/series/expNum/Protocol.m
        % TODO: make this more cautious about overwriting.
        function record(self)
            
            dirs = Paths();
            dataDir = dirs.data;
            if ~exist(dataDir, 'dir')
                error(['Can not find data directory: ', dataDir]);
            end
            % create animal dir if it does not exist
            if ~exist(fullfile(dataDir, self.animal), 'dir');
                mkdir(fullfile(dataDir, self.animal));
            end
            
            % create series dir if it does not exist
            seriesPath = fullfile(dataDir, self.animal, num2str(self.series));
            if ~exist(seriesPath, 'dir');
                mkdir(seriesPath);
            end
            
            % create experiment number dir if it does not exist
            expPath = fullfile(seriesPath, num2str(self.experimentNumber));
            if ~exist(expPath, 'dir');
                mkdir(expPath);
            end
            
            % write .p file
            rpfilePath = fullfile(expPath,...
                [self.animal '_' num2str(self.series) '_' num2str(self.experimentNumber) '.p']);
            self.params.writeToFile(rpfilePath);
            
            % write Protocol.mat
            protocolMatPath = fullfile(expPath, 'Protocol.mat');
            Protocol = getProtocolStructure(self); %#ok<NASGU>
            save(protocolMatPath, 'Protocol'); %will delete in future
            
            %             %% save Protocol to server 2/6/20
            %             expParams.experimentType = 'mpep';
            %             expParams.comment = '';
            %             expRef = dat.newExp(self.animal, self.series(1:10), ...
            %                 str2num(self.series(12:end)), expParams);
            %             superSave(dat.expFilePath(expRef, 'protocol'),struct('Protocol', Protocol));
            

        end
        
        % Can we premake stimuli? This is only possible if we have no repeat
        % number placeholders ('#').
        function r = canPreMake(self)
            r = isempty(find(self.params.stimuli == double(Params.repNumMagic), 1));
        end
    end
    
    
    
end

