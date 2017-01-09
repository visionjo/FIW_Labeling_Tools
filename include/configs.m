function params = configs()
params.logbin = 'intermediate/';
myToolbox.i_o.checkdir(params.logbin);

params.tmp_bin = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/matlab/tmp/';
myToolbox.i_o.checkdir(params.tmp_bin);

%% Name_Parser.java tool configurations
params.f_name_parser = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/java/Name_Parser/dist/Name_Parser.jar';
params.cmd_name_parser = ['java -jar ', params.f_name_parser];
params.f_name_classifier = '/home/jrobby/Documents/janus/sandbox/jrobinson/Agglomerative/java/Name_Parser/classifiers/english.all.3class.distsim.crf.ser.gz';
params.cmd_name_parser = [params.cmd_name_parser,' ',params.f_name_classifier];

% vl_path = '~/Documents/MATLAB/vlfeat-0.9.20/toolbox/vl_setup.m';
params.vl_path = 'vlfeat-0.9.20/toolbox/vl_setup.m';
if exist(params.vl_path)
    run(params.vl_path);
end

% model parameters
params.svm.biasMultiplier = 1 ;
params.svm.C = 1 ;
params.svm.solver = 'sdca';


params.d_source_root = '/home/jrobby/Dropbox/Families_In_The_Wild/Database/New_PIDs/';%/home/jrobby/Dropbox/Families_In_The_Wild/Journal_Extension/data/';
% d_source_root = '/Users/jrob/WORK/janus/sandbox/jrobinson/Agglomerative/matlab/data/New_PIDs/';
params.imdir = [params.d_source_root 'unlabeled/faces/'];

params.fin_labfeats = [params.d_source_root 'labeled/features/'];
params.fin_unlabfeats = [params.d_source_root 'unlabeled/features/'];
params.fin_unlabimages = [params.d_source_root 'unlabeled/images/'];
params.fin_labs = [params.d_source_root 'labeled/FIDs/'];

%% Attributes models fpaths
params.attributes.featbin = 'info/attributes/';
myToolbox.i_o.checkdir(params.attributes.featbin);
params.attributes.d_model_age = '/home/jrobby/caffe/models/cnn_age_gender/';
params.attributes.f_mean = [params.attributes.d_model_age 'mean.mat'];

params.attributes.cropped_dim = 227;
params.attributes.image_dim = 256;
params.attributes.batch_size = 1;

params.attributes.f_age_net = [params.attributes.d_model_age 'deploy_age.prototxt'];
params.attributes.f_age_weights = [params.attributes.d_model_age 'age_net.caffemodel'];

params.attributes.d_model_gender = params.attributes.d_model_age;
params.attributes.f_gender_net = [params.attributes.d_model_age 'deploy_gender.prototxt'];
params.attributes.f_gender_weights = [params.attributes.d_model_age 'gender_net.caffemodel'];


end