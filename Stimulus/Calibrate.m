%% do a new calibration

fprintf('To calibrate, connect the photodiode/photosensor to AI0 and P0.0 to AI1\n');

RigInfo = RigInfoGet;
myScreenInfo = ScreenInfo(RigInfo);

myScreenInfo.Calibration.Make;

%% now check the calibration

RigInfo = RigInfoGet;
myScreenInfo = ScreenInfo(RigInfo);
myScreenInfo = myScreenInfo.CalibrationLoad;
myScreenInfo.CalibrationCheck;

clear mex % to see the figures...

