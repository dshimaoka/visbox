classdef RenderedParams
    %RENDEREDPARAMS A list of paramiters for an xfile. This is generated
    %from a .pfile that is opened and variables are set. This class is
    %immutable, hence it's not a handle class.
    
    % Note although this looks similar to Params it's sematically different
    % enough that it warrents a new class, and no subclassing. Rendered
    % param files indicate an experiment is to be/has been run, quite
    % different from a p file and I want to hilight the separation.
    properties(SetAccess = private)
        % name of pfile - not including extension
        name;
        xFile;
        % numStim * numParam int64 matrix
        stimuli;
        
        numStim;
        numParam;
        
        % for matrix commands
        numRow;
        numCol;
        
        % variable settings
        variables;
        values;
        
        experimentType;
        
        minimumWait;
        deadTime;
        expEndDelay;
        blockEndDelay; %6/10/19
    end
    
    methods
        function self = RenderedParams(name, xFile, stimuli, numRow, numCol, ...
                variables, values, experimentType, minimumWait, deadTime, ...
                expEndDelay, blockEndDelay)
            self.name = name;
            self.xFile = xFile;
            self.stimuli = stimuli;
            self.numRow = numRow;
            self.numCol = numCol;
            self.variables = variables;
            self.values = values;
            self.experimentType = experimentType;
            self.minimumWait = minimumWait;
            self.deadTime = deadTime;
            self.expEndDelay = expEndDelay;
            self.blockEndDelay = blockEndDelay;%6/10/19
            [self.numStim self.numParam] = size(stimuli);
        end
        
        % Write this object to a .p file, this is used as a log of the
        % experiment.
        function writeToFile(self, path)
            fid = fopen(path, 'wt');
            [s, p] = size(self.stimuli);
            fprintf(fid, [self.xFile.name '.x\n']);
            fprintf(fid, [upper(self.experimentType) '\n']);
            fprintf(fid, '%d %d %d\n', s, p, 0); % find out what 0 is
            fprintf(fid, '%d %d %d\n', 0, self.numRow, self.numCol); % find out what 0 is
            for i = 1:s
                for j = 1:p
                    % write out rep num symbol, or actual number
                    if self.stimuli(i, j) == Params.repNumMagic
                        str = '#';
                    else
                        str = sprintf( '%d ', self.stimuli(i, j));
                    end
                    if j ~= p
                        fprintf(fid, '%s ', str);
                    else
                        fprintf(fid, '%s', str);
                    end
                end
                fprintf(fid, '\n');
            end
            fclose(fid);
        end
        
        function r = getDuration(self, index)
            % assume duration is always first param
            r = double(self.stimuli(index, 1));
        end
    end
end


