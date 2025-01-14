classdef StimEditor < handle
    %STIMEDITOR Given a Prams object creates a GUI to edit and add to
    % the stimuli.
    % The "Control" from MVC (where view is the table object itself,
    % and the model is our Params object)
    % NOTE: A seperate object worries about setting the variables in stimuli.
    properties(SetAccess = private)
        table;
        rowLabelListModel;
        rowHeader;
        model;
        params;
        pane;
        
        % Handle to the component we put into parentFigure during
        % construction (if one were given)
        uiHandle;
        
        addButton;
        deleteButton;
        cutButton
        copyButton;
        pasteButton;
        
        copyData = [];
        eatEvents = false;
        
        toolTips;
        toolTipCell;
        % hack to forward key press info
        testCB = [];
    end
    
    events
       selectionChanged;
    end
    
    methods
        % params is our Params object
        % parentPanel is the panel to put ui components into
        function self = StimEditor(params, parentFigure, testCB)
            import javax.swing.*;
            
            self.params = params;
            self.table = javaObjectEDT('StimTable');
            self.table.setFillsViewportHeight(true);
            self.table.setCellSelectionEnabled(false);
            
            self.toolTips = ColumnHeaderToolTips();
            self.table.getTableHeader().addMouseMotionListener(self.toolTips);
            
            self.model = javaObjectEDT(self.table.getModel());
            
            self.rowLabelListModel = ZeroBaseListModel();
            self.rowHeader = JList(self.rowLabelListModel);
            self.rowHeader.setFixedCellWidth(50);
            self.rowHeader.setCellRenderer(RowHeaderRenderer(self.table));
            self.rowHeader.setFixedCellHeight(...
            self.table.getRowHeight());
            
            
            sp = JScrollPane(self.table);
            sp.setRowHeaderView(self.rowHeader);
            sp.getViewport().setBackground(java.awt.Color.white);
            
            self.setTableToParams();
            
            self.addButton = JButton('+');
            self.deleteButton = JButton('-');
            self.cutButton = JButton('Cut');
            self.copyButton = JButton('Copy');
            self.pasteButton = JButton('Paste');
            
            self.pane = JPanel();
            self.pane.setLayout(java.awt.BorderLayout());
            
            buttonPane = JPanel();
            buttonPane.getLayout().setAlignment(java.awt.FlowLayout.LEADING);
            buttonPane.add(self.addButton);
            buttonPane.add(self.deleteButton);
            buttonPane.add(self.cutButton);
            buttonPane.add(self.copyButton);
            buttonPane.add(self.pasteButton);

            self.pane.add(buttonPane, java.awt.BorderLayout.PAGE_START);
            self.pane.add(sp, java.awt.BorderLayout.CENTER);       
            
            jbh = handle(self.model, 'CallbackProperties');
            set(jbh,'TableChangedCallback', @(src, evt)(self.modelChanged(src, evt)));
            
            jbh = handle(self.addButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', @(src, evt)(self.addButtonCB(src,evt)));
            
            jbh = handle(self.deleteButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', @(src, evt)(self.delete(src,evt)));
            
            jbh = handle(self.cutButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', @(src, evt)(self.cut()));
            
            jbh = handle(self.copyButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', @(src, evt)(self.copy()));
            
            jbh = handle(self.pasteButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', @(src, evt)(self.paste()));
            
            jbh = handle(self.rowHeader, 'CallbackProperties');
            set(jbh, 'MousePressedCallback', @(src,evt)(self.rowHeaderCB(src,evt)));
            
            jbh = handle(self.table.getTableHeader(), 'CallbackProperties');
            set(jbh, 'MousePressedCallback', @(src,evt)(self.columnHeaderCB(src,evt)));
            
            jbh = handle(self.table, 'CallbackProperties');
            set(jbh, 'MousePressedCallback', @(src,evt)(self.tableClickCB(src,evt)));
            
            jbh = handle(self.pane, 'CallbackProperties');
            set(jbh, 'KeyPressedCallback', @(src,evt)(self.keyCB(evt)));
            
            jbh = handle(self.table, 'CallbackProperties');
            set(jbh, 'KeyPressedCallback', @(src,evt)(self.keyCB(evt)));
            
            if nargin >= 2
               [~, self.uiHandle] =  javacomponent(self.pane, [], parentFigure);
            end
            
            if nargin == 3
               self.testCB = testCB; 
            end
        end
        
        function setTableToParams(self)
            % Set table to reflect stimuli
            self.params.stimuli;
            self.rowLabelListModel.setSize(self.params.numStim);
            self.model.setDataVector(self.params.stimuli, self.params.xFile.paramNames);
            self.table.clearSelection();
            
            % Set column tooltips to xfile description of param    
            self.toolTipCell = cell(self.params.numParam,1);
            for i = 1:self.params.numParam
                col = self.table.getColumnModel().getColumn(i-1);
                from = num2str(self.params.xFile.paramRange(i,1));
                to = num2str(self.params.xFile.paramRange(i,2));
                desc = [self.params.xFile.paramDescriptions{i}...
                    ', range: [' from ',' to ']'];
                self.toolTips.setToolTip(col, desc);
                self.toolTipCell{i} = desc;
            end
            
            % set sizes
            self.table.autoResizeColWidth();
        end
        
        % updates table to params. Preserves selection. It could take less
        % work than this.
        function lightUpdate(self)
            col = self.getSelectedColumn();
            self.model.setDataVector(self.params.stimuli, self.params.xFile.paramNames);
            % set sizes
            self.table.autoResizeColWidth();
            
            if ~isempty(col)
                self.table.setRowSelectionAllowed(false);
                self.table.setColumnSelectionAllowed(true);                
                self.table.getColumnModel().getSelectionModel().addSelectionInterval(col-1,col-1);
            end
        end
        
        function r = getComponent(self)
            r = self.pane;
        end
        
        function showTestFrame(self)
            f = javax.swing.JFrame('StimEditor test');
            f.getContentPane().add(self.pane);
            f.pack();
            f.setDefaultCloseOperation(javax.swing.JFrame.DISPOSE_ON_CLOSE);
            f.setVisible(true);
        end
        
        
        function rows = getSelectedRows(self)
            if self.table.getRowSelectionAllowed == false
                rows = [];
                return;
            end
            rows = self.table.getSelectedRows()+1;
        end
        
        function column = getSelectedColumn(self)
            if self.table.getColumnSelectionAllowed == false
                column = [];
                return;
            end
           column = self.table.getSelectedColumns()+1;
        end
        
        function cut(self)
            self.copy();
            self.delete();
        end
        
        function copy(self)
            if ~isempty(self.getSelectedRows())
               selection = self.getSelectedRows();
               self.copyData = self.params.stimuli(selection, 1:end);
            end
        end
        
        function paste(self)
            if ~isempty(self.copyData)
                srows = self.getSelectedRows();
                insertAt = max(srows);
                if isempty(insertAt)
                    insertAt = self.params.numStim;
                end
                self.params.insertAt(insertAt+1, self.copyData);
                self.setTableToParams();
                self.setSelectedRows((insertAt+1:insertAt+size(self.copyData, 1))');
                notify(self, 'selectionChanged');
            end
        end
        
        function setSelectedRows(self, rows)
           self.table.setColumnSelectionAllowed(false);
           self.table.setRowSelectionAllowed(true);
           self.table.clearSelection();
           selModel = self.table.getSelectionModel();
           for i = 1:length(rows)
              selModel.addSelectionInterval(rows(i)-1,rows(i)-1); 
           end
        end
                
        % clear callbacks so allow for deletion
        function cleanup(self)
            jbh = handle(self.model, 'CallbackProperties');
            set(jbh,'TableChangedCallback', []);
            
            jbh = handle(self.addButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', []);
            
            jbh = handle(self.deleteButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', []);
            
            jbh = handle(self.copyButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', []);
            
            jbh = handle(self.pasteButton, 'CallbackProperties');
            set(jbh, 'ActionPerformedCallback', []);
            
            jbh = handle(self.rowHeader, 'CallbackProperties');
            set(jbh, 'MouseClickedCallback', []);
            
            jbh = handle(self.table.getTableHeader(), 'CallbackProperties');
            set(jbh, 'MouseClickedCallback', []);
            
            jbh = handle(self.table, 'CallbackProperties');
            set(jbh, 'MousePressedCallback', []);
            self.model = [];
            self.table = [];
            self.pane = [];
        end
        
        function setEnabled(self, flag)
           self.table.setEnabled(flag);
           self.addButton.setEnabled(flag);
           self.deleteButton.setEnabled(flag);
           self.cutButton.setEnabled(flag);
           self.copyButton.setEnabled(flag);
           self.pasteButton.setEnabled(flag);
        end
        
        function keyCB(self,evt)
            c = get(evt, 'keyCode');
            if c == 112
                self.testCB();
            end
            if get(evt, 'Modifiers') == 2
                if c == 67 % copy
                    self.copy();
                elseif c == 88 % cut
                    self.cut();
                elseif c == 86 % paste
                    self.paste();
                elseif c == 84 % ctr-t
                    self.testCB();
                    self.table.requestFocus();
                end
           end
        end
    end
    
    methods(Access = private)
        function modelChanged(self, ~, evt)
            disp('Table event.');
            if self.eatEvents
                disp('ignoring');
                return;
            end
            
            col = get(evt, 'Column')+1;
            row = get(evt, 'FirstRow')+1;
            
            if col == 0 || row == 0 % add or delete event
                return;
            end
            
            oldValue = self.params.stimuli{row,col};
            newValue = self.model.getValueAt(row-1, col-1);
            
            try
                self.params.setValue(row, col, newValue);
                pValue = self.params.stimuli{row,col};
                if ~strcmp(char(newValue), pValue)
                    self.model.setValueAt(pValue, row-1, col-1);
                end
            catch e % revert to old value if new value bad
                if strcmp(e.identifier, 'mpep:badvalue')
                    self.model.setValueAt(oldValue, row-1, col-1);
                else
                    rethrow(e);
                end
            end
        end
        
        function addButtonCB(self, ~,~)
            % add stim
            srows = self.getSelectedRows();
            insertAt = max(srows);
            if isempty(insertAt)
                insertAt = self.params.numStim;
            end
            insertAt = insertAt+1;
            self.eatEvents = true;
            self.params.insertDefaultStim(insertAt);
            self.model.insertRow(insertAt-1, self.params.stimuli(insertAt, 1:end));
            self.rowLabelListModel.setSize(self.rowLabelListModel.getSize()+1);
            
            self.eatEvents = false;
        end
        
        function delete(self, ~,~)
            if self.table.isEditing()
                msgbox('Can not remove stimulus when editng a cell.', 'Error');
                return;
            end
            
            if self.params.numStim == 2
                return;
            end
            % remove selected stim
            srows = self.getSelectedRows();
            % go backwards to preserve indexes
            srows = sort(srows, 'descend');
            for i = 1:length(srows)
                % never remove first row, it's special "test" row
                if srows(i) == 1
                    continue;
                end
                self.params.removeStim(srows(i));
                self.model.removeRow(srows(i)-1);
            end
            self.rowLabelListModel.setSize(self.params.numStim);
            notify(self,'selectionChanged')
        end
        
        function tableClickCB(self, ~, e)
            self.table.setColumnSelectionAllowed(false);
            self.table.setRowSelectionAllowed(true);
            
            notify(self,'selectionChanged');
        end
        
        function columnHeaderCB(self, ~, e)
            import javax.swing.*;
            column = self.table.getTableHeader().columnAtPoint(e.getPoint());
            if column < 0
                return;
            end
            if(e.getButton() == 3)            
                menu = JPopupMenu();
                menu.add(JMenuItem(self.toolTipCell{column+1}));
                menu.show(self.table, e.getPoint().getX(), e.getPoint().getY());
            else
                self.table.getSelectionModel().clearSelection();
                self.table.setRowSelectionAllowed(false);
                self.table.setColumnSelectionAllowed(true);
                self.table.selectAll();

                self.table.getColumnModel().getSelectionModel().clearSelection();
                self.table.getColumnModel().getSelectionModel().addSelectionInterval(column,column);
                notify(self,'selectionChanged');
            end
        end
        
        function rowHeaderCB(self, ~, e)
            row = self.table.rowAtPoint(e.getPoint());
            if row < 0
                return;
            end
            self.table.setRowSelectionAllowed(true);
            self.table.setColumnSelectionAllowed(false);
            self.table.getSelectionModel().clearSelection();
            self.table.getSelectionModel().addSelectionInterval(row,row);
            notify(self,'selectionChanged');
        end
        
       
    end
    
end

