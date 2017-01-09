function FT = handle_portaits(FT, infos, name_lut)
%%
% Determines whether PIDs with single face are portait images (i.e., clean
% label provided by metadata and with a single face allows for confident
% label through logical inference.
% 
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 1-December-2016
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : prepare_fid_table.m
%
%   REVISIONS:
%   1-December-2016 -   Function created
%%
%

nfaces = length(FT.ID);
sf_set = find([FT.Portrait]);
sf_pids = FT.PID(sf_set);
nsingles = length(sf_set);
cmeta = strtrim(FT.Metadata(FT.Portrait==1));
cmeta = clean_text(cmeta);
mids = cell(nfaces,1);
midsarray = zeros(nfaces,1);
mids2 = zeros(nsingles,1);
for j = 1:infos.nmembers
    %%for each member
    % This for-loop iterates over different family members
    names = name_lut(j).list;
    
    num_names = length(names);
    for y = 1:num_names
        %% for each name listing for jth member
        indz = strcmpi(cmeta,names{y});
        if isempty(find(indz, 1))
            continue; 
        end
        
        pidz = sf_pids(indz);
        for z = 1:length(pidz)
            mids(strcmp(FT.PID,pidz{z})) =strcat('MID',infos.mid(j));
            midsarray(strcmp(FT.PID,pidz{z})) = str2double(infos.mid{j});
            mids2(strcmp(sf_pids,pidz{z}))  = str2double(infos.mid{j});
        end
    end
end

FT.label = mids;
updated_ids = midsarray > 0;
FT.Confidence(updated_ids) = 1;

%% determine how many newly labeled faces thus far
ntags = length(find(updated_ids));



end
function cmeta = clean_text(cmeta)
cmeta = lower(cmeta);
cmeta = strrep(cmeta,'brother','');
cmeta = strrep(cmeta,'father','');
cmeta = strrep(cmeta,'mother','');
cmeta = strrep(cmeta,'dad','');
cmeta = strrep(cmeta,'mom','');
cmeta = strrep(cmeta,'sister','');
cmeta = strrep(cmeta,'wife','');
cmeta = strrep(cmeta,')','');
cmeta = strrep(cmeta,'(','');
cmeta = strrep(cmeta,'sibling','');
cmeta = strtrim(cmeta);
end

