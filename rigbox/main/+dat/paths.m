function p = paths(rig)
%DAT.PATHS Returns struct containing important paths
%   p = DAT.PATHS([RIG])
%
% Part of Rigbox

% 2013-03 CB created

thishost = hostname;

if nargin < 1 || isempty(rig)
  rig = thishost;
end

% server = 'S:\biomed-physiology\imaging-data\vsPC\Documents\MATLAB\Data';
% server = 'C:\Users\Experiment\Documents\MATLAB\Data'; %14/5/25 disabled
server = 'M:';

%% defaults
% Repository for local copy of everything generated on this rig
% p.localRepository = '\\zserver\Data\expInfo';%'C:\LocalExpData';
p.localRepository = 'E:\LocalExpData';
% for all data types, under the new system of having data grouped by mouse
% rather than data type
p.mainRepository = fullfile(server, 'Subjects');
% Repository for info about experiments, i.e. stimulus, behavioural,
% Timeline etc

p.expInfoRepository = fullfile(server, 'Subjects'); %restored for mpep

p.vaultRepository = fullfile(server, 'Subjects');

%% for rig-specific configuration

% path containing rigbox config folders
% p.rigbox = fullfile(zserverName, 'code', 'Rigging');
p.rigbox = 'C:\Users\Experiment\Documents\MATLAB\visbox\rigbox';

% directory for organisation-wide configuration files
p.globalConfig = fullfile(p.rigbox, 'config');

% directory for rig-specific configuration files
p.rigConfig = fullfile(p.globalConfig, rig);
%p.rigConfig = 'C:\Users\Experiment\Documents\MATLAB\Data\code\Rigging\config\Experiment'; %hack

%% load rig-specific overrides from config file, if any 
%this applies only to "master" not "local"
customPathsFile = fullfile(p.rigConfig, 'paths.mat');
if file.exists(customPathsFile)
  customPaths = loadVar(customPathsFile, 'paths');
  if isfield(customPaths, 'centralRepository')
    % 'centralRepository' is deprecated, remove field, if any
    customPaths = rmfield(customPaths, 'centralRepository');
  end
  % merge paths structures, with precedence on the loaded custom paths
  p = mergeStructs(customPaths, p);
end


end