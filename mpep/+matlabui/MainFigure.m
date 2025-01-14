classdef MainFigure < handle
    %MAINFIGURE Main window of mpep. Shows the animal/series selection,
    % variable editor, stimulus editor and allows experiments to be run.
    
    properties
       lastDir = cd; % last dir p-file opened from
    end
    
    properties(SetAccess = private)
        fig;
        stimServer = [];
        dataHostComs = [];
        
        animal = 'dummy4'; % animal name
        series = []; % series number
        experiment = []; % experiment number
        params = [];
        
        fileList;
        varEditor;
        stimEditor;
        
        animalEdit;
        animalEditButton;
        seriesEdit;
        seriesUpdateButton;%1/4/20
        animalLabel;
        seriesLabel;
        expNumLabel;
        runButton;
        runLabel;
        
        fileMenu;
        expMenu;
        stimMenu;
        paramMenu;
        
        saveMenuItem;
        saveAsMenuItem;
        
        running = false;
        minimumWait = 0;
        
        inited = false; % has xfile been stim initilised
        dirty = false; % params modified since load
    end
    
    properties(GetAccess = private, SetAccess = private)
    end
    
    methods
        function self = MainFigure(stimServer, coms)
            
            % Warn user if any paths appear to be broken.
            paths = Paths();
            if ~exist(paths.data , 'dir')
                msgbox('data path not set correctly, please edit Paths.m', 'Error');
                return;
            end
            if ~exist(paths.xfiles , 'dir')
                msgbox('xfile path not set correctly, please edit Paths.m', 'Error');
                return;
            end
            
            if nargin == 2
                self.stimServer = stimServer;
                self.dataHostComs = coms;
            elseif nargin == 1
                self.stimServer = stimServer;
                self.dataHostComs = DataHostCommunicator();
                self.dataHostComs.connect();
            else
                self.stimServer = StimulusServer();
                self.stimServer.connect();
                self.dataHostComs = DataHostCommunicator();
                self.dataHostComs.connect();
            end
                        
            self.fig = figure;
            set(self.fig, 'MenuBar', 'none', 'DockControls', 'off')
            set(self.fig, 'Name', 'mPEP')
            set(self.fig, 'NumberTitle', 'off')
            set(self.fig, 'ResizeFcn', @(src,evt) self.layout());
            set(self.fig, 'CloseRequestFcn', @(src,evt)self.closeCB());
            
            screenDim = get(0, 'ScreenSize');
            w = 0; h = 400;
            set(self.fig, 'Position', [screenDim(1)/2 + w/2,screenDim(2)/2 + h/2, 900, 300]);
                    
            % TODO: retrieve old value for animal/series. Update ui
            % components to match.
            
            % On selection of animal auto select last series and change
            % expNum label correctly.
            % On selection of series check it's a number, and change expNum
            % label correctly.
            self.animalEdit = uicontrol(self.fig, 'Style', 'edit',...
                'String', self.animal, 'Enable', 'on', 'BackgroundColor', [1 1 1]);%21/1/20 changed from inactive
            self.animalEditButton = uicontrol(self.fig, 'String', 'Select...');
            self.seriesEdit = uicontrol(self.fig, 'Style', 'edit',...
                'String', num2str(self.series));
            self.seriesUpdateButton = uicontrol(self.fig, 'String', 'New');
            
            % seriesEdit not enabled until animal selected
            if isempty(self.animal)
                set(self.seriesEdit, 'Enable', 'off');
            end
            
            self.animalLabel = uicontrol(self.fig, 'Style', 'text', 'String', 'Animal:');
            self.seriesLabel = uicontrol(self.fig, 'Style', 'text', 'String', 'Series:');
            self.expNumLabel = uicontrol(self.fig, 'Style', 'text', 'String', '');
           
            self.runButton = uicontrol(self.fig, 'Style', 'pushbutton', ...
                'String', 'Run', 'Enable', 'off', 'BackgroundColor', [0 1 0]);
            self.runLabel = uicontrol(self.fig, 'Style', 'text', 'String', '', 'FontSize', 14);
            
            
            
            self.fileList = uicontrol(self.fig, 'Style', 'listbox', 'BackgroundColor', [1 1 1]);
            self.varEditor = matlabui.VariableMapEditor(self.fig);
            
            % create menus
            self.fileMenu = uimenu('Label','File');
            % TODO: Implement new
            uimenu(self.fileMenu,'Label','New...', 'Callback', @(src,evt)self.newCB());
            uimenu(self.fileMenu,'Label','Open...', 'Callback', @(src,evt)self.openMenuCB);
            % TODO: Implement save, save as
            self.saveMenuItem = uimenu(self.fileMenu,'Label','Save', 'Enable', 'off', 'Accelerator', 's', ...
                'Callback', @(src,evt)self.saveCB());
            self.saveAsMenuItem = uimenu(self.fileMenu,'Label','Save As...', 'Enable', 'off', ...
                'Callback', @(src,evt)self.saveAsCB());
            uimenu(self.fileMenu,'Label','Hosts...', 'Callback', @(src,evt)self.hostsCB());
            uimenu(self.fileMenu,'Label','Exit', 'Callback', @(src,evt)self.closeCB());
            
            self.expMenu = uimenu('Label','Experiment', 'Enable', 'off');
            uimenu(self.expMenu, 'Label', 'Run...', 'Callback', @(src,evt) self.runButtonCB());
            
            uimenu(self.expMenu, 'Label', 'Test All', 'Callback', @(src,evt) self.testAllCB());
            
            % TODO: Implement continue.
%             uimenu(self.expMenu, 'Label', 'Continue', 'Enable', 'off');

            uimenu(self.expMenu, 'Label', 'Properties...', 'Callback', ...
                @(src,evt) matlabui.showExperimentPropertiesDialog(self.params, self.fig));
            uimenu(self.expMenu, 'Label', 'Set interstimulus delay...', 'Callback', ...
                @(src,evt) self.setMinimumWait());
            uimenu(self.expMenu, 'Label', 'Set dead time...', 'Callback', ...
                @(src,evt) self.setDeadTime());
            uimenu(self.expMenu, 'Label', 'Set ExpEnd delay...', 'Callback', ...
                @(src,evt) self.setExpEndDelay());
            uimenu(self.expMenu, 'Label', 'Set BlockEnd delay...', 'Callback', ...
                @(src,evt) self.setBlockEndDelay());
            
            self.stimMenu = uimenu('Label', 'Stimulus', 'Enable', 'off');
            
            uimenu(self.stimMenu, 'Label', 'Cut', 'Callback', @(src,evt)self.stimEditor.cut(), 'Accelerator', 'x');
            uimenu(self.stimMenu, 'Label', 'Copy', 'Callback', @(src,evt)self.stimEditor.copy(), 'Accelerator', 'c');
            uimenu(self.stimMenu, 'Label', 'Paste', 'Callback', @(src,evt)self.stimEditor.paste(), 'Accelerator', 'v');
            
            uimenu(self.stimMenu, 'Label', 'Test', 'Enable', 'on',...
                'Callback', @(src,evt)self.testStimCB(), 'Interruptible', 'off', 'Accelerator', 't');
            
            self.paramMenu = uimenu('Label', 'Parameter', 'Enable', 'off');
            uimenu(self.paramMenu, 'Label', 'Row...','Callback',  @(src,evt) self.rowCB());
            uimenu(self.paramMenu, 'Label', 'Column...','Callback',  @(src,evt) self.colCB());
            uimenu(self.paramMenu, 'Label', 'Range...', ...
                'Callback', @(src,evt) self.rangeCB());
            uimenu(self.paramMenu, 'Label', 'Set to...', ...
                'Callback', @(src,evt) self.setToCB());
            
            helpMenu = uimenu('Label', 'Help');
            uimenu(helpMenu, 'Label', 'About', 'Callback', @(src,evt) self.aboutCB());
            
            % set callbacks
            set(self.animalEditButton, 'Callback', @(src,evt) self.animalEditCB());
            %set(self.animalEdit, 'ButtonDownFcn', @(src,evt) self.animalEditCB()); 
            set(self.animalEdit, 'Callback', @(src,evt) self.animalEditField()); %21/1/20
            set(self.seriesEdit, 'Callback', @(src,evt) self.seriesEditCB());
            set(self.seriesUpdateButton, 'Callback', @(src,evt) self.seriesUpdateCB());
            set(self.runButton, 'Callback', @(src,evt) self.runButtonCB());
            set(self.fileList, 'Callback', @(src,evt) self.fileListCB(evt));
                        
            % set background colour of figure to something resonable
            set(self.fig, 'Color', get(self.seriesLabel,'BackgroundColor'));
            
            self.layout();
            
            % Restore settings
            self.loadSettings();
            self.updateFileList();
            
            % if no animal selected after setting load prompt user
            if isempty(self.animal)
                self.animalEditCB();
            end
            
            % lower delay before showing tooltips, will effect everything -
            % even matlab GUI
            javax.swing.ToolTipManager.sharedInstance().setInitialDelay(100);
        end
        
        function layout(self)
            figSize = get(self.fig, 'Position');
            width = figSize(3);
            height = figSize(4);
            
            split = 190;
            if ~isempty(self.varEditor)
                set(self.varEditor.uiHandle, 'Position', [0 0 split height-80]);
            end
            
            set(self.fileList, 'Position', [split 0 180 height-80]);
            
            split = split+180;
            if ~isempty(self.stimEditor)
                stimEditorWidth = width-split;
                if stimEditorWidth > 0 && height > 0
                    set(self.stimEditor.uiHandle, 'Position', [split 0 width-split height]);
                end
            end
            
            set(self.animalEdit, 'Position',  [70, height-32, 150, 22]);
            set(self.animalEditButton, 'Position',  [225, height-32, 70, 22]);
            set(self.animalLabel, 'Position', [5, height-37, 50, 25]);
            
            set(self.seriesEdit, 'Position',  [70, height-35-22, 80, 22]);
            set(self.seriesLabel, 'Position', [5, height-37-22, 50, 22]);
            set(self.seriesUpdateButton, 'Position',  [155, height-35-22, 30, 22]);
            
            set(self.expNumLabel, 'Position', [5, height-35-25-25, 80, 25]);
            
            set(self.runButton, 'Position',   [300, height-35, 60, 25]);
            set(self.runLabel, 'Position',    [195, height-80, 160, 45]);
            drawnow;
        end
        
        % TODO: Make this more error resistant (espeically for missing
        % xfile)
        function openParamFile(self, path)
            if isempty(self.animal)
                error('Select animal before opening .p file.')
            end
            
            % prompt for save first
            if self.dirty
                a = questdlg('Param file modified, save?', 'mPep');
                if strcmp(a, 'Yes')
                   self.saveCB(); % save changes
                elseif ~strcmp(a, 'No') % cancel
                    return;
                end
            end
            
            self.inited = false;
            
            paths = Paths();
            
            try
                self.params = Params(path, paths.xfiles);
            catch e
                msgbox(e.message, 'Error')
                return;
            end
            
            % if components existed already remove them
            if ~isempty(self.stimEditor)
               delete(self.stimEditor.uiHandle);
               self.stimEditor.cleanup();
               self.stimEditor = [];
            end
            
            % add "sandbox" row
            self.params.addDefaultStimTop();
            
            self.varEditor.removeEmpties();
            
            % register with var editor
            self.varEditor.setParams(self.params);
            
            % put stim editor into figure
            self.stimEditor = javaui.StimEditor(self.params, self.fig, @self.testStimCB);
            
            % Enable/disable certain ui components
            if ~isempty(self.animal) && ~isempty(self.series)
                set(self.runButton, 'Enable', 'on');
                set(self.expMenu, 'Enable', 'on');
                set(self.saveMenuItem, 'Enable', 'on');
                set(self.saveAsMenuItem, 'Enable', 'on');
                
                % will be no selections so disable stim and param
                set(self.stimMenu, 'Enable', 'off');
                set(self.paramMenu, 'Enable', 'off');

            end
            
            set(self.fig, 'Name', [self.params.name ' - mPep'])
            self.dirty = false; % clean on new load
            self.layout();
            
            % listen to event notification from table
            self.stimEditor.addlistener('selectionChanged', @(src,evt) self.selectionCB());
            
            % listen to event notifications from params
            self.params.addlistener('stimsChanged', @(src,evt) self.paramsModified(evt));
            self.params.addlistener('experimentPropertiesChanged', @(src,evt) self.makeDirty());
            
            % if legacy file then mark as dirty so user has to resave
            if(self.params.oldExperimentFlag)
               self.makeDirty(); 
            end
            
            % run default stim
            self.testDefault();
        end
        
        
        % TODO: Perhaps only allow opening when an animal is selected.
        function openMenuCB(self)
            % cd into last dir so uigetfile opens in it       
            dir = cd;
            try %#ok<TRYNC>
                cd(self.lastDir);
            end
            
            % open dialog
            [fn pn] = uigetfile('*.p', 'Select p-file', 'MultiSelect', 'off');
            cd(dir);
            
            % no file selected
            if fn == 0
                return;
            end
            
            % open the .p file
            path = fullfile(pn,fn);      
            
            try
                self.openParamFile(path);
                Logger.singleton.pfileOpened(path);
            catch e
                msgbox(e.message, 'Error')
                return;
            end
            
            % remember the path
            self.lastDir = pn;
            self.updateFileList();
        end
        
        function animalEditCB(self)
            if isempty(self.animal)
                response = matlabui.animalNameSelector(self.fig);
            else
                response = matlabui.animalNameSelector(self.fig, self.animal);
            end
            
            if isempty(response)
                return;
            end
            self.selectAnimal(response);
        end
        
        function animalEditField(self) %21/1/20
            response = self.animalEdit.String;
            
            if ~isempty(response)
                self.selectAnimal(response);
            else 
                return;
            end
        end
        
        function selectAnimal(self, a)
            self.animal = a;
            set(self.animalEdit, 'String', self.animal);
            Logger.singleton.selectAnimal(self.animal);
            
            % Update series and experiment number.
            self.series = suggestDateSeries(self.animal);
            %self.experiment = findNextExpNumber(self.animal, self.series);
            self.experiment = [];
            % Update the ui elements.
            set(self.seriesEdit, 'String', self.series);
            set(self.expNumLabel, 'String', ...
                ['Experiment: ' num2str(self.experiment)]);
            
            
            % Make sure series number editable now
            %set(self.seriesEdit, 'Enable', 'on'); 
            set(self.seriesEdit, 'Enable', 'off'); 
            
            % prompt to clear variables
            if self.varEditor.hasResolvedVariables()
                a = questdlg('Clear resolved variables?','Prompt', 'Yes', 'No', 'No');
                if strcmp(a, 'Yes')
                   self.varEditor.clear(); 
                   self.params.clearVarMap();
                   self.varEditor.setParams(self.params);
                end
            end
        end
        
        %replaced with seriesUpdateCB on 1/4/20
        % %         function seriesEditCB(self)
        % %             newSeries = get(self.seriesEdit, 'String');
        % %
        % %             changed = ~strcmp(self.series,newSeries);
        % %             self.series = newSeries;
        % %
        % %             % Update experiment number to reflect change.
        % %
        % %             set(self.expNumLabel, 'String', ...
        % %                 'Experiment: ' );
        % %
        % %
        % %             % prompt to clear variables
        % %             if changed && self.varEditor.hasResolvedVariables()
        % %                 a = questdlg('Clear resolved variables?','Prompt', 'Yes', 'No', 'No');
        % %                 if strcmp(a, 'Yes')
        % %                    self.varEditor.clear();
        % %                    self.params.clearVarMap();
        % %                    self.varEditor.setParams(self.params);
        % %                 end
        % %             end
        % %         end
        
        
         function seriesUpdateCB(self) %1/4/20
            [~,prefix, suffix] = suggestDateSeries(self.animal);
            newSeries = [prefix '_' num2str(suffix+1)];
            self.series = newSeries;
            self.seriesEdit.String=self.series;
            self.experiment = [];
            set(self.expNumLabel, 'String','Experiment: ' );
        end
        
        function runButtonCB(self)            
            
            % If we are already running then user has asked us to stop.
            % Change running flag, progress function will alert
            % Protocol.run method by changing it's return value.
            if self.running
                self.running = false;
                set(self.runButton, 'Enable', 'off');
                return;
            end
            
            
            oldStim = self.params.stimuli();
            try
                % remove "sandbox" stim
                % TODO: clean this up.
                self.params.stimuli = self.params.stimuli(2:end, 1:end);
                [rp i j] = self.params.render();
                self.params.stimuli = oldStim;
            catch e
                if strcmp(e.message, 'Not all variables set!')
                    if ~self.setVars()
                        self.params.stimuli = oldStim;
                        return;
                    end
                    try
                        [rp i j] = self.params.render();
                    catch e
                        self.params.stimuli = oldStim;
                        msgbox(e.message,'Error')
                        return;
                    end
                    self.params.stimuli = oldStim;
                else
                    self.params.stimuli = oldStim;
                    msgbox(e.message,'Error')
                    return;
                end
            end
            
            % In case of error rendering (bad variable settings) show
            % informative error message.
            if isempty(rp)
                x = self.params.stimuli{i+1, j};
                val = self.params.variableMap(x);
                message = ['Variable ' x '=' num2str(val) ' is invalid.' ...
                    ' Fails to be in valid range for stimulus ' num2str(i) ...
                    ' parameter: ' num2str(j)];
                msgbox(message,'Error resolving parameters.')
                return;
            end
    
            % Prompt for number of reps
            repString = inputdlg2('Number of repeats:', 'Input', 1, {'10'});
            if isempty(repString)
                return;
            end
            
            reps = str2double(repString);
            if isnan(reps) || reps ~= int64(reps);
                msgbox('Pleae enter an integer.', 'Error');
                return;
            end
            
            comment = inputdlg2('Comment:', 'Input');
            if isempty(comment)
                comment = '';
            else
                comment = comment{1};
            end
            

            
            preMake = false;
            try       
                clear expParams;
                expParams.experimentType = 'mpep';                                
                expParams.comment = comment;
%                 expRef = dat.newExp(self.animal, self.series, expParams);   
                expRef = dat.newExp(self.animal, self.series(1:10), ...
                    str2num(self.series(12:end)), expParams);   
                [subjectRef, expDate, expSeries, expSequence] = dat.parseExpRef(expRef);
                self.experiment = expSequence;
                set(self.expNumLabel, 'String', ...
                    ['Experiment: ' num2str(self.experiment)]);
                
                exp = mpepcore.Protocol(self.animal, self.series, expSequence, rp, reps, preMake, comment);
                
                % normally this saving of the parameters happens in
                % exp.newDat, but we had to run that before generating the
                % protocol so that we have the right expSequence number 
                expParams.Protocol = exp.getProtocolStructure();
                superSave(dat.expFilePath(expRef, 'parameters'), struct('parameters', expParams));
            catch e
                msgbox(e.message, 'Error');
                return;
            end
            
            % Prompt for premake stimuli, if possible.
            if exp.canPreMake()
                button = questdlg('Make stimuli first?','Question');
                if isempty(button) || strcmp(button, 'Cancel');
                    return;
                end
                exp.preMake = strcmp(button, 'Yes');
            end
            %             exp.preMake = 'Yes'; %19/3/20
            
            self.running = true;
            set(self.runButton, 'BackgroundColor', [1 0 0]);
            set(self.runButton, 'String', 'Stop');
            drawnow;
            self.setControlsEnabled(0);
            try
                
                finished = exp.run(self.stimServer, self.dataHostComs, ...
                    @(repeat, index, sequence) self.progress(repeat, index, sequence), ...
                    @matlabui.MainFigure.getInterruptReason);
            catch e
            % TODO: perhaps add some special cases here.
                finished = false;
                msgbox(e.message,'Error');
                disp(e.message);
            end
            
            set(self.runButton, 'BackgroundColor', [0 1 0]);
            set(self.runButton, 'String', 'Start');
            set(self.runButton, 'Enable', 'on');
            drawnow;
            self.running = false;
            self.setControlsEnabled(1);                        
            
            if finished
                self.playTada();
            end
            
            % end comment
            comment = inputdlg2('End comment:', 'Input');
            if isempty(comment)
                comment = '';
            else
                comment = comment{1};
            end
            %num = findNextExpNumber(self.animal, self.series) -1;
            Logger.singleton.complete(self.series, expSequence, comment);
        end
        
        function loadSettings(self)
            settings = getSettingsStruct();
            if ~isempty(settings.lastAnimal)
                % change string in editor and manually fire callback
                self.selectAnimal(settings.lastAnimal);
            end
            if ~isempty(settings.lastDir)
                self.lastDir = settings.lastDir;
            end
        end
        
        function saveSettings(self)
           settings.lastAnimal = self.animal;
           settings.lastDir = self.lastDir;
           save(configPath, '-append', '-struct',  'settings');
        end
        

       
         function closeCB(self)
            if self.running
                return;
            end
            
            % if param file changed prompt to save
            if self.dirty
                a = questdlg('Parameters modified, save before exit?', 'mPep');
                if strcmp(a, 'Yes')
                   self.saveCB(); % save changes
                elseif ~strcmp(a, 'No') % cancel
                    return;
                end
            end
            
            a = questdlg('Close matlab too?', 'mPep');
            
            exitMatlab = 0;
            if strcmp(a, 'Yes')
                exitMatlab = 1;
            elseif ~strcmp(a, 'No') % cancel
                return;
            end
             
            self.saveSettings();
            if ~isempty(self.stimEditor)
                self.stimEditor.cleanup();
            end
            self.stimServer.disconnect();
            self.dataHostComs.disconnect();
            delete(self.fig);
            
            if(exitMatlab)
               exit; 
            end
         end
         
         function updateFileList(self)
            try
                d = dir(self.lastDir);
            catch e %#ok<NASGU>
                return;
            end
            % eliminate dirs
            d = d(~cell2mat({d(:).isdir}));
            % filter .p files
            isP = @(str)(length(str) >= 2 && strcmp(str([end-1, end]), '.p'));
            d = d(cellfun(isP,{d(:).name}));
            
            str = {d.name};
            set(self.fileList, 'String', str); 
         end
         
         function fileListCB(self, ~)
             % if double clicked
             if strcmp(get(self.fig, 'SelectionType'), 'open')
                 strs = get(self.fileList, 'String');
                 fileName = strs{get(self.fileList, 'Value')};
                 filePath = fullfile(self.lastDir, fileName);      
                 self.openParamFile(filePath);
             end
         end
         
         % enable or disable everything on GUI except run/stop button
         % only use this when pfile is loaded (assumes all gui components
         % exist)
         function setControlsEnabled(self, flag)
             if flag
                 v = 'on';
             else
                 v = 'off';
             end     
             
             set([self.fileMenu, self.expMenu, self.stimMenu, ...
                 self.paramMenu self.varEditor.table, self.fileList...
                 self.animalEdit self.animalEditButton,self.seriesUpdateButton],...
                 'Enable', v);
             %replaced self.seriesEdit with self.seriesUpdate 2/4/20
             
             % commented out 21/1/20
             %              if flag
             %                  set(self.animalEdit, 'Enable', 'Inactive')
             %              end
             
             self.stimEditor.setEnabled(flag);
             
             % disable close button
             if flag
                 set(self.fig, 'CloseRequestFcn', @(src,evt)self.closeCB());
             else
                set(self.fig, 'CloseRequestFcn', @(src,evt)zeros());
             end
         end
         
         function setMinimumWait(self)
             msg = sprintf(...
               ['Please enter the minimum delay between stimuli (seconds):'...
                '\nUse one number for a fixed delay, or two for the min & max'...
                ' of a random uniform delay\n(e.g. "5 10" specifies a random'...
                ' delay between 5 and 10 seconds).']);
             delayStr = inputdlg2(msg, 'Input', 1, {num2str(self.params.minimumWait, '%g ')});
             if ~isempty(delayStr)
                 delay = str2num(delayStr{1});
                 if numel(delay) >= 1 && numel(delay) <= 2 && all(delay >= 0)
                     self.params.minimumWait = delay;
                 else
                     msgbox('Delays must be non-negative.', 'Error');
                 end
             end
         end
         
         function setDeadTime(self)
             delayStr = inputdlg2('Please enter the dead time after sending StimStart to data hosts (seconds):', ...
                 'Input', 1, {num2str(self.params.deadTime)});
             if isempty(delayStr)
                 return;
             end
             delay = str2double(delayStr);
             if isscalar(delay) && delay >= 0
                 self.params.deadTime = delay;
             else
                msgbox('Please enter a positive number.', 'Error');
             end
         end
         
         function setExpEndDelay(self)
             delayStr = inputdlg2('Please enter the delay before sending ExpEnd to data hosts (seconds):', ...
                 'Input', 1, {num2str(self.params.expEndDelay)});
             if isempty(delayStr)
                 return;
             end
             delay = str2double(delayStr);
             if isscalar(delay) && delay >= 0
                 self.params.expEndDelay = delay;
             else
                msgbox('Please enter a positive number.', 'Error');
             end
         end
         
          function setBlockEndDelay(self) %6/10/19
             delayStr = inputdlg2('Please enter the delay before sending BlockEnd to data hosts (seconds):', ...
                 'Input', 1, {num2str(self.params.blockEndDelay)});
             if isempty(delayStr)
                 return;
             end
             delay = str2double(delayStr);
             if isscalar(delay) && delay >= 0
                 self.params.blockEndDelay = delay;
             else
                msgbox('Please enter a positive number.', 'Error');
             end
          end
         
         % set remaining variables, return 0 user cancels, 1 if not.
         function r = setVars(self, stimIndices)
             r = 0;
             if nargin == 1
                varNames = self.params.variableMap.keys;
             else
                varNames = self.params.requiredVariables(stimIndices);
             end
             
             i = 1;
             while i <= length(varNames)
                if isempty(self.params.variableMap(varNames{i}))
                    v = inputdlg2([varNames{i} ' ='], 'Set variable...');
                    if isempty(v)
                        return;
                    end
                    v = str2double(v{1});
                    
                    if int64(v) ~= v
                        msgbox('Please enter a scalar integer.', 'Error');
                        return;
                    else
                       self.params.setVariable(varNames{i}, v); 
                    end
                end
                i = i+1;
             end
             r = 1;
         end
    end
    
    methods(Access = private)
        function r = progress(self, repeat, index, sequence)
            % if running flag has turned off then we need to return 1 to
            % signal experiement interrupt.     
            if ~self.running 
                r = 1;
                return;
            end
            if repeat > 0
                [seqLength, numRepeats] = size(sequence);
                % Update progress label
                set(self.runLabel, ...
                    'String', ...
                    ['Stimulus: ' num2str(index) '/' num2str(seqLength) sprintf('\r\n') ...
                     'Repeat: ' num2str(repeat) '/' num2str(numRepeats)]);
                % Select current stimulus on the stimEditor
                self.stimEditor.setSelectedRows(sequence(index, repeat)+1);
            else
                if isempty(sequence)
                    if repeat == 0
                        set(self.runLabel, 'String', 'Showing fill up.');
                        self.stimEditor.setSelectedRows(self.params.numStim);
                    else
                        set(self.runLabel, 'String', 'Showing top up.');
                        if strcmp(self.params.experimentType, 'adapt')
                            self.stimEditor.setSelectedRows(self.params.numStim-1);
                        else
                            self.stimEditor.setSelectedRows(self.params.numStim);
                        end
                    end
                else
                    set(self.runLabel, 'String', ['Making stim ' num2str(index)]);
                    self.stimEditor.setSelectedRows(index+1);
                end
            end
            
            drawnow;
            r = 0;
        end
        
        function selectionCB(self)
            % ignore if running
            if self.running
                return;
            end
            % if stil row(s) selected
            if ~isempty(self.stimEditor.getSelectedRows())
                set(self.stimMenu, 'Enable', 'on');
            else
                set(self.stimMenu, 'Enable', 'off');
            end
            
            if ~isempty(self.stimEditor.getSelectedColumn())
                set(self.paramMenu, 'Enable', 'on');
            else
                set(self.paramMenu, 'Enable', 'off');
            end
        end
        
        function rangeCB(self)
            matlabui.showRangeSetDialog(self.params, ...
                self.stimEditor.getSelectedColumn(), self.fig);
            self.stimEditor.lightUpdate();
        end
        
        function setToCB(self)
            col = self.stimEditor.getSelectedColumn();
            pramName = self.params.xFile.paramNames{col};
            val = inputdlg2(['Set parameter ' pramName ' to:'] , 'Input');
            if isempty(val) || isempty(val{1}) || ~isscalar(val)
                return;
            end
            testVal = self.params.stimuli{1,col};
            colCell = cell(1, self.params.numStim);
            colCell{1} = testVal;
            colCell(2:end) = repmat({val{1}},self.params.numStim-1,1);
            try
                self.params.setParamCol(col, colCell);
            catch e
                msgbox(e.message, 'Error')
            end
            
            self.stimEditor.lightUpdate();
        end
        
        function rowCB(self)
            numCol = self.params.numCol;
            numRow = self.params.numRow;
            row = inputdlg2(['Please enter ' num2str(numRow) ' numbers.'], 'Input');
            if isempty(row)
                return;
            end
            row = str2num(row{1}); %#ok<ST2NM>
            s = size(row);
            if s(1) ~=1 || s(2) ~= numRow || ~isreal(row)
                msgbox(['Please enter ' num2str(numRow) ' numbers.']);
                return;
            end
            row = cellfun(@num2str, num2cell(row), 'UniformOutput', 0)';
            p = self.stimEditor.getSelectedColumn();
            
             % setup new column values, first stim is sandbox so don't set it
            paramCol = self.params.stimuli(2:end, p);
            for i = 1:numRow
                paramCol(1+(i-1)*numCol:1+i*numCol-1) = repmat({row{i}}, numCol, 1); %#ok<CCAT1>
            end
            testVal = self.params.stimuli{1,p};
            try
                self.params.setParamCol(p, [testVal; paramCol]);
            catch e
                msgbox(e.message, 'Error')
            end
            
            self.stimEditor.lightUpdate();
        end
        
        function colCB(self)
            numCol = self.params.numCol;
            numRow = self.params.numRow;
            col = inputdlg2(['Please enter ' num2str(numCol) ' numbers.'], 'Input');
            if isempty(col)
                return;
            end
            col = str2num(col{1}); %#ok<ST2NM>
            s = size(col);
            if s(1) ~=1 || s(2) ~= numCol || ~isreal(col)
                msgbox(['Please enter ' num2str(numCol) ' numbers.']);
                return;
            end
            col = cellfun(@num2str, num2cell(col), 'UniformOutput', 0)';
            p = self.stimEditor.getSelectedColumn();
            
            % setup new column values, first stim is sandbox so don't set it
            paramCol = self.params.stimuli(2:end, p);
            paramCol(1:(numCol*numRow)) = repmat(col, numRow, 1);
            testVal = self.params.stimuli{1,p};
            try
                self.params.setParamCol(p, [testVal; paramCol]);
            catch e
                msgbox(e.message, 'Error')
            end
            
            self.stimEditor.lightUpdate();
        end
        
        function saveCB(self)
            path = fullfile(self.lastDir, [self.params.name '.p']);         
            self.saveParams(path);
        end
        
        function saveAsCB(self)
            oldName = fullfile(self.lastDir, [self.params.name '.p']);
            [fileName, filePath] = uiputfile({'*.p','Parameter Files';...
                '*.*','All Files'},'Save Parameter File',...
                oldName);
            
            if fileName == 0
                return;
            end
            self.params.name = fileName(1:end-2);
            path = fullfile(filePath, fileName);
            self.saveParams(path);
            self.updateFileList();
            self.dirty = false;
        end
        
        function saveParams(self, path)
            oldStim = self.params.stimuli();
            try
                % remove "sandbox" stim
                % TODO: clean this up.
                self.params.stimuli = self.params.stimuli(2:end, 1:end);
                self.params.writeToFile(path);
            catch e
                msgbox(e.message, 'Error')
            end
            self.params.stimuli = oldStim;
            set(self.fig, 'Name', [self.params.name ' - mPep']);
            self.dirty = false;
        end
        
        function hostsCB(self)
            self.stimServer.disconnect();
            self.dataHostComs.disconnect();
            [s d] = matlabui.showHostsDialog();
            % user canceled hosts dialog
            if isempty(s)
                self.stimServer.connect();
                self.dataHostComs.connect();
            else
               self.inited = false;
               self.stimServer = s;
               self.dataHostComs = d;
            end
        end
        
        % test selected stim
        function testStimCB(self)
            % test selected rows
            rows = self.stimEditor.getSelectedRows();
            
            % render params
            try
                rp = self.params.renderSubset(rows);                
            catch e
                if strcmp(e.message, 'Not all variables set!')
                    if ~self.setVars(rows) % request for vars to be set
                        return;
                    else % try again
                        self.testStimCB();
                        return;
                    end
                else
                    msgbox(e.message, 'Error');
                    return;
                end
            end
            
            self.setControlsEnabled(false);
            try
%                 self.dataHostComs.startZeroBlock();
                for i = 1:length(rows)
                   stim = rp.stimuli(i,1:end);
                   duration = rp.getDuration(i);
                   self.stimEditor.setSelectedRows(rows(i));
                   self.showStim(stim, rows(i), duration);
                end
%                 self.dataHostComs.endZeroBlock();
            catch e
                self.setControlsEnabled(true);
                msgbox(e.message, 'Error');
                return;
            end
            self.stimEditor.setSelectedRows(rows);
            self.setControlsEnabled(true);

        end
        
        function testDefault(self)
            self.stimEditor.setSelectedRows(1);
            self.testStimCB();
        end
        
        function testAllCB(self)
            self.stimEditor.setSelectedRows(2:self.params.numStim);
            self.testStimCB();
        end
        
        % show test stim
        function showStim(self, stim, index, ~)
            if ~self.inited
                % initialize
                self.inited = true;
                self.stimServer.stimInitialize(self.params.xFile.name);
            end
            self.stimServer.makeStim(stim);
            %             self.dataHostComs.stimStartTest(0, -1, stim(1));
            %             self.dataHostComs.stimEndTest(0, -1);
            self.dataHostComs.stimStartTest(self.animal, self.series, self.experiment, 0, -1, stim(1));
            self.stimServer.showStim(stim);
            self.dataHostComs.stimEndTest(self.animal, self.series, self.experiment, 0, -1);

        end
        
        function newCB(self)
            % cd into last dir so uigetfile opens in it
            ps = Paths();
            xfileDir = ps.xfiles;
            dir = cd;
            try 
                cd(xfileDir);
            catch e %#ok<NASGU>
                msgbox('Can not open xfile directory.', 'error');
                return;
            end
            
            % open dialog
            [fn pn] = uigetfile('*.x', 'Select x-file', 'MultiSelect', 'off');
            cd(dir);
            
            % no file selected
            if fn == 0
                return;
            end
            
            try
                newparam = Params(fullfile(pn,fn));
            catch e
                msgbox('You must choose a file in the x-file directory!', 'error');
                disp(e.message);
                return;
            end
            
            [fileName, filePath] = uiputfile({'*.p','Parameter Files';...
                '*.*','All Files'},'Save New Parameter File',...
                self.lastDir);
            
            if fileName == 0
                return;
            end
            
            path = fullfile(filePath, fileName);
            try
                newparam.writeToFile(path);
                self.openParamFile(path);
            catch e
                msgbox(e.message, 'Error')
            end
            
            self.updateFileList();
        end
        
        function aboutCB(self)
            S = ver('mpep');
            msgbox(['mPEP version:' S.Version], 'About');
        end
        
        function paramsModified(self, evt)
           
           if ~isequal(evt.rows, 1)
               self.makeDirty();
           end
        end
        
        function makeDirty(self)
            self.dirty = true;
            set(self.fig, 'Name', ['*' self.params.name ' - mPep'])
        end
        
        function playTada(self) %#ok<MANU>
            rootdir = fileparts(mfilename('fullpath'));
            load(fullfile(rootdir, 'tada.mat'));
            player = audioplayer(y, Fs);
            playblocking(player);
        end
    end
    
    methods(Static = true)
       function r = getInterruptReason()
          r = inputdlg2('Reason for interrupt', 'Prompt');
          if isempty(r)
              r = '';
          else
              r = r{1};
          end
       end
       
    end
    
end

