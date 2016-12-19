function main()
%% Description of system and components involved in semi-automatic data labeling for FIW.
% The purpose of this file is to abstract the workflow of semi-supervised
% labeling of family photos. In a nutshell, the program is founded on two
% streams (i.e., channels): (1) UNKNOWN data, which are unlabeled images,
% each contain a reference to the faces, FID, and metadata; (2) KNOWN data,
% knowledge about a particular family already a part of the FIW database,
% which may or may not exist (should, unless unlabeled image(s) is of a
% family new to FIW). If KNOWN, reference to the family tree, which may or
% may not include all members of UNKNOWN, along with names (hashed to MIDs)
% and facial samples are used to filter noisy metadata and compare face
% encodings, respectfully.--
%% Temporary directory for dumping intermediate results
% global tmp_bin  cmd_name_parser;
params = configs();
%% FID LUT
TFID = readtable(strcat(params.d_source_root,'FIW_FIDs.csv'));
%% Prepare UNKNOWN
% Fetch family information, if any
T = readtable(strcat(params.d_source_root,'PIDs_New_Master.csv'));
fids = unique(T.FIDs);
nfids = length(fids);



% fid_path = '/home/jrobby/Dropbox/Families_In_The_Wild/Ann/FW_FIDs/';
obin = strcat(params.d_source_root, 'unlabeled/FIDs/',fids,'/');
cellfun(@mkdir,obin)
fid_paths = strcat(params.fin_labs,fids,'.csv');
fam_info = cellfun(@exist,  fid_paths) > 0; % families with existing labels

% get featpaths for unlabeled faces
tt=dir([params.fin_unlabfeats '*/*/*.mat']);
tmp = strcat({tt.folder},'/'); tmp1 = {tt.name};
f_unlabfeats = strcat(tmp,tmp1)';
% imset = imageSet('data/New_PIDs/unlabeled/faces/','recursive');
% f_unlabfeats = strrep(strrep([imset.ImageLocation]','faces','features'),'.jpg','.mat');

sind = length(strcat(params.d_source_root, 'unlabeled/features/'));
unlabs_gt = cellfun(@(x) x(sind+1:sind+5), f_unlabfeats,'uni',false);

%% Prepare KNOWN
%% get featpaths for labeled faces
tt=dir([params.fin_labfeats '*/*/*.mat']);
tmp = strcat({tt.folder},'/'); tmp1 = {tt.name};
f_labfeats = strcat(tmp,tmp1)';


% tt=dir([fin_labfeats 'F*']);
% tmp = strcat(fin_labfeats,{tt.name},'/');
% f_labfeats = {};
% for x = 1:length(tmp)
%     tmp1 = dir([tmp{x} 'M*']);
%     tmp1 = strcat(tmp{x}, {tmp1.name},'/');
%
%     for y = 1:length(tmp1)
%         tmp2 = dir([tmp1{y} '*.mat']);
%         tmp2 = strcat(tmp1{y}, {tmp2.name});
%         f_labfeats{length(f_labfeats) + 1} = tmp2;
%     end
%
% end
% f_labfeats = [f_labfeats{:}]';

sind = length(strcat(params.d_source_root, 'labeled/features/'));
labs_gt = cellfun(@(x) x(sind+1:sind+5), f_labfeats,'uni',false);




for x = 37% 1:nfids
    %% For each family
    
    if fam_info(x)
        infos = FIW.utils.get_family_info(fid_paths{x});
    end
    
    fbin = strcat(params.imdir,fids{x},'/');
    inds = find(strcmp(T.FIDs,fids{x}));
    meta = T.METADATA(inds);
    pids = T.PIDs(inds);
    
    fid_listing = TFID.surnames{strcmp(TFID.FIDs,fids{x})};
    [tmp, check] = split(fid_listing,'.');
    if any(strcmpi(tmp,'royal'))
        
    end
    if isempty(check)
        fprintf(2, ...
            '\nError parsing surname: FID listing does not contain period as demiliter\n');
        infos.surname = lower(fid_listing);
        fprintf(2, ...
            'Assigning complete listing as surname:\t%s\n\n',surname);
    else
        infos.surname = lower(tmp{1});
    end
    %% prepare table containing PIDs, metadata, image path, label, and
    % whether or not a single face (i.e., Portait)
    FT = FIW.prepare_fid_table(params.imdir, fids{x}, meta, pids);
    nfaces = length(FT.ID);
    
    %% expand on prior knowledge
    % search all metadata for instances of names. Names not present in FIDs
    % are potential candidates for new family members
    allnames = find_candidate_names(params.cmd_name_parser, meta, params.tmp_bin);
    
    [names_lut, new_names] = FIW.create_names_lut( infos, allnames);
    
    %% first handle cases with single face (i.e., profile pics)
    FT = FIW.handle_portaits(FT, infos, names_lut);
    
    
    %% Model known members
    % First model existing MIDs as one-vs-rest SVMs
    % load face features
    fpaths_tr = f_labfeats(strcmp(labs_gt,fids{x}));
    feats = load_features(fpaths_tr);
    
    % train one-against-all models
    % Generate SVMs
    ind = strfind(fpaths_tr{1},'MID');
    labs_tr = cellfun(@fileparts,cellfun(@(x) x(ind:end),fpaths_tr ,'uni',false),'uni',false);
    
    model = FIW.model_mids(feats', labs_tr, params.svm);
    clear feats;
    save([params.logbin 'models_init.mat'],'model','labs_tr');
    print_scores(model.tr_scores, labs_tr);
    

    
    
    %% Get scores for SVMs
    fpaths = f_unlabfeats(strcmp(unlabs_gt,fids{x}));
    un_feats = load_features(fpaths)';%FT.fpath(FT.Confidence == 0)
    
    scores = model.w' * un_feats + model.b * ones(1,size(un_feats,2));
    [topscore,topscorer]=max(scores);
    save([params.logbin 'initial_svm_scores.mat'],'topscore','topscorer','scores');
    
    
    
    %% update SVM models
    ids = find(FT.Confidence);
    fpaths = cat(1,fpaths_tr, FT.fpath(ids));
    labs  = cat(1,labs_tr, FT.label(ids));
    feats = load_features(fpaths);
    
    model = FIW.model_mids(feats', labs, params.svm);
    save([params.logbin 'models_update_portait.mat'],'model','labs');
        
    
   
    
    print_scores(model.tr_scores, labs, [params.logbin 'initial_svm_scores.mat'])
    
%     [~,topscorer] = max();
%     correct = str2num(cell2mat(cellfun(@(x) x (4:end),labs_tr,'uni',false))) == topscorer';
%     per_correct = (length(find(correct(:)==1))/ length(correct)) * 100;
%     disp([num2str(per_correct) '% correct testing SVMs on training data']);

    %% Get updated scores for unlabeled face encodings
    unlab_ids = find(FT.Confidence==0);
    fpaths = f_unlabfeats(strcmp(unlabs_gt,fids{x}));
    fpaths=fpaths(unlab_ids);
    un_feats = load_features(fpaths)';%FT.fpath(FT.Confidence == 0)
    
    scores = model.w' * un_feats + model.b * ones(1,size(un_feats,2));
    [topscore,topscorer]=max(scores);
    save([params.logbin 'initial_svm_scores.mat'],'topscore','topscorer','scores');     
    
     pid_list = FT.PID(find(FT.Confidence==0));
     pids = unique(pid_list);
     npids = length(pids);
     
     pointer = 1;
     %% Process each PID
     for y = 1:npids
         pid = pids{y};
         
         cind = strcmp(FT.PID,pid);
         c_nfaces = find(cind);
         cmeta = cell2mat( unique(FT.Metadata(cind)));
         
         
         
         fileID = fopen('info/tmp/cmeta.txt','w');
         fprintf(fileID,'%s',cmeta);
         fclose(fileID);
         
         cmd = [params.cmd_name_parser ' ' 'info/tmp/cmeta.txt info/tmp/cmeta_names.csv'];
         
         cnames = myToolbox.i_o.csv2cell('info/tmp/cmeta_names.csv', 'fromfile');
         if ~isempty(cnames)
             nnames = length(cnames);
            ids_names = zeros(nnames,1);
            for z = 1:nnames
                for r = 1:length(names_lut)
                    
                    
                    
                    
                    tmp = find(strcmp(lower(cnames{z}),names_lut(r).list ));
                    
                    if isempty(tmp), continue; end
                    
                    
                    ids_names(z) = r;
                    break;
                end
            end
         end
        
         
         if (FT.Confidence(y) < 1)
             
             %             FT = FIW.process_pids(FT);
             pmeta = lower(FT.Metadata(y));
             
             while ~isempty(pmeta)
                 
                 
             end
             
             
        end
    end
%     inds = find(FT.Confidence);
%     high_confidence = FT.label(inds) == topscorer(inds)';
%     FT.Confidence(inds(high_confidence)) = 1;
    
    

    
    

    
    %% get attribute features for unknown facial images
    FIW.prepare_facial_attributes(attributes,  FT.ipath, strcat(attributes.featbin,fids{x},'/'));
    
    
    
    
    
end
end
function print_scores(scores, labs_tr, fout)
% eval model on training data
[topscore,topscorer] = max(scores);
% correct = str2num(cell2mat(cellfun(@(x) x (4:end),labs_tr,'uni',false))) == topscorer';
correct = cell2mat(cellfun(@str2num, cellfun(@(x) x (4:end),labs_tr,'uni',false),'uni',false))' == topscorer';
per_correct = (length(find(correct(:)==1))/ length(correct)) * 100;
disp([num2str(per_correct) '% correct testing SVMs on training data']);

if nargin == 3
    save(fout,'topscore','topscorer','scores');
end

end








%     labs_ne = find(strcmp(labs_gt,fids{x})==0);
%
%     strcmp(cat(2,cmeta{:}),'Rob');
%
%     fid = fopen(strrep(sf_set(2).ImageLocation,'.jpg','.txt'),'r');
%     A=fscanf(fid,'left: %d top: %d right: %d bottom: %d');
%     fclose(fid);
%     Member(name,id,fid,gender, featpaths)




