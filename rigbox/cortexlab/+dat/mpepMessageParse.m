function info = mpepMessageParse(str)
%DAT.MPEPMESSAGEPARSE Extract experiment info from an MPEP UDP message
%   Detailed explanation goes here
%
% Part of Cortex Lab Rigbox customisations

% 2014-01 CB created

% take first 'word' to be the instruction
instruction = first(regexp(str, '\w+', 'match'));
switch lower(instruction)
  case 'infosave'
%     rexp = '^(?<instruction>infosave) (?<subject>\w+)_(?<series>\d{1,8})_(?<exp>[0-9]+)$';
    rexp = '^(?<instruction>infosave) (?<subject>\w+)_(?<series>\d+)_(?<exp>[0-9]+)$';%1/4/20
  case 'hello'
    rexp = '^(?<instruction>\w+)';
  otherwise
    % handle everything but 'infosave' instruction
    rexp = ['^(?<instruction>\w+)\s+(?<subject>\w+)\s+(?<series>\-?\w+)\s+(?<exp>\-?\w+)',...
      '\s*(?<block>\-?\w*)\s*(?<stim>\-?\w*)\s*(?<duration>\-?\w*)'];
end

emptyInfo = struct('instruction', '',...
  'subject', '',...
  'series', '',...
  'exp', '',...
  'block', '',...
  'duration', '');
parsed = regexp(str, rexp, 'names');
if isempty(parsed)
  error('Mpep message ''%s'' is not valid', str);
end
info = mergeStructs(parsed, emptyInfo);

%if length(info.series) == 8
  % assume mpep 'series' contains the digits of date format yyyymmdd
%   info.series = datestr(datenum(info.series, 'yyyymmdd'), 'yyyy-mm-dd');
if ~isempty(info.series)
  info.series = [datestr(datenum(info.series(1:8), 'yyyymmdd'), 'yyyy-mm-dd') '_' info.series(9:end)];%1/4/20
end

if ~isempty(info.exp)
  info.expRef = dat.constructExpRef(info.subject, info.series(1:10), info.series(12:end), str2double(info.exp));
else
  info.expRef = [];
end

end

