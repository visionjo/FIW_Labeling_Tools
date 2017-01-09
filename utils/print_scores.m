function print_scores(scores, labs_tr, fout)
% eval model on training data
[topscore,topscorer] = max(scores);
% correct = str2num(cell2mat(cellfun(@(x) x (4:end),labs_tr,'uni',false))) == topscorer';
correct = cell2mat(cellfun(@str2num, cellfun(@(x) x (4:end),labs_tr,'uni',false),'uni',false))' == topscorer';
per_correct = (length(find(correct(:)==1))/ length(correct)) * 100;
disp([num2str(per_correct) '% correct testing SVMs on training data']);

if nargin == 3
    save(fout,'topscore','topscorer','scores');
end