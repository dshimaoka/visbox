classdef ScreenStim < handle
    %SCREENSTIM Stimulus object to be shown on the screen
    %   A ScreenStim object specifies what the stimulus should be on a
    %   frame by frame basis. Includes information on the wave stimuli. 
    %
    % See also: WaveStim
    
    % NOTE BY MATTEO: BackgroundColor used to be 128 until 26 August 2011
    
    properties
        Type = '';              % The type of stimulus
        Parameters = [];        % The parameters that went into making it
        MinusOneToOne = true;   % Whether intensity range is [-1,1] or [0 255]
        UseAlpha = false;       % Whether to use alpha values or not (transparency);
                                % NOTE: if true, overwrites MinusOneToOne
        nFrames = 0;            % number of frames to be shown
        nTextures = 0;          % number of textures to be shown per frame
        ImageSequence = [];     % sequence of image tags (ntextures X nframes)
        Orientations = [];      % sequence of orientations (ntextures X nframes)
        Amplitudes = [];        % sequence of alpha blendings (ntextures X nframes)
        SourceRects = [];       % sequence of source rectangles (4 X ntextures X nframes)
        DestRects   = [];       % sequence of destination rectangles (4 X ntextures X nframes)
        nImages = 0;            % number of images to be stored
        ImageTextures = {};     % cell array of images (nimages X 1) -- often empty
        ImagePointers = [];     % array of pointers to images in VRAM (nimages X 1)
        BilinearFiltering = []; % whether to interpolate: 0 means no, 1 means yes (DEFAULT)
        BackgroundColor = [127 127 127];   % Background color, between 0 and 255 (3 x 1)
        BackgroundPersists = false; % Whether to keep background after stimulus
        WaveStim  = [];         % information on wave stimulus
		WaveSoundcard = [];     % information on sound to be played from soundcard
    end
    
%     properties  (Dependent = true)
%     
%         PointerSequence   % ntextures X nframes

    methods(Static)
        
        function SS = Make(myScreenInfo, XFileName, Pars)
            % MAKE Makes the ScreenStim object
            %
            % SS = Make(myScreenInfo, XFileName, Pars)
            %
            % SS = Make(myScreenInfo, XFileName)
%             myScreenInfo
%             XFileName
%             Pars
            if nargin<2
                error('Must specify myScreenInfo and XFileName');
            end
            
            if nargin<3
                disp('Using default parameters');
                Pars = [];
            end
            
            % if there is not enough memory, stop right there.
            uview = memory;
            Available = uview.MemAvailableAllArrays/(10^6);
            if Available < 50
                fprintf('Interrupting: Getting too close to memory limit\n');
                SS = ScreenStim;
                return;
            end
            
            % Figure out if it is one of the modern Xfiles or one of the
            % previous ones (pre 2011).
            if strcmp(XFileName(1:4),'stim')
                % it is one of the
                % should go with try .... catch but for now let's be rough
                fprintf('\n************* Calling %s ****************\n', XFileName );
                SS = feval(XFileName, myScreenInfo, Pars)
                fprintf('***************************************%s\n\n', repmat('*',1,length(XFileName)));
            else
                if isempty(Pars)
                    fprintf('Getting default parameters for xfile %s\n', XFileName);
                    x = XFileLoad(XFileName);
                    Pars = x.pardefaults;                   
                end
                
                % new code by Matteo 2013-09-03
                if isnan(myScreenInfo.ScaleOldStimuliFactor)
                    ScaleFactor = floor(myScreenInfo.Xmax/800); % rule of thumb...
                else
                    ScaleFactor = myScreenInfo.ScaleOldStimuliFactor;
                end
               
                clear address;
                
                
                FakeScreen = myScreenInfo;
                FakeScreen.PixelSize = ScaleFactor*FakeScreen.PixelSize;
                FakeScreen.Xmax = round(FakeScreen.Xmax/ScaleFactor);
                FakeScreen.Ymax = round(FakeScreen.Ymax/ScaleFactor);
                FakeScreen.ScreenRect = round(FakeScreen.ScreenRect/ScaleFactor);
                
                % make the stimulus
                try
                    
                    fprintf('\n************* Calling %s ****************\n', XFileName );
                    Stim = feval(XFileName,Pars,FakeScreen);
                    fprintf('***************************************%s\n\n', repmat('*',1,length(XFileName)));
                    
                    oglStim = vsLoadTextures(FakeScreen, Stim);
                    oglStim.Type                = XFileName;
                    oglStim.Pars                = Pars;
                    
                    %% done making the oglStim...
                    SS = ScreenStim(oglStim);
                    
                    SS.DestRects = round(ScaleFactor*SS.DestRects);
                catch ME
                    fprintf('Could not make stimulus of type %s\n',XFileName);
                    disp(ME.message);
                    fprintf('-----------Returning an empty stimulus--------------\n');
                    SS = ScreenStim;
                end
            end
            
            uview = memory;
            Available = uview.MemAvailableAllArrays/(10^6);
            fprintf('%3.1f MB remaining in RAM\n', Available);
            
        end % Make
    end
    
    methods
        
        function SS = ScreenStim(oglStim)
            % SCREENSTIM creates a ScreenStim object
            %
            % myScreenStim = ScreenStim with no arguments returns an empty
            % ScreenStim object.
            %
            % myScreenStim = ScreenStim(oglStim) imports an earlier oglStim
            
            if nargin < 1
                return
            end
            
            SS.Type = oglStim.Type;
            SS.Parameters = oglStim.Pars;
            SS.nFrames = oglStim.nframes;
            SS.MinusOneToOne = oglStim.FlagMinusOneToOne;
            
            switch oglStim.Version
                case 3
                    % SS.nTextures = size(oglStim.position,1); MC 2011-03-10
                    SS.nTextures = size(oglStim.positionIndex,1); 
                otherwise
                    SS.nTextures = 1;
            end
            
            % PointerSequence     = zeros(SS.nTextures,SS.nFrames);
            SS.Orientations = zeros(SS.nTextures,SS.nFrames);
            SS.Amplitudes   = zeros(SS.nTextures,SS.nFrames);
            SS.SourceRects  = zeros(4,SS.nTextures,SS.nFrames);
            SS.DestRects    = zeros(4,SS.nTextures,SS.nFrames);
            
            switch oglStim.Version
                case 3
                    for iFrame = 1:SS.nFrames
                        % PointerSequence    (:,iFrame)  = oglStim.texturePtrList(oglStim.frameIndex(:,iFrame));
                        SS.Orientations(:,iFrame)  = oglStim.ori(:,iFrame);
                        SS.Amplitudes  (:,iFrame)  = oglStim.globalAlpha(:,iFrame);
                        SS.DestRects   (:,:,iFrame) = oglStim.position(oglStim.positionIndex(:,iFrame), :)';
                        sz = oglStim.textureSizes(oglStim.frameIndex(:,iFrame),:);
                        SS.SourceRects (1,:,iFrame) = 1;
                        SS.SourceRects (2,:,iFrame) = 1;
                        SS.SourceRects (3,:,iFrame) = sz(:,2);
                        SS.SourceRects (4,:,iFrame) = sz(:,1); % why the switch?
                    end
                    
                case 2
                    
                    for iFrame = 1:SS.nFrames
                        % PointerSequence    (:,iFrame)  = oglStim.texturePtrList(oglStim.frameIndex(iFrame));
                        SS.Orientations(:,iFrame)  = oglStim.ori(iFrame);
                        SS.Amplitudes  (:,iFrame)  = oglStim.globalAlpha(iFrame);
                        SS.DestRects   (:,1,iFrame) = oglStim.position(oglStim.positionIndex(iFrame), :)';
                        SS.SourceRects (:,1,iFrame) = oglStim.srcRect{iFrame};
                    end
                    
                case 1
                    
                    for iFrame = 1:SS.nFrames
                        % PointerSequence    (:,iFrame)  = oglStim.texturePtrList(oglStim.frameIndex(iFrame));
                        SS.Amplitudes  (:,iFrame)  = 1;
                        SS.DestRects   (:,1,iFrame) = oglStim.position(oglStim.positionIndex(iFrame), :)';
                        SS.SourceRects (1:2,1,iFrame) = 1;
                        SS.SourceRects (3:4,1,iFrame) = SS.DestRects(3:4,1,iFrame)-SS.DestRects(1:2,1,iFrame);
                    end
                    
                otherwise
                    error('Whoa, dude!');
                    
            end
            
            % if ~isempty(oglStim.frames)
            % SS.nImages = length(oglStim.AllTextures);
            SS.nImages = oglStim.nImages;
            if SS.nTextures == 1
                % SS.ImageSequence = oglStim.frameIndex'; MC 2011-03-11
                SS.ImageSequence = oglStim.frameIndex(:)';
            else
                SS.ImageSequence = oglStim.frameIndex;
            end
            % SS.ImageTextures = oglStim.AllTextures;
            SS.ImagePointers = oglStim.texturePtrList;
            
            %                 % Undo a bit of the work of oglStimMake (ie of vsLoadTextures):
            %                 % remove the images from VRAM
            %                 ImagePointers = unique(oglStim.texturePtrList);
            %                 nPointers = length(ImagePointers);
            %                 fprintf('Removing %d textures from the video card.\n', nPointers);
            %                 for iPointer = 1:nPointers
            %                     Screen('Close', ImagePointers(iPointer));
            %                 end
            % end
            
            if oglStim.nperiods > 1
                np = oglStim.nperiods; % handier to have it short
                SS.nFrames = SS.nFrames*np;
                SS.ImageSequence = repmat(SS.ImageSequence,[1,np]);
                SS.Orientations  = repmat(SS.Orientations ,[1,np]);
                SS.Amplitudes    = repmat(SS.Amplitudes   ,[1,np]);
                SS.SourceRects   = repmat(SS.SourceRects  ,[1,1,np]);
                SS.DestRects     = repmat(SS.DestRects    ,[1,1,np]);
            end
            
        end % ScreenStim
        
        function ShowTextures(SS)
            
            %             if isempty(SS.ImageTextures)
            %                 disp('No image textures in memory...');
            %                 return
            %             end
            
            nr = ceil(sqrt(SS.nImages));
            nc = ceil(SS.nImages/nr);
            
            figure; clf; ax = zeros(SS.nImages,1);
            for iImage = 1:SS.nImages
                ax(iImage) = subplot(nr,nc,iImage);
                % ImageTexture = SS.ImageTextures{iImage};
                if SS.MinusOneToOne
                    ImageTexture = ...
                        Screen('GetImage', SS.ImagePointers(iImage),[],[],1,3);
                    image((ImageTexture+1)/2);
               else
                    ImageTexture = ...
                        Screen('GetImage', SS.ImagePointers(iImage),[],[],0,3);
                    image(ImageTexture);
                end
                axis image;
            end
            set(ax,'box','off','xtick',[],'ytick',[]);
            
        end % function ShowTextures
        
        function Result = Matches(SS, strType, Pars)
            Result = false; % start pessimistic
            if isempty(  SS   ), return; end
            if ~isvalid( SS   ), return; end
            if isempty(strType), return; end
            if length(Pars)~=length(SS.Parameters), return; end
            Result =  strcmp(strType,SS.Type) & all(Pars == SS.Parameters );
        end % function Compare
        
        function SS = LoadImageTextures(SS, myScreenInfo, ImageTextures)
            
            if nargin < 3
                ImageTextures = SS.ImageTextures;
            end
            
            if isnan(myScreenInfo.windowPtr)
                % it is not a true screen, just a simulation
                SS.ImageTextures = ImageTextures;
                return
            end
            
            if SS.MinusOneToOne
                FloatPrecision = 1; % 16 bit
            else 
                FloatPrecision = 0; % 8 bit
            end
            
            fprintf('Uploading %d images to video RAM\n',SS.nImages);
            
            SS.ImagePointers = zeros(SS.nImages,1);
            for iImage = 1:SS.nImages
                if ~isequal(myScreenInfo.ColorChannels2Use(:), [1; 1; 1])
                    texture = ImageTextures{iImage};
                    nChans = size(texture, 3);
                    if nChans < 3 % 05/2015: changed by SS to include LA spaces (2 channels)
                        t = repmat(texture(:,:,1), [1, 1, 3]);
                        if nChans == 2
                            texture = cat(3, t, texture(:,:,2));
                        else
                            texture = t;
                        end
                    end
                    [h, w, ~] = size(texture);
                    % 05/2015: changed by SS to include cases of 2 (LA space) and 4 (RGBA spaces) channels
                    % 09/2015: changed by MP to convert ColorChannels2Use to the numeric class of texture
                    ColorChannels2Use =  eval(sprintf('%s(myScreenInfo.ColorChannels2Use)', class(texture)));
                    texture(:,:,1:3) = texture(:,:,1:3).*...
                        repmat(reshape(ColorChannels2Use, 1, 1, 3), h, w);
                    SS.ImagePointers(iImage) = Screen('MakeTexture', ...
                        myScreenInfo.windowPtr, texture, [], 0, FloatPrecision);
                    % the next line is commented out to save Matlab memory
%                       SS.ImageTextures{iImage} = texture;
                else
                    SS.ImagePointers(iImage) = Screen('MakeTexture', ...
                        myScreenInfo.windowPtr, ImageTextures{iImage}, [], 0, FloatPrecision);
                    % the next line is commented out to save Matlab memory
%                       SS.ImageTextures{iImage} = ImageTextures{iImage};
                end
            end

        end % function LoadImageTextures
        
        function PointerSequence = GetPointerSequence(SS)
            
            PointerSequence = zeros(SS.nTextures,SS.nFrames);
            for iFrame = 1:SS.nFrames
                PointerSequence(:,iFrame) = SS.ImagePointers(SS.ImageSequence(:,iFrame));
            end
            if isempty(PointerSequence)
                error('What is going on here?');
            end

        end % function GetPointerSequence
        
        function Show(SS, myScreenInfo)
            % SHOW shows the ScreenStim object
            
            if nargin<2
                error('Must specify argument myScreenInfo');
            end
            
            if SS.nFrames == 0 && isempty(SS.WaveStim) && isempty(SS.WaveSoundcard)
                % this is an empty stimulus
                fprintf('--------------- Empty stimulus ----------------\n');
                return
            end
            
            if ~isempty(SS.WaveStim)
                nt = size(SS.WaveStim.Waves,1);
                tt = (1:nt)/SS.WaveStim.SampleRate;
                figure; plot(tt,SS.WaveStim.Waves)
            end
            
            WinPtr = myScreenInfo.windowPtr; % this way it is not in an object
            
            % alas, this seems inevitable:
            if SS.MinusOneToOne
                Screen('BlendFunction', myScreenInfo.windowPtr, GL_SRC_ALPHA, GL_ONE);
            else
                Screen('BlendFunction', myScreenInfo.windowPtr, GL_ONE, GL_ZERO);
            end
                       
            PointerSequence = SS.GetPointerSequence; % a sequence of pointers to those textures
            
            success = Screen('PreloadTextures', WinPtr, unique(PointerSequence));
            if ~success,
                fprintf('WARNING: Failed to preload textures! Low video memory.\n');
            end
            
            Priority(2);
            
            % first fill the background color
            Screen('FillRect',WinPtr,SS.BackgroundColor(:).*myScreenInfo.ColorChannels2Use(:));
            
            for iFrame = 1:SS.nFrames
                Screen('Flip', WinPtr);
                Screen('DrawTextures', ...
                    WinPtr, ...
                    PointerSequence(:,iFrame), ...
                    SS.SourceRects(:,:,iFrame), ...
                    SS.DestRects(:,:,iFrame), ...
                    SS.Orientations(:,iFrame), ...
                    SS.BilinearFiltering, ...
                    SS.Amplitudes(:,iFrame) );
            end
            Screen('Flip', WinPtr);
            
            if SS.BackgroundPersists
                PersistColor = SS.BackgroundColor;
            else
                PersistColor = GrayIndex(myScreenInfo.WhichScreen); % gray 
            end
            Screen('FillRect', WinPtr, PersistColor(:).*myScreenInfo.ColorChannels2Use(:));
            Screen('Flip', WinPtr);
            
            %             fprintf('Removing %d textures from the video card.\n', SS.nImages);
            %             for iImage = 1:SS.nImages,
            %                 Screen('Close', ImagePointers(iImage));
            %             end
            
            Priority(0);
            
        end % Show
        
        function delete(SS)
            % Delete methods are always called before a object of the class is destroyed
            
            if SS.nImages > 0 && numel(SS.ImagePointers)>0
                fprintf('Deleting stimulus object of kind %s\n',SS.Type);
                fprintf('Removing %d textures from the video card.\n', SS.nImages);
                for iImage = 1:SS.nImages,
                    Screen('Close', SS.ImagePointers(iImage));
                end
            end
            
        end % function delete
        
    end
    
end