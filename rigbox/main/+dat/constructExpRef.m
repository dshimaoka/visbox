function ref = constructExpRef(subjectRef, expDate, expSeries, expSequence)
%DAT.CONSTRUCTEXPREF Constructs an experiment reference string
%   ref = DAT.CONSTRUCTEXPREF(subject, dat, seq) constructs and returns a
%   standard format string reference, for the experiment using the 'subject',
%   the 'date' of the experiment (a MATLAB datenum), and the daily sequence
%   number of the experiment, 'seq' (must be an integer).
%
% Part of Rigbox

% 2013-03 CB created
% 2020-03 DS added expSeries input(3rd)

if ischar(expSeries) 
    expSeries = str2num(expSeries); %1/4/20
end
if ischar(expSequence)
    expSequence = str2num(expSequence); %1/4/20
end

% tabulate the args to get complete rows
% [subjectRef, expDate, expSequence, singleArgs] = ...
%   tabulateArgs(subjectRef, expDate,expSequence);
[subjectRef, expDatePrefix, expDateSuffix, expSequence, singleArgs] = ...
  tabulateArgs(subjectRef, expDate, expSeries, expSequence);

% Convert the experiment datenums to strings
%expDate = mapToCell(@(d) iff(ischar(d), d, @() datestr(d, 'yyyy-mm-dd')), expDate);
expDatePrefix = mapToCell(@(d) iff(ischar(d), d, @() datestr(d, 'yyyy-mm-dd')), expDatePrefix);


% Format the reference strings using elements from each property
%ref = cellsprintf('%s_%i_%s', expDate, expSequence, subjectRef);
ref = cellsprintf('%s_%i_%i_%s', expDatePrefix, expDateSuffix, expSequence, subjectRef);

if singleArgs
  % if non-cell inputs were supplied, make sure we don't return a cell
  ref = ref{1};
end

end

