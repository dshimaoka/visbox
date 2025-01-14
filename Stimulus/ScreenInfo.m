classdef ScreenInfo
    %SCREENINFO the ScreenInfo object
    % 23/7/20 incoropolated screen undistortion with Spencer's code
    
    properties
        
        PixelSize = 0.0609;     % The size of the pixels in cm
        Xmax = 640;             % Total number of pixels, horizontal
        Ymax = 480;             % Total number of pixels, vertical
        FrameRate  = 124.8918;  % Refresh rate
        WhichScreen             % Screen number
        MonitorType = 'Dummy';  % Make and model of the monitor(s)
        MonitorSize             % Total size of monitor in cm, horizontal
        Dist = 64;              % Distance between observer and screen, cm
        Geometry                % Geometry of the screens configuration {'Flat', 'Circular'}
        HorizontalSpan          % Defines the overall X-span in degrees (for 'Circular' geometry)
        PixelDepth = 8;         % The pixel depth
        windowPtr               % The pointer assigned to the window by Screen
        ScreenRect              % The rectangle assigned by Screen
        SyncSquare              % Object specifying the properties of the Sync Square
        WaveInfo                % Object specifying the properties of DAQ
        Calibration             % A struct with Calibration info (will be an object)
        ScaleOldStimuliFactor   %
        ColorChannels2Use = [1 1 1]  % RGB channels to use, useful to switch off some of the colors (e.g. red)
        BackgroundColor = 127   % A default color to be used at startup and 
                                % between experiments, if your stimulus 
                                % does not specify a persist color. 
                                % Will be taken from RigInfo, where it can
                                % be set as a scalar from 0-255 or an RGB
                                % triplet. 
                                % Added 2015-05-01 by NAS. 
    end
    
    methods
        
        function SI = ScreenInfo(RigInfo, LBflag)
            % ScreenInfo initializes the ScreenInfo object
            %
            % ScreenInfo(RigInfo)
            %
            % ScreenInfo(RigInfo,LBflag) lets you specify the
            % "Laura Busse" mode (default: 1, meaning that it is on)
            %
            % See also: RigInfoGet
            
            if nargin < 1
                return
            end
            
            if nargin<2
                LBflag = 1;
            end
            
            AssertOpenGL;
            
            SI.WhichScreen      = RigInfo.VsDisplayScreen;
            SI.MonitorType      = RigInfo.MonitorType;
            SI.MonitorSize      = RigInfo.MonitorSize;
            SI.Calibration      = Calibration; %#ok<CPROP,PROP>
            SI.Calibration.Directory   = RigInfo.VsHostCalibrationDir;
            SI.Dist             = RigInfo.DefaultMonitorDistance;
            
            if isfield(RigInfo, 'Geometry')
                SI.Geometry     = RigInfo.Geometry;
                if isequal(SI.Geometry, 'Circular')
                    SI.HorizontalSpan  = RigInfo.HorizontalSpan;
                else
                    SI.HorizontalSpan  = [];
                end
            else % backward-compatible, behaves as 'Flat'
                SI.Geometry = ''; 
                SI.HorizontalSpan = [];
            end
            
            % MK 2014-06-20
            if isfield(RigInfo, 'ColorChannels2Use')
                SI.ColorChannels2Use = RigInfo.ColorChannels2Use;
            else
                SI.ColorChannels2Use = [1 1 1];
            end
            
            % added by MC 2013-04-25:
            rect = RigInfo.VsDisplayRect; % defaults to [] i.e. whole screen
            
            SI.PixelDepth = 8;
            
            % suppress all the greetings and warnings
            oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel');
            oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings');

            Screen('CloseAll');
            
            % suppress all the greetings and warnings
            Screen('Preference', 'VisualDebugLevel', oldVisualDebugLevel);
            Screen('Preference', 'SuppressAllWarnings', oldSupressAllWarnings);

            WaitSecs(0.5);
            % HACK TO TAKE CARE OF A FLAW IN 64 bit ver of Psychtoolbox (MC
            % 2013-01-23)
            if  strcmp(mexext,'mexw64')
                pixdepth = []; 
            else 
                pixdepth = SI.PixelDepth;
            end
            
            Screen('Preference', 'SkipSyncTests', 1); %17/9/20 restored
            
              % the following line needs be enabled for proper linear superposition
            if LBflag
                %[SI.windowPtr, SI.ScreenRect] = Screen('OpenWindow', SI.WhichScreen, ...
                %[], rect, pixdepth, [], [], [], kPsychNeed16BPCFloat);
                
                %screen undistortion. added 23/7/20
                PsychImaging('PrepareConfiguration');
                
                if RigInfo.DefaultMonitorDistance == 4.9
                    undistortionFile = 'C:\Users\Experiment\Documents\MATLAB\Undistortion\IpadLandscapeUndistortion_LabRigger_490mm.mat';
                elseif RigInfo.DefaultMonitorDistance == 8
                    undistortionFile = 'C:\Users\Experiment\Documents\MATLAB\Undistortion\IpadLandscapeUndistortion_LabRigger_800mm.mat';
                end
                PsychImaging('AddTask', 'AllViews', 'GeometryCorrection', undistortionFile);
                
%                 [SI.windowPtr, SI.ScreenRect] = PsychImaging('OpenWindow', SI.WhichScreen, ...
%                 [], rect, pixdepth, [], [], [], kPsychNeed16BPCFloat,[],[0 0 2048 1536]);

                [SI.windowPtr, SI.ScreenRect] = PsychImaging('OpenWindow', SI.WhichScreen, ...
                [], rect, pixdepth, [], [], [], kPsychNeed16BPCFloat);

            else
                 [SI.windowPtr, SI.ScreenRect] = Screen('OpenWindow', SI.WhichScreen, [], rect, pixdepth);
            end
            
            % the following will be overruled in various cases
            % Screen('BlendFunction', SI.windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            % Screen('BlendFunction', ScreenInfo.windowPtr, GL_ONE, GL_ZERO);
            
            if isfield(RigInfo, 'BackgroundColor')
                SI.BackgroundColor = RigInfo.BackgroundColor;
            else
                SI.BackgroundColor = GrayIndex(SI.WhichScreen);
            end
            Screen('FillRect', SI.windowPtr, SI.BackgroundColor);
            Screen('Flip', SI.windowPtr);		% force gray screen
            
            
            % make a linear Clut (do this even though you will load the calibration later!!!)
            Screen('LoadNormalizedGammaTable', SI.WhichScreen, repmat((0:255)', 1, 3)/255);
%             % AS added next two lines 2012-08, cause calibration was never loaded before.
%             comment: I don't see this coming in anywhere in vs. 
%             SI = CalibrationLoad(SI);
%             Screen('LoadNormalizedGammaTable', SI.WhichScreen, SI.Calibration.monitorGamInv./255);
            
            SI.Xmax = RectWidth(SI.ScreenRect);
            SI.Ymax = RectHeight(SI.ScreenRect);
            
            SI.FrameRate =  1/Screen('GetFlipInterval',SI.windowPtr);
            % was FrameRate(SI.WhichScreen); but this occasionally got rid of
            % calibration, and needed to be flushed after changing framerate
            
            SI.PixelSize = SI.MonitorSize/SI.Xmax; % size of pixel
            
            SI.SyncSquare = RigInfo.SyncSquare;
            SI.ScaleOldStimuliFactor = RigInfo.ScaleOldStimuliFactor;
            
            %% Deal with the WaveInfo
            
            SI.WaveInfo = RigInfo.WaveInfo;
            
            %% inform the user of how things are going
            
            fprintf('\n *** ScreenInfoInitialize *** \n');
            fprintf('VBLTimestampingMode is %d\n',...
                Screen('Preference', 'VBLTimestampingMode'));
            disp(['You are using a ' SI.MonitorType]);
            disp(['The refresh rate is ' num2str(SI.FrameRate,'%3.3f') ' Hz']);
            fprintf('The resolution is %dx%d pixels.\n',SI.Xmax,SI.Ymax);
            SI.WaveInfo.Describe;
            
        end % function ScreenInfo
        
        function [xPix, yPix] = Deg2PixCoord(SI,xDeg,yDeg)
            % Deg2PixCoord converts degrees coordinates into pixel coordinates
            %
            % [xPix, yPix] = ScreenInfo.Deg2PixCoord(xDeg,yDeg)
            % Rounds the results
            % Assumes you want to center things in the middle
            % Crops so you don't get out of the screen
            %
            % This function is 'precise', unlike e.g. Deg2Pix, which
            % assumes being in the center of the screen for a flat screen
            % However, it is not truly precise for a 'Circular' screen made
            % of flat screens.
            % 
            % See also Deg2Pix, Pix2Deg, and Deg2PixCirc
            
            xPixCtr = SI.Xmax/2;
            yPixCtr = SI.Ymax/2;
            
            switch SI.Geometry
                case {'', 'Flat'}
                    xPix = 2 * SI.Dist/ SI.PixelSize * tan( pi/180 * xDeg/2 );
                case 'Circular'
                    xPix = xDeg * SI.Xmax / SI.HorizontalSpan;
            end
            yPix = 2 * SI.Dist/ SI.PixelSize * tan( pi/180 * yDeg/2 );
            
            xPix = round(xPixCtr + xPix);
            yPix = round(yPixCtr + yPix);
            
            xPix = max(1,xPix);
            yPix = max(1,yPix);
            
            xPix = min(xPix, SI.Xmax);
            yPix = min(yPix, SI.Ymax);
            
        end % function Deg2PixCoord
        
        function Pix = Deg2PixCirc(SI,Deg)
            % Deg2PixCirc converts degrees into pixels for a circular screen
            %
            % Pix = ScreenInfo.Deg2PixCirc(Deg) converts the degrees of
            % visual angle Deg into a round number of pixels Pix. This is
            % correct for a circular screen and obeys Deg2PixCirc(a+b) =
            % Deg2Pix(a)+Deg2Pix(b). If you want something appropriate for
            % a flat screen, see , use Deg2Pix.
            % This function is obsolete after the introduction of
            % SI.Geometry == 'Circular' with SI.HorizontalSpan
            
            DegPerPix = 2* 180/pi * asin(SI.PixelSize/2 / SI.Dist);            
            Pix = round(Deg/DegPerPix);
            
        end % function Deg2PixCirc
        
        function Pix = Deg2Pix(SI,Deg)
            % Deg2Pix converts degrees into pixels (flat or circular screen)
            %
            % Pix = ScreenInfo.Deg2Pix(Deg) converts the degrees of visual
            % angle Deg into a round number of pixels Pix. This is correct
            % for a flat screen for objects centered in the middle of
            % the screen, and for circular screen for objects placed anywhere.
            % For flat scrrens uses tan (tangent) and has the
            % counterintuitive property that Deg2Pix(a+b) is not
            % Deg2Pix(a)+Deg2Pix(b). 
            
            switch SI.Geometry
                case {'', 'Flat'}
                    Pix = 2 * SI.Dist/ SI.PixelSize * tan( pi/180 * Deg/2 );
                case 'Circular'
                    Pix = SI.Xmax / SI.HorizontalSpan * Deg;
            end
            Pix = round(Pix);
            
        end % function Deg2Pix
         
        function Deg = Pix2Deg(SI,Pix)
            % Pix2Deg converts pixels into degrees
            %
            % Deg = ScreenInfo.Pix2Deg(SI,Pix)
            %
            % See also Deg2Pix.
            
            if isempty(SI.Geometry), SI.Geometry = ''; end
            
            switch SI.Geometry
                case {'', 'Flat'}
                    Deg = 2 * 180/pi*atan(Pix / (2 * SI.Dist/ SI.PixelSize));
                case 'Circular'
                    Deg = Pix / SI.Xmax * SI.HorizontalSpan;
            end
            
        end % function Pix2Deg
        
        function SI = CalibrationLoad(SI)
            % CalibrationLoad loads the calibration file and applies it
            
            SI.Calibration = Calibration.Load(SI); %#ok<PROP>
  
        end % function CalibrationLoad
        
        function CalibrationCheck(SI)
            % Check calibration automatically to ensure linearity
            
            Calibration.Check(SI); %#ok<PROP>  
            
        end
        
        function result = IsCalibrationStillOn(SI)
            % Checks whether the gamma table that we wanted is still on
            
            PresentGamma = Screen('ReadNormalizedGammaTable', SI.windowPtr);
            DesiredGamma = SI.Calibration.monitorGamInv / 255;	% corrected to have linear luminance
            MaxDifference = max(max(abs(PresentGamma-DesiredGamma)));
            result = MaxDifference<0.01;
            
        end % function IsCalibrationStillOn
    
        function FrameRate = RealFrameRate(SI)
            % RealFrameRate is for backward compatibility
            % MC 2011-06-15
            
            FrameRate = SI.FrameRate;
        end 
    end % Methods
    
end

