function p = reposPath(name, location)
%DAT.REPOSPATH Get the path to a named data repository
%   p = DAT.REPOSPATH(name, [location]) returns paths to the named
%   repository specified by 'name'.
%
%   Each repository can have multiple locations with one location being the
%   "master" copy and others considered backups (e.g. copies on local
%   machines). Users of this function wanting to *save* data should do so
%   in all locations. To *load* data, the master may be the only location
%   containing all data (i.e. because local copies will only be on specific
%   machines). The optional 'location' parameter specifies one or more
%   locations, with "all" being the default that returns all locations for
%   that repository, and "master" will return the path to the master
%   location.
%
%   e.g. to get all paths you should save to for the "expInfo" repository:
%   savePaths = DAT.REPOSPATH('expInfo') % savePaths is a string cell array
%
%   To get the master location for the "expInfo" repository:
%   loadPath = DAT.REPOSPATH('expInfo', 'master') % loadPath is a string
%
% Part of Rigbox

% 'name' list:
% main
% expInfo
% twoPhoton
% widefield
% eyeTracking
% lfp
% spikes


% 2013-03 CB created

paths = dat.paths;

%% Deal with wildcard repos mode, i.e. if name='*' list them all
if strcmpi(name, '*')
  % "*" for repository name means return them all
  if nargin == 1
    fn = fieldnames(paths);
    endInRepos = fn(~emptyElems(regexp(fn, 'Repository$')));
    p = cellfun(@(n) paths.(n), endInRepos, 'uni', false);
    return
  else
    error('With wildcard repositories mode (name=''*'') you should not specify a location');
  end
end

%% Default parameters
if nargin < 2
  if strcmpi(name, 'local')
    location = {'local'};
  else
    location = 'all';
  end
end

if strcmpi(location, 'all')
  % "all" currently always means "local" and "master" locations
  location = {'local'; 'master'};
end

%% Deal with multiple locations (if 'location' is a cell array)
if iscell(location)
  % Recursive call with each location and return a cell array of results
  p = cellfun(@(loc) dat.reposPath(name, loc), location, 'uni', false);
  return
end

%% Return path to named repository of a particular location
switch lower(location)
  case {'master' 'm'}
    p = paths.([name 'Repository']);
  case {'local' 'l'}
    p = paths.localRepository;
  otherwise
    error('"%s" is not a recognised repository location.', location);
end

end