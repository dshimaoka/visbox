classdef VariableMapEditor < handle
    %VARIABLEMAPEDITOR Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        table;
        map;
    end
    
    properties(SetAccess = private)
        params;
        listener;
    end
    
    properties(Dependent = true)
        uiHandle;
    end
    
    methods
        function self = VariableMapEditor(parent)
            self.table = uitable('Parent', parent);
            self.map = containers.Map();
            set(self.table, ...
                'ColumnName', [],...
                'ColumnWidth', {100},...
                'ColumnEditable', true,...
                'Position', [0 0 205 200],...
                'BackgroundColor', [1 1 1]);
            
            set(self.table, 'CellEditCallback', @(src,evt) self.cellEditCallback(src,evt));
        end
        
        function syncTableToMap(self)
            numVars = self.map.length(); 
            data = cell(numVars,1);
            keys = self.map.keys();
            for i = 1:numVars
               varName = keys{i};
               data{i} = self.map(varName);
            end
            
            set(self.table,'Data', data, 'RowName', keys);
        end
        
        function cellEditCallback(self, ~, ~)
            values = get(self.table, 'Data');
            [numVars, ~] = size(values);
            
            % check for invalid input
            for i = 1:numVars
               % if not integer reject
               if int64(values{i}) ~= values{i} % && length(values{i}) == 1
                    % roll back change
                    self.syncTableToMap();
                    return;
               end
            end
            
            varNames = get(self.table, 'RowName');
            values = get(self.table, 'Data');
            [numVars, ~] = size(values);
            % put values in var maps
            for i = 1:numVars
                self.map(varNames{i}) = values{i};
                if self.params.variableMap.isKey(varNames{i})
                    self.params.variableMap(varNames{i}) = values{i};
                end
            end
        end
        
        
        function self = setParams(self,v)
            delete(self.listener);
            self.params = v;
            % react to changes in param var map
            self.listener = self.params.addlistener('variableMapChanged', @(src,evt) self.setParams(self.params));

            numVars = self.params.variableMap.length();
            keys = self.params.variableMap.keys();
            
            for i = 1:numVars
                varName = keys{i};
                % new var added
                if ~self.map.isKey(varName)
                    self.map(varName) = self.params.variableMap(varName);
                elseif ~isempty(self.params.variableMap(varName))
                    % existing var changed
                    self.map(varName) = self.params.variableMap(varName);
                else
                    % param var value can inherit our value
                    self.params.variableMap(varName) = self.map(varName);
                end
            end
            
            self.syncTableToMap();
        end
        
        % get the UI component that this object put into it's parent during
        % construction
        function r = get.uiHandle(self)
            r = self.table;
        end
        
        function r = hasResolvedVariables(self)
            r = sum(cellfun(@isempty, self.map.values)-1) ~= 0;
        end
        
        % remove keys with empty values
        function removeEmpties(self)
            empties = cellfun(@isempty, self.map.values);
            keys = self.map.keys();
            keys = keys(empties);
            self.map.remove(keys);
            self.syncTableToMap();
        end
        
        function clear(self)
           self.map = containers.Map(); 
           self.syncTableToMap();
        end
    end
    
end
