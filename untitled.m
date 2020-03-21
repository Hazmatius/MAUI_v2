folder = '/Volumes/ALEX_SSD/BRAIN_DATA/Med_AD/';

points = {};
for i=1:259
    point = struct();
    [point.counts, point.labels, point.tags] = loadTIFF_multi([folder, 'Point', num2str(i), '.tiff']);
    points{end+1} = point;
end

%%
test_points = [11,21,30,38,39,49,53,73,78,89,103,105,124,127,145,175,184,188,193,196,214,215,223,229,234,247,253];
for i=1:numel(points)
    if any(i==test_points)
        figure('Name', 'test');
    else
        figure();
    end
    point = points{i};
    imagesc(point.counts(:,:,5)); plotbrowser on;
end

%%
