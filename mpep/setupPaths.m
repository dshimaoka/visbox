function setupPaths()
mlock;
persistent added;
if isempty(added)
    added = 1;
    rootdir = fileparts(mfilename('fullpath'));
    javaaddpath(rootdir);
    javaaddpath(fullfile(rootdir, '+javaui'));
end
end

