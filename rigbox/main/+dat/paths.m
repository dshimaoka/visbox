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

%server_market = 'C:\Users\Experiment\Documents\MATLAB\Data';%'\\zubjects.cortexlab.net';
%server_market = '\\ad.monash.edu\home\User006\dshi0006\Documents\tempMarketServer';
server_market = 'M:'; %23/6/20

%server_vault = 'C:\Users\Experiment\Documents\MATLAB\Data';%'\\zserver.cortexlab.net';
%server_vault = '\\ad.monash.edu\home\User006\dshi0006\Documents\tempVaultServer';
server_vault = 'V:'; %23/6/20

%% defaults
% Repository for local copy of everything generated on this rig
% p.localRepository = '\\zserver\Data\expInfo';%'C:\LocalExpData';
p.localRepository = 'C:\LocalExpData';
% for all data types, under the new system of having data grouped by mouse
% rather than data type
p.mainRepository = fullfile(server_market, 'Subjects');
% Repository for info about experiments, i.e. stimulus, behavioural,
% Timeline etc

p.expInfoRepository = fullfile(server_market, 'Subjects'); %restored for mpep

%for long-term storage  14/5/20 
p.vaultRepository = fullfile(server_vault, 'Subjects');

%% for rig-specific configuration

% path containing rigbox config folders
% p.rigbox = fullfile(zserverName, 'code', 'Rigging');
p.rigbox = 'C:\Users\Experiment\Documents\MATLAB\visbox';

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