function shuffled = smooth_shuffle(unshuffled,winsize)

% USAGE: shuffled = smooth_shuffle(unshuffled,winsize)
%
% Smoothly shuffles a vector.  Ensures that every value is present
% in a sliding window of size winsize.
%
% If winsize is not supplied, defaults to twice the number of
% unique elements in unshuffled input.
%
% If winsize is less than 1.5x the number of unique elements, will
% override the input with 1.5x the number of unique elements.

% v1.0 John Schlerf, August 2010

uniqueItems = unique(unshuffled);

min_winsize = 1.5*length(uniqueItems);
if ~exist('winsize','var')
    winsize = 2*length(uniqueItems);
elseif winsize < min_winsize
    disp('Input window size is too small... overriding');
    winsize = min_winsize;
end

% Shuffle.
shuffled = unshuffled(randperm(length(unshuffled)));

if winsize > length(shuffled)
    return;
else
    % make sure the result is "smooth"...
    indexmat = repmat(1:winsize,length(shuffled)+1-winsize,1) + ...
        repmat([0:length(shuffled)-winsize]',1,winsize);
    while any(~ismember(shuffled(indexmat),uniqueItems))
        shuffled = unshuffled(randperm(length(shuffled)));
    end
end
