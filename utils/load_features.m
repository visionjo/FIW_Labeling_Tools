function feats = load_features(fpaths, do_prepocess)
nfeats = length(fpaths);
feats = cell(1,nfeats);
for y = 1:nfeats
    tmp =  load(fpaths{y});
    feats{y} = tmp.feat;
end
feats = double(cat(2,feats{:}))';

if nargin == 2 && do_prepocess
   feats = feature.utils.centralize_features(feats,1);
   feats = feature.utils.normalize_features(feats,1);
end
end