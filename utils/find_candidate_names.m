function allnames = find_candidate_names(cmd, meta, tmp_bin)
%%
% Function to call JAVA (JAR) file to find all names in text file
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 2-December-2016
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : call_name_parser.m
%
%   REVISIONS:
%   2-December-2016 -   Function created
%
%


f_meta = strcat(tmp_bin,'portrait_meta.csv');
myToolbox.i_o.cell2csv(f_meta, meta);
f_names = strcat(tmp_bin,'fid_names.csv');

cmd = [cmd ' ' f_meta ' ' f_names];
system(cmd);

allnames = myToolbox.i_o.csv2cell(f_names, 'fromfile');
% remove empty elements of cell array 
allnames = allnames(cellfun(@isempty,allnames)==0);
% Reference family information to determine members whom are present in
% collection of unlabeled images.
allnames = unique(lower(strtrim(    allnames)));