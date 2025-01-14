function [Measured,Digital,SampleRate] = Acquire32(myScreenInfo, testColors, CloseAtTheEnd)

if nargin<3
    CloseAtTheEnd = false;
end

winPtr = myScreenInfo.windowPtr; % for speed of access
Device = myScreenInfo.WaveInfo.DAQString;

SampleRate = 5000; % Hz

ai = analoginput('nidaq',Device) ;
ch = addchannel(ai,0:1); %#ok<NASGU> % adds two channels
ai.Channel.InputRange = [-10 10]; % apparently I can't do [0 10]

set(ai,'InputType','SingleEnded');
set(ai,'TriggerType','Manual');
set(ai,'SamplesPerTrigger',Inf);
set(ai,'SampleRate',SampleRate);

do = digitalio('nidaq',Device);
addline(do,0,'out');
putvalue(do,false);

%% Measure Gamma

start(ai);
start(do);
Screen('FillRect', winPtr, [0 0 0]);
Screen('Flip', winPtr);

nStim = size(testColors,1);

trigger(ai); % go!
for iStim = 1:nStim
        
        Screen('FillRect', winPtr, [0 0 0]);
        Screen('Flip', winPtr);
        Screen('FillRect', winPtr, testColors(iStim,:));
        for iframe = 1:25
            Screen('Flip', winPtr);
            putvalue(do,true);
        end
        Screen('FillRect', winPtr, [0 0 0]);
        Screen('Flip', winPtr);
        putvalue(do,false);
        for iframe = 1:25
            Screen('Flip', winPtr);
            putvalue(do,false);
        end
        
end

Screen('FillRect', winPtr, [128 128 128]);
Screen('Flip', winPtr);

if CloseAtTheEnd
    Screen(winPtr, 'Close'); % Close the screen
end

stop(ai);
stop(do);

ns = get(ai,'SamplesAvailable');
data = getdata(ai,ns);
Measured = data(:,1);
Digital  = data(:,2);
