% SetDefaultDirs sets the default directories
% 
% 2013-09-24 Matteo Carandini
% 2013-10-10 AS: line 44 & 47, corrected the variable name
% 2016-05-12 AP: added alternate server names (cortexlab.net)
% 2016-05-19 AP: zserver2 doesn't exist anymore, old server name was taking
% a long time to check for existance so switched default/alternative
% server names
% 2016-08-08 LFR: changed all the pointers to zserver2 to zserver, where
% the data has been moved
% 2017-03-20 AP: changed LFRs pointer from .ioo to .cortexlab

% Did I screw up anything? If so, please see the older version at
% \\zserver.ioo.ucl.ac.uk\Code\Archive\Spikes\Spikes 2013-09-24
% and let me know... Thanks 
% Matteo

% At some point we may want to use IP addresses to determine if we are at
% Rockefeller or at Bath Street. If the former, we should probably use
% zcloneX instead of zserverX. A method to determine IP address is:
% address = java.net.InetAddress.getLocalHost 
% IPaddress = char(address.getHostAddress)

global DIRS serverName 

if isunix 
    serverName    = '/mnt/zserver';
    
    DIRS.Temp      = '/tmp';
else   
    %     serverName     = 'C:\Users\Experiment\Documents\MATLAB';%16/5/19
    serverName = 'M:\';

    if isdir('D:\Temp')
        DIRS.Temp       = 'D:\Temp'; 
    else
        DIRS.Temp       = 'C:\Windows\Temp'; 
    end
    
end

% DIRS.data           = fullfile(serverName,'Data','Subjects'); % added 'Data' 14/6/19
DIRS.data           = fullfile(serverName,'Subjects'); % removed 'Data' 14/5/25
%DIRS.EyeTrack       = fullfile(serverName,'Data','EyeTrack');

% DIRS.xfiles         = fullfile(server2Name,'Data','xfiles');
DIRS.xfiles         = 'C:\Users\Experiment\Documents\git\stimFiles\xfiles';
% DIRS.stimInfo       = fullfile(serverName,'Data','stimInfo');
% DIRS.expInfo        = fullfile(serverName,'Data','expInfo');
DIRS.stimInfo       = fullfile(serverName,'Subjects');
DIRS.expInfo        = fullfile(serverName,'Subjects');
