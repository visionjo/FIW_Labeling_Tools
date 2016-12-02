
rdir = '~/Dropbox/Families_In_The_Wild/Ann/FW_FIDs/';
d1 = dir([rdir 'F*.csv']);
fpaths = strcat(rdir,{d1.name})'
obin = 'info/family_info/';
obins = strrep(strcat(obin,{d1.name}),'.csv','.mat');
npaths= length(fpaths);
for x = 1:npaths
    contents = myToolbox.i_o.csv2cell(fpaths{x},'fromfile');
    [a,b]=find(strcmp(contents,'Gender'));
    tmp = contents(:,b);
    ind = find(strcmp(tmp,'-1'),1,'first')-1;
    tab.MID = contents(2:ind,1);
    tab.Names = contents(2:ind,b-1);
    tab.Gender = contents(2:ind,b);
     
    rel_matrix = contents(2:ind,2:ind);
    
    save(obins{x},'tab','rel_matrix')
    
end