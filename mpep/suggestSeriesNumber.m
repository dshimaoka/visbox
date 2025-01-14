function expDateSeries = suggestSeriesNumber(animal)
% SUGGESTSERIESNUMBER Given an animal suggest a series number for it as a string.
% Will suggest the highest series number that exists if there are any,
% otherwise it suggets 1.
% 30/3/20 DS added series suffix number

% dirs = Paths();
% dataDir = dirs.data;
% num = maxNumberInDir(fullfile(dataDir, animal));
% if num == 0
%     num = 1;
% end
% end

prefix = datestr(now, 'yyyy-mm-dd'); %commented out 27/3/20

%dataDir = dirs.data;
%suffix = maxNumberInSeries(fullfile(dataDir, animal));
suffix = maxNumberInSeries(animal, prefix);
if suffix == 0
    suffix = 1;
end

expDateSeries = [prefix '_' num2str(suffix)];

end