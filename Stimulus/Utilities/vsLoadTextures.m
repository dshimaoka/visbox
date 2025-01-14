function stim = vsLoadTextures(myscreen, stim, keep)
% Converts old format stimuli into textures and load into memory
% Old format stimuli used to be specified as frames / cluts
%
% stim = vsLoadTextures(myscreen, stim, [keep])
% keep = 0 clears obsolete data from stim structure (frames, etc.)
% keep = 1 leaves that data intact [DEFAULT]
%
% 2006-11-16 JBB created
% 2007-03 MC replaced calls to Snd with calls to audioplayer
% 2008-03 LB checks if textures are already loaded
% 2009-12 MC gets the ring tone from VisBox directory
% 2010-02 MC added mergeStimuli as subfunction instead of separate function

if nargin < 3,
    keep = 1; % default is to keep the frames
end

if isfield(stim, 'texturePtrList') && ~isempty(stim.texturePtrList)
    % the function has already been called
    return;
end

% merge stimuli if they are interleaved
if length(stim) > 1,
    [stim, stimKey] = mergeStimuli(stim);
else
    %%%	stim = stim{1};	% only 1 stimulus so remove second cell wrapper
    if isfield(stim, 'positionIndex')
        stimKey = stim.positionIndex;
    else
        stimKey = [];	% will fill in later
    end
end

% calculate key vectors for indexing stimulus data (frames, cluts, etc.)
frameKey = stim.sequence.frames;
clutKey = stim.sequence.luts; % obsolete
nframes = length(frameKey);		% total number of frames to play...
realFrames = ~isnan(frameKey);
realCluts = ~isnan(clutKey);
ntextures = length(unique(frameKey(realFrames))) * ...
    length(unique(clutKey(realCluts)));		% maximum total textures needed

if isempty(stimKey),
    stimKey = ones(size(frameKey))';		% all frames belong to single (first) stimulus
end

% pre-access some structure data
frameList = stim.frames{1};
clutList = stim.luts;

% MC 2010-02-03
if ~isfield(stim,'FlagMinusOneToOne')
    stim.FlagMinusOneToOne = 0;
    % traditional stimulus, from 0 to 255
end

try

    % change made by MC 2009-12
    % ring = wavread('C:\WINDOWS\Media\ringin.wav');
    try
        ring = wavread('ringin.wav'); % now in VisBox
    catch
        % MK 2017-09-20 wavread() has been removed in newer Matlab versions
        ring = audioread('ringin.wav'); % now in VisBox
    end

    % ADDED BY MC 2007-03-20 TO AVOID USING BUGGY Snd
    oRingRing = audioplayer([ring; ring], 2*8192);

    % some error checks originally in vsPlayStimulus
    if length(stim.sequence.luts) ~= length(stim.sequence.frames),
        % Edited by MC 2007-03-20:
        play(oRingRing); % Snd('Play', [ring; ring], 2*8192 );
        error('Bad stimulus: Stim.sequence.luts and Stim.sequence.frames must have the same length!');
    end
    if isempty(stim.luts)
        % Edited by MC 2007-03-20:
        play(oRingRing); % Snd('Play', [ring; ring], 2*8192 );
        error('Bad stimulus: You must specify at least one lut in Stim.lut!');
    end
    if isempty(stim.frames)
        % Edited by MC 2007-03-20:
        play(oRingRing); % Snd('Play', [ring; ring], 2*8192 );
        error('Bad stimulus: You must specify at least one frame in Stim.frames!');
    end
%     failSizeCheck = 0;

    winPtr = myscreen.windowPtr;
    fprintf('Loading textures... ');
    texPtrList = zeros(ntextures, 1);
    
    % added by MC 2011-02-15 and 2011-02-18
    texSizes = zeros(ntextures,2);
    AllTextures = cell(ntextures,1);
    
    textureIndexList = zeros(nframes, 1);

    % record frame and clut index used to build each texture
    uniqueTextureFrameClut = zeros(ntextures, 2);

    % preload textures into memory
    lastFrameIdx = 1;		% index of last frame loaded
    currentTextureIdx = 0;	% index of current texture
    for iframe = 1:nframes,		% check each frame played for novel index combinations
        
        frameIdx = frameKey(iframe);
        clutIdx = clutKey(iframe);

        % handle NaN frame indices
        if isnan(frameIdx),
            frameIdx = lastFrameIdx;	% replace NaN frame with previous (non-NaN)
        else
            lastFrameIdx = frameIdx;	% just loading for next potential NaN
        end

        % determine if this frame/clut combo is novel
        locator = find( uniqueTextureFrameClut(:,1) == frameIdx & ...
            uniqueTextureFrameClut(:,2) == clutIdx);
        if isempty(locator),

            % YES -- create texture and save index information
            currentTextureIdx = currentTextureIdx + 1;
             
            if stim.FlagMinusOneToOne
                currentFrame = frameList{frameIdx};
            else
                currentFrame = frameList{frameIdx} + 1;		% original frame indices were 0:255
            end
            
            currentClut = clutList{clutIdx};
            % MC 2011-03 
            % textureSize = [size(currentFrame), 3];		% 3-D RGB texture planes
            
            % map frame (i.e., list of CLUT index values) to 3-plane rgb texture matrix         
            if ~stim.FlagMinusOneToOne
                % MC 2011-03 
                texture1 = zeros(size(currentFrame),'uint8');
                texture1(:) = currentClut(currentFrame, 1);
                texture2 = zeros(size(currentFrame),'uint8');
                texture2(:) = currentClut(currentFrame, 2);
                texture3 = zeros(size(currentFrame),'uint8');
                texture3(:) = currentClut(currentFrame, 3);
                texture = cat( 3, texture1, texture2, texture3 );
                AllTextures{currentTextureIdx} = texture;
                
                % MC 2011-03 
                % texture = reshape( currentClut(currentFrame, :), textureSize );
                
                % AllTextures{currentTextureIdx} = uint8(texture);
                FloatPrecision = 0; % 8 bit
            else
                texture = currentFrame;
                % load frame into texture memory (default: 16 bit precision)
                AllTextures{currentTextureIdx} = single(texture);
                FloatPrecision = 1; % 16 bit
            end
                texPtrList(currentTextureIdx) = Screen('MakeTexture', winPtr, double(texture), [], 0, FloatPrecision);
            % added by MC 2011-02-15 and 2011-02-18
            texSizes(currentTextureIdx,:) = [size(texture,1) size(texture,2)];
            
            % record frame and clut indices used
            uniqueTextureFrameClut(currentTextureIdx, :) = [frameIdx, clutIdx];
            textureIndexList(iframe) = currentTextureIdx;

        else
            % NO -- frame/clut combo previously used, so just index that texture
            textureIndexList(iframe) = locator;
        end

    end		% for iframe = 1:nframes,
    fprintf('%d textures stored.\n', currentTextureIdx);
    texPtrList = texPtrList(1:currentTextureIdx);	% in case fewer textures than max were loaded

    % added by MC 2011-02-15 and 2011-02-18
    texSizes = texSizes(1:currentTextureIdx,:);
    AllTextures = AllTextures(1:currentTextureIdx);
    
    if ~keep,
        stim.frames = {};
        stim.luts = {};
        stim.sequence = [];
    end

    % finish stim structure
    stim.texturePtrList = texPtrList;	% pointers to each frame
    stim.frameIndex = textureIndexList;
    stim.positionIndex = stimKey;
    stim.saved = 0;		% flag used by vs.m to manage pointers for saved stimuli

    % added by MC 2011-02-15 and 2011-02-18
    stim.textureSizes = texSizes;
    % then subsequently commented it out as it takes up too much memory...
    % stim.AllTextures = AllTextures;
    stim.nImages = length(AllTextures);
    
    %% added by MC 2010-03
    % figure out what version of the stimulus we are working with 
    
    % 1: traditional stimulus
    % 2: ogl stimulus, single frame (can specify srcRect)
    % 3: ogl stimulus, multiple frames (srcRect assumed to be empty)
    
    % VERSION:
    % 1: ogl stimulus, one texture per frame, no srcRect, no ori, no globalAlpha
    % 2: ogl stimulus, one texture per frame, srcRect, ori, globalAlpha
    % 3: ogl stimulus, multiple textures per frame (srcRect
    % assumed to be empty)
                
    stim.Version = 1; % default
    nframes = length(stim.frameIndex);
    
    if all(isfield(stim, {'srcRect', 'ori', 'globalAlpha'})) % new fields in the stim structure
        
        stim.Version = 2; % default
        
        if size(stim.position,1) > 1 && size(stim.position,1) ~= length(stim.frameIndex)
            stim.Version = 3;
            [ntextures,nframes] = size(stim.ori);
            fprintf('Reshaping.\n');
            stim.positionIndex = reshape(stim.positionIndex, [ntextures,nframes]);
            stim.frameIndex    = reshape(stim.frameIndex   , [ntextures,nframes]);
            stim.srcRect       = reshape(stim.srcRect, [ntextures,nframes]); % not used
        end
        
    end
    
    stim.nframes = nframes;
    
    %% added by MC 2011-02-21
    if ~isfield(stim,'FlagMinusOneToOne')
        stim.FlagMinusOneToOne   = false;
        
        if isfield(Stim,'ori')
            % this is a stupid way of doing this:
            if isempty(stim.srcRect)
                stim.Version = 3;
            else
                stim.Version = 2;
            end
        else
            stim.Version = 1;
        end
    end
                

catch

    Screen('CloseAll');
    fprintf('Error from vsLoadTextures.m\n');
    psychrethrow(psychlasterror);
end

%%

function [mergedStim, interleaveSeq] = mergeStimuli(stim)
% mergeStimuli merges interleaved stimuli into a single stim structure
% output interleaveSeq is index list of which frames (pointers, etc.)
%  belong to which stimuli (1, 2, etc.)
% note: expects outer cell wrapper to be stripped from <stim> input
% called by vsLoadTextures.m
%
% 2006-11-17 JBB created
% 2008-03 LB support for fields ori, globalAlpha, srcRect for new ogl stimuli

nstim = length(stim);	% number of stimuli

% LB 080307
oglStimFlag = 0;
if isfield(stim{1}, 'ori')
    oglStimFlag = 1;
end

% initialize pooled data variables
positionList = zeros(nstim, 4);
mergedFrames = {};
mergedCluts = {};
frameIndexStack = [];
clutIndexStack = [];
interleaveIndexStack = [];

% merge loop
for s = 1:nstim,

	% calculate cumulative frame lists
	% to index the new frames, their original index values need to be shifted
	%  by the number of frames already in the stack, hence indexShift
	indexShift = length(mergedFrames);
	currentFrames = stim{s}.frames{1};
	if size(currentFrames, 2) > 1,			% if it is a row cell vector
		currentFrames = currentFrames';		% standardize to column
	end
	mergedFrames = cat(1, mergedFrames, currentFrames);
	% keep indices as a row vector but stack subsequent stimuli on top
	frameIndexStack = [frameIndexStack; stim{s}.sequence.frames + indexShift];

	% calculate cumulative clut lists, as per frames
	indexShift = length(mergedCluts);
	currentCluts = stim{s}.luts;			% (no cell wrapper here)
	if size(currentCluts, 2) > 1,			% if it is a row cell vector
		currentCluts = currentCluts';		% standardize to column
	end
	mergedCluts = cat(1, mergedCluts, currentCluts);
	clutIndexStack = [clutIndexStack; stim{s}.sequence.luts + indexShift];

	% cumulative positions, periods (?), and original stimulus membership index
	positionList(s, :) = stim{s}.position;
	interleaveIndexStack = [interleaveIndexStack; repmat(s, size(stim{s}.sequence.frames))];
    
    % LB 080307: take care of ogl fields
    if oglStimFlag
        oriList(s,:) = stim{s}.ori;
        globalAlphaList(s,:) = stim{s}.globalAlpha;
        srcRectList = cell(length(stim{s}.srcRect),1);
        for iframe = 1 : length(stim{s}.srcRect)
            srcRectList{iframe}{s} = stim{s}.srcRect{iframe};
        end
    end

end		% for s = 1:nstim,

% total number of index values in merged structure
totalSeq = numel(frameIndexStack);

% build new output structure
mergedStim.frames = {mergedFrames};		% rewrap frame list in cell
mergedStim.luts = mergedCluts;
mergedStim.sequence.frames = reshape(frameIndexStack, totalSeq, 1);
mergedStim.sequence.luts = reshape(clutIndexStack, totalSeq, 1);
mergedStim.position = positionList;
mergedStim.nperiods = stim{1}.nperiods;	% ignore nperiod for stimuli > 1
% 080307 take care of merged stim
if oglStimFlag
    mergedStim.ori = oriList;
    mergedStim.globalAlpha = globalAlphaList;
    mergedStim.srcRect = srcRectList;
end
% need original membership to index (e.g.) position matrix
interleaveSeq = reshape(interleaveIndexStack, totalSeq, 1);

% added by MC 2010-02-03:
if isfield(stim{1},'FlagMinusOneToOne')
    mergedStim.FlagMinusOneToOne = stim{1}.FlagMinusOneToOne;
else 
    mergedStim.FlagMinusOneToOne = false;
end
