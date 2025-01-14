To get mpep running all you need to do is
 - edit Paths.m to point to correct directories.
 - run "mpep" on the matlab command window

The default settings of
"
    % directory where mpep saves experiment logs
    DIRS.data = fullfile(cd, 'test_data');
    % directory where mpep expects to find xfiles
    DIRS.xfiles = fullfile(cd, 'xfiles');
    % config path for mpep (currently in working directory)
    DIRS.config = 'config.mat';
"
allow mpep to run stand alone, but you'll want to change these to use mpep
properly. You can either ignore or delete the pfiles, xfiles, and test_data
directories within mpep.
