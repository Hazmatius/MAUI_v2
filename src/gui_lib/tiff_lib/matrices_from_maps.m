function [counts, labels, tags] = matrices_from_maps(counts_dict, labels, tags_dict)
    tags = {};
    counts = [];
    for i=1:numel(labels)
        counts(:,:,i) = counts_dict(labels{i});
        tags{i} = tags_dict(labels{i});
    end
end

