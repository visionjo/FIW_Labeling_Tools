function FT = prepare_fid_table(imdir, fid, meta, pids)
%%
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

iset = imageSet(strcat(imdir,fid,'/'),'recursive');
nfaces = sum([iset.Count]);
ID = zeros(nfaces,1);   indx = 1;
cPIDs = cell(nfaces,1);
fid_meta = cell(nfaces,1);
single_face = zeros(nfaces,1);
indt = 1;

for y = 1:length(iset)
    %% get relative face-to-pic indices
    uplimit = indx + iset(y).Count - 1;
    indz = indx:uplimit;
    ID(indz) = y;
    indx = uplimit + 1;
    
    pid_ids = find(strcmp(pids,iset(y).Description));
    for z = 1:iset(y).Count
        cPIDs{indt} = iset(y).Description;
        fid_meta{indt} = meta{pid_ids};
        single_face(indt) = iset(y).Count;
        indt = indt + 1;
    end
    
end
single_face(single_face ~= 1) = 0;

FT = table(transpose(1:nfaces),...
    ID,...
    cell(nfaces,1), ...%     zeros(nfaces,1), ...
    zeros(nfaces,1), ...
    single_face,...
    cPIDs,...
    fid_meta,...
    [iset.ImageLocation]',... image paths
    strrep(strrep([iset.ImageLocation]','faces','features'),'.jpg','.mat'), ... feature paths
    'VariableNames',{'FaceID' 'ID' 'label' 'Confidence' 'Portrait' 'PID' 'Metadata' 'ipath' 'fpath'});

FT.label = repmat(string(''),length(FT.label),1);
