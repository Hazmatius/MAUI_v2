function [labels] = load_labels(path, varargin)
    % Figure out the paths
    if numel(varargin)==0
        masterPath = strsplit(mfilename('fullpath'), filesep);
        masterPath = strjoin(masterPath(1:(end-3)), filesep);
        try
            options = json.read([masterPath, filesep, 'options.json']);
            tifspath = [path, filesep, options.pathext];
        catch err
            disp(err)
            warning([masterPath, filesep, 'options.json not found, proceding under assumption of basic Point directory structure']);
        end
    else
        tifspath = [path, filesep, varargin{1}];
    end
    
    % Find all tiffs or, if a cell array is provided, tiffs for all listed
    fileList = [dir(fullfile(tifspath, '*.tiff'));...
                dir(fullfile(tifspath, '*.tif'))];
    if isempty(fileList)
        error(['No TIFF files found in ', tifspath]);
    end
    % Clean up the list of files by removing totalIon (never a file we care
    % about) and hidden files that sometimes pop up, like '.CD45.tif'
    files = {fileList.name}';
    rmIdx = [find(strcmp(files, 'totalIon.tif')), find(strcmp(files, 'totalIon.tiff'))];
    files(rmIdx) = []; % removes totalIon.tif and/or totalIon.tiff
    rmIdx = find(cellfun(@isHiddenName, {fileList.name}));
    files(rmIdx) = [];
    
    num_pages = numel(files);
    labels = {};
    for index=1:num_pages
        tiff = Tiff([tifspath, filesep, files{index}]);
        try
            desc = json.load(tags{index}.ImageDescription);
            label = desc.channel0x2Etarget;
        catch
            [~, label, ~] = fileparts(files{index});
        end
        labels{index} = label;
    end
    labels = sort_labels_by_mass(labels, path);
end