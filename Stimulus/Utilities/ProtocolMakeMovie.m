function ProtocolMakeMovie(filename,protocol,istim,unit,irpt,myscreen,fullflag,maxdur,rfpars)
%PROTOCOLMAKEMOVIE Makes avi movie of a given stimulus
%
% The AVI is saved in the CURRENT directory
%
% ProtocolMakeMovie
% shows a movie for a stimulus in the currently picked protocol.
%
% ProtocolMakeMovie(filename) saves the movie in a file called filename in
% the Temp directory (DEFAULT: [], which means don't save)
%
% ProtocolMakeMovie(filename,protocol) lets you specify the protocol you
% want to work with (DEFAULT: the value in the global PICK.protocol)
%
% ProtocolMakeMovie(filename,protocol,istim)
% lets you specify the stimulus to compute (DEFAULT: asks for it)
% 
% ProtocolMakeMovie(filename,protocol,istim,unit,irpt)
% generates a wav-file containing the sound of the spikes
%
% ProtocolMakeMovie(filename,protocol,istim,unit,irpt,myscreen)
% lets you specify the screen data (default: defaultscreen)
%
% ProtocolMakeMovie(filename,protocol,istim,unit,irpt,myscreen,fullflag)
% if fullflag set to 'full' (default), then plots the entire screen
%
% ProtocolMakeMovie(filename,protocol,istim,unit,irpt,myscreen,fullflag,maxdur)
% lets you specify how many seconds of the stimulus are generated (default: 5 sec) 
%
% ProtocolMakeMovie(filename,protocol,istim,unit,irpt,myscreen,fullflag,maxdur,rfpars)
% plots also a circle that corresponds to the position of the receptive field
% rfpars has fields .x, .y and .diam (all in deg, model reference frame)
%
% part of VisBox

% 2003-12 VM made it
% 2009-04 MC fixed bug to work without rfpars
% 2009-04 MC made it save only if desired, and in Windows temp dir
% 2009-04 MC made it ask for stimulus number
% 2009-04 MC made it work with no parameters

%% Parse the parameters

if nargin<1
    filename = '';
end

if nargin<2
    global PICK
    protocol = PICK.protocol;
end

% The stimuli to plot
if nargin < 3 || isempty(istim)

      str = cell(protocol.nstim,1);
      for istim = 1:protocol.nstim, str{istim} = num2str(istim); end
      istim = listdlg('PromptString','Select a stimulus:',...
                      'SelectionMode','single',...
                      'ListString',str);
else
   if istim > protocol.nstim
      error('There are only %i stimuli in this protocol',protocol.nstim);
   end
end

% The unit
if nargin < 4
   unit = [];
end

% Which repeat
if nargin < 5 || isempty(irpt)
   irpt = 1;
end

% The screen log
if nargin < 6 || isempty(myscreen)
   myscreen = defaultscreen;
   myscreen.PixelSize  = 0.0609*2;
    myscreen.Xmax       = 320;
    myscreen.Ymax       = 240;
end

% The fullflag
if nargin < 7 || isempty(fullflag)
   fullflag = 'full';
end

% The maximum lenght of the stimulus
if nargin < 8 || isempty(maxdur)
   maxdur = 5;
end

if nargin < 9
   rfpars = [];
end

%% Make the stimuli

newprot.xfile = protocol.xfile;
newprot.pars = zeros(size(protocol.pars,1),1);
newprot.pars = protocol.pars(:,istim);
stim = makestims(newprot,myscreen);

% Get the position of the patches
patchedge = [];
nleave = length(stim{1});
npatch = zeros(1,nleave);
onemore = 0;

for ileave = 1:nleave 
   npatch(ileave) = length(stim{1}{ileave}.frames);
   
   for ipatch = 1:npatch
      onemore = onemore + 1;
      pos = round(stim{1}{ileave}.position(ipatch,:));
      % MC 2009-04-02 added round to avoid crashes (crazy that this should
      % ever be required!!)
      patchedge(onemore,:) = [pos(1) pos(2) pos(3)-1 pos(4)-1];
   end
end

% Find the position of the stimulus
stimedge = zeros(1,4);
stimedge(1) = min(patchedge(:,1));
stimedge(2) = min(patchedge(:,2));
stimedge(3) = max(patchedge(:,3));
stimedge(4) = max(patchedge(:,4));
nxstim = stimedge(3) - stimedge(1) + 1;
nystim = stimedge(4) - stimedge(2) + 1;

% Find the position of each patch within the stimulus
patchindex = [];
for ipatch = 1:sum(npatch)
   patchindex(ipatch).ix = (patchedge(ipatch,1) - stimedge(1) + 1) : ...
      (nxstim - stimedge(3) + patchedge(ipatch,3));
   patchindex(ipatch).iy = (patchedge(ipatch,2) - stimedge(2) + 1) : ...
      (nystim - stimedge(4) + patchedge(ipatch,4));
end

% Find the position of the stimulus on the screen
screenindex.ix = max(1,stimedge(1)) : min(myscreen.Xmax,stimedge(3));
screenindex.iy = max(1,stimedge(2)) : min(myscreen.Ymax,stimedge(4));

% The stimulus pixels that are inside the screen borders
stimindex.ix = (screenindex.ix(1) - stimedge(1) + 1) : ...
   (nxstim - stimedge(3) + screenindex.ix(end));
stimindex.iy = (screenindex.iy(1) - stimedge(2) + 1) : ...
   (nystim - stimedge(4) + screenindex.iy(end));

% The receptive field position in pixels
if isfield(rfpars,'x') && ~isempty(rfpars.x)
   [rfpx,rfpy] = convertc2p(rfpars.x,rfpars.y,myscreen.PixelSize);
   [rfx,rfy] = convertp2ps(rfpx,rfpy,myscreen);
else
   rfx = mean(screenindex.ix);
   rfy = mean(screenindex.iy);
end

% The rf diameter
if ~isempty(rfpars)
    rfd = rfpars.diam / myscreen.PixelSize;
end

% Generate the movie
clear stimmovie;
nstimframes = length(stim{1}{1}.sequence.frames)*length(stim{1});
% Make sure that it is not too long
nframes = min(ceil(maxdur*myscreen.RealFrameRate),nstimframes); 

figure;
colormap gray;

for iframe = 1:nframes
   stimlum = zeros(nystim,nxstim) + 0.5;
   
   % Generate the luminance distribution for each patch
   patchlum = [];
   [patchlum,ileave] = virtualplaystimulus(iframe,myscreen,stim{1});
   
   % Place the patches on the stimulus
   for ipatch = 1:npatch(ileave)
      whichpatch = (ileave-1)*sum(npatch(1:(ileave-1))) + ipatch;
      stimlum(patchindex(whichpatch).iy,patchindex(whichpatch).ix) =....
         patchlum{ipatch}(1:nystim,1:nxstim);
     % MC 2009-04-02 added (1:nystim,1:nxstim) because sometimes the
     % patches were one pixel too big, and gave errors

   end
   
   % Plot it
   if strcmp(fullflag,'full')
      % Place the stimulus on the screen
      screenlum = zeros(myscreen.Ymax,myscreen.Xmax) + 0.5;
      screenlum(screenindex.iy,screenindex.ix) = ...
         stimlum(stimindex.iy,stimindex.ix);
      imagesc(screenlum,[0 1]);
      
      % Plot the receptive field
      if ~isempty(rfpars)
         set(gca,'nextplot','add')
         circle([rfx rfy],rfd/2,'r-');
      end
      
      % Make it look nice
      set(gca,'plotboxaspectratio',[myscreen.Xmax myscreen.Ymax 1]);
      axis off;
      
   else
      % Don't plot the entire screen
      imagesc(stimlum,[0 1]);
      
      % Plot the receptive field
      if ~isempty(rfpars)
%          irfx = find(screenindex.ix == round(rfx));
%          irfy = find(screenindex.iy == round(rfy));
         irfx = screenindex.ix == round(rfx);
         irfy = screenindex.iy == round(rfy);
         set(gca,'nextplot','add')
         circle([stimindex.ix(irfx) stimindex.iy(irfy)],rfd/2,'r-');
      end
   
      % Make it look nice
      set(gca,'plotboxaspectratio',[nxstim nystim 1]);
      axis off;
   
   end
   
   % Get this frame of the movie
   stimmovie(iframe) = getframe;
   cla;
end

close gcf;

%% Save the file if the user has requested it

if ~isempty(filename)
    fprintf('Preparing avi file...');
    OriginalDir = pwd;
    [foo,TempDir] = system('echo %TEMP%'); % has a carriage return at the end
    cd(TempDir(1:end-1));


    % Save it in the current directory
    aviname = sprintf('%s-stim%d.avi',filename, istim);
    movie2avi(stimmovie,aviname,'compression','Cinepak','FPS',myscreen.RealFrameRate);
    fprintf('done\n');
    fprintf('Saved the avifile %s in directory %s',aviname,TempDir);

    cd(OriginalDir);
end

%% MAKE THE WAV FILE

if ~isempty(unit)
   samplerate = 9192; % Hz
   dt = 1/samplerate;
   
   ntimesamples = ceil(nframes/myscreen.RealFrameRate/dt);
%   goodspikes = find(unit.spiketimes{istim,irpt} <= nframes/myscreen.RealFrameRate);
   goodspikes = unit.spiketimes{istim,irpt} <= nframes/myscreen.RealFrameRate;
   spikebins = ceil(unit.spiketimes{istim,irpt}(goodspikes)/dt);
   mysound = zeros(1,ntimesamples);
   
   % Make the spikes
   tt = 0:100; f = 440*2^4; yy = sin(2*pi*tt*f/samplerate);
   for spikebin = spikebins
      mysound(spikebin+tt) = yy;
   end
   
   wavname = [filename '.wav'];
   wavwrite(mysound,samplerate,16,wavname);
   disp(sprintf('Saved the wavfile %s in the current directory',wavname));
end





return



%% Code to test the function

addpath('y:\VisBox');

global DIRS DEMO;
DEMO = 1;

DIRS.data = 'z:\trodes\';
DIRS.spikes = 'x:\';

%--- Make the stimulus
% A large grating
protocol = ProtocolLoad('catz035',3,3);
istim = 5;
% A sweep experiment
protocol = ProtocolLoad('catz035',1,28);
istim = 5;

% The parameters of the receptive field
rfpars.x = protocol.pars(6,1)/10;
rfpars.y = protocol.pars(7,1)/10;
rfpars.diam = protocol.pars(4,1)/100;


cd('t:\');
ProtocolMakeMovie('prova',protocol,istim,[],[],[],[],[],rfpars);


%--- Make stimulus and spikes
% A texture experiment
protocol = ProtocolLoad('catz035',2,43);
unit = UnitLoad(DIRS.spikes,'catz035',2,43);
istim = 19;

cd('u:\data');
ProtocolMakeMovie('prova',protocol,istim,unit,1,[],[],1);
ProtocolMakeMovie('prova',protocol,istim,unit,1);

