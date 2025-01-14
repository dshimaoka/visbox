function showRangeSetDialog(params, col, parentFig)
%SHOWRANGESETDIALOG Summary of this function goes here
%   Detailed explanation goes here
persistent type;
persistent fromRemember;
persistent fromSRemember;
persistent toRemember;
persistent toSRemember;
persistent paramRemember;
if isempty(type)
    type = 1;
end

if isempty(paramRemember)
   paramRemember = params; 
end

if isempty(fromSRemember) || paramRemember ~= params; 
    fromSRemember = 1;
end
if isempty(toSRemember) || paramRemember ~= params; 
    toSRemember = num2str(params.numStim-1);
end
paramRemember = params; 

f = figure();
set(f, 'MenuBar', 'none', 'Name', 'MPep', 'NumberTitle', 'off', 'Resize', 'off',...
    'WindowStyle', 'modal');
if nargin == 3 % position releative to "parent" figure
    parentPos = get(parentFig, 'Position');
    width = 240;
    height = 200;
    newPos = [parentPos(1)+parentPos(3)/2-width/2, parentPos(2)+parentPos(4)/2-height/2, width, height];
    set(f, 'Position', newPos);
end

y = height-25-5;

uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Name of param:', ...
    'Position', [5, y, 115, 25]);
uicontrol( 'Parent', f, 'Style', 'edit', 'Enable', 'off', ...
    'String', params.xFile.paramNames{col}, ...
    'Position', [5+105+5, y, 115, 25]);
y = y - 50;
fromPanel = uipanel('Parent',f,'Title','From',...
    'Units', 'pixels', 'Position', [5, y, 230, 50]);
uicontrol( 'Parent', fromPanel, 'Style', 'text', 'String', 'Value:',...
    'Position', [5 5 60 25]);
fromValue = uicontrol( 'Parent', fromPanel, 'Style', 'edit', 'String', fromRemember,...
    'Position', [60 5 50 25], 'Background', [1 1 1]);
uicontrol( 'Parent', fromPanel, 'Style', 'text', 'String', 'Stimulus:',...
    'Position', [115 5 60 25]);
fromStim = uicontrol( 'Parent', fromPanel, 'Style', 'edit', 'String', fromSRemember,...
    'Position', [175 5 50 25], 'Background', [1 1 1]);

y = y - 55;
toPanel = uipanel('Parent',f,'Title','To',...
    'Units', 'pixels', 'Position', [5, y, 230, 50]);
uicontrol( 'Parent', toPanel, 'Style', 'text', 'String', 'Value:',...
    'Position', [5 5 60 25]);
toValue = uicontrol( 'Parent', toPanel, 'Style', 'edit', 'String', toRemember,...
    'Position', [60 5 50 25], 'Background', [1 1 1]);
uicontrol( 'Parent', toPanel, 'Style', 'text', 'String', 'Stimulus:',...
    'Position', [115 5 60 25]);
toStim =uicontrol( 'Parent', toPanel, 'Style', 'edit', 'String', toSRemember,...
    'Position', [175 5 50 25], 'Background', [1 1 1]);

y = y - 30;
uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Scale type:',...
    'Position', [5 y 115 25]);
typeCombo = uicontrol( 'Parent', f, 'Style', 'popupmenu', 'String', {'Linear', 'Logarithmic'}, ...
    'Value', type, 'Position', [120 y 115 25]);

y = y - 30;
uicontrol('Parent', f, 'String', 'Cancel', 'Callback', @(src,evt) delete(f),...
    'Position', [5 y 115 25]);
uicontrol('Parent', f, 'String', 'OK', 'Callback', @(src,evt) ok(), ...
    'Position', [120 y 115 25]);

set(f, 'Color', get(typeCombo, 'BackgroundColor'));
% wait until f deleted
uiwait(f);

    function ok()
        from = str2double(get(fromValue, 'String'));
        to = str2double(get(toValue, 'String'));
        fromIndex = str2double(get(fromStim, 'String'));
        toIndex = str2double(get(toStim, 'String'));
        
        fromIndex = round(fromIndex);
        toIndex = round(toIndex);
        
        if ~isempty(find(isnan([from to fromIndex toIndex]), 1))
            msgbox('Please fill in all inputs.', 'Error')
            return;
        end
        
        % gui uses 0based indexing
        fromIndex = fromIndex+1;
        toIndex = toIndex+1;
        
        if fromIndex >= toIndex || toIndex > params.numStim
            msgbox('Invalid from/to indices.', 'Error')
            return;
        end
        
        type = get(typeCombo, 'value');  
        if type == 1
           values = linspace(from, to, toIndex-fromIndex+1);
        else
           values = logspace(log10(from), log10(to), toIndex-fromIndex+1);
        end
        
        values = round(values); % entries must be integers
        column = params.stimuli(1:end, col);
        for i = fromIndex:toIndex
            column{i} = num2str(values(i-fromIndex+1));
        end

        try
               params.setParamCol(col, column);
        catch e
            msgbox(e.message, 'Error')
            return;
        end
        
        % remember form values        
        
        fromRemember = get(fromValue, 'String');
        fromSRemember = get(fromStim, 'String');
        toRemember = get(toValue, 'String');
        toSRemember = get(toStim, 'String');
        
        delete(f);
    end
end

