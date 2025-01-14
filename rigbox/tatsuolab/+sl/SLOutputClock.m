classdef SLOutputClock < hw.TLOutput
    % A regular analog pulse at a specified frequency and duty
    %   cycle. Can be used to trigger camera frames.
    % 2020-02 DS created from HW.TLOutputRampIllumination
    
    properties
        DaqDeviceID % The name of the DAQ device ID, e.g. 'Dev1', see DAQ.GETDEVICES
        DaqVendor = 'ni' % Name of the DAQ vendor
        DaqChannelID; % camera exposure output channel
        triggerChannelID; % the channel to trigger output ??
        Frequency; % Hz
        lightExposeTime; % ms from start to end
        exposureSamples; % created on init - actual exposure output
    end
    
    properties (Transient, Hidden, Access = protected)
        Timer
    end
    
    methods
        %     function obj = TLOutputRampIllumination()
        %       % TLOutputRampIllumination Constructor method
        %       %   Can take the struct form of a previous instance (as saved in the
        %       %   Timeline hw struct) to intantiate a new object with the same
        %       %   properties.
        %       %
        %       % See Also HW.TIMELINE
        %       obj.Name = 'rampIllumination';
        %     end
        
        function obj = TLOutputCamExpose()
            % TLOutputCamExpose Constructor method
            %   Can take the struct form of a previous instance (as saved in the
            %   Timeline hw struct) to intantiate a new object with the same
            %   properties.
            %
            % See Also HW.TIMELINE
            obj.Name = 'camExpose';
        end
        
        function init(obj, ~)
            % INIT Initialize the output session
            %   INIT(obj, timeline) is called when timeline is initialized.
            %   Creates the DAQ session and adds a PulseGeneration channel with
            %   the specified frequency, duty cycle and delay.
            %
            % See Also HW.TIMELINE/INIT
            
            fprintf(1, 'initializing %s\n', obj.toStr);
            
            % Set the clock rate for the light (need high precision)
            lightRate = 5000;%40000; 23/6/20 for USB6001
            
            % Set max voltage to light (the Cairn box can take 10V and the NIDAQ
            % can give 10V, but this is usually way over the light overload)
            maxLightVoltage = 5;
            
            % Set the light shape (ramps in beginning and end)
            exposureShape = maxLightVoltage*ones(round(lightRate*(obj.lightExposeTime/1000)),1);
            
            % Queue light for a given number of seconds to transition smoothly
            % (i.e. the number of queued samples has to be an integer)
            queueSeconds = obj.Frequency/gcd(obj.Frequency,lightRate);
            illuminationSamples_numSamples = lightRate*queueSeconds;
            illuminationSamples_t = (0:illuminationSamples_numSamples-1)/lightRate;
            % Get the samples which are closest to frame start times
            frameStartIdx = diff([Inf,mod(illuminationSamples_t,1/obj.Frequency)]) < 0;
            frameStartVector = zeros(illuminationSamples_numSamples,1);
            frameStartVector(frameStartIdx) = 1;
            % Draw an exposure time at the start of each frame
            exposureSamplesFull = conv(frameStartVector,exposureShape);
            exposureSamples = exposureSamplesFull(1:illuminationSamples_numSamples);
            
            % Store output samples for queueing before start later
            %obj.illuminationSamples = illuminationSamples;
            obj.exposureSamples = exposureSamples;
            
            % Set up triggered continuous daq output
            obj.Session = daq.createSession(obj.DaqVendor);
            obj.Session.TriggersPerRun = 1;
            obj.Session.IsContinuous = true;
            
            % Define when to queue more data
            % (NOTE: slower computers need more time)
            obj.Session.NotifyWhenScansQueuedBelow = ...
                round(length(exposureSamples)/2);
            
            % Set up outputs for both illumination and camera acquisition
            obj.Session.addAnalogOutputChannel( ...
                obj.DaqDeviceID, obj.DaqChannelID, 'Voltage');
            %  obj.Session.addDigitalChannel(obj.DaqDeviceID, obj.DaqChannelID, 'OutputOnly'); %as in TLOutputAcqLive
            
            % Initialize outputs to zero
            % (do before setting trigger, otherwise flushes)
            obj.Session.outputSingleScan(0);%[0,0]);
            
            % Set clock rate
            obj.Session.Rate = lightRate;
            
            % Trigger onset with acqLive
            addTriggerConnection(obj.Session,'external',obj.triggerChannelID,'StartTrigger'); %???
            
        end
        
        function start(obj, ~)
            % START Starts the clocking pulse
            %   Called when timeline is started, this uses STARTBACKGROUND to
            %   start the clocking pulse
            %
            % See Also HW.TIMELINE/START
            
            % Upload the output samples (has to be done here, if it's done
            % earlier things in the pipeline flush the queue)
            queueOutputData(obj.Session, obj.exposureSamples);
            
            % Set up future queueing
           addlistener(obj.Session,'DataRequired',@(src,event) ...
                src.queueOutputData([obj.exposureSamples]));
            
            % Start output
            startBackground(obj.Session);
            
        end
        
        function process(~, ~, ~)
            % PROCESS() Listener for processing acquired Timeline data
            %   PROCESS(obj, source, event) is a listener callback
            %   function for handling tl data acquisition. Called by the
            %   'main' DAQ session with latest chunk of data.
            %
            % See Also HW.TIMELINE/PROCESS
            
            %fprintf(1, 'process Clock\n');
            % -- pass
        end
        
        function stop(obj,~)
            % STOP Stops the DAQ session object.
            %   Called when timeline is stopped.  Stops and releases the
            %   session object.
            %
            % See Also HW.TIMELINE/STOP
            if obj.Verbose; fprintf(1, 'stop %s\n', obj.Name); end
            stop(obj.Session);
            
            % Set outputs to zero
            obj.Session.outputSingleScan(0);%[0,0]);
            
            %             release(obj.Session);
            %             obj.Session = [];
            %             obj.Timer = [];
        end
        
        function s = toStr(obj)
            % TOSTR Returns a string that describes the object succintly
            %
            % See Also INIT
            s = sprintf('%s: %g Hz Frequency, %g ms exposure', obj.Name, ...
                obj.Frequency, obj.lightExposeTime);
        end
        
        function terminate(obj,~) %11/10/2019
            if obj.Enable
                fprintf(1, 'terminate %s\n', obj.Name);
                stop(obj.Session); %28/7/20
                release(obj.Session);
                obj.Session = [];
                obj.Timer = [];
            end
        end
        
    end
    
end

