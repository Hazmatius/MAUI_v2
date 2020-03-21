% calculate the mask and stats (i.e. objects) in the image based upon set
% blur, threshold, and minimum values.
function [mask, stats] = calc_mask(point, pipeline_data)
    
    counts = point.counts;
    
    mask_channel_index = find(strcmp(pipeline_data.mask_channel, pipeline_data.points.labels()));
    mask_src = counts(:,:,mask_channel_index);
    
    scale = 1;
    mask_src = mask_src*scale;
    mask_values = pipeline_data.points.getEZ_SegmentParams();
    
    if mask_values.blur~=0
        mask_src = imgaussfilt(mask_src, mask_values.blur);
    end
    
    mask = imbinarize(mask_src, mask_values.threshold); hold on;
    stats = regionprops(mask, 'Area', 'PixelIdxList');
    [tmp, idxs] = sort(cell2mat({stats.Area}), 'descend');
    stats = stats(idxs);
    
    rm_obj_idxs = find([stats.Area] < mask_values.minimum);
    rm_pxl_idxs = [];
    for index = rm_obj_idxs
        rm_pxl_idxs = cat(1, rm_pxl_idxs, stats(index).PixelIdxList);
    end
    mask(rm_pxl_idxs) = 0;
    stats(rm_obj_idxs) = [];