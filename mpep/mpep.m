function  mpep()

% Mpep updated 2016-06-23 by N. Steinmetz to conform to lab standards for
% mouse names and experiment organization. In this version, "series" is
% always a string with the date in yyyy-mm-dd format, like '2016-06-23'.
% It's not going to work if you set it to be a number (because the dat
% package, now used to select experiments, requires this new format).
% However, this version of mpep does keep backwards compatibility of output
% files - everything that was formerly written to /trodes and to the log
% file still is. 

global mpepFigure;
% Run mpep
setupPaths();
[s d] = matlabui.showHostsDialog();
% user canceled hosts dialog
if ~isempty(s)
    mpepFigure = matlabui.MainFigure(s,d);
end

