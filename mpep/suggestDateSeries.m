function [expDateSeries, expDate, expSeries] = suggestDateSeries(animal)
% suggestDateSeries(animal)
% Given an animal suggest a series number for it as a [yyyy-mm-dd_(suffix)] format.
% Will suggest the highest series number that exists if there are any,
% otherwise it suggets 1.
% 30/3/20 DS added series suffix number

expDate = datestr(now, 'yyyy-mm-dd'); 

try
    expSeries = maxNumberInSeries(animal, expDate);
catch err
    expSeries = 1;
end

if isempty(expSeries)
    expSeries = 1;
end

expDateSeries = [expDate '_' num2str(expSeries)];

end