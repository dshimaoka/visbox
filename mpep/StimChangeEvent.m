classdef StimChangeEvent < event.EventData
    properties
        rows
        cols
    end
    
    methods
        function self = StimChangeEvent(rows,cols)
           self.rows = rows;
           self.cols = cols;
        end
    end
    
end

