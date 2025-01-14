import javax.swing.*;
import javax.swing.table.*;
import java.awt.*;
import java.awt.event.KeyEvent;

public class StimTable extends JTable{
    
    // method to resonable set column widths
    public void autoResizeColWidth() {      
        setAutoResizeMode(JTable.AUTO_RESIZE_OFF);
        DefaultTableModel model = (DefaultTableModel)getModel();
        int margin = 5;
        
        for (int i = 0; i < getColumnCount(); i++) {
            int                     vColIndex = i;
            DefaultTableColumnModel colModel  = (DefaultTableColumnModel) getColumnModel();
            TableColumn             col       = colModel.getColumn(vColIndex);
            int                     width     = 0;
            
            // Get width of column header
            TableCellRenderer renderer = col.getHeaderRenderer();
            
            if (renderer == null) {
                renderer = getTableHeader().getDefaultRenderer();
            }
            
            Component comp = renderer.getTableCellRendererComponent(this, col.getHeaderValue(), false, false, 0, 0);
            
            width = comp.getPreferredSize().width;
            
            // Get maximum width of column data
            for (int r = 0; r < getRowCount(); r++) {
                renderer = getCellRenderer(r, vColIndex);
                comp     = renderer.getTableCellRendererComponent(this, getValueAt(r, vColIndex), false, false,
                r, vColIndex);
                width = Math.max(width, comp.getPreferredSize().width);
            }
            
            // Add margin
            width += 2 * margin;
            
            // Set the width
            col.setPreferredWidth(width);
        }
        
        ((DefaultTableCellRenderer) getTableHeader().getDefaultRenderer()).setHorizontalAlignment(
        SwingConstants.LEFT);
        
        // setAutoCreateRowSorter(true);
        getTableHeader().setReorderingAllowed(false);
    }
    
    // make zeroth cells a special colour
    FirstRowRenderer firstRowRenderer = new FirstRowRenderer();

    private class FirstRowRenderer extends DefaultTableCellRenderer{
	public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column){
		Component r = super.getTableCellRendererComponent(table,value,isSelected,hasFocus,row,column);
		if(!isSelected)
			r.setBackground(new Color(220,220,220));
		return r;
	}
    }

    public TableCellRenderer getCellRenderer(int row, int column) {
    	if (row == 0) 
    		return firstRowRenderer;
        else 
        	return super.getCellRenderer(row, column);
    }
}
