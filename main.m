% function main()
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

tmp_bin = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/matlab/tmp/';
myToolbox.i_o.checkdir(tmp_bin);
%% Name_Parser.java tool configurations
f_name_parser = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/java/Name_Parser/dist/Name_Parser.jar';
cmd_name_parser = ['java -jar ', f_name_parser];
f_name_classifier = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/java/Name_Parser/classifiers/english.all.3class.distsim.crf.ser.gz';
cmd_name_parser = [cmd_name_parser,' ',f_name_classifier];

% vl_path = '~/Documents/MATLAB/vlfeat-0.9.20/toolbox/vl_setup.m';
vl_path = 'vlfeat-0.9.20/toolbox/vl_setup.m';
if exist(vl_path)
    run(vl_path);
end

% model parameters
svm.biasMultiplier = 1 ;
svm.C = 1 ;
svm.solver = 'sdca';


d_source_root = '/home/jrobby/Dropbox/Families_In_The_Wild/Database/New_PIDs/';%/home/jrobby/Dropbox/Families_In_The_Wild/Journal_Extension/data/';
% d_source_root = '/Users/jrob/WORK/janus/sandbox/jrobinson/Agglomerative/matlab/data/New_PIDs/';
imdir = [d_source_root 'unlabeled/faces/'];

fin_labfeats = [d_source_root 'labeled/features/'];
fin_unlabfeats = [d_source_root 'unlabeled/features/'];
fin_unlabimages = [d_source_root 'unlabeled/images/'];
fin_labs = [d_source_root 'labeled/FIDs/'];
 
%% Attributes models fpaths
attributes.featbin = 'info/attributes/';
myToolbox.i_o.checkdir(attributes.featbin);
attributes.d_model_age = '/home/jrobby/caffe/models/cnn_age_gender/';
attributes.f_mean = [attributes.d_model_age 'mean.mat'];

attributes.cropped_dim = 227;
attributes.image_dim = 256;
attributes.batch_size = 1;

attributes.f_age_net = [attributes.d_model_age 'deploy_age.prototxt'];
attributes.f_age_weights = [attributes.d_model_age 'age_net.caffemodel'];

attributes.d_model_gender = attributes.d_model_age;
attributes.f_gender_net = [attributes.d_model_age 'deploy_gender.prototxt'];
attributes.f_gender_weights = [attributes.d_model_age 'gender_net.caffemodel'];

%% FID LUT
TFID = readtable(strcat(d_source_root,'FIW_FIDs.csv'));
%% Prepare UNKNOWN
% Fetch family information, if any
T = readtable(strcat(d_source_root,'PIDs_New_Master.csv'));
fids = unique(T.FIDs);
nfids = length(fids);



% fid_path = '/home/jrobby/Dropbox/Families_In_The_Wild/Ann/FW_FIDs/';
obin = strcat(d_source_root, 'unlabeled/FIDs/',fids,'/');
cellfun(@mkdir,obin)
fid_paths = strcat(fin_labs,fids,'.csv');
fam_info = cellfun(@exist,  fid_paths) > 0; % families with existing labels

% get featpaths for unlabeled faces
tt=dir([fin_unlabfeats '*/*/*.mat']);
tmp = strcat({tt.folder},'/'); tmp1 = {tt.name};
f_unlabfeats = strcat(tmp,tmp1)';
% imset = imageSet('data/New_PIDs/unlabeled/faces/','recursive');
% f_unlabfeats = strrep(strrep([imset.ImageLocation]','faces','features'),'.jpg','.mat');

sind = length(strcat(d_source_root, 'unlabeled/features/'));
unlabs_gt = cellfun(@(x) x(sind+1:sind+5), f_unlabfeats,'uni',false);

%% Prepare KNOWN
%% get featpaths for labeled faces
tt=dir([fin_labfeats '*/*/*.mat']);
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

sind = length(strcat(d_source_root, 'labeled/features/'));
labs_gt = cellfun(@(x) x(sind+1:sind+5), f_labfeats,'uni',false);




for x = 1:nfids
    %% For each family
    
    if fam_info(x)
       infos = FIW.utils.get_family_info(fid_paths{x}); 
    end
    
    fbin = strcat(imdir,fids{x},'/');
    inds = find(strcmp(T.FIDs,fids{x}));
    meta = T.METADATA(inds);
    pids = T.PIDs(inds);
    
    fid_listing = TFID.surnames{strcmp(TFID.FIDs,fids{x})};
    [tmp, check] = split(fid_listing,'.');
    if isempty(check)
        fprintf(2, ...
            '\nError parsing surname: FID listing does not contain period as demiliter\n');
          surname = fid_listing;
        fprintf(2, ...
            'Assigning complete listing as surname:\t%s\n\n',surname);
    else
        surname = tmp{1};
    end
        
    %% prepare table containing PIDs, metadata, image path, label, and 
    % whether or not a single face (i.e., Portait)
    FT = FIW.prepare_fid_table(imdir, fids{x}, meta, pids);
    nfaces = length(FT.ID);

    %% expand on prior knowledge
    % search all metadata for instances of names. Names not present in FIDs
    % are potential candidates for new family members
    allnames = find_candidate_names(cmd_name_parser, meta, tmp_bin);
    names = create_names_lut(allnames, infos.name);
    
    new_mids = ones(length(allnames),1);
    names_lut = [];
    for y = 1:infos.nmembers
        names_lut(y).list{1} = infos.name{y};
        
        % determine whether or not last name is included in name listing
        tmp_ids = strfind(infos.name{y},surname);
        if isempty(tmp_ids)
            % doesnt include last name
            names_lut(y).list{2} = [infos.name{y} ' ' surname];
        else
            % name listing includes lastname; therefore, add instance
            % without it
            names_lut(y).list{2} = strtok(infos.name{y});
        end
        
        
        tmp_ids = find(strcmp(infos.name(y),allnames));        
        if ~isempty(tmp_ids), new_mids(tmp_ids) = 0; end
        
    end
    new_names = allnames(new_mids==1);
    
    
    
    %% first handle cases with single face (i.e., profile pics)
    FT = FIW.handle_portaits(FT, infos);
    
    %% get attribute features for unknown facial images
    FIW.prepare_facial_attributes(attributes,  FT.ipath, strcat(attributes.featbin,fids{x},'/'));

    
    
    %% Model known members
    % load face features 
    fpaths_tr = f_labfeats(strcmp(labs_gt,fids{x}));  
    feats = load_features(fpaths_tr);

    % train one-against-all models
    % Generate SVMs
    ind = strfind(fpaths_tr{1},'MID');
    labs_tr = cellfun(@fileparts,cellfun(@(x) x(ind:end),fpaths_tr ,'uni',false),'uni',false);

    model = FIW.model_mids(feats, labs_tr, svm);
    clear feats;
    % eval model on training data
    [~,topscorer] = max(model.tr_scores);
    correct = str2num(cell2mat(cellfun(@(x) x (4:end),labs_tr,'uni',false))) == topscorer';
    per_correct = (length(find(correct(:)==1))/ length(correct)) * 100;
    disp([num2str(per_correct) '% correct testing SVMs on training data']);
    
    
    %% Get scores for SVMs
    fpaths = f_unlabfeats(strcmp(unlabs_gt,fids{x}));
    un_feats = load_features(FT.fpath(FT.Confidence == 0));
           
    scores = model.w' * un_feats + model.b * ones(1,size(un_feats,2));
    [topscore,topscorer]=max(scores);
    
    inds = find(FT.label);
    high_confidence = FT.label(inds) == topscorer(inds)';
    FT.Confidence(inds(high_confidence)) = 1;
    
    
    %% update SVM models
    ids = find(FT.Confidence);
    fpaths = cat(1,fpaths_tr, FT.fpath(ids));
    labs  = cat(1,labs_tr, FT.label(ids));
    feats = load_features(fpaths);
    
    model = FIW.model_mids(feats, labs, svm);
      
    [~,topscorer] = max(model.tr_scores);
    correct = str2num(cell2mat(cellfun(@(x) x (4:end),labs,'uni',false))) == topscorer';
    per_correct = (length(find(correct(:)==1))/ length(correct)) * 100;
    disp([num2str(per_correct) '% correct testing SVMs on training data']);
    
    
    %% Process each PID
    FT = FIW.process_pids(FT);
    
    
end


% end

%     labs_ne = find(strcmp(labs_gt,fids{x})==0);
%     
%     strcmp(cat(2,cmeta{:}),'Rob');
%     
%     fid = fopen(strrep(sf_set(2).ImageLocation,'.jpg','.txt'),'r');
%     A=fscanf(fid,'left: %d top: %d right: %d bottom: %d');
%     fclose(fid);
%     Member(name,id,fid,gender, featpaths)
    



