function expSeries = maxNumberInSeries(subject, expDate)
%expSeries = maxNumberInSeries(subject, expDate)
%MAXNUMBERINSERIES Looks into a directory and for all files/dirs with numbers
% as names return the maximum (rounded to integer). If no numbers found or
% directory does not exist returns 0.
% 30/3/20 DS created from maxNumberInDir

% retrieve list of experiments for subject
[~, dateList, seriesList, seqList] = dat.listExps(subject);

% filter the list by expdate
% expDate = floor(expDate); 
% filterIdx = dateList == expDate; 

if ischar(expDate)
    expDate = datenum(expDate, 'yyyy-mm-dd');
end

expDate = floor(expDate); 
filterIdx_prefix = find(dateList == expDate); 
expSeries = max(seriesList(filterIdx_prefix));

end

