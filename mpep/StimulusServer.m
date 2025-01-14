classdef StimulusServer < handle
    % STIMULUS Abstracts out communication to stimulus maker.
    % Holds information about which host to talk to.
    % "mpepProtocol" class will use this when running an experiment to make
    % stimuli.
    
    properties
        
    end
    
    properties(SetAccess = private, GetAccess = private)
        outPort = 1005;
        inPort = 1102;
        stimHost = [];
        socket;
        timeout = 30000;
        duration = 0;
    end
    
    methods
        function self = StimulusServer(host)
            if nargin == 0
                return;
            end
            
            self.stimHost = host;
        end
        
        % r = 1 if established connection with host
        function r = connect(self)
            if isempty(self.stimHost)
                r = 1;
                return;
            end
            import java.net.*;
            self.socket = DatagramSocket(self.inPort);
            
            %% taken out from DatahostCommunicator
%             sendString(self.socket, 'hello', self.stimHost, self.outPort);
%             % will throw exception if anything does not respond
%             try
%                 receiveFromSocket(self.socket, 100, 2000); % short timeout for pings
%             catch e
%                 error(['Unable to communicate with datahost '  self.stimHost]);
%             end
            
            %%
             r = self.ping();
        end
        
        % tell vs to save screen info to log for this expt
        function infoSave(self, animal, series, expNum)
            %seriesAsNum = str2num(datestr(datenum(series, 'yyyy-mm-dd'), 'yyyymmdd'));
            str = sprintf('infosave %s_%d_%d', animal, seriesAsNum(series), expNum);
            if isempty(self.stimHost)
                disp(str);
                pause(0.5);
                return;
            end
            sendString(self.socket, str, self.stimHost, self.outPort);
            self.receive(str);
        end
        % should probably check we don't do more than needed
        function stimInitialize(self, xfile)
            str = ['stiminitialize ' xfile '.x'];
            if isempty(self.stimHost)
                disp(str);
                pause(0.5);
                return;
            end
            sendString(self.socket, str, self.stimHost, self.outPort);
            self.receive(str);
        end
        
        % This function will _block_ until vs finishes making stim.
        function makeStim(self, params)
            disp('Making stim...');
            self.duration = double(params(1));
            str = ['stimmake' sprintf('% d', params)];
            if isempty(self.stimHost)
                disp(str);
                pause(0.5);
                return;
            end
            sendString(self.socket, str, self.stimHost, self.outPort);
            self.receive(str);
            self.duration = params(1);
        end
        
        % This function will _block_ until vs finishes making stim.
        function holdStim(self, ~)
            disp('Making stim...');
            str = 'stimhold';
            if isempty(self.stimHost)
                disp(str);
                pause(0.5);
                return;
            end
            sendString(self.socket, str, self.stimHost, self.outPort);
            self.receive(str);
        end
        
        % This function will _block_ until vs finishes showing stim.
        function showStim(self, ~)
            disp('Playing stim...');
            str = 'stimplay';
            if isempty(self.stimHost)
                disp(str);
                pause(self.duration/10);
                return;
            end
            sendString(self.socket, str, self.stimHost, self.outPort);
            self.receive(str);
        end
        
        function receive(self, expect)
            try
                if strcmp(expect, 'stimplay')
                    r = char(receiveFromSocket(self.socket, 100, self.timeout+100*double(self.duration)));   
                else
                    r = char(receiveFromSocket(self.socket, 100, self.timeout));
                end
                
                if ~strcmp(r,expect)
                    error(['Expected to receive ''' expect '''but got ''' r ''' from stim server.']);
                end
                
            catch e
                % timeout, prompt user to try again
                if ~isempty(regexp(e.message, 'SocketTimeoutException', 'once'))
                    response = questdlg('Timeout on receiving from stimulus sever, try again?',...
                        'Timeout...',  'Yes', 'No', 'Yes');
                    drawnow;
                    if ~strcmp(response, 'Yes')
                        error('Timout when communicating with stimulus server.');
                    else
                        receive(self,expect) % try again
                    end
                else
                    rethrow(e);
                end
            end
        end
        
        function r = ping(self)
            if isempty(self.stimHost)
                r = 1;
                return;
            end
            sendString(self.socket, 'hello', self.stimHost, self.outPort);
            try
                receiveFromSocket(self.socket, 100, 2000);
            catch e
                disp(e)
                r = 0;
                return;
            end
            r = 1;
        end
        
        function disconnect(self)
            if isempty(self.stimHost)
                return;
            end
            if ~isempty(self.socket)
                self.socket.close();
            end
        end
        
        function delete(self)
            self.disconnect();
        end
    end
    
end

