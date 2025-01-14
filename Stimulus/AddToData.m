function AddToData(src,event)
    global AcquiredData
    n = length(event.TimeStamps);
    ii = AcquiredData.nSamples+(1:n);
    AcquiredData.TimeStamps(ii) = event.TimeStamps;
    AcquiredData.Data(ii,:) = event.Data;
    AcquiredData.nSamples = AcquiredData.nSamples + n;
end