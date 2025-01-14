classdef Calibration
    %CALIBRATION object that contains the information on screen calibration
    %   Methods:
    %       Save
    %       Plot
    %       Load [calls PsychToolbox function Screen('LoadNormalizedGammaTable')]
    %       Make
    %       Check
    %
    % Part of the Stimulus toolbox
    %     MK - to calibrate connect the photodiode to AI0 and P0.0 to AI1
    
    properties  
        date            % Date of calibration (e.g. '14-Mar-2011')
        MonitorType     % Type of monitor (e.g. 'HANNS-G HA-191')
        FrameRate       % Refresh rate in Hz
        Directory       % The directory where the calibration is stored (e.g. 'C:\Calibrations\')
        monitorGamInv   % A matrix 256 x 3
        DelayTime       % The delay in ms between digital output and screen display
    end
    
    properties (Hidden)
        xx                  
        yyy                 
        monitorGam    
    end
    
    methods
        
        function Save(C)
            % save the calibration structure
            
            filename = [C.MonitorType , '_', C.date , '.mat'];
            filename(findstr(filename,' ')) = '_';
            filePathname = fullfile(C.Directory, filename);
            
            if ~exist(C.Directory, 'dir')
                mkdir(C.Directory);
            end
            
            if ~exist(filePathname, 'file'),
                save(filePathname, 'C');
            else
                prompt = sprintf('Filename %s exists already, please give different name or confirm', filename);
                answer = inputdlg(prompt, '', 1, {filename});
                if isempty(answer),
                    fprintf('Saving cancelled!.\n');
                else
                    filePathname = fullfile(C.Directory, answer{1});
                    save(filePathname, 'C');
                end
            end
            
            fprintf('Saved file %s\n',filePathname);
        end % function Save
    
        function Plot(C)
            % shows the calibration graphs

            figure; clf
            
            rr = C.yyy(1,:);
            gg = C.yyy(2,:);
            bb = C.yyy(3,:);
            
            % Normalize to the max and min for r g and b
            rr = (rr - min(rr)) / (max(rr) - min(rr));
            gg = (gg - min(gg)) / (max(gg) - min(gg));
            bb = (bb - min(bb)) / (max(bb) - min(bb));
            
            subplot(1,2,1)
            % plot interpolated functions
            plot(0:255,C.monitorGam(:,1),'r'); hold on
            plot(0:255,C.monitorGam(:,2),'g')
            plot(0:255,C.monitorGam(:,3),'b')
            plot(C.xx,rr,'ro')
            plot(C.xx,gg,'go')
            plot(C.xx,bb,'bo')
            set(gca,'XLim',[0 255])
            set(gca,'YLim',[0 1])
            xlabel('gun values')
            ylabel('normalized luminance')
            title('Data and fits')
            
            subplot(1,2,2)
            plot(0:255,C.monitorGamInv(:,1),'r'); hold on
            plot(0:255,C.monitorGamInv(:,2),'g')
            plot(0:255,C.monitorGamInv(:,3),'b')
            hold off
            set(gca,'XLim',[0 255])
            set(gca,'YLim',[0 255])
            xlabel('Desired relative output')
            ylabel('Required relative voltage')
            title('Inverse gamma');
            
        end % function Plot
        
    end
    
    methods (Static)
        
        function C = New(myScreenInfo,xx,yyy,delay)
            % Creates a new Calibration structure
            %
            % C = New(myScreenInfo, xx, yyy) where xx is 1 X 9 and
            % yyy is 3 X n (for r, g, and b).
            %
            % C = New(myScreenInfo, xx, yyy, delay) lets you specify
            % a delay in ms (between digital signal and monitor intensity)
            %
            % C = New(myScreenInfo) creates a  new calibration
            % structure with fake monitorGam (as if the monitor was already linear).
            %
            % Call CalibrationMake to calibrate.
            %
            % 2011-02 Matteo Carandini extracted from ltCalibrateMonitor
            
            if nargin < 4
                delay = NaN;
            end
            
            if nargin < 2
                xx = [];
                yyy = [];
            end
            
            if nargin < 1
                error('Need at least one argument');
            end
            
            C = Calibration;
            C.MonitorType = myScreenInfo.MonitorType;
            C.FrameRate   = myScreenInfo.FrameRate;
            C.Directory   = myScreenInfo.Calibration.Directory;
            
            %  choose step value (something that goes into 256 evenly)
            %  stepsize = 32; % usually 16; %32;
            %  xx = [0, stepsize-1:stepsize:255];
            %  yyy = repmat(xx,[3,1]);
            
            if isempty(xx)
                return;
            end
            
            today = datestr(now);
            today = today(1:11);
            C.date        = today;
            
            C.xx          = xx;
            C.yyy         = yyy;
            C.DelayTime   = delay;
            
            %% interpolate to obtain monitorGam
            
            rr = yyy(1,:);
            gg = yyy(2,:);
            bb = yyy(3,:);
            
            % Normalize to the max and min for r g and b
            rr = (rr - min(rr)) / (max(rr) - min(rr));
            gg = (gg - min(gg)) / (max(gg) - min(gg));
            bb = (bb - min(bb)) / (max(bb) - min(bb));
            
            C.monitorGam=zeros(256,3);
            C.monitorGam(:,1)=interp1(xx,rr,0:255)';
            C.monitorGam(:,2)=interp1(xx,gg,0:255)';
            C.monitorGam(:,3)=interp1(xx,bb,0:255)';
            
            %% calculate inverse gamma table
            
            nguns = size(C.monitorGam,2);
            numEntries = 2^myScreenInfo.PixelDepth;
            
            C.monitorGamInv = zeros(numEntries,nguns);
            %  Check for monotonicity, and fix if not monotone
            %
            for igun=1:nguns
                
                thisTable = C.monitorGam(:,igun);
                
                % Find the locations where this table is not monotonic
                %
                list = find(diff(thisTable) <= 0, 1);
                
                if ~isempty(list)
                    announce = sprintf('Gamma table %d NOT MONOTONIC.  We are adjusting.',igun);
                    disp(announce)
                    
                    % We assume that the non-monotonic points only differ due to noise
                    % and so we can resort them without any consequences
                    %
                    thisTable = sort(thisTable);
                    
                    % Find the sorted locations that are actually increasing.
                    % In a sequence of [ 1 1 2 ] the diff operation returns the location 2
                    %
                    % posLocs is positions of values with positive derivative
                    posLocs = find(diff(thisTable) > 0);
                    
                    % We now shift these up and add in the first location
                    %
                    posLocs = [1; (posLocs + 1)];
                    % monTable is values in original vector with positive derivatives
                    monTable = thisTable(posLocs,:);
                    
                else
                    
                    % If we were monotonic, then yea!
                    monTable = thisTable;
                    posLocs = 1:size(thisTable,1);
                end
                
                % nrow = size(monTable,1);
                
                % Interpolate the monotone table out to the proper size
                % 092697 jbd added a ' before the ;
                C.monitorGamInv(:,igun) = ...
                    interp1(monTable,posLocs-1,(0:(numEntries-1))/(numEntries-1))';
                
            end
            if any(isnan(C.monitorGamInv)),
                msgbox('Warning: NaNs in inverse gamma table -- may need to recalibrate.');
            end
            
        end % function New
        
        function C = Load(myScreenInfo)
           
            %% AS added as it keeps crashing without 2012-08
            if nargin < 1
                RigInfo = RigInfoGet;
                myScreenInfo = ScreenInfo(RigInfo);
                if isempty(RigInfo.WaveInfo.DAQString)
                    error('Cannot autocalibrate because there is no DAQ hardware');
                end
            end
            
            CalibrationDir = myScreenInfo.Calibration.Directory; %store it, as it will be overwritten
            
            dd = dir( fullfile(CalibrationDir,'*.mat'));
            ncals = length(dd);
            
            if ncals==0
                error('There are no calibration files. Run Calibration.Make');
            end
            
            dates = zeros(ncals,1); % added by MC on 2009-09
            for ical = 1:ncals
                dates(ical) = datenum(dd(ical).date);
            end
            
            % find the most recent file
            [~,ifile] = max(dates);
            
            C = Calibration; % just to pacify the syntax checker
            
            % load the calibration data
            data = load( fullfile(CalibrationDir,dd(ifile).name) );
            
            %if C is not a an object of Class 'Calibration' import manually
            %from the old Calibration structure
            if isfield(data,'C') && isa(data.C,'Calibration')
                C = data.C;
            elseif isfield(data,'Calibration')
                C.date = data.Calibration.date;
                C.MonitorType = data.Calibration.ScreenInfo.MonitorType;
                C.FrameRate = data.Calibration.ScreenInfo.FrameRate;
                C.Directory = data.Calibration.ScreenInfo.CalibrationDir;
                C.monitorGamInv = data.Calibration.monitorGamInv;
                %C.DelayTime = 0; % defaults to zero anyway
            else
                error('There are no valid Calibrations in myScreenInfo.Calibration.Directory. Calibration must be object or struct');
            end
            
            if strcmp(myScreenInfo.MonitorType,C.MonitorType) && ...
                    abs(myScreenInfo.FrameRate-C.FrameRate)<0.1
                fprintf('Loading and applying calibration done on %s\n',C.date);
            else
                warning(...
                    'Latest calibration was done on %s\n for a %s monitor running at %3.1f Hz\nRERUN Calibration.Make and Calibration.Check', ...
                    C.date, C.MonitorType, C.FrameRate); %#ok<WNTAG>
            end
            
            if any(isnan(C.monitorGamInv))
                error('Ouch! There are NaNs in inverse gamma function!')
            end
            
            GammaTable = C.monitorGamInv / 255;	% corrected to have linear luminance
            Screen('LoadNormalizedGammaTable', myScreenInfo.windowPtr, GammaTable);
            
        end % function Load
        
        function C = Make(myScreenInfo)
            % Creates a calibration file automatically using the light meter
            
            if nargin < 1
                RigInfo = RigInfoGet;
                myScreenInfo = ScreenInfo(RigInfo);
                if isempty(RigInfo.WaveInfo.DAQString)
                    error('Cannot autocalibrate because there is no DAQ hardware');
                end
                CloseAtTheEnd = true;
            else
                CloseAtTheEnd = false;
            end
            
            steps = round(linspace(0,255,17)); % 17 steps            
            nsteps = length(steps);
            testColors = zeros(nsteps*3,3);           
            iStim = 0;
            for igun = 1:3 % 1,2,3 for r,g,b
                for istep = 1:nsteps
                    iStim = iStim+1;
                    testColors(iStim,:) = [0 0 0];
                    testColors(iStim,igun) = steps(istep);
                end
            end
            
            switch computer
                case 'PCWIN64'
                    [Measured,Digital,SampleRate] = Acquire64(myScreenInfo,testColors,CloseAtTheEnd);
                otherwise
                    [Measured,Digital,SampleRate] = Acquire32(myScreenInfo,testColors,CloseAtTheEnd);
            end
            
            %% assess the delay between digital and analog
            
            [xc, lags ] = xcorr(Measured,Digital,1000,'coeff');
            % figure; plot(lags,xc)
            [~,imax] = max(xc);
            ishift = lags(imax);
            delay = 1000*ishift/SampleRate; % in ms
            fprintf('Digital is ahead of screen by %2.2f ms\n',delay);
            
            % correct the data
            Digital = circshift(Digital,[ishift,0]);
            
            %% plot the data
            
            ns = length(Measured);
            tt = (1:ns)/SampleRate;
            
            figure(1); plot(tt,Digital);
            xlabel('Time (s)');
            ylabel('Digital output from port1/line0 measured at Ai1');
            
            UpCrossings = find(diff( Digital > 1 ) ==  1);
            DnCrossings = find(diff( Digital > 1 ) == -1);

            figure(2); clf
            for iC = 1:length(UpCrossings)
                plot(tt(UpCrossings(iC))*[1 1],[0 5],'-', ...
                    'color', 0.8*[1 1 1] ); hold on
            end
            plot( tt, Measured ); hold on
            xlabel('Time (s)');
            ylabel('Signal (Volts) from screen measured at Ai0');
            set(gca,'ylim',[0 1.1*max(Measured)]);
            title(sprintf('In this plot. digital has been delayed by %2.2f ms', delay));
            
            %% interpret the results
            
            nsteps = length(steps); % length(UpCrossings)/3;
                        
            vv = zeros(3,nsteps);
            istim = 0;
            for igun = 1:3 % 1,2,3 for r,g,b
                for istep = 1:nsteps
                    istim = istim+1;
                    vv(igun,istep) = ...
                        mean( Measured(UpCrossings(istim):DnCrossings(istim)) );
                end
            end

            %% put all this into a Calibration file and compute inverse gamma table
            
            C = Calibration.New(myScreenInfo, steps, vv, delay);
            
            %% Plot calibration data
            
            C.Plot;
            
            %% save the calibration structure
            
            C.Save;
            
        end % function Make
        
        function [vv, steps] = Check(myScreenInfo)

                       
            if nargin < 1
                RigInfo = RigInfoGet;
                myScreenInfo = ScreenInfo(RigInfo);
                % % AS (2015-06) added next line
                myScreenInfo.CalibrationLoad;
                if isempty(RigInfo.WaveInfo.DAQString)
                    error('Cannot autocalibrate because there is no DAQ hardware');
                end
                CloseAtTheEnd = true;
            else
                CloseAtTheEnd = false;
            end
            
            steps = round(linspace(0,255,17)); % 17 steps            
            nsteps = length(steps);
            testColors = zeros(nsteps,3);           
            iStim = 0;
            for istep = 1:nsteps
                iStim = iStim+1;
                testColors(iStim,:) = repmat(steps(istep), 1, 3);
            end
            
            switch computer
                case 'PCWIN64'
                    [Measured,Digital,SampleRate] = Acquire64(myScreenInfo,testColors,CloseAtTheEnd);
                otherwise
                    [Measured,Digital,SampleRate] = Acquire32(myScreenInfo,testColors,CloseAtTheEnd);
            end
            
            %% assess the delay between digital and analog
            
            [xc, lags ] = xcorr(Measured,Digital,1000,'coeff');
            % figure; plot(lags,xc)
            [~,imax] = max(xc);
            ishift = lags(imax);
            delay = 1000*ishift/SampleRate; % in ms
            fprintf('Digital is ahead of screen by %2.2f ms\n',delay);
            
            % correct the data
            Digital = circshift(Digital,[ishift,0]);
            
            %% plot the data
            
            ns = length(Measured);
            tt = (1:ns)/SampleRate;
            
            UpCrossings = find(diff( Digital > 1 ) ==  1);
            DnCrossings = find(diff( Digital > 1 ) == -1);

            MaxVal = 1.1*max(Measured);
            figure; clf
            for iC = 1:length(UpCrossings)
                plot(tt(UpCrossings(iC))*[1 1],[0 MaxVal],'-', ...
                    'color', 0.8*[1 1 1] ); hold on
            end
            plot( tt, Measured ); hold on
            xlabel('Time (s)');
            ylabel('Signal (Volts)');
            set(gca,'ylim',[0 MaxVal]);
            title(sprintf('In this plot. digital has been delayed by %2.2f ms', delay));

            %% interpret the results
            
            nsteps = length(steps); % length(UpCrossings)/3;
            
            vv = zeros(1,nsteps);
            istim = 0;
            for istep = 1:nsteps
                istim = istim+1;
                vv(istep) = ...
                    mean( Measured(UpCrossings(istim):DnCrossings(istim)) );
            end
            
            
            %% Graphics
            
            figure;
            plot(steps,vv,'ko')
            Y1 = interp1(steps,vv,0:255,'linear');
            hold on;
            plot(0:255,Y1,'k-');
            set(gca,'XLim',[0 255],'ylim',[0 inf])
            xlabel('gun values')
            ylabel('measured grayscale luminance')
            title('Linearity check')
            
        end % function Check
        
    end
 
end

