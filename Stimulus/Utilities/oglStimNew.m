function oglStim = oglStimNew()
% Creates a new (blank) oglStim
%
% oglStim = oglStimNew()
% Use it before making stimuli to preallocate with correct order of fields
% 
% *************** FIELDS OF GENERAL IMPORTANCE
% Type                % the code that made it
% saved               % if true, it prevents being cleared
% Pars                % a record of the parameters that went in
% TextureParameters   % indicates which parameters determine the textures
%
% *************** FIELDS THAT ARE NEEDED BY oglStimPlay:
%
% The fields of oglStim are:
%
% oglStim.Version   % can have these values:
%           1: one texture per frame, no srcRect, no ori, no globalAlpha
%           2: one texture per frame, srcRect, ori, globalAlpha
%           3: multiple textures per frame (srcRect assumed to be empty)
%
% FlagMinusOneToOne % false (for gray levels 0 to 255) or true (for -1 to 1)
% nframes
% nperiods
% position;         % position of each stimulus
% texturePtrList;	% pointers to each texture in memory
% frameIndex;		% index of texture to use each frame
% positionIndex;	% index of stimulus to use each frame
%
% For versions 1 and 2:
% srcRect
% ori
% globalAlpha
%
% *************** POSSIBLY OBSOLETE:
% Generation
%
%
% 2010-02 MC
% 2010-03 MC updated
% 2010-07 MC updated

oglStim.Type                = []; 
oglStim.saved               = false; % if true, it prevents being cleared
oglStim.Pars                = []; % needed??
oglStim.TextureParameters   = [];

oglStim.Version             = NaN; % 
oglStim.FlagMinusOneToOne   = []; % possibly always 1 in generation >3?
oglStim.nframes             = [];
oglStim.nperiods            = 1; % I suppose this is the default.
oglStim.position            = [];
oglStim.texturePtrList      = [];
oglStim.frameIndex          = [];
oglStim.positionIndex       = [];

oglStim.srcRect             = [];
oglStim.ori                 = [];
oglStim.globalAlpha         = [];

oglStim.Generation          = []; % probabaly soon to be obsolete

% added by MC 2010-07
oglStim.frames   = [];
oglStim.luts     = [];  % probably obsolete
oglStim.sequence = [];  % important
