function pahandle = prepareSoundcardforStimuli(stimuli)

waveSoundcard = stimuli.WaveSoundcard;
if ndims(waveSoundcard)<2 || size(waveSoundcard,1)==1 || size(waveSoundcard,2)==1	 
    waveSoundcard = waveSoundcard(:)';
	waveSoundcard = [waveSoundcard; waveSoundcard];
end
pahandle = PsychPortAudio('Open', [], [], 0, [], 2);
PsychPortAudio('FillBuffer', pahandle, waveSoundcard);