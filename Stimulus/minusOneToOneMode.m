function prevInMode = minusOneToOneMode(screenInfo, enable)
%MINUSONETOONEMODE Set whether to use "minus one to one" drawing mode
%   prevInMode = MINUSONETOONEMODE(screenInfo, [enable]) if 'enable' is true, 
%   use a graphics blending trick on the screen specified by 'screenInfo'
%   such that luminance values range from minus one (black) to one (white).
%   Otherwise use default, zero to one. Returns the original mode, whether or
%   not a new one is set.

if nargin > 1
  if enable
    [srcFactor, dstFactor] = Screen('BlendFunction', screenInfo.windowPtr, GL_SRC_ALPHA, GL_ONE);
  else
    [srcFactor, dstFactor] = Screen('BlendFunction', screenInfo.windowPtr, GL_ONE, GL_ZERO);
  end
else
  [srcFactor, dstFactor] = Screen('BlendFunction', screenInfo.windowPtr);
end

prevInMode = strcmp(srcFactor, 'GL_SRC_ALPHA') && strcmp(dstFactor, 'GL_ONE');

end

