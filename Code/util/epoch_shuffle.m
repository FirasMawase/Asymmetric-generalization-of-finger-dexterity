function shuffled = epoch_shuffle(unshuffled,epochsize)

% USAGE: shuffled = epoch_shuffle(unshuffled,epochsize)
%
% Shuffles each epoch of a vector.  Ensures that every epoch is distinct.
%
% If epochsize is not supplied, defaults to the number of unique elements
% in unshuffled input.
%
% If epochsize is less than the number of unique elements, will
% override the input with the number of unique elements.

% v1.0 John Schlerf, August 2010

uniqueItems = unique(unshuffled);

min_epochsize = length(uniqueItems);
if ~exist('epochsize','var')
    epochsize = min_epochsize;
elseif epochsize < min_epochsize
    disp('Input epoch size is too small... overriding');
    epochsize = min_epochsize;
end

% For robustness of my intention with this code, first make sure that we're
% not dealing with sorted input:
% Firas Changed ##########################################################
% if length(uniqueItems) ~= length(unshuffled)
%     assert(~isequal(unshuffled,sort(unshuffled)));
% end

% Now shuffle each epoch:
shuffled = unshuffled;
allShuffled = [];
thisShuffled = [];
for ep = 1:ceil(length(unshuffled)/epochsize)
    thisEpoch = (ep-1)*epochsize+[1:epochsize];
    thisEpoch = thisEpoch(thisEpoch<=length(unshuffled));
    lastShuffled = thisShuffled;
    thisShuffled = unshuffled(thisEpoch(randperm(length(thisEpoch))));
    if ep > 1
        itemRepeat = shuffled(thisEpoch(1)-1) == thisShuffled(1);
    else
        itemRepeat = 0;
    end
    try
        assert(ismember(size(allShuffled,2),[0,length(thisShuffled)]));
    catch
        allShuffled = allShuffled(:,1:length(thisShuffled));
    end
    % This bit is inappropriate unless there are lots of targets:
    if factorial(epochsize) > length(unshuffled)
        while ~isempty(findrow(allShuffled,thisShuffled(:)')) | itemRepeat
            thisShuffled = unshuffled(thisEpoch(randperm(length(thisEpoch))));
            if ep > 1
                itemRepeat = shuffled(thisEpoch(1)-1) == thisShuffled(1);
            else
                itemRepeat = 0;
            end
        end
    % This is the bit that's more appropriate for small numbers of targets:
    elseif epochsize > 2
        % at the very least, don't repeat the trial-order two epochs in a
        % row?
        
        while isequal(thisShuffled,lastShuffled)
            thisShuffled = unshuffled(thisEpoch(randperm(length(thisEpoch))));
        end
    end
            
    allShuffled(end+1,:) = thisShuffled(:)';
    shuffled(thisEpoch) = thisShuffled;
end
if ~isequal(size(shuffled),size(unshuffled))
    shuffled = shuffled';
end

