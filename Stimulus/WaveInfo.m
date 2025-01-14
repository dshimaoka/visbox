classdef WaveInfo
  %WAVEINFO information about DAQ config on the rig
  %   Information about the DAQ configuration to use for delivering
  %   waveforms during stimulus and frame sync square
  %
  % 2013-01 CB Added FrameSyncChannel & WaveChannelIDs, removed DoWaves
  
  properties
    DAQAdaptor = ''
    DAQString  = ''
    ExtTriggerChannel = 'PFI0';
    TriggerCondition = 'RisingEdge';
    SampleRate = 5000
    FrameSyncChannel = 'port0/line0' %Sync square echo digital output
    %Analog output channel to use for each row in the WaveStim
    WaveStimChannel = 0:9
  end
  
  methods
    function r = DoWaves(WI)
      r = ~isempty(WI.DAQAdaptor);
    end

    function Describe(WI)
      if ~isempty(WI.DAQAdaptor)
        fprintf('Adaptor is %s (%s), samplerate %d Hz\n',...
          WI.DAQAdaptor, WI.DAQString, WI.SampleRate);
      else
        fprintf('No DAQ adaptor\n');
      end
    end
    
  end
  
end

