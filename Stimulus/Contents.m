% STIMULUS TOOLBOX
% Version 20131212 12-Dec-2013
%
% Toolbox to make visual stimuli and control other types of stimuli
% % Minimal code:
% RigInfo = RigInfoGet;
% myScreenInfo = ScreenInfo(RigInfo);
% 
% % calibrate the monitor
% % myScreenInfo = myScreenInfo.Calibration.Make
% % clear mex ?????
% myScreenInfo = myScreenInfo.CalibrationLoad;
% 
% % myScreenInfo.CalibrationCheck;
% 
% % make a stimulus and show it
% myScreenStim1 = ScreenStim.Make(myScreenInfo,'stimRandNoise');
% [vblTimestamps1, data] = Play(myScreenStim1,myScreenInfo);
% myScreenStim1.Show(myScreenInfo)
% 
% CONTENTS:
%
%   vs   - Stimulation program: obeys zpep (or mpep), shows visual stimuli and plays waves
%
% To initialize screens and calibrate them:
%
%   RigInfoGet          - Database of information of various rigs in the lab
%   ScreenInfo          - the ScreenInfo object
%   SyncSquare          - The sync square
%   Calibration         - object that contains the information on screen calibration
%
% To deal with stimuli 
%
%   ScreenStim                     - Stimulus object to be shown on the screen
%
% Utilities:
%   SearchStim              - Allows interactive control of a drifting grating patch
%   Play        - Plays visual stimuli and wave stimuli
%   WaveInfo    - information about wave i/o in the rig
%   XFile       - Class for the reading and writing of xfiles
%   Merge       - Merges two stimuli
%   actxlicense - 
%
% Path must contain Stimulus toolbox and Stimulus/Utilities
%
% Example:
%
% RigInfo = RigInfoGet;
% myScreenInfo = ScreenInfo(RigInfo);
% myScreenInfo = myScreenInfo.CalibrationLoad;
% myScreenStim1 = ScreenStim.Make(myScreenInfo,'stimRandNoise');
% myScreenStim1.Show(myScreenInfo)
% [vblTimestamps1, data] = Play(myScreenStim1,myScreenInfo);
%
% % To calibrate a monitor:
% output of digital 0 going into analog input 1
% output of light meter into analog input 0
%
% RigInfo = RigInfoGet;
% myScreenInfo = ScreenInfo(RigInfo);
% myScreenInfo = myScreenInfo.Calibration.Make
% % you might have to do a clear mex ?????
% RigInfo = RigInfoGet;
% myScreenInfo = ScreenInfo(RigInfo);
% myScreenInfo = myScreenInfo.CalibrationLoad;
% myScreenInfo = myScreenInfo.Calibration.Check;




