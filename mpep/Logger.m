classdef Logger < handle
    % Handles writing to animal log file.
    properties
        % default to writing to stdout if animal not specified
        fhandle = 1;
        animal = [];
    end
    
    methods
        function selectAnimal(self, animal)
            % close any open files
            if ~isempty(self.fhandle) && self.fhandle ~=1
                fclose(self.fhandle);
            end
            self.animal = animal;

            dirs = Paths();
            dataDir = dirs.data;
            if ~exist(dataDir, 'dir')
                error(['Can not find data directory: ', dataDir]);
            end
            % create animal dir if it does not exist
            if ~exist(fullfile(dataDir, self.animal), 'dir');
                mkdir(fullfile(dataDir, self.animal));
            end
            
            % open/create log file for writing
            logFilePath = fullfile(dataDir, self.animal, [self.animal '.txt']);
            self.fhandle = fopen(logFilePath, 'at');
            if self.fhandle == -1
               self.fhandle = [];
               self.animal = [];
               error(['Unable to open/create log file for animal ' animal]);
            end
            
            % write log file opened
            self.write('Log file opened');
        end
        
        function pfileOpened(self, path)
            self.write(['Loaded parameter file ' path]);
        end 
        
        function start(self, series, exp, params, comment)
            if nargin == 4
                comment = '';
            end
            disp(['Logger, start ' path ' ' exp]);
            fileStr = [self.animal '\' series '\' num2str(exp) '\' self.animal '_' series '_' num2str(exp)];
            self.write(['Starting Series ' series ' Exp ' num2str(exp) ' (File ' fileStr '). ' comment]);
            str = '';
            for i = 1:length(params.values)
               str = [str params.variables{i} '=' num2str(params.values{i}) '; ']; 
            end
            self.write(str);
        end
        
        function complete(self, series, exp, comment)
            disp(['Logger, complete exp.']);
            self.write(['Completed Experiment ' num2str(exp) '. ' comment]);
        end
        
        function interrupt(self, rep, reason)
            if nargin == 2
                reason = [];
            end
            self.write(['Interrupted during repeat ' num2str(rep) '. ' reason]);
        end
        
        function write(self, string)
            pre = [datestr(now, 'dd-mmm-yyyy HH:MM') ' --- '];
            fprintf(self.fhandle, [pre '%s' '\n'], string);
        end
        
        function close(self)
           if ~isempty(self.fhandle) && self.fhandle ~= 1
              fclose(self.fhandle); 
           end
        end
        
        function delete(self)
           self.close(); 
        end
    end
    
    methods(Access = private)
        function self = Logger()
            disp('Creating logger');
        end
    end
    
    properties(Constant = true)
       singleton = Logger(); 
    end
    
    methods(Static = true)
    end
    
end

