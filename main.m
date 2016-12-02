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
d_source_root = '/home/jrobby/Dropbox/Families_In_The_Wild/Database/New_PIDs/';%/home/jrobby/Dropbox/Families_In_The_Wild/Journal_Extension/data/';
% d_source_root = '/Users/jrob/WORK/janus/sandbox/jrobinson/Agglomerative/matlab/data/New_PIDs/';
imdir = [d_source_root 'unlabeled/faces/'];

fin_labfeats = [d_source_root 'labeled/features/'];
fin_unlabfeats = [d_source_root 'unlabeled/features/'];
fin_unlabimages = [d_source_root 'unlabeled/images/'];
fin_labs = [d_source_root 'labeled/FIDs/'];
 
%% Prepare UNKNOWN
%% Fetch family information, if any
T = readtable(strcat(d_source_root,'PIDs_New_Master.csv'));
fids = unique(T.FIDs);
nfids = length(fids);



 
%% Parse metadata
% Reference family information to determine members whom are present in 
% collection of unlabeled images.
% fid_path = '/home/jrobby/Dropbox/Families_In_The_Wild/Ann/FW_FIDs/';
obin = strcat(d_source_root, 'unlabeled/FIDs/',fids,'/');
cellfun(@mkdir,obin)
fid_paths = strcat(fin_labs,fids,'.csv');
fam_info = cellfun(@exist,  fid_paths) > 0; % families with existing labels


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

%% get featpaths for unlabeled faces
tt=dir([fin_unlabfeats '*/*/*.mat']);
tmp = strcat({tt.folder},'/'); tmp1 = {tt.name};
f_unlabfeats = strcat(tmp,tmp1)';
% imset = imageSet('data/New_PIDs/unlabeled/faces/','recursive');
% f_unlabfeats = strrep(strrep([imset.ImageLocation]','faces','features'),'.jpg','.mat');

sind = length(strcat(d_source_root, 'unlabeled/features/'));
unlabs_gt = cellfun(@(x) x(sind+1:sind+5), f_unlabfeats,'uni',false);


for x = 1:nfids
    %% For each family
    
    if fam_info(x)
       infos = FIW.utils.get_family_info(fid_paths{x}); 
    end
    
    fbin = strcat(imdir,fids{x},'/');
    inds = find(strcmp(T.FIDs,fids{x}));
    meta = T.METADATA(inds);
    pids = T.PIDs(inds);
    
    %% prepare table containing PIDs, metadata, image path, label, and 
    % whether or not a single face (i.e., Portait)
    FT = FIW.prepare_fid_table(imdir, fids{x}, meta);
    

    %% first handle cases with single face (i.e., profile pics)   
    
    %     single_face = [iset.Count] == 1;
    %     sf_set = iset(single_face);
    %     sf_pids = {sf_set.Description};
    %
    %     cmeta = cell(1,length(sf_pids));
    %
    %     for y = 1:length(sf_pids)
    %         ind = strcmp(pids,sf_pids{y});
    %         cmeta{y} = meta(ind);
    %     end
    
    sf_set = find([FT.Portrait]);
    nsingles = length(sf_set);
    mids = zeros(nfaces,1);
    mids2 = zeros(nsingles,1);
    for y = 1:infos.nmembers
        indz = strcmp([cmeta{:}],infos.name{y});
        if isempty(find(indz, 1)), continue; end
        pidz = sf_pids(indz);
        for z = 1:length(pidz)
            mids(strcmp(FT.PID,pidz{z})) = str2double(infos.mid{y});
            mids2(strcmp(sf_pids,pidz{z}))  = str2double(infos.mid{y});
        end
    end
    
    
    
    %% Generate SVMs
    fpaths_tr = f_labfeats(strcmp(labs_gt,fids{x}));
    ind = strfind(fpaths_tr{1},'MID');
    
    labs_tr = cellfun(@fileparts,cellfun(@(x) x(ind:end),fpaths_tr ,'uni',false),'uni',false);
    labs = unique(labs_tr);
    nfeats = length(fpaths_tr);
    feats = cell(1,nfeats);
    for y = 1:nfeats
        tmp =  load(fpaths_tr{y});
        feats{y} = tmp.feat;
    end
    feats = double(cat(2,feats{:}));
    %# train one-against-all models
    nlabs = numel(labs);
    model = cell(nlabs,1);
    w = zeros(size(feats,1),nlabs);  b =zeros(1,nlabs); info=cell(1,nlabs);
    biasMultiplier = 1 ;
    C = 1 ;
    lambda = 1 / (C * nlabs);
    numiter = 50/lambda;
    for ci = 1:nlabs
        try
            fprintf('Training model for class %s\n', labs{ci}) ;
            y = 2 * strcmp(labs_tr, labs{ci}) - 1;
            %       y(~pos_samps)=-1;
            [w(:,ci), b(ci), info{ci}] = vl_svmtrain(feats, y, lambda, ...
                'Solver', 'sdca', ...
                'MaxNumIterations',numiter, ...
                'BiasMultiplier', biasMultiplier, ...
                'Epsilon', 1e-3);
        catch
            %       logger(lpath,['Error generating model for ' tags{ci}])
            display('Error modeling SVM');
        end
    end

    
    %% Get scores for SVMs
    fpaths = f_unlabfeats(strcmp(unlabs_gt,fids{x}));
%     ind = strfind(fpaths{1},'MID');
    
%     labs_tr = cellfun(@fileparts,cellfun(@(x) x(ind:end),fpaths_tr ,'uni',false),'uni',false);
%     labs = unique(labs_tr);
    nfeats = length(fpaths);
    feats = cell(1,nfeats);
    for y = 1:nfeats
        tmp =  load(fpaths{y});
        feats{y} = tmp.feat;
    end
    feats = double(cat(2,feats{:}))';
    
    %# get probability estimates of test instances using each model
%     prob = zeros(nfeats,nlabs);
%     for k=1:nlabs
%         cinds = strcmp(labs_tr,labs{k});
% %         cinds = labs_tr==k;        
%         [~,~,p] = svmpredict(double(cinds), feats, model{k}, '-b 1');
%         prob(:,k) = p(:,model{k}.Label==1);    %# probability of class==k
%     end
    
    

%     labs_ne = find(strcmp(labs_gt,fids{x})==0);
%     
%     strcmp(cat(2,cmeta{:}),'Rob');
%     
%     fid = fopen(strrep(sf_set(2).ImageLocation,'.jpg','.txt'),'r');
%     A=fscanf(fid,'left: %d top: %d right: %d bottom: %d');
%     fclose(fid);
%     Member(name,id,fid,gender, featpaths)
    
end


