function [fullpath, filename] = expFilePath(varargin)
%DAT.EXPFILEPATH Full path for file pertaining to designated experiment
%   Returns the path(s) that a particular type of experiment file should be
%   located at for a specific experiment. i.e. if you want to know where a
%   file should be saved to, or where to load it from, use this function.
%
%   e.g. to get the paths for an experiments 2 photon TIFF movie:
%   DAT.EXPFILEPATH('mouse1', datenum(2013, 01, 01), 1, '2p-raw');
%
%   [full, filename] = expFilePath(ref, type, [reposlocation])
%
%   [full, filename] = expFilePath(subject, date, seq, type, [reposlocation])
%
%   Options for reposlocation are: 'local' or 'master'
%   Many options for type: as of 14/5/20
% 'hw-info'
% 'timeline'
% 'eyetracking'
% 'parameters'
% 'expdeffun'
% 'widefield'
% 'widefield_raw'
% 'eyetracking_raw'

% 2013-03 CB created

if nargin == 3 || nargin == 6%5
    % repos argument was passed, save the value and remove from varargin
    location = varargin(end);
    varargin(end) = [];
elseif nargin < 2
    error('Not enough arguments supplied.');
else
    % repos argument not passed
    location = {};
end

% tabulate the args to get complete rows
[varargin{1:end}, singleArgs] = tabulateArgs(varargin{:});

% last argument is the file type
fileType = varargin{end};
% convert file types to file suffixes
[repos, suffix, dateLevel] = mapToCell(@typeInfo, fileType);

reposArgs = cat(2, {repos}, location);

% and the rest are for the experiment reference
[expPath, expRef] = dat.expPath(varargin{1:end - 1}, reposArgs{:});

    function [repos, suff, dateLevel] = typeInfo(type)
        % whether this repository is at the date level or otherwise deeper at the sequence
        % level (default)
        dateLevel = false;
        switch lower(type)
            %% almost everything goes to Market server
            case 'hw-info' % MAT-file with info about the hardware used for an experiment
                repos = 'main';
                suff = '_hardwareInfo.mat';
            case 'timeline' % MAT-file with acquired timing information
                repos = 'main';%'expInfo';
                suff = '_Timeline.mat';
            case 'eyetracking'
                repos = 'main';%'eyeTracking';
                suff = '_eye';
            case 'parameters' % MAT-file with parameters used for experiment
                repos = 'main';%'expInfo';
                suff = '_parameters.mat';
            case 'expdeffun'
                repos = 'main';%'expInfo';
                suff = '_expDef.m';
            case 'widefield' %cannot use because svd does not follow this format?
                repos = 'main';
                suff = '_SVD.mat'; %?
                
            %% Vault server
            case 'widefield_raw'
                repos = 'vault';
                suff = ''; %?
            case 'eyetracking_raw'
                repos = 'vault';
                suff = '';
                
                %% 2p-related. NOT YET IMPLEMENTED
            case '2p_raw' % TIFF with 2-photon raw fluorescence movies & ThorSync files %25/6/2020
                repos = 'vault';
                suff = '';
            case '2p' %16/7/20
                repos = 'main';
                suff = '';
                %          case '2p-raw' % TIFF with 2-photon raw fluorescence movies
                %         repos = 'twoPhoton';
                %         suff = '_2P.tif';
                %       case 'calcium-preview'
                %         repos = 'twoPhoton';
                %         suff = '_2P_CalciumPreview.tif';
                %       case 'calcium-reg'
                %         repos = 'twoPhoton';
                %         suff = '_2P_CalciumReg';
                %       case 'calcium-regframe'
                %         repos = 'twoPhoton';
                %         suff = '_2P_CalciumRegFrame.tif';
                %       case 'calcium-roi'
                %         repos = 'twoPhoton';
                %         suff = '_ROI.mat';
                %       case 'calcium-fc' % minimally filtered fractional change frames
                %         repos = 'twoPhoton';
                %         suff = '_2P_CalciumFC';
                %       case 'calcium-ffc' % ROI filtered fractional change frames
                %         repos = 'twoPhoton';
                %         suff = '_2P_CalciumFFC';
                
                %% others. DELETE?
                  %       case 'lasermanip'
                %         repos = 'expInfo';
                %         suff = '_laserManip.mat';
                %       case 'img-info'
                %         repos = 'twoPhoton';
                %         suff = '_imgInfo.mat';
                %       case 'calcium-widefield-svd'
                %         repos = 'widefield';
                %         suff = '_SVD';
                %       case 'svdspatialcomps'
                %         dateLevel = true;
                %         %               expPath = mapToCell(@fileparts, expPath);
                %         %                 repos = 'expInfo';
                %         %                 suff = '_expDef.m';
                
            otherwise
                error('"%s" is not a valid file type', type);
        end
    end

% generate a filename for each experiment
filename = cellsprintf('%s%s', expRef, suffix);

% generate a fullpath for each experiment
fullpath = mapToCell(@(p, f) file.mkPath(p, f), expPath, filename);

if singleArgs
    % passed a single input, so make sure we return one
    fullpath = fullpath{1};
    filename = filename{1};
end

end

