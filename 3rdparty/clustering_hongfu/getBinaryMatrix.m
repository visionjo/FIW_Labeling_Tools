function result = getBinaryMatrix(IDX, K)
    n = size(IDX,1);
    result = zeros(n,K);
    l = IDX>0;
    label =eye(K);
    result(l>0,:) = label(IDX(l>0),:);
end
