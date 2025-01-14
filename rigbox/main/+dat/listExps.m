function [expRef, expDate, expSeries, expSequence] = listExps(subjects)
%DAT.LISTEXPS Lists experiments for given subject(s)
%   [ref, date, seq] = DAT.LISTEXPS(subject) Lists experiment for given
%   subject(s) in date, then sequence number order.
%
% Part of Rigbox

% 2013-03 CB created
% 2020-03 DS added expSeries output (3rd)

% The master 'expInfo' repository is the reference for the existence of
% experiments, as given by the folder structure
expInfoPath = dat.reposPath('expInfo', 'master');

  function [expRef, expDate, expSeries, expSeq] = subjectExps(subject)
    % finds experiments for individual subjects
    % experiment dates correpsond to date formated folders in subject's
    % folder
    % expDate is number converted via datenum
    subjectPath = fullfile(expInfoPath, subject);
    subjectDirs = file.list(subjectPath, 'dirs');
    dateRegExp = '^(?<year>\d\d\d\d)\-?(?<month>\d\d)\-?(?<day>\d\d)_(?<seq>\d+)$';%30/3/20
    dateMatch = regexp(subjectDirs, dateRegExp, 'names');
    dateStrs = subjectDirs(~emptyElems(dateMatch));
    [expDate, expSeries, expSeq] = mapToCell(@(d) expsForDate(subjectPath, d), dateStrs);
    expDate = cat(1, expDate{:});
    expSeries = cat(1, expSeries{:});
    expSeq = cat(1, expSeq{:});
    expRef = dat.constructExpRef(repmat({subject}, [size(expDate,1) 1]), expDate, expSeries, expSeq);
    %sort them by date first then sequence number
%    [~,  isorted] = sort(cellsprintf('%.0d-%03i', expDate, expSeq)); %30/3/20
    [~,  isorted] = sort(cellsprintf('%.0d-%03i-%03i', expDate, expSeries, expSeq));
    expRef = expRef(isorted);
    expDate = expDate(isorted);
    expSeries = expSeries(isorted);
    expSeq = expSeq(isorted);
    
    %expDateSeries = arrayfun(@(x,y)[num2str(x) '_' num2str(y)], expDate, expSeries, 'UniformOutput', false); %31/3/20
  end

  function [dates, series, seqs] = expsForDate(subjectPath, dateStr)
      %[dates, seqs] = expsForDate(subjectPath, dateStr)
      %dates is number converted via datenum
      
    dateDirs = file.list(fullfile(subjectPath, dateStr), 'dirs');
    seqMatch = cell2mat(regexp(dateDirs, '(?<seq>\d+)', 'names'));
    if numel(seqMatch) > 0
      seqs = str2double({seqMatch.seq}');
    else
      seqs = [];
    end
    %if length(dateStr) > 8 %30/3/20
        dateFormat = 'yyyy-mm-dd';
    %else %30/3/20
    %    dateFormat = 'yyyymmdd'; %30/3/20
    %end %30/3/20
    dates = repmat(datenum(dateStr, dateFormat), size(seqs)); %30/3/20
    series = repmat(str2num(sprintf('%s',dateStr(12:end))), size(seqs)); %30/3/20
  end

if iscell(subjects)
  [expRef, expDate, expSeries, expSequence] = mapToCell(@subjectExps, subjects);
else
  [expRef, expDate, expSeries, expSequence] = subjectExps(subjects);
end

end

