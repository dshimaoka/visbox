function settings = getSettingsStruct()
if exist(configPath, 'file')
    settings = load(configPath);
else
    % fill with sane defaults
    settings = struct();
    settings.lastAnimal = [];
    settings.lastDir = [];
    % n*3 cell array. First col = host name, second = bidrectional flag,
    % third = enabled
    settings.datHosts = cell(0,3);
    settings.stimHost = '';
    settings.stimEnabled = 0;
    settings.minimumWait = 0;
    % make the config file
    save(configPath, '-struct', 'settings');
end
end