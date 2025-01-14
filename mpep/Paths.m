function r = Paths()
global DIRS;
if isunix % linux development environment (ignore or delete this)
    r.data =  'test_data';
    r.xfiles = '/home/luke/Dropbox/zpep_work/xfiles/';
    r.config = 'config.mat';
else
    try % try to use SetDefaultDirs if available
        SetDefaultDirs();
        r = DIRS;
        r.config = fullfile(getenv('USERPROFILE'),'mpep_config.mat');
    catch e % SetDefaultDirs not available.
        % Edit these paths to make mpep work in the lab
        % directory where mpep saves experiment logs
        r.data = fullfile(cd, 'test_data');
        % directory where mpep expects to find xfiles
        r.xfiles = fullfile(cd, 'xfiles');
        % config path for mpep
        r.config = fullfile(getenv('USERPROFILE'),'mpep_config.mat');
    end
end

