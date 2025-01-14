function [stimServer, com] = showHostsDialog(parentFig)
%SHOWHOSTSDIALOG Summary of this function goes here
%   Detailed explanation goes here

f = figure();
set(f, 'MenuBar', 'none', 'Name', 'Hosts', 'NumberTitle', 'off', 'Resize', 'off',...
    'WindowStyle', 'modal');

% makes no difference to positioning
if nargin == 0
    parentFig = f;
end

parentPos = get(parentFig, 'Position');
width = 360;
height = 280;
newPos = [parentPos(1)+parentPos(3)/2-width/2, parentPos(2)+parentPos(4)/2-height/2, width, height];
set(f, 'Position', newPos);
settings = getSettingsStruct();



pos = get(f, 'Position');
h = pos(4);

% outerBox = uiextras.VBox('Spacing', 5,'Padding', 5);
acqHostH = 175;
acquasitionHostPanel = uipanel('Parent',f,'Title','Data acquisition hosts', ...
    'Units', 'pixels', 'Position', [10 h-acqHostH-10 310 acqHostH]);
set(f, 'Color', get(acquasitionHostPanel, 'BackgroundColor'))
% acquasitionHostBox = uiextras.VBox('Parent', acquasitionHostPanel, 'Spacing', 5, 'Padding', 5);

numDaq = 5;
daqControls = cell(5,2);
for i = 1:numDaq
    daqControls{i, 1} = uicontrol('Parent', acquasitionHostPanel, ...
        'Position', [5 acqHostH-(i*30)-15 150 25], 'Style', 'edit', 'Background', [1 1 1]);
    daqControls{i, 3} = uicontrol('Parent', acquasitionHostPanel, ...
        'Position', [165 acqHostH-(i*30)-15 55 25], 'Style', 'checkbox', 'String', 'enable');
    daqControls{i, 2} = uicontrol('Parent', acquasitionHostPanel, ...
        'Position', [165+55 acqHostH-(i*30)-15 80 25], 'Style', 'checkbox', 'String', 'bidirectional');
    [l, ~] = size(settings.datHosts);
    if i <= l
       set(daqControls{i,1}, 'String', settings.datHosts{i,1});
       set(daqControls{i,2}, 'Value', settings.datHosts{i,2});
       set(daqControls{i,3}, 'Value', settings.datHosts{i,3});
    end
end

stimHostPanel = uipanel('Parent',f,'Title','Stimulus server',...
    'Units', 'pixels', 'Position', [10 h-acqHostH-65 310 50]);
stimEdit = uicontrol('Parent', stimHostPanel, 'Style', 'edit', 'Background', [1 1 1], ...
    'String', settings.stimHost, 'Position', [5, 5, 150, 25]);
stimCheck = uicontrol('Parent', stimHostPanel, 'Style', 'checkbox', 'String', 'enable', ...
    'Value', settings.stimEnabled, 'Position', [165, 5, 80, 25]);
uicontrol('Parent', stimHostPanel, ...
        'Position', [165+55 5 80 25], 'Style', 'checkbox', ...
        'String', 'bidirectional', 'Enable', 'off', 'Value', 1);


uicontrol('Parent', f, 'String', 'Cancel', 'Callback', @(src,evt)delete(f), ...
    'Position', [5 5 (width-10)/2 25]);
uicontrol('Parent', f, 'String', 'OK', 'Callback', @(src,evt) ok(), ...
    'Position', [5+((width-10)/2) 5 (width-10)/2 25]);

stimServer = [];
com = [];
uiwait(f);



    function ok()
        % dataquastion severs/enabled
        datHostSettings = cell(5,2);
        
        for j = 1:numDaq
            datHostSettings{j, 1} = get(daqControls{j, 1}, 'String');
            datHostSettings{j, 2} = get(daqControls{j, 2}, 'Value');
            datHostSettings{j, 3} = get(daqControls{j, 3}, 'Value');
            % no string entered for host force it to be disabled
            if isempty(datHostSettings{j, 1})
                datHostSettings{j, 2} = 0;
                datHostSettings{j, 3} = 0;
            end
        end
        
        
        bidirectionalHosts = datHostSettings(find(cell2mat(datHostSettings(1:end, 2))), 1:end);
        bidirectionalHosts = bidirectionalHosts(find(cell2mat(bidirectionalHosts(1:end, 3))), 1)'; 
        normalHosts = datHostSettings(find(cell2mat(datHostSettings(1:end, 2))==0), 1:end);
        normalHosts = normalHosts(find(cell2mat(normalHosts(1:end, 3))), 1)';
        allHosts = [normalHosts bidirectionalHosts];
        
        com = DataHostCommunicator();
        com.oneWayHosts = normalHosts;
        com.bidirectionalHosts = bidirectionalHosts;
        
        stimHost = get(stimEdit, 'String');
        stimEnabled = get(stimCheck, 'Value');
        
        
        if isempty(stimHost)
            stimEnabled = 0;
        end
                   
        % check all daq hosts are at least valid names      
        for j = 1:length(allHosts)
           try
               java.net.InetAddress.getByName(allHosts{j});
           catch e %#ok<NASGU>
               msgbox(['Unable to resolve host ' allHosts{j}], 'Network error.')
               return;
           end
        end
        
        if stimEnabled
           stimServer = StimulusServer(stimHost); 
        else
           stimServer = StimulusServer(); % dummy server
        end

        
        % check connection works
        try
            if ~stimServer.connect();
               msgbox('Failed to connect to stimulus server, please check host is correct or disable it.', 'Network error.')
               stimServer.disconnect();
               stimServer = [];
               return;
            end
        catch e
           msgbox(e.message, 'Network error.')
           e.message
           stimServer = [];
           return;
        end
        
        % check com socket OK
        try
            com.connect();
        catch e
            msgbox(e.message, 'Network error.')
            return;
        end
        
        datHosts = datHostSettings; %#ok<NASGU>
        save(configPath, '-append', 'datHosts', 'stimHost', 'stimEnabled');
        delete(f);
    end
end

