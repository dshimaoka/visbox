function RigInfo = RigInfoGet(VsHostName)
% Database of information of various rigs in the lab
%
% RigInfo = GetRigInfo gives you information on the computer you are
% running from.
%
% RigInfo = GetRigInfo(VsHostName) lets you specify the name of the
% computer.
%
% RigInfo has the following fields:
%  VsHostName
%  VsHostCalibrationDir
%  VsDisplayScreen
%  VsDisplayAdaptor
%  MonitorType
%  MonitorSize
%  MonitorNumber
%  DefaultMonitorDistancevs
%  zpepComputerName
%  zpepComputerIP
%  SyncSquare an object with fields Type, Position, Size
%  W
%  ColorChannels2Use
%
% 2011-02 Matteo Carandini extracted from vs and improved
% 2011-07 AA commented out RigInfo.WaveInfo object specifications for
%         zupervision
% 2012-04 MK added ZMAZE rig
% 2012-08 AS added RigInfo.WaveInfo object specifications for
%         zupervision back in to try new NI card
% 2013-09 MC added ScaleOldStimuliFactor
% 2022-05 NH added new case for MU00221314 for wf, changed zpep host name
%         and IP
%% deal with arguments

if nargin < 1
    MyDir = pwd;
    cd('C:/');
    [~,VsHostName] = system('hostname');
    VsHostName = VsHostName(1:end-1);
    cd(MyDir);
end

%% defaults

RigInfo.VsHostName = VsHostName;
RigInfo.VsHostCalibrationDir = 'C:\Calibrations\';
RigInfo.VsDisplayScreen = 1;
RigInfo.VsDisplayAdaptor = '';
RigInfo.MonitorType = '';
RigInfo.MonitorSize = NaN; % this is the total size !
RigInfo.MonitorNumber = 1;
RigInfo.DefaultMonitorDistance = 28.5; % cm

RigInfo.VsDisplayRect = []; % empty means whole screen (MC 2013-04-25)
RigInfo.zpepComputerName = '';
RigInfo.zpepComputerIP = '';

% defaults for the sync square
RigInfo.SyncSquare = SyncSquare; % this makes a new object

RigInfo.WaveInfo = WaveInfo; % blank DAQ info object

RigInfo.ScaleOldStimuliFactor = NaN; % MC 2013/09/03 scales "old style" stimuli to save memory

%% database

fprintf('Loading information for VS host %s\n', VsHostName);

switch upper(VsHostName)
    
    case 'LILRIG-STIM'        
        % Copied from ZGOOD
        
        RigInfo.VsDisplayScreen = 0;
        RigInfo.VsDisplayAdaptor = 'Nvidia NVS 510';
        RigInfo.MonitorType = 'Apple Ipad';
        RigInfo.MonitorSize = 20*3; %cm
        RigInfo.MonitorNumber = 3;
        RigInfo.MonitorHeight = 15;
        RigInfo.DefaultMonitorDistance = 10;
        
        RigInfo.Geometry = 'Circular'; % 'Flat' or 'Circular'
        RigInfo.HorizontalSpan = 270; % degrees of the overall (two-sided) span
                
        RigInfo.zpepComputerIP = 'LILRIG-MC';
        RigInfo.zpepComputerName = 'LILRIG-MC';
                
        flickerflag=[];
        while isempty(flickerflag)
            flickerflag=input('Type of sync square?  ({s}teady or {f}licker) >>','s');
            switch flickerflag
                case 's'
                    RigInfo.SyncSquare.Type = 'Steady';
                case 'f'
                    RigInfo.SyncSquare.Type = 'flicker';
                    
                otherwise
                    flickerflag=[];
            end
        end
        
        RigInfo.SyncSquare.Size = 200;
        RigInfo.SyncSquare.Position = 'SouthEast';
        
        RigInfo.WaveInfo.DAQAdaptor = 'ni';
        RigInfo.WaveInfo.DAQString = 'Dev1';
        RigInfo.WaveInfo.FrameSyncChannel = 'port1/line0';
        RigInfo.ScaleOldStimuliFactor = 6;
   
        

    case 'MU00177020' %for wf; new MPEP pc
       RigInfo.VsDisplayAdaptor = 'Nvidia Quadro P620';
        RigInfo.MonitorType = 'Apple Ipad';
        RigInfo.MonitorSize = 14.744; %20; % cm - short side 
        
        %for geometry undistortion ... "stimproblem" from vs 18/11/24
%          RigInfo.DefaultMonitorDistance = 8;%24/7/20 %cm
         
         %without geometry undistortion
        RigInfo.DefaultMonitorDistance = 11.5;%cm
        RigInfo.Geometry = 'Circular'; % 'Flat' or 'Circular'
        RigInfo.HorizontalSpan = 209; % degrees of the overall span

        RigInfo.VsDisplayScreen = 2;%0; %7/8/25
        RigInfo.VsHostCalibrationDir = 'C:\Users\Experiment\Documents\MATLAB\Calibrations\';
        RigInfo.WaveInfo.DAQAdaptor = 'ni'; %4/5/20
        RigInfo.WaveInfo.DAQString = 'Dev3';%27/1/26 'Dev2'; %24/10/24
        RigInfo.WaveInfo.FrameSyncChannel = 'port1/line7';%27/1/26 'port0/line7'; %4/5/20
        RigInfo.zpepComputerIP = '130.194.196.61';%28/10/24
        RigInfo.zpepComputerName = 'MU00189260';%28/10/24
        RigInfo.ColorChannels2Use = [0 1 1]; %27/1/26
        RigInfo.SyncSquare.Size = 110; %25/2/26
       
        RigInfo.SyncSquare.Position = 'SouthEast';%17/9/20 
        RigInfo.SyncSquare.Type = 'flicker';
        RigInfo.SyncSquare.Angle = 0;%50;%[deg] %%7/2/21
        %RigInfo.BackgroundColor = [0 0 0];    %5/4/20 make sure syncsquare is black before exp
        
        %start waveOutput when receiving input on this port when
        %waveStim.TriggerType = HwDigital. see prepareSessionForStimuli
        RigInfo.WaveInfo.ExtTriggerChannel = 'PFI4';%27/1/26 'PFI0'; %25/9/20
        RigInfo.WaveInfo.TriggerCondition = 'RisingEdge';
        RigInfo.WaveInfo.SampleRate = 5000;%1000;%NG >5000 in NI-USB60001
        
        %     %Analog output channel to use for each row in the WaveStim
        RigInfo.WaveInfo.WaveStimChannel = 0:1;

    case 'MU00188743' %for 2pF
        RigInfo.VsDisplayScreen = 2;
        RigInfo.VsDisplayAdaptor = 'Nvidia Quadro P620';
        RigInfo.MonitorType = 'Apple Ipad';
        RigInfo.MonitorSize = 14.744; %20; % cm - short side 
        RigInfo.DefaultMonitorDistance = 8.5; %cm fixed 28/10/19
        RigInfo.Geometry = 'Circular'; % 'Flat' or 'Circular'
        RigInfo.HorizontalSpan = 164.8; % degrees of the overall (two-sided) span
        %RigInfo.Xmax
        RigInfo.VsHostCalibrationDir = 'C:\Users\Experiment\Documents\MATLAB\Calibrations\';
        %RigInfo.WaveInfo.FrameSyncChannel = [];
        RigInfo.zpepComputerIP = '130.194.192.189';%19/7/19
        RigInfo.zpepComputerName = 'MU00189074';%28/6/19
      
        RigInfo.SyncSquare.Type = 'Steady';%17/1/20 'flicker';
        RigInfo.SyncSquare.Size = 130;
        RigInfo.SyncSquare.Position = 'NorthEast';
        RigInfo.ColorChannels2Use = [0 0 1]; %31/7/19
    
        RigInfo.WaveInfo.DAQAdaptor = 'ni'; %28/10/19
        RigInfo.WaveInfo.DAQString = 'Dev1'; %28/10/19
        
        %digital output that echos the sync square state 28/10/19
        RigInfo.WaveInfo.FrameSyncChannel = 'port0/line0';
        
        %start waveOutput when receiving input on this port when
        %waveStim.TriggerType = HwDigital. see prepareSessionForStimuli
        RigInfo.WaveInfo.ExtTriggerChannel = 'PFI12';
        RigInfo.WaveInfo.TriggerCondition = 'RisingEdge';
%         RigInfo.WaveInfo.SampleRate = 5000;%
        
        %     %Analog output channel to use for each row in the WaveStim
        RigInfo.WaveInfo.WaveStimChannel = 0:3;

    otherwise
        error('I do not know this host -- amend RigInfoGet');
end

