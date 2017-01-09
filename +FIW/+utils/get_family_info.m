function info = get_family_info(fpath)
%% Read FID file and parse into struct
ind = 22;
contents = myToolbox.i_o.csv2cell(fpath,'fromfile');


info.fid = fpath(end - 8:end-4);
if size(contents,2) == 44
    ind = 40;
end
info.nmembers = find(strcmp(contents(:,ind),'-1'),1,'first') - 2;
% lowercase to avoid case sensitivity
info.name = lower(contents(2:info.nmembers+1,ind));

info.gender = contents(2:info.nmembers+1,ind+1);
% add 'm' for male and 'f' for female
info.gender = lower(cellfun(@(x) x (1),info.gender,'uni',false));
info.rel = contents(2:info.nmembers+1,2:info.nmembers+1);
info.mid = contents(2:info.nmembers+1,1);


end

