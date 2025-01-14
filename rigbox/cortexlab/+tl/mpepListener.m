function mpepListener()
%TL.MPEPLISTENER Starts an Mpep UDP listener to start/stop Timeline
%   TL.MPEPLISTENER() starts a blocking listener for Mpep protocol UDP
%   messages to start/stop Timeline when an experiment is started or
%   stopped.
%
% Part of Cortex Lab Rigbox customisations

% 2014-01 CB created

config_timeline_dsRig; %21/10/2020

pnet('closeall');%7/10/19

tls = tl.bindMpepServer();
cleanup = onCleanup(tls.close);
tls.listen();

end

