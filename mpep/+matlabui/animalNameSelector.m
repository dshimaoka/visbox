function animalName = animalNameSelector(parentFig, currentName)
animalName = [];
f = figure();
set(f, 'MenuBar', 'none', 'Name', 'Select animal', 'NumberTitle', 'off','Resize', 'off', ...
    'WindowStyle', 'modal');
w = 200;
h = 50;
parentPos = get(parentFig, 'Position');
newPos = [parentPos(1)+parentPos(3)/2-w/2, parentPos(2)+parentPos(4)/2-h/2, w, h];
set(f, 'Position', newPos);

subjectDropdown = uicontrol('Style', 'popupmenu', 'Parent', f, 'Position',[10 h-25 (w-20)/2 25], ...
    'String', dat.listSubjects, 'Background', [1 1 1]);


uicontrol('Style', 'pushbutton', 'String', 'OK', 'Position', [10+w/2 h-25 (w-20)/2 25],'Callback', @ok);


uiwait();

    function ok(~,~)
        
        animalList = get(subjectDropdown, 'String');
        animalName = animalList{get(subjectDropdown, 'Value')};
        delete(f)
    end


end