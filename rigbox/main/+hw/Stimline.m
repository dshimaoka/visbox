classdef Stimline < handle
    % HW.STIMLINE Returns an object that generate clocking pulses
    %   Stimline (tl) manages the generation of experimental
    %   timing data "acqLive" using an NI data aquisition device. 
    % 
    % 17/7/2019 DS created from Rigbox/+hw/Timeline.m
    
    properties
        DaqVendor = 'ni' % 'ni' is using National Instruments USB-6211 DAQ
        DaqIds = 'Dev1' % Device ID can be found with daq.getDevices()
        %DaqSampleRate = 1000 % rate at which daq aquires data in Hz, see Rate
        %DaqSamplesPerNotify % determines the number of data samples to be processed each time, see Timeline.process(), constructor and NotifyWhenDataAvailableExceeds
        Outputs = sl.SLOutputAcqLive % array of output classes, defining any signals you desire to be sent from the daq. See Also HW.TLOUTPUT, HW.TLOUTPUTCLOCK
        %MaxExpectedDuration = 2*60*60 % expected experiment time so data structure is initialised to sensible size (in secs)
        IsRunning = false %true if liveAcq is HIGH (this is no longer dependent property)
        % flag is set to true when the first chrono pulse is aquired and set to false when tl is stopped (and everything saved), see tl.process and tl.stop
        trigEnabled = false; %true when receiving ExpStart
    end
    
%     properties (Dependent)
%         SamplingInterval % defined as 1/DaqSampleRate
%     end
    
    properties (Transient, Access = protected)
        Listener % holds the listener for 'DataAvailable', see DataAvailable and Timeline.process()
        LastTimestamp % the last timestamp returned from the daq during the DataAvailable event.  Used to check sampling continuity, see tl.process()
        Ref % the expRef string.  See tl.start()
     end
    
    properties (Transient, SetAccess = protected, GetAccess = {?hw.Timeline, ?hw.TLOutput})
        Sessions = containers.Map % map of daq sessions and their channels, created at SL.start()
    end
    
    methods
        function obj = Stimline(hw)
            % STIMLINE Constructor method
            %   SL.STIMLINE(hw) constructor can take only aquireLive to the outputs list,
            
            
            %obj.DaqSamplesPerNotify = 1/obj.SamplingInterval; % calculate DaqSamplesPerNotify
            if nargin % if old tl hardware struct provided, use these to populate properties
                obj.DaqVendor = hw.daqVendor;
                obj.DaqIds = hw.daqDevice;
                %obj.DaqSampleRate = hw.daqSampleRate;
                %obj.DaqSamplesPerNotify = hw.daqSamplesPerNotify;
                % Configure the outputs
                outputs = catStructs(hw.Outputs);
                obj.Outputs = objfun(@(o)eval([o.Class '(o)']), outputs, 'Uni', false);
                obj.Outputs = [obj.Outputs{:}];
            end
        end
        
        function start(obj, expRef)
            % START Starts timeline data acquisition
            %   START(obj, ref) starts all DAQ sessions and adds
            %   the relevent output channels.
            %
            % See Also HW.TLOUTPUT/START
            
            if obj.IsRunning % check if it's already running, and if so, stop it
                disp('"AcqLive" already running, stopping first');
                obj.stop();
            end
            obj.Ref = expRef; % set the current experiment ref
            
            %init(obj); % start the relevent sessions and add channels
         
            %obj.LastTimestamp = -obj.SamplingInterval;
            %startBackground(obj.Sessions('main')); % start aquisition
            
            % wait for first acquisition processing to begin
            % while ~obj.IsRunning; pause(5e-3); end
            %             end %~isempty(obj.UseInputs)
            
            % Start each output
            arrayfun(@start, obj.Outputs)
            obj.IsRunning = true; %17/7/19
            
            % Report success
            fprintf('started "acqLive" successfully for ''%s''.\n', expRef);
        end
        
        
%         function v = get.SamplingInterval(obj)
%             %GET.SAMPLINGINTERVAL Defined as the reciprocal of obj.DaqSampleRate
%             v = 1/obj.DaqSampleRate;
%         end
        
        %         function bool = get.IsRunning(obj)
            %             % TL.ISRUNNING Determine whether tl is running.
            %             %   timeline is officially 'running' when first acquisition
            %             %   samples are in, i.e. the raw sample count is greater than 0
            %             if isfield(obj.Data, 'rawDAQSampleCount')&&...
            %                     obj.Data.rawDAQSampleCount > 0
            %                 % obj.Data.rawDAQSampleCount is greater than 0 during the first call to tl.process
            %                 bool = true;
            %             else % obj.Data is cleared in tl.stop, after all data are saved
            %                 bool = false;
            %             end
            %            end
        
        
        function stop(obj)
            %SL.STOP Stops Timeline data acquisition
            %   SL.STOP() stops all running DAQ sessions
            %
            % See Also HW.TLOUTPUT/STOP
            if ~obj.IsRunning
                fprintf('Nothing to do, Stimline is not running!\n');
                return
            end
            
            % stop acquisition output signals
            arrayfun(@stop, obj.Outputs)
            obj.IsRunning = false; %17/7/19

            % Report successful stop
            fprintf('stopped "acqLive" for ''%s'' successfully.\n', obj.Ref);
        end
        
        %     methods (Access = private) %why private?
        function init(obj)
            % Create DAQ session and add channels
            %   SL.INIT() creates all the DAQ sessions
            %   and stores them in the Sessions map by their Outputs name.
            %   Also add a 'main' session to which all input channels are
            %   added.
            %
            % See Also DAQ.CREATESESSION
            
            
            %Initialize outputs
            arrayfun(@(out)out.init(obj), obj.Outputs)
        end
        
        function terminate(obj)
            %Release outputs
            arrayfun(@(out)out.terminate(obj), obj.Outputs)
            fprintf('\n');
        end
        
    end
end