function num = findNextExpNumber(animal, series)
%FINDNEXTEXPNUMBER Given an animal name and experiement series find the
% next valid experiment number (1 if new series or animal)

dirs = Paths();
dataDir = dirs.data;
if ~exist(dataDir, 'dir')
    error(['Can not find data directory: ', dataDir]);
end

% If animal dir does not exist return 1
if ~exist(fullfile(dataDir, animal), 'dir');
    num = 1;
    return;
end

% Check series is numeric, make it a string of the number if required
if isnumeric(series)
    series = num2str(series);
end
if isnan(str2double(series))
    error('Series needs to be a scalar number, or string of a scalar number.');
end

% If series dir does not exist return 1
if ~exist(fullfile(dataDir, animal, series), 'dir');
    num = 1;
    return;
end

% Return maximum number in animal/series directory + 1
num = maxNumberInDir(fullfile(dataDir, animal, series))+1;

end

