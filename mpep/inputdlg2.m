function Answer=inputdlg2(Prompt, Title, NumLines, DefAns, Resize)
% Minimal reimplementation of inputdlg. The reason for this is so that we
% can press return to accept. Does not accept multiple questions. The
% argument list is arranged to be compatable with inputdlg, not elegant.


if nargin<1
  Prompt='Input:';
end
if ~iscell(Prompt)
  Prompt={Prompt};
end
NumQuest=numel(Prompt);

if nargin<2,
  Title=' ';
end

if nargin<3
  NumLines=1;
end


if nargin<4
  DefAns='';
else
    if(iscell(DefAns))
        DefAns = DefAns{1};
    end
end

if nargin<5
  Resize = 'off';
end
import javax.swing.*;
ans = JOptionPane.showInputDialog([],Prompt,Title, 3, [],[], DefAns);
if ~isempty(ans)
    Answer = {char(ans)};
else
    Answer = {};
end

