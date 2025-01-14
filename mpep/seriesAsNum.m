function Num = seriesAsNum(series)
Num = str2num([datestr(datenum(series(1:10), 'yyyy-mm-dd'),'yyyymmdd') series(12:end)]); %31/3/20
end