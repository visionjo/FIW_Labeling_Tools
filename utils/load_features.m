function feats = load_features(fpaths)
nfeats = length(fpaths);
feats = cell(1,nfeats);
for y = 1:nfeats
    tmp =  load(fpaths{y});
    feats{y} = tmp.feat;
end
feats = double(cat(2,feats{:}));
end