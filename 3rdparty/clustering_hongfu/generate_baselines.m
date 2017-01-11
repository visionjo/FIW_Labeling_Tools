function cluster_ids = generate_baselines(fpaths, alllabs, k, lamda, fout)
%% Wrapper function to generate cluster assignments 
%
%   AUTHOR    : Joseph P. Robinson
%   DATE      : 6-December-2017
%   Revision  : 1.0
%   DEVELOPED : 9.1.0.441655 (R16b)
%   FILENAME  : generate_baselines.m
%
%   REVISIONS:
%   6-January-2017 -   Function created
%
do_save = true;
if (nargin < 4)
    lamda = 1e3;
    do_save = false;
elseif (nargin < 5)
    do_save = false;
end

feats = load_features(fpaths);
[cluster_ids, centroids] = pconstraintKmeans(feats,k,alllabs,lamda);


if (do_save)
    save(fout, 'centroids', 'cluster_ids');
end