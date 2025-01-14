function mpepListener()
%SL.MPEPLISTENER Starts an Mpep UDP listener to start/stop Timeline
%   SL.MPEPLISTENER() starts a blocking listener for Mpep protocol UDP
%   messages to start/stop Timeline when an experiment is started or
%   stopped.
%

% 16/7/2019 DS created from Rigbox/TL.MPEPLISTENER

pnet('closeall');%7/10/19

sls = sl.bindMpepServer();
cleanup = onCleanup(sls.close);
sls.listen();

end

