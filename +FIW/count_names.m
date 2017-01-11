function [FT, Y] = count_names(FT, names_lut)
%%
% Counts the number of names found in name_lut struct in metadata. FT is
% updated accordingly.
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 10-January-2016
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : count_names.m
%
%   REVISIONS:
%   10-January-2016 -   Function created
%%
%

nnames = numel(names_lut);

g_onehot = zeros(1,length(FT.Metadata));
Y = zeros(nnames, length(FT.Metadata));
for y = 1:nnames
    
    cnames = names_lut(y).list;
    onehot = zeros(1,length(FT.Metadata));
    %    findstr(cnames{1},FT.Metadata)
    for r = 1:length(cnames)
        onehot(cellfun(@length,(strcat(cellfun(@(x) num2str(strfind(x,cnames{r})),lower(FT.Metadata),'uni',false),'.'))) > 1)=1;
    end
    
    g_onehot(onehot > 0) = g_onehot(onehot > 0)+1;
    Y(y, onehot > 0) = 1;
end
FT.NNames= g_onehot';