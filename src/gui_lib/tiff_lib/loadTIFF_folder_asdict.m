function [counts_dict, labels, tags_dict] = loadTIFF_folder_asdict(path, varargin)
    % Find all tiffs or, if a cell array is provided, tiffs for all listed
    if numel(varargin)==0
        fileList = [dir(fullfile(path, '*.tiff'));...
                    dir(fullfile(path, '*.tif'))];
        if isempty(fileList)
            error(['No TIFF files found in ', path]);
        end
    else
        desiredTIFs = varargin{1};
        if ~iscell(desiredTIFs)
            error('desiredTIFs must be a cell array of strings, but is not a cell array');
        else
            for i=1:numel(desiredTIFs)
                if ~ischar(desiredTIFs{i})
                    disp(desiredTIFs{i}{1})
                    error(['The ', num2str(i), 'th element "', char(string(desiredTIFs{i})), '" of desiredTIFs is not a string']);
                end
            end
        end
        fileList = [];
        for i=1:numel(desiredTIFs)
            subFileList = [dir(fullfile(path, [desiredTIFs{i}, '.tiff']));...
                           dir(fullfile(path, [desiredTIFs{i}, '.tif']))];
            if isempty(subFileList)
                error(['"', desiredTIFs{i}, '" was not found in ', path]);
            else
                fileList = [fileList; subFileList];
            end
        end
    end
    % Clean up the list of files by removing totalIon (never a file we care
    % about) and hidden files that sometimes pop up, like '.CD45.tif'
    files = {fileList.name}';
    rmIdx = [find(strcmp(files, 'totalIon.tif')), find(strcmp(files, 'totalIon.tiff'))];
    files(rmIdx) = []; % removes totalIon.tif and/or totalIon.tiff
    rmIdx = find(cellfun(@isHiddenName, {fileList.name}));
    files(rmIdx) = [];
    
    num_pages = numel(files);
    counts_dict = containers.Map;
    labels = {};
    tags_dict = containers.Map;
    for index=1:num_pages
        tiff = Tiff([path, filesep, files{index}]);
        data = read(tiff);
        % just in case the tiff was opened in photoshop and got saved as an
        % rgb image
        if size(data,3)==3
            warning('you did some weird stuff to your tiffs, huh?');
            data1=data(:,:,1); data2=data(:,:,2); data3=data(:,:,3);
            if all(data1==data2) & all(data2==data3)
                data = data(:,:,1);
            else
                error('invalid data format');
            end
        end
        
        tags = getTagStruct(tiff);
        tags.SamplesPerPixel = 1;
        tags.Compression = 32946;
        tags.RowsPerStrip = 16;
        tags.Photometric = 1;
        try tags = rmfield(tags{index}, 'Software'); catch; end
        try tags = rmfield(tags{index}, 'DateTime'); catch; end
        try
            desc = json.load(tags{index}.ImageDescription);
            label = desc.channel0x2Etarget;
        catch
            [~, label, ~] = fileparts(files{index});
        end
        
        labels{index} = label;
        counts_dict(label) = data;
        tags_dict(label) = tags;
    end
end