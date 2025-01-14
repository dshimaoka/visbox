function [p, expRef] = expPath(varargin)
%DAT.EXPPATH Folder paths for files pertaining to designated experiment
%   [P, REF] = DAT.EXPPATH(ref, reposname, [reposlocation]) returns paths
%   for the experiment 'ref' at a particular repository 'reposname'.
%   Optionally specify 'reposlocation' to specify a specific repository's
%   location.
%
%   [P, REF] = DAT.EXPPATH(subject, date, seq, reposname, [reposlocation])
%   sames as the above, but returns paths for an experiment with a
%   specified 'subject', on a particular 'date', and numbered 'seq'.
%
% e.g. to get the paths for the 'expInfo' repository, for the first
% experiment of the day for 'SUBJECTA':
% 
% paths = DAT.EXPPATH('SUBJECTA', now, 1, 'expInfo');
%
% Part of Rigbox

% 2013-03 CB created

% take care of handling with/without 'reposlocation' arg
if nargin == 2 || nargin == 5 %nargin == 4 %31/3/20
  reposArgs = varargin(end);
  varargin = varargin(1:end - 1);
else
  reposArgs = varargin((end - 1):end);
  varargin = varargin(1:end - 2);
end

[reposArgs{1:end}] = tabulateArgs(reposArgs{:});
% get the paths for each repos arg
reposPaths = mapToCell(@dat.reposPath, reposArgs{:});

% tabulate the args to get complete rows
[varargin{1:end}, singleArgs] = tabulateArgs(varargin{:});

% if single repos info was passed, replicate to match ref cell size
if numel(reposPaths) < numel(varargin{1})
  reposPaths = repmat(reposPaths, size(varargin{1}));
end

if nargin == 2 || nargin == 3
  expRef = varargin{1};
  [subjectRef, expDate, expSeries, expSequence] = dat.parseExpRef(expRef);
elseif nargin == 5 || nargin == 6 %nargin == 4 || nargin == 5
  [subjectRef, expDate, expSeries, expSequence] = varargin{:};
  expRef = dat.constructExpRef(subjectRef, expDate, expSeries, expSequence);
else
  error('Incorrect number of arguments');
end


p = mapToCell(@pathfun, reposPaths, subjectRef, expDate, expSeries, expSequence);
if singleArgs
  % we were passed non-cell arguments so make sure we dont return cells
  p = p{1};
  expRef = expRef{1};
end

  function str = pathfun(p, subject, date, series, seq)
    if ~ischar(date)
      date = datestr(date, 'yyyy-mm-dd');
    end
    dateSeries = [date '_' num2str(series)]; %31/3/20
    str = file.mkPath(p, subject, dateSeries, sprintf('%i', seq));
  end

end