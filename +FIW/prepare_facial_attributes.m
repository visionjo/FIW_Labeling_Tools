function prepare_facial_attributes(params, im_list, featbin)
%%
% Extracts features for age and gender attributes if a feature file (.mat)
% does not already exist.
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 2-December-2016
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : prepare_facial_attributes.m
%
%   REVISIONS:
%   2-December-2016 -   Function created
%
%
f_gender = strcat(featbin, 'genders.mat');
f_age = strcat(featbin, 'ages.mat');

if exist(f_gender,'file') && exist(f_age,'file')
    %% exit function if both sets of attributes already exist
    str = 'Both Gender and Age (Attribute) Features exist... leaving function!!';
    disp(str);
    return;
else
    myToolbox.i_o.checkdir(featbin);
end
    
% load mean image
d=load(params.f_mean);
image_mean = d.mean_image;
clear d;
phase = 'test';

%% Gender Attribute
if exist(f_gender,'file')
    %% if feature file already exist, then skip
    str = 'Gender (Attribute) Features already exist... %s\n ... skipping!!\n\n';
    fprintf(str,f_gender);
else
    %% Extract features
    
    net = caffe.Net(params.f_gender_net, params.f_gender_weights, phase);
    feats = feature.utils.extract_caffe_features(net, im_list,image_mean,params.batch_size,2,params.cropped_dim);
    caffe.reset_all();
    save(f_gender, 'feats', '-v7.3');
    clear feats;
    
end


%% Age Attribute
if exist(f_age,'file')
    %% if feature file already exist, then skip
    str = 'Age (Attribute) Features already exist... %s\n ... skipping!!\n\n';
    fprintf(str,f_age);
else
    %% Extract features
    net = caffe.Net(params.f_age_net, params.f_age_weights, phase);
    feats = feature.utils.extract_caffe_features(net, im_list,image_mean,params.batch_size,8,params.cropped_dim);
    caffe.reset_all();
    save(f_age, 'feats', '-v7.3');
    clear feats;
end
