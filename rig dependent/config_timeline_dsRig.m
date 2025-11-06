function config_timeline_dsRig
% Create a timeline object to be saved in hardware.mat for widefield
% imaging
% 27/9/2019 Created from config_timeline_2prig
% 10/21/2020 convert to a function, run every time Timeline starts

totalCameraFrameRate = input('What is camera total frame rate in Hz? [60]: ');
if isempty(totalCameraFrameRate)
    totalCameraFrameRate = 60;
end

% Instantiate the timeline object
timeline = hw.Timeline;
timeline.DaqIds = 'Dev1';
timeline.UseTimeline = 1; %18/9/2019
%timeline.trigStim ??
%timeline.StopDelay = 2 by default
timeline.AquiredDataType = 'single';
%timeline.WriteBufferToDisk = false; this does not help to reduce "clocking pulse not detected"

%% Configure inputs

% Set sample rate
timeline.DaqSampleRate = 1000;%17/9/20

% Set up function for configuring inputs
daq_input = @(name, channelID, measurement, terminalConfig) ...
    struct('name', name,...
    'arrayColumn', -1,... % -1 is default indicating unused
    'daqChannelID', channelID,...
    'measurement', measurement,...
    'terminalConfig', terminalConfig, ...
    'axesScale', 1);

timeline.Inputs = [...
    daq_input('chrono', 'ai8', 'Voltage', 'SingleEnded')... % for reading back self timing wave 
    daq_input('tlExposeClock', 'ai1', 'Voltage', 'SingleEnded'), ... %from NI to camera to start exposure
    daq_input('PCObusy', 'ai10', 'Voltage', 'SingleEnded'),... %
    daq_input('acqLive', 'ai13', 'Voltage', 'SingleEnded'), ... %TL starts acquisition
    daq_input('photoDiode','ai14','Voltage', 'SingleEnded'),... %photodiode measured at screen renamed 30/4/20
    daq_input('syncSquare','ai0','Voltage', 'SingleEnded'),... %syncSquare from vs. added 4/5/20
    daq_input('laserIn','ai6','Voltage','SingleEnded'),... %25/9/20
    daq_input('DMDIn','ai4','Voltage','SingleEnded'),... %5/3/25
    daq_input('DMDOut','ai5','Voltage','SingleEnded'),... %17/12/20
    daq_input('stimScreen','ai2','Voltage','SingleEnded'),...
    daq_input('amberLEDmonitor','ai11','Voltage','SingleEnded'),... %05/11/25
    daq_input('redLEDmonitor','ai12','Voltage','SingleEnded'); %06/11/25
    %< there is a delay between syncSquare and actual output on screen. usually syncsquare is earlier, delay size seems to depend on stimulus protocol 
    ];
    %daq_input('eyeCamStrobe', 'ai5', 'Voltage', 'SingleEnded')...

% Activate all defined inputs
timeline.UseInputs = {timeline.Inputs.name};


%% Configure outputs (each output is a specialized object)

% (chrono - required timeline self-referential clock)
chronoOutput = hw.TLOutputChrono;
chronoOutput.DaqChannelID = 'port0/line3'; %chosen as not used for thorImage on 18/9/19 

% (acq live output - for external triggering)
acqLiveOutput = hw.TLOutputAcqLive;
acqLiveOutput.Name = 'acqLive'; % rename for legacy compatability
acqLiveOutput.DaqChannelID = 'port0/line5'; %chosen as not used for thorImage on 18/9/19 

% % (output to synchronize face camera)
% camSyncOutput = hw.TLOutputCamSync;
% camSyncOutput.Name = 'camSync'; % rename for legacy compatability
% camSyncOutput.DaqChannelID = 'port0/line2';
% camSyncOutput.PulseDuration = 0.2;
% camSyncOutput.InitialDelay = 0.5;
% 
% (camera triggering)
camExposeOutput = hw.TLOutputCamExpose;
camExposeOutput.DaqDeviceID = timeline.DaqIds;
camExposeOutput.exposureOutputChannelID = 'ao1';% 'port0/line0'; %
camExposeOutput.triggerChannelID = 'Dev1/PFI1';%this port receives acqLive signal
camExposeOutput.framerate = totalCameraFrameRate;
camExposeOutput.lightExposeTime = 1;%6.5; %22/4/20 for starndard triggering

% % (behavior camera triggering) %17/12/20
% bhvCamExposeOutput = hw.TLOutputCamExpose;
% bhvCamExposeOutput.DaqDeviceID = timeline.DaqIds;
% bhvCamExposeOutput.exposureOutputChannelID = 'ao0';% 'port0/line0'; %
% bhvCamExposeOutput.triggerChannelID = 'Dev1/PFI1';%this port receives acqLive signal
% bhvCamExposeOutput.framerate = 60;
% bhvCamExposeOutput.lightExposeTime = 1;%6.5; %22/4/20 for starndard triggering

% Package the outputs (VERY IMPORTANT: acq triggers illum, so illum must be
% set up BEFORE starting acqLive output)
timeline.Outputs = [chronoOutput,  camExposeOutput, acqLiveOutput];
% timeline.Outputs = [chronoOutput,  acqLiveOutput];%1/4/20 omit camExposeOutput because of error
%timeline.Outputs = [chronoOutput,rampIlluminationOutput,acqLiveOutput,camSyncOutput];

% Configure live "oscilloscope"
timeline.LivePlot = true; %turned false on 16/6/20 for sampling >2000Hz

% Clear out all temporary variables
clearvars -except timeline

% save to "hardware" file
%save('\\zserver.cortexlab.net\Code\Rigging\config\LILRIG-TIMELINE\hardware.mat')
%save('C:\Users\Experiment\Documents\MATLAB\Data\code\Rigging\config\Experiment\hardware.mat');
path = dat.paths(hostname);
savepath = path.rigConfig;
save(fullfile(savepath, 'hardware.mat'), 'timeline');
disp('Saved timeline config file');
end







