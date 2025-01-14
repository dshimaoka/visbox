%TODO: modify device/channel ID so that it matches with
%config_timeline_widefield.m


%load('\\ad.monash.edu\home\User006\dshi0006\Documents\MATLAB\test\hardware.mat');

path = dat.paths(hostname);
savepath = path.rigConfig;

stimline = hw.Stimline();
stimline.DaqIds = 'Dev1';

% stimline.Outputs.DaqDeviceID = 'Dev1';
% stimline.Outputs.DaqChannelID = 'port0\line1';
% stimline.Outputs.Name = 'acqLive';

%% acqLive
acqLiveOutput = sl.SLOutputAcqLive;
acqLiveOutput.DaqDeviceID = stimline.DaqIds;
acqLiveOutput.Name = 'acqLive'; % rename for legacy compatability
acqLiveOutput.DaqChannelID = 'port0/line5'; %chosen as not used for thorImage on 18/9/19 

%% camera exposure
slExposeClockOutput = sl.SLOutputClock_analog; %202023
slExposeClockOutput.Name = 'slExposeClock';
slExposeClockOutput.DaqDeviceID = stimline.DaqIds;
slExposeClockOutput.DaqChannelID = 'ao1';
%slExposeClockOutput.InitialDelay = 0;
slExposeClockOutput.Frequency = 65; %[Hz]
slExposeClockOutput.lightExposeTime = 5;%[ms]
%slExposeClockOutput.DutyCycle = 0.2;
%slExposeClockOutput.Verbose = 1;

stimline.Outputs = [acqLiveOutput, slExposeClockOutput];%camExposeOutput];

save(fullfile(savepath, 'hardware.mat'), 'stimline');

disp('Saved config file')
