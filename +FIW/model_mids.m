function  model = model_mids(feats, labs_tr, params)


labs = unique(labs_tr);
nlabs = numel(labs);

w = zeros(size(feats,1),nlabs);  b =zeros(1,nlabs); info=cell(1,nlabs);


lambda = 1 / (params.C * nlabs);
numiter = 50/lambda;
for ci = 1:nlabs
    try
        fprintf('Training model for class %s\n', labs{ci}) ;
        y = 2 * strcmp(labs_tr, labs{ci}) - 1;
        %       y(~pos_samps)=-1;
        [w(:,ci), b(ci), info{ci}] = vl_svmtrain(feats, y, lambda, ...
            'Solver', params.solver, ...
            'MaxNumIterations',numiter, ...
            'BiasMultiplier', params.biasMultiplier, ...
            'Epsilon', 1e-3);
    catch
        %       logger(lpath,['Error generating model for ' tags{ci}])
        display('Error modeling SVM');
    end
end
model.w = w; model.b = b'; model.info = info;
model.labels = labs;

model.tr_scores = w' * feats + b' * ones(1,size(feats,2));
end

