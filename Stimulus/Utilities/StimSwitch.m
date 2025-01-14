function SingleStim = StimSwitch(Stim1,Stim2,frmSwitch)
% Switches from one stimulus to another at a given frame
% 
% Stim = StimConcatenate(Stim1,Stim2)
% concatenates stimuli with fields
% frames
% luts
% sequence
% position
% nperiods
%
% It assumes that stimuli have same position, nperiods, number of frames. 

fprintf(1,'Concatenating stimuli with switch at frame %d\n',frmSwitch);

%% parse the parameters 

if any(Stim1.position-Stim2.position)
    error('Positions of the two stimuli should be the same!!');
end

if Stim1.nperiods ~= Stim2.nperiods
    error('Periods of the two stimuli should be the same!!');
end

if numel(Stim1.sequence.frames) ~= numel(Stim2.sequence.frames)
    error('Durations of the two stimuli should be the same!!');
end

nt = numel(Stim1.sequence.frames);
if frmSwitch > nt || frmSwitch < 1
    error('The switch should occur during the stimulus...');
end

%%

% allocation
SingleStim = Stim1;

nluts1 = length(Stim1.luts);
nframes1 = length(Stim1.frames{1});

% nluts2 = length(Stim2.luts);
% nframes2 = length(Stim2.frames{1});

SingleStim.luts = [Stim1.luts; Stim2.luts];
SingleStim.frames = {[Stim1.frames{1} Stim2.frames{1}]};

SingleStim.sequence.luts   = [ ...
    Stim1.sequence.luts(            1:frmSwitch),     ...
    Stim2.sequence.luts((frmSwitch+1):end)+ nluts1 ];

SingleStim.sequence.frames = [ ...
    Stim1.sequence.frames(            1:frmSwitch), ...
    Stim2.sequence.frames((frmSwitch+1):end) + nframes1 ];

