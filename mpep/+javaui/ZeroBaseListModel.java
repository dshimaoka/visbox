import javax.swing.*;
import javax.swing.table.*;
import java.awt.*;

public class ZeroBaseListModel extends AbstractListModel {
    
    private int size = 0;
   
    public void setSize(int s){
        int oldSize = size;
        size = s;
        if(size > oldSize){
            fireIntervalAdded(this, size-1, oldSize);
        }else if(size < oldSize){
            fireIntervalRemoved(this, size, oldSize-1);
        }
    }
    
    public int getSize() {
        return size;
    }
    
    public Object getElementAt(int index) {
        return new Integer(index).toString();
    }
};