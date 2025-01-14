function showExperimentPropertiesDialog(params, parentFig)
%SHOWEXPERIMENTPROPERTIESDIALOG Given a Params object show a dialog which
% allows setting of row/col size and experiment type. Optional parentFig
% argument allows for good default placement of the new figure. This
% function blocks until the user clicks ok, cancel, or closes the dialog.

f = figure();
set(f, 'MenuBar', 'none', 'Name', 'Properties', 'NumberTitle', 'off','Resize', 'off',...
    'WindowStyle', 'modal');
w = 255;
h = 160;
if nargin == 2 % position releative to "parent" figure
    parentPos = get(parentFig, 'Position');
    newPos = [parentPos(1)+parentPos(3)/2-w/2, parentPos(2)+parentPos(4)/2-h/2, w, h];
    set(f, 'Position', newPos);
end

colw1 = 150;
colw2 = w-colw1-15;
colh = 25;
% g = uiextras.Grid( 'Parent', f, 'Spacing', 5 , 'Padding', 5);
% set( g, 'ColumnSizes', [-1 -1], 'RowSizes', [20 25 25 25 25 25] );
l = uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Number of test stimuli:', ...
    'Position', [5, h-colh-5, colw1, 25]);
uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Number of rows:', ...
    'Position', [5, h-colh*2-5, colw1, 25])
uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Number of columns:', ...
    'Position', [5, h-colh*3-5, colw1, 25])
uicontrol( 'Parent', f, 'Style', 'text', 'String', 'Type of experiment:', ...
    'Position', [5, h-colh*4-5, colw1, 25])
uicontrol( 'Parent', f, 'Style', 'text', 'String', 'XFile:', ...
    'Position', [5, h-colh*5-5, colw1, 25])
uicontrol( 'Parent', f, 'String', 'Cancel', 'Callback', @(src,evt) delete(f), ...
    'Position', [5, h-colh*6-5, w/2-5, 25])

uicontrol( 'Parent', f, 'Style', 'edit', 'String', num2str(params.numStim), 'Enable', 'off', ...
    'Position', [5+colw1+5, h-colh-5, colw2, 25], 'Background', [1 1 1])
numRowH = uicontrol( 'Parent', f, 'Style', 'edit', 'String', num2str(params.numRow), ...
    'Position', [5+colw1+5, h-colh*2-5, colw2, 25], 'Background', [1 1 1]);
numColH = uicontrol( 'Parent', f, 'Style', 'edit', 'String', num2str(params.numCol), ...
    'Position', [5+colw1+5, h-colh*3-5, colw2, 25], 'Background', [1 1 1]);

val = find(ismember(Params.validExperiementTypes, params.experimentType)==1);

typeH = uicontrol( 'Parent', f, 'Style', 'popupmenu', 'String', Params.experimentTypeLabels, ...
    'Value', val, ...
    'Position', [5+colw1+5, h-colh*4-5, colw2, 25], 'Background', [1 1 1]);
uicontrol( 'Parent', f, 'Style', 'edit', 'String', params.xFile.name, 'Enable', 'off', ...
    'Position', [5+colw1+5, h-colh*5-5, colw2, 25], 'Background', [1 1 1]);
uicontrol( 'Parent', f, 'String', 'OK', 'Callback', @(src,evt) ok(), ...
    'Position', [w/2, h-colh*6-5, w/2-5, 25])

set(f, 'Color', get(l, 'BackgroundColor'))

uiwait(f);

    function ok()
        numRow = str2double(get(numRowH, 'String'));
        numCol = str2double(get(numColH, 'String'));
        if isempty(numRow) || isempty(numCol) || numRow < 0 || numCol < 0
            msgbox('Please enter positive numerical values for numer of rows and number of columns.', 'Invalid input.')
            return;
        end
        
        if numRow*numCol > params.numStim-1
            msgbox('numRow*numCol must be less than number of test stimuli.', 'Invalid input.')
            return;
        end
        
        type = Params.validExperiementTypes{get(typeH, 'Value')};
        
        params.numRow = numRow;
        params.numCol = numCol;
        params.experimentType = type;
        delete(f);
    end
end

