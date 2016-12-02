function info = get_family_info(fpath)
%% Read FID file and parse into struct
contents = myToolbox.i_o.csv2cell(fpath,'fromfile');
info.nmembers = find(strcmp(contents(:,22),'-1'),1,'first') - 2;
info.name = contents(2:info.nmembers+1,22);
info.gender = contents(2:info.nmembers+1,23);
info.rel = contents(2:info.nmembers+1,2:info.nmembers+1);
info.mid = contents(2:info.nmembers+1,1);


end

