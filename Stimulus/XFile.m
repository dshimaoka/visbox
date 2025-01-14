classdef XFile
    % XFILE Class for the reading and writing of x-files
    %   
    % XFILE Properties:
    %   Name - Name of the x-file
    %   nPars - Number of parameters
    %   ParDefs - Parameter definitions
    %   ParDefaults - Parameter default values
    %   ParLims - Parameter limits (nx2)
    %
    % XFILE Methods:
    % XFile - Class constructor
    % Load - Loads an existing x-file
    % Write - writes the x-file in text file
    % Ind - Finds index of a given parameter
    % WriteFirstPfile - Writes a basic p-file
    
    
    
    properties
        Name      = ''; % name, without the .x extension
        nPars     = [];
        ParNames  = [];
        ParDefs   = [];
        ParDefaults = [];
        ParLims   = []; % npars x 2
    end
    
    methods (Static)
        
        function x = XFile( name, pp )
            % XFILE builds an XFile object
            %
            % x = XFile( name, pp ) takes as input a name and a cell array
            % indicating parameter names, definitions, defaults, and
            % limits.
            
            if nargin < 2
                return
            end
            
            x = XFile;
            x.Name = name;
            x.nPars = size(pp,2);
            if strcmp( x.Name(end-1:end), '.x'  )
                x.Name = x.Name(1:end-2);
            end
            x.ParNames = cell(x.nPars,1);
            x.ParDefs  = cell(x.nPars,1);
            x.ParDefaults = zeros(x.nPars,1);
            x.ParLims  = zeros(x.nPars,2);
            for iPar = 1:x.nPars
                x.ParNames{iPar}    = pp{iPar}{1};
                x.ParDefs {iPar}    = pp{iPar}{2};
                x.ParDefaults(iPar) = pp{iPar}{3};
                x.ParLims(iPar,:)   = [pp{iPar}{4} pp{iPar}{5}];
            end
            
        end
            
        function x = Load ( xfilename, quiet )
            % LOAD loads an x-file
            %
            % x = Load ( xfilename )
            %
            % Load ( xfilename,'quiet') suppresses any text
            % output (important e.g. when called from a Visual Basic program).
            %
            % needs to be extended so it reads more properties of the x-file
            
            if nargin<2
                quiet = 'loud';
            end
            
            if nargin<1
                error('Must specify the x file to load');
            end
            
            global DIRS
            
            if ~strcmp(xfilename(end-1:end),'.x')
                xfilename = [xfilename '.x'];
            end
                        
            if ~isfield(DIRS,'xfiles')
                SetDefaultDirs;
                % error('Need to specify DIRS.xfiles');
            end
            
            if isempty(DIRS.xfiles)
                xfiledir = fullfile(fileparts(DIRS.data),'xfiles');
            else
                xfiledir = DIRS.xfiles;
            end
            
            if ~isdir(xfiledir)
                error('Problem with x file directory : it is not a directory');
            end
            
            fullxfilename = fullfile(xfiledir,xfilename);
            
            if ~exist(fullxfilename,'file')
                errordlg(['Could not find x-file ' fullxfilename ],'Spikes', 'modal');
                return;
            end
            
            xfileptr = fopen(fullxfilename,'r');
            
            if xfileptr < 0
                errordlg(['x-file ' fullxfilename ' exists but I could not open it'],'Spikes');
                return;
            end
            
            if ~strcmp(quiet,'quiet')
                disp([ 'Reading ' xfilename ]);
            end
            
            ss = fscanf(xfileptr,'%c');
            
            controlMs  = strfind(ss,10);	% the control-M characters
            endoflines = strfind(ss,13);	% the end-of-line characters
            
            begoflines = 1+[0, endoflines(1:end-1), controlMs(1:end-1)];
            % the good lines start with a number
            goodlines = find( ss(begoflines)>='0' & ss(begoflines)<='9' );
            if isempty(goodlines)
                error('Trouble reading the x-file');
            end
            
            x = XFile;

            starthere = begoflines(goodlines(1));
            thisstring = ss(starthere:end);
            [~, x.ParNames, x.ParDefs, x.ParDefaults, ParRange, ~] = ...
                strread(thisstring,'%d %s %q %d %s %s');

            x.Name  = xfilename;
            if strcmp( x.Name(end-1:end), '.x'  )
                x.Name = x.Name(1:end-2);
            end
            
            x.nPars = length(x.ParDefs);
            
            x.ParLims = zeros(x.nPars,2);
            for iPar = 1:x.nPars
                ii = strfind(ParRange{iPar},'-');
                switch length(ii)
                    case 1
                        j = ii;
                    case 2
                        if ii(1) == 1
                            % the first limit is negative
                            j = ii(2);
                        else
                            j = ii(1);
                        end
                    case 3
                        j = ii(2);
                end
                
                x.ParLims(iPar,:) = [...
                    str2double(ParRange{iPar}(1:j-1)),
                    str2double(ParRange{iPar}(j+1:end))];
            end

            successflag = 1;
            
            if ~successflag
                disp('something wrong reading the x-file');
                return;
            end
            
            fclose(xfileptr);
           
        end
    end
    
    
    methods
        
        function Write ( x )
            % Write writes an x file
            %
            % Write ( x )
            %
            
            global DIRS
            
           if ~isfield(DIRS,'xfiles')
                SetDefaultDirs;
            end
            
            if isempty(DIRS.xfiles)
                xfiledir = fullfile(fileparts(DIRS.data),'xfiles');
            else
                xfiledir = DIRS.xfiles;
            end
            
            if ~isdir(xfiledir)
                error('Problem with x file directory : it is not a directory');
            end
            
            xfilename = [x.Name '.x'];
            fullxfilename = fullfile(xfiledir,xfilename);
            
            if exist(fullxfilename,'file')
%                 choice = questdlg(...
%                     ['CAREFUL! x-file ' fullxfilename ' already exists.'], ...
%                     'Xfile','Overwrite', 'Cancel','Cancel' );
%                 if strcmp(choice,'Cancel')
%                     return;
%                 end
            end
            
            xfileptr = fopen(fullxfilename,'wt');
            
            if xfileptr < 0
                errordlg(['Could not open x-file ' fullxfilename ],'XFile');
                return;
            end
            
            fprintf(xfileptr,'#\n#\t%s\n#\n#\n',x.Name);
            fprintf(xfileptr,'foo nonperiodic\t%d\n#\n',x.nPars);

            for iPar = 1:x.nPars
                fprintf(xfileptr,'%d\t%s\t"%40s"\t%d\t%d-%d 1+\n', ...
                    iPar-1, x.ParNames{iPar},x.ParDefs{iPar},...
                    x.ParDefaults(iPar),x.ParLims(iPar,:));
            end
            
            fclose(xfileptr);
            
        end
        
        function iPar = Ind( x, strParName )
            % IND returns the index of a parameter with a given name
            for iPar = 1:x.nPars
                if strcmp( x.ParNames{iPar}, strParName )
                    return
                end
            end
            iPar = [];
        end
        
        function WriteFirstPfile( xfile )
            % WRITEFIRSTPFILE writes a simple pfile from the x-file
            %
            % WRITEFIRSTPFILE( xfile ) writes a file called FirstYada.p on the desktop,
            % where Yada is the name of the x-file. Case of the xfile name
            % must be correct (this function won't give you an error but vs
            % will later).
            %
            % Example:
            % addpath '\\zserver.ioo.ucl.ac.uk\Code\Stimulus'
            % addpath '\\zserver.ioo.ucl.ac.uk\Code\Spikes'
            % xfile = XFile.Load('stimRandNoiseFixed.x');
            % xfile.WriteFirstPfile;
            %
            % 2014-09 MC WROTE THIS AT HOME AND COULD NOT CHECK THAT IT WORKS
            %   - NS tested, seems to work fine. 
            
            DesktopDir = winqueryreg('HKEY_CURRENT_USER', 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', 'Desktop');
            PfileName = ['First' xfile.Name '.p'];
            
            myfile = fopen( fullfile( DesktopDir, PfileName ), 'w' );
            fprintf(myfile,'%s.x\r\n1 %d 0\r\n0 0 0\r\n', xfile.Name, xfile.nPars);
            fprintf(myfile,'%d ', xfile.ParDefaults);
            fprintf(myfile,'\r\nREGULAR MINWAIT 0 DEADTIME 0\r\n');
            fclose(myfile);
        end
        
    end
end


