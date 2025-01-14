function grat = SearchStim(myScreenInfo)

% Allows interactive control of a drifting grating patch
%
% grat = SearchStim(myScreenInfo)
%
% Notice that it hides the cursor and at the end it shows it again, if you
% wanted it to be off, call HideCursor after calling this function.
%
% Notice that it is not able to return to the location where it has shown
% the stimulus previously. This could be fixable in a future version
% (at the beginning, calculate the offset between mouse position and
% stimulus position, and take it into consideration...).
% 
% EXAMPLE:
% RigInfo = RigInfoGet; 
% myScreenInfo = ScreenInfo(RigInfo);
% grat = SearchStim(myScreenInfo);
%
% part of the Stimulus Toolbox

% 2001-03 MC improved it and made it part of vs
% 2000-05 version 0.3 TCBF and MC 
% 2000-01 MC commented out the disps, corrected obsolete call to ltGetScreenInfo
% 1999-11 version 0.2 TCBF and MC 
% 2006-12 JBB major rewrite, upgraded to Windows PTB 3.x
% 2007-03 MC cleaned messages to user
% 2007-04 MC updated calls to sound routines (was crashing when sounds overlapped)
% 2011-02 MC made it output grat rather than visdriftsinpars
% 2011-02 MC renamed SearchStim
% 2011-02 MC no longer changes directory to C:
% 2015-11 MC saves info to Desktop, not to C:

fprintf('Preparing search stimulus...');

HideCursor; 
ListenChar(2);	% don't echo keypresses to matlab screen

% make a gray screen to be used before and after the Stim
gray = 127;
Screen('FillRect', myScreenInfo.windowPtr, gray); Screen('Flip', myScreenInfo.windowPtr);

% enable alpha blending in window (needed for the viewing aperture)
Screen('BlendFunction', myScreenInfo.windowPtr, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% possible values for contrast, spatial frequency, temporal frequency, image diameter
cs 		= [0.05 0.1 0.2 0.4 0.8];					% fraction (percent / 100)
sfs		= [0.02 0.05 0.1 0.2 0.4 0.8 1.2 1.6];		% cycles per degree
tfs 	= [0.5 1 2 4 8 16 32];						% cycles per second
diams 	= round(2.^(3:0.5:8.5)) / 10;				% degrees

nContrasts = length(cs);
nSpatFreqs = length(sfs);
nTempFreqs = length(tfs);
nDiams = length(diams);

% possible values for orientation (degrees)
nOris = 12;
oris = (0:nOris-1)/nOris * 180;	% when n = 12, 0 to 165 in incs of 15

% converted spatial frequency units
spatFreqDegPerCyc = 1 ./ sfs;
spatFreqPixPerCyc = ltdeg2pix(spatFreqDegPerCyc, myScreenInfo);
% spatFreqCycPerPix = 1 ./ spatFreqPixPerCyc;

% initial values
DesktopDir = winqueryreg('HKEY_CURRENT_USER', 'Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders', 'Desktop');

if exist(fullfile(DesktopDir,'LastSearchStimPars.mat'), 'file')
	load(fullfile(DesktopDir,'LastSearchStimPars.mat'),'v'); 
else
	v.ic 	= 3;
	v.isf = 2;
	v.itf = 1;
	v.idiam = 4;
	v.iori = 1;
	v.xpix = round(myScreenInfo.Xmax/2)+ceil(ltdeg2pix(0,myScreenInfo));	% default: screen center
	v.ypix = round(myScreenInfo.Ymax/2)+ceil(ltdeg2pix(0,myScreenInfo));
end

Stim.direction 			= +1;
Stim.Contrast			= cs(v.ic);
Stim.SpatialFrequency	= sfs(v.isf);	% Cycles/degree
Stim.phase				= 0;	% 0 is cosine phase
Stim.sqwv				= 0;	% 0=sine, 1=square
Stim.flick 				= 0;	% 0=moving, 1=sine flicker, 2=square flicker
Stim.tFreq				= tfs(v.itf);	% Hz
Stim.Diam				= diams(v.idiam);
Stim.innerRad 			= 0;				% pixels
Stim.outerRad 			= ceil(ceil(ltdeg2pix(Stim.Diam,myScreenInfo))/2); 	% pixels
Stim.x 		= myScreenInfo.Pix2Deg(v.xpix); % ltpix2deg(v.xpix - round(myScreenInfo.Xmax/2), myScreenInfo); 
Stim.y 		= myScreenInfo.Pix2Deg(v.ypix); % ltpix2deg(v.ypix - round(myScreenInfo.Ymax/2), myScreenInfo); 
Stim.Ori360 			= oris(v.iori) + (Stim.direction == -1)*180; 
Stim.Orientation 		= Stim.Ori360 * pi/180;

%%



%---- make blending apertures for each image diameter
fprintf('%d diameters...', nDiams);
aperturePtrList = zeros(nDiams, 1);
clipSizeX = zeros(nDiams, 1);
clipSizeY = zeros(nDiams, 1);

ThisStim = Stim;
ThisStim.Orientation = 0;
for i = 1:nDiams,
	ThisStim.Diam = diams(i);
	ThisStim.outerRad = ceil(ceil(ltdeg2pix(ThisStim.Diam, myScreenInfo))/2); 	% pixels
	tempFrame = ltMakeGratingFrame(ThisStim, myScreenInfo);
 	tempFrameSize = size(tempFrame);
	clipSizeX(i) = tempFrameSize(1);
	clipSizeY(i) = tempFrameSize(2);

	% need to add extra zeros around aperture to make sure it covers
 	tempFrameSize = tempFrameSize + 20;
	null = zeros(tempFrameSize);
	null(11:end-10, 11:end-10) = tempFrame;
	tempFrame = null;

	% convert to alpha transparency values
	tempFrame(tempFrame ~=0) = 255;
	tempFrame = 255 - tempFrame;
	null = repmat(gray, [tempFrameSize, 2]);
	null(:, :, 2) = tempFrame;

	aperturePtrList(i) = Screen('MakeTexture', myScreenInfo.windowPtr, null);
end
aperturePadRect = [-10 -10 10 10];		% adjust aperture draw rectangle to completely cover grating

%---- make baseline cluts for each image contrast
fprintf('%d contrasts...', nContrasts);
tempClutList = cell(nContrasts, 1);
ThisStim.tFreq = myScreenInfo.FrameRate;	% make only one clut
for i = 1:nContrasts,
	ThisStim.Contrast = cs(i);
	tempClutList{i} = squeeze(ltMakeGratingCluts(ThisStim, myScreenInfo));		% basically, this is for first frame
end

%---- make square frames for each image spatial frequency
% the width of each stimulus frame must equal the width of the aperture PLUS one cycle
% the apertuture moves along this extended stimulus to give the illusion of motion
% after traversing one cycle it jumps back to the beginning to continue the animation
fprintf('%d spatial frequencies...', nSpatFreqs);
tempFrameList = cell(nSpatFreqs, 1);
ThisStim.sizeY = clipSizeY(end);			% defining sizeX, sizeY enables square grating
for j = 1:nSpatFreqs,
	ThisStim.sizeX = ceil( clipSizeX(end) + ceil(spatFreqPixPerCyc(j)) );		% be ready for largest diameter
	ThisStim.SpatialFrequency = sfs(j);
	tempFrameList{j} = ltMakeGratingFrame(ThisStim, myScreenInfo);
end

%---- combine contrast cluts and s.f. frames into image textures
fprintf('combining into %d textures...', nContrasts * nSpatFreqs);
imagePtrList = zeros(nContrasts, nSpatFreqs);
for i = 1:nContrasts,
	Clut = tempClutList{i};
	for j = 1:nSpatFreqs,
		tempFrame = tempFrameList{j};

		% map frame (i.e., list of CLUT index values) to 3-plane rgb texture matrix
		textureSize = [size(tempFrame), 3];
		texture = reshape( Clut(tempFrame+1, :), textureSize );

		imagePtrList(i, j) = Screen('MakeTexture', myScreenInfo.windowPtr, texture);
	end
end
clear null tempFrame tempFrameList texture	% clean up some larger vbls

%---- prepare draw loop
SetMouse(v.xpix, v.ypix, myScreenInfo.windowPtr);		% NOTE: does not work in windows

showinfo(Stim);

currentpar = 's';		% image parameter to change -- can be d, c, s, t

tt = linspace( 0, 0.05, 22000*0.05 );

oBeep3440 = audioplayer( sin( tt*2*pi*3440), 22000);
oBeep880  = audioplayer( sin( tt*2*pi* 880), 22000);
oBeep440  = audioplayer( sin( tt*2*pi* 440), 22000);

% Query duration of monitor refresh interval:
ifi = Screen('GetFlipInterval', myScreenInfo.windowPtr);
waitframes = 1;
waitduration = waitframes * ifi;		% sec
flipInc = (waitframes - 0.5) * ifi;


kbDelayTicks = round(0.200 / waitduration);		% number of loop iterations (ticks) in 200 msec
% kbDelayTicks = round(1.00 / waitduration);		% number of loop iterations (ticks) in 1000 msec

% fprintf('actual temp freq = %.4f cyc/sec\n', shiftPerFrame*spatFreqCycPerPix*myScreenInfo.FrameRate);
% fprintf('actual temp freq = %.4f cyc/sec\n', myScreenInfo.FrameRate / nFrames);

fprintf('done\n');

while KbCheck;
	% 
end; % wait until all keys are released.

%%

frameIdx = 0;
exitFlag = 0;
kbDelay = 0;	% only check for keyboard input when zero
				% this is used for a little delay loop to prevent multiple keypresses from
				% being registered during a single button press

Priority(1);

% Perform initial Flip to sync us to the VBL and for getting an initial
% VBL-Timestamp for our "WaitBlanking" emulation:
% vbl = 0;	% init
vbl = Screen('Flip', myScreenInfo.windowPtr);

while ~exitFlag,

	% Translate requested speed of the grating (in cycles per second)
	% into a shift value in "pixels per frame", assuming given
	% waitduration: This is the amount of pixels to shift our "aperture" at
	% each redraw (adapted from DriftDemoOSX2.m):
	shiftPerFrame = tfs(v.itf) * spatFreqPixPerCyc(v.isf) * waitduration;
	nFrames = ceil(myScreenInfo.FrameRate / tfs(v.itf));	% number of frames per cycle

	% update animation frame
	if Stim.direction == 1
		frameIdx = mod( frameIdx-1, nFrames );
	else
		frameIdx = mod( frameIdx+1, nFrames );
	end
	xoffset = frameIdx * shiftPerFrame;		% calculate amount to shift grating this frame

	% Define shifted srcRect that cuts out the properly shifted rectangular
	% area from the texture.  Noninteger values drawn using bilinear interpolation.
	srcRect = [xoffset, 0, xoffset + clipSizeX(v.idiam), clipSizeY(v.idiam)];

	% compute destination rectangle based on mouse position
	destRect = getrect([v.xpix, v.ypix], [clipSizeX(v.idiam), clipSizeY(v.idiam)]);
	[newxpix, newypix, button] = GetMouse(myScreenInfo.windowPtr);	
	if newxpix ~= v.xpix || newypix ~= v.ypix || any(button),
		v.xpix = max(1, min(newxpix, myScreenInfo.Xmax));
		v.ypix = max(1, min(newypix, myScreenInfo.Ymax));
		
		Stim.x = ltpix2deg(v.xpix - round(myScreenInfo.Xmax/2), myScreenInfo); 
		Stim.y = ltpix2deg(v.ypix - round(myScreenInfo.Ymax/2), myScreenInfo); 
		
		destRect = CenterRectOnPoint(destRect, v.xpix, v.ypix);
		if any(button),
			showinfo(Stim);
		end
		
	end

	% Draw rotated grating texture
	Screen('DrawTexture', myScreenInfo.windowPtr, imagePtrList(v.ic, v.isf), srcRect, destRect, oris(v.iori));

	% Draw aperture mask over grating: We need to subtract 0.5 from
	% the real size to avoid interpolation artifacts that are
	% created by the gfx-hardware due to internal numerical
	% roundoff errors when drawing rotated images: (comment from demo. ***DO WE???***)
	Screen('DrawTexture', myScreenInfo.windowPtr, aperturePtrList(v.idiam), [], destRect + aperturePadRect, oris(v.iori));

	% Flip 'waitframes' monitor refresh intervals after last redraw.
	vbl = Screen('Flip', myScreenInfo.windowPtr, vbl + flipInc);

	% check for keyboard input
	if kbDelay <= 0,
		[keyPress, junk, keyCode] = KbCheck; %#ok<ASGLU>
	else
		kbDelay = kbDelay - 1;
		keyPress = 0;
	end

	if (keyPress) 	% a key was pressed
		
		kbDelay = kbDelayTicks;		% ignore any more keypresses for next 200 msec
		switch find(keyCode, 1)

		case KbName('c')		% current active parameter = contrast
			play(oBeep3440);
			currentpar = 'c';

		case KbName('d')		% current active parameter = diameter
			play(oBeep3440);
			currentpar = 'd';

		case KbName('s')		% current active parameter = spatial frequency
			play(oBeep3440);
			currentpar = 's';

		case KbName('t')		% current active parameter = temporal frequency
			play(oBeep3440);
			currentpar = 't';

		case KbName('left')		% rotate orientation counterclockwise
			play(oBeep880);
			v.iori = mod(v.iori-2, nOris) + 1;
			if v.iori == nOris  % you went through a whole range
				Stim.direction = -Stim.direction;
			end	
			Stim.Ori360 = oris(v.iori) + (Stim.direction == -1)*180; 

		case KbName('right')		% rotate orientation clockwise
			play(oBeep880);
			v.iori = mod(v.iori, nOris) + 1;
			if v.iori == 1  % you went through a whole range
				Stim.direction = -Stim.direction;
			end
			Stim.Ori360 = oris(v.iori) + (Stim.direction == -1)*180; 

		case KbName('space');		% reverse grating direction
			play(oBeep880);
			Stim.direction = - Stim.direction;			
			Stim.Ori360 = oris(v.iori) + (Stim.direction == -1)*180; 

		case KbName('up')			% apply command: increase current parameter value
			play(oBeep880);
			switch currentpar

			case 'd'	% increase diameter
				v.idiam = mod(v.idiam, nDiams) + 1;
				Stim.Diam = diams(v.idiam);
				Stim.outerRad = ceil(ceil(ltdeg2pix(Stim.Diam,myScreenInfo))/2); 	% pixels

			case 'c'	% increase contrast
				v.ic = mod(v.ic, nContrasts) + 1;
				Stim.Contrast = cs(v.ic);

			case 't'	% increase temporal frequency (speed)
				v.itf = mod(v.itf, nTempFreqs) + 1;
				Stim.tFreq = tfs(v.itf);

			case 's'	% increase spatial frequency
				v.isf = mod(v.isf, nSpatFreqs) + 1;
				Stim.SpatialFrequency = sfs(v.isf);

			end

		case KbName('down');			% apply command: decrease current parameter value
			play(oBeep880);
			switch currentpar

			case 'd'	% decrease diameter
				v.idiam = mod(v.idiam-2, nDiams) + 1;
				Stim.Diam = diams(v.idiam);
				Stim.outerRad = ceil(ceil(ltdeg2pix(Stim.Diam,myScreenInfo))/2); 	% pixels

			case 'c'	% decrease contrast
				v.ic = mod(v.ic-2, nContrasts) + 1;
				Stim.Contrast = cs(v.ic);

			case 't'	% decrease temporal frequency (speed)
				v.itf = mod(v.itf-2, nTempFreqs) + 1;
				Stim.tFreq = tfs(v.itf);

			case 's'	% decrease spatial frequency
				v.isf = mod(v.isf-2, nSpatFreqs) + 1;
				Stim.SpatialFrequency = sfs(v.isf);

			end

		case KbName('p')	% pause (blank screen)
			play(oBeep880);
			% disp('Paused.....')
			Screen('FillRect', myScreenInfo.windowPtr, gray);
			Screen('Flip', myScreenInfo.windowPtr);
			while KbCheck
				% wait until all keys are released
			end  
			KbWait;
			% disp('..Continued..')
			vbl = Screen('Flip', myScreenInfo.windowPtr);	% get another vbl timestamp for next iteration
			
			% letter Q
			
		case KbName('Esc')
			play(oBeep440);
			exitFlag = 1;

		otherwise
			play(oBeep440);
			% do nothing

		end
		showinfo(Stim);

	end		% if (keyPress)

end		% while ~exitFlag

%----------- clean up
Priority(0);
Screen('Close');	% clear all textures
Screen('FillRect', myScreenInfo.windowPtr, gray); Screen('Flip', myScreenInfo.windowPtr);

%% report the parameters that were used last

grat.tf 	= Stim.tFreq*10;
grat.sf 	= Stim.SpatialFrequency;
grat.c  	= 100*Stim.Contrast;
grat.ori  	= round(Stim.Ori360);
grat.x  	= round(10*Stim.x);
grat.y  	= round(10*Stim.y);
grat.diam 	= Stim.Diam*10;


save(fullfile(DesktopDir,'LastSearchStimPars'),'v');

ShowCursor;
ListenChar(1);			% reenable echo keypresses to matlab screen

if ~isempty(grat)
    fprintf(...
        'tf = %2.1f Hz, sf = %2.2f cpd, c = %d %%, ori = %3d deg, x = %2.1f deg, y = %2.1f deg, diam = %2.1f deg\n\n',...
        grat.tf/10, grat.sf, grat.c, grat.ori,grat.x/10, grat.y/10, grat.diam/10);
end

%%
function rect = getrect(ctr_pix, size_pix)
% getrect 
%
% rect = getrect([xctr yctr], [xsize ysize]) gives a rectangle 
% centered at pixel xctr, yctr of size xsize, ysize pixels

xctr = ctr_pix(1);
yctr = ctr_pix(2);

xsize = size_pix(1);
ysize = size_pix(2);

x1 = xctr - round(xsize/2);
y1 = yctr - round(ysize/2);

x2 = xctr + (xsize  - round(xsize/2));
y2 = yctr + (ysize  - round(ysize/2));

rect = [ x1 y1 x2 y2 ];
%------- end of function getrect

%%
function showinfo(Stim)

clc;

strInstructions = {...

'                                                                       ';
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *';
'                  I N S T R U C T I O N S                              ';
'* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *';
'                                                                       ';
'                                                                       ';
'                                                                       ';
['LEFT, RIGHT, SPACE        Orientation = ' num2str(Stim.Ori360          ,3) ' deg'];
['c + (UP,DOWN)                Contrast = ' num2str(100*Stim.Contrast    ,3) ' %'];
['t + (UP,DOWN)      Temporal Frequency = ' num2str(Stim.tFreq           ,3) ' Hz'];
['s + (UP,DOWN)       Spatial Frequency = ' num2str(Stim.SpatialFrequency,3) ' cpd'];
['d + (UP,DOWN)                Diameter = ' num2str(Stim.Diam            ,3) ' deg'];
['mouse                               X = ' num2str(Stim.x               ,3) ' deg'];
['mouse (click to update positions)   Y = ' num2str(Stim.y               ,3) ' deg'];
'                                                                       ';
'                                                                       ';
'                                                                       ';
' p --- pause (until further keystroke)                                 ';
' Esc - Quit                                                            ';
'                                                                       ';
'                                                                       '};
disp(strInstructions);
%------- end of function showinfo

return


