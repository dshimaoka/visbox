function nWaveChans = prepareSessionForStimuli(sess, screenInfo, stimuli)
%PREPARESESSIONFORSTIMULI Sets up DAQ session for outputting waveforms
%   nWaveChans = PREPARESESSIONFORSTIMULI(sess, screenInfo, stimuli)
%   configures and queues the DAQ session, 'sess' with waveform samples from
%   'stimuli.WaveStim', and returns the number of channels that have been
%   queued.
%
%   Configuration info is taken from 'screenInfo.WaveInfo' and the
%   session will be reconfigured with the number of channels required
%   for the stimuli.

waveInfo = screenInfo.WaveInfo;
waveStim = stimuli.WaveStim;

if ~isempty(waveStim)
  nWaveChans = size(waveStim.Waves, 2);
else
  nWaveChans = 0;
end

if ~isempty(sess)
  nWaveOutChans = numel(sess.Channels);
  % remove excess channels
  while nWaveOutChans > nWaveChans
     fprintf('Removing channel %i\n', nWaveOutChans);
    sess.removeChannel(nWaveOutChans);
    nWaveOutChans = nWaveOutChans - 1;
  end
  % add missing channels
  missingChanIds = waveInfo.WaveStimChannel((nWaveOutChans + 1):nWaveChans);
  if numel(missingChanIds) > 0
     fprintf('Adding %i channel(s)\n', numel(missingChanIds));
    sess.addAnalogOutputChannel(waveInfo.DAQString, missingChanIds, 'Voltage');
  end
  if nWaveChans > 0
    % now load the waveform samples with correct sample rate
    sess.Rate = waveStim.SampleRate;
    sess.queueOutputData(waveStim.Waves);
    currentConnections = sess.Connections;
    for iC = length(currentConnections):-1:1
        if isequal(char(currentConnections(iC).Type), 'StartTrigger')
            sess.removeConnection(iC);
        end
    end
    if isfield(waveStim, 'TriggerType') && isequal(waveStim.TriggerType, 'HwDigital')
        triggerDestination = sprintf('%s/%s', waveInfo.DAQString, waveInfo.ExtTriggerChannel);
        tc = sess.addTriggerConnection('external', triggerDestination, 'StartTrigger');
        tc.TriggerCondition = waveInfo.TriggerCondition;
%     sess.ExternalTriggerTimeout = 5; % sec
    end
    sess.prepare();
  end
else
  if nWaveChans > 0
    error('Stimuli contains %i waveforms to deliver, but no waveOut was specified', nWaveChans);
  end
end

end

