function scores = extract_caffe_features(net,list_im, image_mean, batch_size, dim,CROPPED_DIM, fout)
%% Extract features using caffe. 
% Caffe model 'net' needs to be instatiated prior to passing to this
% function. Features are saved as a cell array, with each index
% representing the features of the image in the order provided by 'list_im'

% if exist(fout,'file')
%     str = ['Obj Detections found on disc ' fout];
%     display(str);
%     return;
% end
do_save = true;
if (nargin == 6)
    do_save = false;
elseif (nargin < 7)
     str = ['Only ' num2str(nargin) ' input args provide. Minimum of '...
         '6 inputs required (i.e., only optional is output filename)'];
     disp(str);
     return;
end

disp('Extracting Caffe Features')

num_images = length(list_im);
nframes = length(list_im);
scores = zeros(dim,nframes,'single');
num_batches = ceil(length(list_im)/batch_size);
for k = 1:num_batches
    range = 1+batch_size*(k-1):min(num_images,batch_size * k);
    input_data = feature.utils.prepare_batch(list_im(range),image_mean,batch_size,CROPPED_DIM);
    output_data = net.forward({input_data});
    output_data = squeeze(output_data{1});
    scores(:,range) = output_data(:,mod(range-1,batch_size)+1);
end

if (do_save)
    save(fout,'list_im', 'scores', '-v7.3');
end

end