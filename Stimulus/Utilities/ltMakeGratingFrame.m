function img = ltMakeGratingFrame(SinPars,myscreen,reserveflag)
% Utility that makes frame for grating lut animation
%
% f = ltMakeGratingFrame(SinPars,myscreen)
%
% f = ltMakeGratingFrame(SinPars,myscreen,'reserve3')
%
% SinPars must have the following fields:
% SpatialFrequency (cycles per degree)
% Orientation (radians)
% phase (radians)
% FOR ANNULUS WINDOWS
% innerRad, outerRad (pixels)
% FOR RECTANGULAR WINDOWS
% sizeX, sizeY (pixels) (these fields take precedence)
%
% 1999 FH, TF, MC
% 2000 TF MC added the 'reserve3' flag
% 2000-04 TF corrected bug in orientation setting 
% 2001-01 MC removed dependence on fields x and y from SinPars
% 2001-03 MC rewrote completely to avoid lethal diam-sf bug
%
% Part of LabTools


if nargin<3
	reserveflag = '';
end

if ~strcmp(reserveflag,'reserve3')
	nreslutentries = 1;
else
	nreslutentries = 3;
end

windowtype = '';
if isfield(SinPars, 'sizeX') & isfield(SinPars, 'sizeY') 
    % these fields indicate size of rectangular window, in pixels
    nx = SinPars.sizeX;
    ny = SinPars.sizeY;
    windowtype = 'rectangle';
else
    nx = 2*SinPars.outerRad;
    ny = 2*SinPars.outerRad;
    windowtype = 'annulus';
end

DegPerCycle = 1/SinPars.SpatialFrequency;
PixPerCycle = ltdeg2pix(DegPerCycle,myscreen);
cyclesperpix = 1/PixPerCycle; % sf in cycles/pix

% ---- make a grid of x and y
[xx,yy]=meshgrid(1-nx/2:nx/2,1-ny/2:ny/2);

% ---- make grid of angular frequency
% the minus sign below is for consistency with the orientation of other stimuli
angfreq = -2*pi*cyclesperpix*(cos(SinPars.Orientation).*xx+sin(SinPars.Orientation).*yy ) +SinPars.phase;
% in radians

angles = angle(exp(sqrt(-1)*angfreq)) + pi;
% now it is between 0 and 2*pi

img = round(angles* (255-nreslutentries)/(2*pi)) + nreslutentries;
% now it is between nreslutentries and 255

if any(img<nreslutentries | img>255)
	error('img is out of range');
end

img = uint8(img);

% ---------------  window ----------------

if strcmp(windowtype, 'annulus')
    dd = sqrt(xx.^2+yy.^2); 	% distance matrix
    outside=find( dd<SinPars.innerRad  | dd>=SinPars.outerRad );
    img(outside)=0;
end

return

%-----------------------------------------------------------------
%           CODE TO TEST THE FUNCTION
%-----------------------------------------------------------------

SinPars.SpatialFrequency = 0.5;     % cycles per degree
SinPars.Orientation = 0;            % radians
SinPars.phase = 0;                  % radians

% FOR ANNULUS WINDOWS
SinPars.innerRad = 0;               % pixels
SinPars.outerRad = 100;             % pixels

% FOR RECTANGULAR WINDOWS
SinPars.sizeX = 50;                % pixels
SinPars.sizeY = 300;                 % pixels

myscreen.PixelSize = 0.0609;
myscreen.Dist = 65;

img = ltMakeGratingFrame(SinPars,myscreen,'reserve3');

imagesc(img);
colormap gray
axis equal