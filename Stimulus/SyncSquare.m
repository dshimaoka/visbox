classdef SyncSquare 
    %SYNCSQUARE The sync square
    % It lets you specify whether or not
    % to show a sync square, where to put it, and how to modulate it in time.
    % SyncSquare.Type can be 'None', 'Flicker', 'flickergrey', or 'Steady' [DEFAULT]
    % SyncSquare.Position can be 'SouthEast' or 'SouthWest' [DEFAULT]
    % SyncSquare.Size size in pixels [DEFAULT: 80]
    %
    % 2014-01 CB added PreAndPost & Sequence properties
    % 2014-07-31 NS added "flickergrey" type, which is identical to flicker
    %   except leaves the screen grey in between stimuli (so that when the
    %   last frame comes on the down-phase of the flicker, you can tell
    %   when it ends)
    
    properties
        Type = 'Steady'
        Size = 80 % in pixels
        Position = 'SouthWest'
        Angle = 0; %30/7/20 for undistortion
    end
   
    properties (Dependent)
        PreAndPost %value for pre stim and post stim
        Sequence %sequence of values for stimulus frames
    end
    
    methods
        function v = get.PreAndPost(obj)
            switch lower(obj.Type)
                case 'steady'
                    v = 0;
                case 'flicker'
                    v = 0;
                case 'flickergrey'
                    v = 0.5;
                case 'none'
                    v = 0.5;
                otherwise
                    error('Unknown SyncSquare.Type ''%s''', SyncSquare.Type);
            end
        end

        function v = get.Sequence(obj)
            switch lower(obj.Type)
                case 'steady'
                    v = 1;
                case 'flicker'
                    % 2014-03-13 18:00 CB reversed order of flicker so that
                    % first stimulus frame is actually high (from low value
                    % before)
                    v = [1; 0];
                case 'flickergrey'
                    v = [1; 0];
                case 'none'
                    v = 0.5;
                otherwise
                    error('Unknown SyncSquare.Type ''%s''', SyncSquare.Type);
            end
        end
      
        function SS = set.Type( SS, strType )
            if  ~ischar(strType) || ~(...
                    strcmpi(strType,'Steady')  || ...
                    strcmpi(strType,'Flicker') || ...
                    strcmpi(strType,'Flicker-Steady') || ...%DS on 13.11.1
                    strcmpi(strType,'flickergrey') || ...%NS on 2014-07-31
                    strcmpi(strType,'None') )
                error('Type of SyncSquare can only be Steady, Flicker, Flicker-Steady or None');
            end
            SS.Type = strType;
            
        end
 
        function SS = set.Position( SS, strPosition )
            if  ~ischar(strPosition) || ~(...
                    strcmpi(strPosition,'SouthEast') || ...
                    strcmpi(strPosition,'SouthWest') || ...
                    strcmpi(strPosition,'NorthEast') )
                error('Position of SyncSquare can only be SouthEast or SouthWest or NorthEast');
            end
            SS.Position = strPosition;
            
        end
        
        function [preAndPost, stimSeq] = createTextures(SS, screenInfo)
            % Create graphics textures for the each sync square state
            %
            % [preAndPost, stimSeq] = CREATETEXTURES(screenInfo) creates
            % the textures for different sync square states on the graphics
            % device for the screen specified by 'screenInfo'. 'preAndPost'
            % will contain the texture handle for the state used before and
            % after stimulus presentation. 'stimSeq' will be a vector of
            % texture handles for the cycled sequence of states for
            % consecutive frames.
            %
            % The value (between 0 and 1) of the corresponding properties
            % are converted to textures of uniform luminance rectangles (size
            % given by GetSyncRect) with the appropriate graphics luminace
            % level.
            preAndPost = textureFor(SS, screenInfo, SS.PreAndPost);
            stimSeq = arrayfun(@(v) textureFor(SS, screenInfo, v), SS.Sequence);
        end
        
        function SyncRect = GetSyncRect( SS, screenInfo )
            switch SS.Position
                case 'SouthWest'
                    row1 = 0;
                    col1 = screenInfo.Ymax - SS.Size + 1;
                    row2 = SS.Size-1;
                    col2 = screenInfo.Ymax;
                case 'SouthEast'
                    row1 = screenInfo.Xmax - SS.Size + 1;
                    col1 = screenInfo.Ymax - SS.Size + 1;
                    row2 = screenInfo.Xmax;
                    col2 = screenInfo.Ymax;
                case 'NorthEast'
                    row1 = screenInfo.Xmax - SS.Size + 1;
                    col1 = 0;
                    row2 = screenInfo.Xmax;
                    col2 = SS.Size;
                otherwise
                    error('Do not understand SS.Position');
            end

            SyncRect = [row1 col1 row2 col2];
        end
        
        function h = textureFor(SS, screenInfo, value)
            white = 1;
            if minusOneToOneMode(screenInfo)
              black = -1;
            else
              black = 0;
            end
            % compute appropriate graphics luminance from sync value
            lum = (white - black)*value + black;
            rect = GetSyncRect(SS, screenInfo); % get the sync rectangle
            h = Screen('MakeTexture', screenInfo.windowPtr, lum*ones(size(rect)), 0, 0, 1);
        end
    end
end



