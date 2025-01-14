function sls = bindMpepServer(mpepListenPort)
%TL.BINDMPEPSERVER Mpep data host for Timeline
%   SLS = SL.BINDMPEPSERVER([listenPort]) binds to the Mpep data host UDP
%   port, and returns state and utility functions for processing Mpep
%   instructions to start/stop Timeline with experiments.
%
%   Functions are fields of returned 'sls' struct, and include:
%   'process()' that will check for UDP messages, and start & stop Stimline
%   if valid 'ExpStart' or 'ExpEnd' instructions are recieved, and 'listen()'
%   which blocks to keep calling process() in a loop. Mpep UDP messages are
%   echoed back to the client while all is well.
%
% 17/7/2019 DS created from tl.bindMpepServer


if nargin < 1 || isempty(mpepListenPort)
    mpepListenPort = 1001; % listen for commands on this port
end

% mpepSendPort = 1103; % send responses back to this remote port
quitKey = KbName('esc');
%manualStartKey = KbName('t');
%livePlotKey = KbName('p');

%% Start UDP communication
listeners = struct(...
    'socket',...
    {pnet('udpsocket', mpepListenPort),...  %mpep listening socket
    },... %deleted ball listening socket
    'callback',...
    {@processMpep,... % special mpep message handling function
    },...        
    'name', {'mpep'});
log('Bound UDP sockets');

sls.close = @closeConns;
sls.process = @process;
sls.listen = @listen;


%% Initialize stimline
rig = hw.devices([], false); %visbox\rigbox\main\+hw
slObj = rig.stimline;


%% Helper functions

    function closeConns()
        log('Unbinding UDP socket');
        arrayfun(@(l) pnet(l.socket, 'close'), listeners);
    end

    function process()
        %% Process each socket listener in turn
        arrayfun(@processListener, listeners);
    end

    function processListener(listener)
        sz = pnet(listener.socket, 'readpacket', 1000, 'noblock');
        if sz > 0
            %t = slObj.time(false); % save the time we got the UDP packet
            msg = pnet(listener.socket, 'read');
%             if slObj.IsRunning
%                 slObj.record([listener.name 'UDP'], msg, t); % record the UDP event in Timeline
%             end
            listener.callback(listener, msg); % call special handling function
        end
    end

    function processMpep(listener, msg)
        [ip, port] = pnet(listener.socket, 'gethost');
        ip = num2cell(ip);
        ipstr = sprintf('%i.%i.%i.%i', ip{:});
        log('%s: ''%s'' from %s:%i', listener.name, msg, ipstr, port);
        % parse the message
        info = dat.mpepMessageParse(msg);
        failed = false; % flag for preventing UDP echo
        %% Experiment-level events start/stop timeline
        
             switch lower(info.instruction)
                case 'expstart'
                    % create a file path & experiment ref based on experiment info
                    try
                        % initialize Stimline
                        slObj.init();
                        slObj.trigEnabled = true;
                    catch ex
                        % flag up failure so we do not echo the UDP message back below
                        failed = true;
                        disp(getReport(ex));
                    end
                    
                case 'blockstart'
                    if slObj.trigEnabled %this won't happen when playing test stimuli
                        try
                            % start sending output
                            slObj.start(info.expRef);
                        catch ex
                            % flag up failure so we do not echo the UDP message back below
                            failed = true;
                            disp(getReport(ex));
                        end
                    else
                        fprintf("Stimline does nothing here\n");
                    end
                    
                case 'blockend'
                    slObj.stop(); % stop output
                 
                case 'expend'
                    slObj.terminate(); % release session
                    slObj.trigEnabled = false;
                    
                case 'expinterrupt'
                    slObj.terminate(); % release session
                    slObj.trigEnabled = false;
                    
            end
     
        if ~failed
            %% echo the UDP message back to the sender
            %       if ~connected
            %         log('Connecting to %s:%i', ipstr, confirmPort);
            %         pnet(tls.socket, 'udpconnect', ipstr, confirmPort);
            %         connected = true;
            %       end
            pnet(listener.socket, 'write', msg);
            pnet(listener.socket, 'writepacket', ipstr, port);
        end
    end

    function listen()
        % polls for UDP instructions for starting/stopping stimline
        % listen to keyboard events
        KbQueueCreate();
        KbQueueStart();
        cleanup1 = onCleanup(@KbQueueRelease);
        log(['Stimline: Polling for UDP messages. PRESS <%s> TO QUIT'],...
            KbName(quitKey));
        running = true;
        tid = tic;
        while running
            process();
            [~, firstPress] = KbQueueCheck;
            if firstPress(quitKey)
                running = false;
            end
      
            if toc(tid) > 0.2
                pause(1e-3); % allow stimline aquisition every so often
                tid = tic;
            end
        end
    end

    function log(varargin)
        message = sprintf(varargin{:});
        timestamp = datestr(now, 'dd-mm-yyyy HH:MM:SS');
        fprintf('[%s] %s\n', timestamp, message);
    end

end

