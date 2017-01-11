function [index, centroid] = pconstraintKmeans(data, K, pIDX, lambda)
% K-means with sqEuclidean distance with partitioning-level constraint
    [n,m] = size(data);
    r = size(pIDX,2);
    maxIter =10; 
    centroid = initialCentroid(data, K, n, r);
    sumbest = inf;
    for i = 1 : maxIter
        D = getDistance(data, pIDX, centroid, K, n, m, r, lambda);
        [d, idx] = min(D, [], 2); 
        totalsum = sum(d);
        if abs(sumbest - totalsum) < 1e-5
            break;           
        elseif totalsum < sumbest
            index = idx; 
            centroid = getCentroid(data, pIDX, index, K, n, m, r);
            sumbest = totalsum;
%             disp(sumbest);
        else
            disp('objective function value increase!!!');
        end
    end
end

function centroid = initialCentroid(data, K, n, r)
    centroid = data(randsample(n,K),:);
    C = zeros(K, r*K);
    for i = 1 : r
        for k = 1 : K
            C(k, randsample(K,1)+ (i-1)*K) =1;
        end
    end
    centroid = [centroid C];
end

function centroid = getCentroid(data, pIDX, index, K, n, m, r)
    centroid = zeros(K,m);
    C = zeros(K, r*K);
    for k = 1 : K
       members = (index==k);
       if any(members)
          centroid(k,:) = sum(data(members,:))/sum(members); 
          
          counts = hist(pIDX(members,:),0:K);
%           disp(size(counts));
%           disp(counts);
          if size(counts,1)==1
            counts = counts';
          end
          
          for i = 1 : r
              if counts(1,i) == sum(members)
                  C(k, randsample(K,1)+ (i-1)*K) =1;
              else
%                   disp(sum(members)- counts(1,i));
                  C(k,1+(i-1)*K:K+(i-1)*K) = counts(2:K+1,i)/(sum(members)- counts(1,i));
                  
              end
          end
          
       else
          centroid(k,:) = data(randsample(n,1),:);
          for i = 1 : r
              C(k, randsample(K,1)+ (i-1)*K) =1;
          end
       end
    end
    centroid = [centroid C];
end

function D = getDistance(data, pIDX, centroid, K, n, m, r, lambda)
    D = zeros(n, K);
    P = zeros(n, K);
    for k = 1 : K
       D(:,k) = sum((data - centroid(repmat(k,n,1),1:m)).^2,2);
    end
    
    for i = 1 : r
       temp = pIDX(:,i);
       l = temp >0;
       matrix = getBinaryMatrix(temp, K);
       
       count = sum(l);
       for k = 1 : K
          P(l,k) =  lambda * sum((matrix(l,:) -  centroid(repmat(k,count,1),m+1+(i-1)*K:m+K+(i-1)*K)).^2,2);
       end
       D = D + P;
    end
end