function vv = vsGetStimulusFrame( stim, myscreen, iframe )
%VSGETSTIMULUSFRAME Gets one frame of the stimulus
%
% vv = vsGetStimulusFrame( stim, myscreen, iframe ) returns frame iframe
% of stimulus stim. The result has dimensions [ny, nx, 3] and can be shown
% with imshow(vv); 
%
% Example of use:
% 
% global DIRS
% DIRS.data = 'Z:\trodes';
% global DEMO
% DEMO = 1;
% myscreen = ScreenLogLoad('catz050',2,3); % a plausible screen structure 
% xfilefunc = 'vlutgrat';
% pars = [6    50    20    80     0     0     0     0   250     1];
% stim = feval( xfilefunc, pars, myscreen );
% vv = vsGetStimulusFrame(stim,myscreen, 3); % the third frame
% imshow(vv); 
% set(gca,'dataaspectratio',[1 1 1])
%
% 2004-12 MC
% 2006-07 MC fixed case in which position has negative elements
% 2006-09 MC fixed case in which stim is a cell array whose first entry has length 2

if iscell(stim) & length(stim) == 2
	nstimframes = 2;
elseif iscell(stim) & length(stim) == 1 & length(stim{1})==2
    stim = stim{1};
	nstimframes = 2;    
else
    stim = {stim};
	nstimframes = 1;
end

vv = zeros( myscreen.Xmax, myscreen.Ymax, 3 );
for istimframe = 1:nstimframes
    pp = stim{istimframe}.position;
    whichframe = stim{istimframe}.sequence.frames(iframe);
    whichlut   = stim{istimframe}.sequence.luts  (iframe);
    if any([ pp(3)-pp(1), pp(4)-pp(2) ] ~= size(stim{istimframe}.frames{1}{whichframe}'))
        error('Stimulus position vector is not consistent with size of frames');
    end
    ii = zeros( myscreen.Xmax, myscreen.Ymax );
    row_list = pp(1):(pp(3)-1); 
    col_list = pp(2):(pp(4)-1);
    goodrows = find( row_list>0 & row_list<=myscreen.Xmax );
    goodcols = find( col_list>0 & col_list<=myscreen.Ymax );
    ii(row_list(goodrows),col_list(goodcols)) = stim{istimframe}.frames{1}{whichframe}(goodcols,goodrows)';
    
    % ii = ii( 1:myscreen.Xmax, 1:myscreen.Ymax ); % in case it had gotten beyond the screen limits
    
    lut = stim{istimframe}.luts{whichlut};
    % assumes there is always one patch per stimframe...
    for igun = 1:3
        rgbmaps{igun} = zeros( myscreen.Xmax, myscreen.Ymax );
        rgbmaps{igun}(:) = lut(ii(:)+1,igun)/255;
        vv(:,:,igun ) = vv(:,:,igun ) + rgbmaps{igun}/nstimframes;
    end
end

vv = permute(vv, [2 1 3]);


   
    
    

    
    
