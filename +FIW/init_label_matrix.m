function lab_vec = init_label_matrix(FT)
%%
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 6-December-2017
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : init_label_matrix.m
%
%   REVISIONS:
%   6-January-2017 -   Function created
%
%
nlabs = length(FT.fpath);
lab_vec = zeros(nlabs,1);

known = find(FT.Confidence);

labs = FT.label(known);

ilabs = str2num(str2mat(cellfun(@(x) x(4:end),labs,'uni',false)));

lab_vec(known) = ilabs;
