function [counts_dict, labels, tags_dict, path_ext, runinfo] = loadTIFF_data_asdict(path, varargin)
    [~, ~, ext] = fileparts(path);
    if strcmp(ext, '.tiff') || strcmp(ext, '.tif') || strcmp(ext, '.TIFF') || strcmp(ext, '.TIF')
        error('Loading multi-tiffs is currently not supported');
        % path_ext = '';
    elseif (strcmp(ext, ''))
        % path is to folder of tiffs, meaning it could be from IonPath or
        % it could be from Leeat's extraction script
        disp(['Loading folder of TIFF data at ', path, '...']);
        % looks for a pathext in options.json file in case there is a more complicated
        % subfolder structure
        if numel(varargin)==0 || iscell(varargin{1})
            masterPath = strsplit(mfilename('fullpath'), filesep);
            masterPath = strjoin(masterPath(1:(end-3)), filesep);
            try
                options = json.read([masterPath, filesep, 'options.json']);
                pathext = options.pathext;
            catch err
                disp(err)
                warning([masterPath, filesep, 'options.json not found, proceding under assumption of basic Point directory structure']);
                pathext = '';
            end
        else
            pathext = varargin{1};
            varargin(1) = [];
        end
        try % we assume that pathext actually respects the directory structure in use
            [counts_dict, labels, tags_dict] = loadTIFF_folder_asdict([path, filesep, pathext], varargin{:});
            path_ext = pathext;
        catch err % if that doesn't work we're going to assume that pathext.txt is bad
            disp(err);
            warning(['Failed to load data from ', path, filesep, pathext]);
            warning(['Attemping to load data from ', path]);
            [counts_dict, labels, tags_dict] = loadTIFF_folder_asdict(path, varargin{:});
            path_ext = '';
        end
    else
        % path is to a dark void in your soul
        error('Path provided is not to a folder or TIFF file, no TIFF files were loaded');
    end
    
    [folder, ~, ~] = fileparts(path); % remember that path should be to a POINT folder
    [folder, ~, ~] = fileparts(folder);
    xmlPath = [folder, filesep, 'info'];
    xmlList = dir(fullfile(xmlPath, '*.xml'));
    xmlList(find(cellfun(@isHiddenName, {xmlList.name}))) = [];
    if numel(xmlList)==1
        filepath = [xmlList.folder, filesep, xmlList.name];
        runxml = xml2struct(filepath);
        [~, runxml.xmlname, ~] = fileparts(xmlList.name);
    elseif isempty(xmlList)
        error(['No XML file was found inside of ', xmlPath]);
    else
        error(['Too many XML files were found inside of ', xmlPath]);
    end
    
    runinfo.runxml = runxml;
end