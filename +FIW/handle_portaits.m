function FT = handle_portaits(FT, infos)
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
%   15-December-2016 -   Function created
%
%
nfaces = length(FT.ID);
sf_set = find([FT.Portrait]);
sf_pids = FT.PID(sf_set);
nsingles = length(sf_set);
cmeta = FT.Metadata(FT.Portrait==1);
mids = cell(nfaces,1);
mids2 = zeros(nsingles,1);
for y = 1:infos.nmembers
    indz = strcmp(cmeta,infos.name{y});
    if isempty(find(indz, 1)), continue; end
    pidz = sf_pids(indz);
    for z = 1:length(pidz)
        mids(strcmp(FT.PID,pidz{z})) =strcat('MID',infos.mid(y));
        mids2(strcmp(sf_pids,pidz{z}))  = str2double(infos.mid{y});
    end
end

FT.label = mids;

