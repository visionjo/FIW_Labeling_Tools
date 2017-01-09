% ------------------------------------------------------------------------
function images = prepare_batch(image_files,IMAGE_MEAN,batch_size,CROPPED_DIM)
% ------------------------------------------------------------------------
IMAGE_DIM = 256;
N = length(image_files);
if nargin < 3
    batch_size = N;
    CROPPED_DIM = 227;
end


indices = [0 IMAGE_DIM-CROPPED_DIM] + 1;
center = floor(indices(2) / 2)+1;

images = zeros(CROPPED_DIM,CROPPED_DIM,3,batch_size,'single');
myToolbox.parfor_progress(N);

parfor i=1:N
    % read file
    myToolbox.parfor_progress;
    fprintf('Preparing %s\n',image_files{i});
     try
         im = imread(image_files{i});
         
        % resize to fixed input size
        im = imresize(im, [IMAGE_DIM IMAGE_DIM], 'bilinear');
        im = single(im);
        
        % Transform GRAY to RGB
        if size(im,3) == 1
            im = cat(3,im,im,im);
        end
        
        % permute from RGB to BGR (IMAGE_MEAN is already BGR)
        im = im(:,:,[3 2 1]) - IMAGE_MEAN;
         % Crop the center of the image
          
         images(:,:,:,i) = im(center:center+CROPPED_DIM-1,center:center+CROPPED_DIM-1,:);
%          images(:,:,:,i) = permute(im(center:center+CROPPED_DIM-1,...
%              center:center+CROPPED_DIM-1,:)-IMAGE_MEAN,[2 1 3]);
     catch
         warning('Problems with file %s',image_files{i});
     end
end