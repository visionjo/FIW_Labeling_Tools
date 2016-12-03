function [names_lut, new_names] = create_names_lut(infos, allnames)
%%
% Function to determine different permutations of the same name.
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 1-December-2016
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : prepare_fid_table.m
%
%   REVISIONS:
%   2-December-2016 -   Function created
%
%

new_mids = ones(length(allnames),1);
names_lut = [];
for y = 1:infos.nmembers
    names_lut(y).list{1} = infos.name{y};
    
    % determine whether or not last name is included in name listing
    tmp_ids = strfind(infos.name{y},infos.surname);
    if isempty(tmp_ids)
        % doesnt include last name
        names_lut(y).list{2} = [infos.name{y} ' ' infos.surname];
        tmp_ids = find(strcmp(allnames,names_lut(y).list{2}));
        if ~isempty(tmp_ids)
            new_mids(tmp_ids) = 0;
        end
    else
        % name listing includes lastname; therefore, add instance
        % without it
        names_lut(y).list{2} = strtok(infos.name{y});
        tmp_ids = find(strcmp(allnames,names_lut(y).list{2}));
        if ~isempty(tmp_ids)
            new_mids(tmp_ids) = 0;
        end
    end
    
    
    tmp_ids = find(strcmp(infos.name(y),allnames));
    if ~isempty(tmp_ids), new_mids(tmp_ids) = 0; end

end
new_names = allnames(new_mids==1);
