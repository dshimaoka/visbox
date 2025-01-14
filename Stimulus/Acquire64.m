function [Measured,Digital,SampleRate] = Acquire64(myScreenInfo,testColors,CloseAtTheEnd)

if nargin<3
    CloseAtTheEnd = false;
end

global AcquiredData

winPtr = myScreenInfo.windowPtr; % for speed of access
Device = myScreenInfo.WaveInfo.DAQString;

SampleRate = 5000; % Hz

s = daq.createSession('ni');
s.addAnalogInputChannel(Device,'ai0', 'Voltage')
s.addAnalogInputChannel(Device,'ai1', 'Voltage')
s.Channels(1).InputType = 'Differential';
s.Channels(2).InputType = 'SingleEnded';
s.Rate = SampleRate;
s.IsContinuous = true;
s.NotifyWhenDataAvailableExceeds = ceil(SampleRate/10); % call it every 100 ms

AcquiredData.TimeStamps = zeros( SampleRate*120, 1 );
AcquiredData.Data       = zeros( SampleRate*120, 2);
AcquiredData.nSamples = 0;

s.addlistener('DataAvailable', @AddToData);

s1 = daq.createSession('ni'); % must be a different session!
s1.addDigitalChannel(Device,'port1/line0','OutputOnly');
s1.outputSingleScan(0);

%% Measure Gamma

Screen('FillRect', winPtr, [0 0 0]);
Screen('Flip', winPtr);

s.startBackground;

nStim = size(testColors,1);
for iStim = 1:nStim
    
    Screen('FillRect', winPtr, [0 0 0]);
    Screen('Flip', winPtr);
    Screen('FillRect', winPtr, testColors(iStim,:));
    for iframe = 1:25
        Screen('Flip', winPtr);
        s1.outputSingleScan(1)
    end
    Screen('FillRect', winPtr, [0 0 0]);
    Screen('Flip', winPtr);
    s1.outputSingleScan(0);
    for iframe = 1:25
        Screen('Flip', winPtr);
        s1.outputSingleScan(0)
    end
    
    drawnow;
end

Screen('FillRect', winPtr, [128 128 128]);
Screen('Flip', winPtr);

if CloseAtTheEnd
    Screen(winPtr, 'Close'); % Close the screen
end

s.stop

%% prepare the data for output

if AcquiredData.nSamples ~= s.ScansAcquired
    fprintf('Acquired %d samples instead of %d\n',s.ScansAcquired,AcquiredData.nSamples);
end

ii = 1:AcquiredData.nSamples;
Measured = AcquiredData.Data(ii,1);
Digital  = AcquiredData.Data(ii,2);
