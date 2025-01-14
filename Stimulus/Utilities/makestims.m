function stim = makestims(protocol,myscreen,istim)
% Makes a stimulus structure for a given protocol
% 
% stim = makestims(protocol,myscreen,istim)
% stim has always the following structure:
% stim{istim}{ileave}.frames{ipatch}{iframe}
% stim{istim}{ileave}.luts{iframe}
% stim{istim}{ileave}.position(ipatch,[1:4])
%
% This function just calls the right vis file and generates all stimuli 
% of an experiment.
% 
% Notice that many vis files need the psychophysics toolbox. 
%
% part of VisBox

% 2003-06-18 VM from makestims
% 

if nargin < 3
   istim = [];
end

% The name of the xfile
xfile = protocol.xfile(1:end-2);

% Loop over the stimuli
nstim = size(protocol.pars,2);
if ~isempty(istim)
   if istim <= nstim
      pars = protocol.pars(:,istim);
      thisstim = eval([xfile '(pars,myscreen)']);
      if iscell(thisstim)
         stim{1} = thisstim;
      else
         stim{1}{1} = thisstim;
      end
   else
      stim = [];
      disp(sprintf('---> WARNING: there are only %i stimuli in this protocol',nstim));
      disp(sprintf('---> Couldn`t compute stimulus %i',istim));
   end
else      
   for istim = 1:nstim
      pars = protocol.pars(:,istim);
      thisstim = eval([xfile '(pars,myscreen)']);
      if iscell(thisstim)
         stim{istim,1} = thisstim;
      else
         stim{istim,1}{1} = thisstim;
      end
   end
end

return

%% Code to test the function

DIRS.data = 'z:\cat';
protocol = protocolload('catz033',3,7);
myscreen = defaultscreen;

stim = makestims(protocol,myscreen,1);


