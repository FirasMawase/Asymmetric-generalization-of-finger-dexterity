function dsave(filename,D)
%  function dsave(filename,D)
%       writes out a Data structure as a tab-delimted worksheet
%       filename if empty, function will promt user for filename
%       D: data-struct
%           each field is a column
% v1.0: 2002 Berkeley
% v1.2: Speed up code (9/21/05)
%  Joern Diedrichsen (jdiedric@jhu.edu)
if nargin==1
    D=filename;
    filename='';
end;
if (~isstruct(D))
    if ischar(D)
        % make the syntax a little closer to Matlab's built in 'save'
        D = evalin('caller',D);
    end
    if ~isstruct(D)
        error('Cannot save matrix or empty structure');
    end
end;
if isempty(filename)
   [F,P]=uiputfile('*.*','Save Cell Array as');
   filename = [P,F];
end
fid=fopen(filename,'wt');
if (fid==-1)
    error(sprintf('Error opening file %s\n',filename));
end;
names=fieldnames(D);
linefeed=sprintf('\n');
tab=sprintf('\t');

% put in variable names
numvar=length(names);
for v=1:numvar
    fprintf(fid,'%s',names{v});
    if(v<numvar)
        fprintf(fid,'\t',linefeed);
    end;
    var_length(v)=size(getfield(D,names{v}),1);    
end;
fprintf(fid,'%s',linefeed);

% Check if all variables have the same length
if (any(var_length~=var_length(1)))
    error('dsave: all variables must have the same length');
end;
% now get out all the variables 
TEXT=[];
for v=1:numvar 
    var=getfield(D,names{v});
    if (iscell(var))
        TEXT=[TEXT char(var)];
    elseif isnumeric(var) || islogical(var)
        TEXT=[TEXT num2str(var)];
    elseif ischar(var) 
        TEXT=[TEXT var];
    else 
        error('variable types have to be cell, numeric or character');
    end;
    if (v<numvar)
        TEXT=[TEXT ones(var_length(1),1).*tab];
    end;
end;
for l=1:size(TEXT,1)
fprintf(fid,'%s\n',TEXT(l,:));
end;
fclose(fid);
