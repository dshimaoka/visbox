classdef XFile < handle
    %XFILE Class to represent an .x file.
    %   Constructor creates an instance from a .x file
    
    properties(SetAccess = private)
        name = '';
        numParams = 0;
        
        paramNames = {};
        paramDescriptions = {};
        % following matricies should all be int64 type
        paramDefaults = [];
        % numParams x 2 int64 matrix
        paramRange = [];
        paramStep = [];
    end
    
    methods
        function self = XFile(filepath)
            [fid message] = fopen(filepath);
            if fid == -1
               error(['Error upon opening xfile "' filepath '" : ' message]);
            end
            
            % name is just name of xfile not including '.x'
            [~,fname,~] = fileparts(filepath);
            self.name = fname;
            
            % read the first line which specifies number of params as third
            % field - not sure what the use of the first two are
            firstLine = textscan(fid, '%s %s %d', 1, 'commentStyle', '#');
            self.numParams = firstLine{3};
            % parse the file row/columns into cellarray
            paramLines = textscan(fid, '%d %s %q %d %s %s', 'commentStyle', '#');
            % if the numbers at the begining of each line are not what we
            % expect throw an error
            if ~isequal(paramLines{1}', 0:(self.numParams-1))
                error(['Unexpected parameter indices in xfile ' filepath])
            end
            
            self.paramNames = paramLines{2}';
            self.paramDescriptions = paramLines{3}';
            self.paramDefaults = int64(paramLines{4}');
            
            % parse range string cell array into numParams x 2 matrix
            ranges = paramLines{5};
            self.paramRange = int64(zeros(self.numParams, 2));            
            try
                for i = 1:self.numParams
                   % convert "from-range" type strings to a 2d matrix
                   % handles extra -'s for negatives fine
                   self.paramRange(i,:) = int64(sscanf(ranges{i}, '%d-')');
                end
            catch e %something went wrong - sscanf returned wrong dim matrix
               error(['Unable to parse ranges in xfile ' filepath]);
            end
            
            % parse step field
            steps = paramLines{6};
            self.paramStep = int64(zeros(1, self.numParams));  
            try
                for i = 1:self.numParams
                   self.paramStep(i) = int64(sscanf(steps{i}, '%d')');
                   if(steps{i}(end) == '-')
                       self.paramStep(i) = -self.paramStep(i);
                   end
                end
            catch e %something went wrong - sscanf returned wrong dim matrix
               error(['Unable to parse steps (last field of params) in xfile ' filepath]);
            end
            
            fclose(fid);
        end
        
        % check if a value is valid for a particular parameter (1-base
        % indexing of params)
        function r = paramValid(self, index, value)  
            range = self.paramRange(index, 1:2);
            % check in range
            r = (floor(value) == value) && value >=  range(1) && value <= range(2);            
            % should check correct step
        end
    end
    

    
end

