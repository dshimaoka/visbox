function num = maxNumberInDir(path)
%MAXNUMBERINDIR Looks into a directory and for all files/dirs with numbers
% as names return the maximum (rounded to integer). If no numbers found or
% directory does not exist returns 0.

list = dir(path);
dirNums = zeros(length(list),1);
for i = 1:length(list)
   dirNums(i) = str2double(list(i).name); %NaN if dirname not a number
end
dirNums = [dirNums; 0];
num = floor(max(dirNums));
end

