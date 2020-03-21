classdef PointManager < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        labelss;
        offset;
        namesToPaths % map from names to paths
        pathsToNames % map from paths to names
        pathsToPoints % map from paths to Points
        % for background removal
        bgRmParams
        % for denoising
        denoiseParams % cell array of denoising params
        channel_load_status
        point_load_status
        % for aggregate removal
        aggRmParams
        % for denoising using fft algorithm
        fftRmParams
        % for object identification and FCS file formation
        ez_segmentParams
        
        run_object
        
        data_status;
        
        point_data_status
        point_stage_status
        channel_data_status
        channel_stage_status
        
        display_caps;
    end
    
    methods
        function obj = PointManager()
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            obj.namesToPaths = containers.Map;
            obj.pathsToNames = containers.Map;
            obj.pathsToPoints = containers.Map;
            
            obj.bgRmParams = {};
            obj.denoiseParams = {};
            obj.aggRmParams = {};
            obj.fftRmParams = {};
            
            obj.point_data_status = containers.Map();
            obj.point_stage_status = containers.Map();
            obj.channel_data_status = containers.Map();
            obj.channel_stage_status = containers.Map();
            
            obj.display_caps = containers.Map();
        end
        
        %% Point management functions
        
        function obj = setLabels(obj, labelss)
            obj.labelss = labelss;
        end
        
        function status_icon = get_status_icon(obj, data_status, stage_status)
            status = num2str([data_status, stage_status]);
            switch status
                case num2str([0,0]) % not in memory, don't want to load
                    status_icon = '';
                case num2str([0,1]) % not in memory, want to load
                    status_icon = char(9633);
                case num2str([1,0]) % in memory, want to unload
                    status_icon = 'x';
                case num2str([1,1]) % in memory, want to load
                    status_icon = char(9632);
                otherwise
                    status_icon = '?';
            end
        end
        
        function status_icon = get_point_status_icon(obj, point_name)
            data_status = obj.point_data_status(point_name);
            stage_status = obj.point_stage_status(point_name);
            status_icon = obj.get_status_icon(data_status, stage_status);
        end
        
        function status_icon = get_channel_status_icon(obj, channel)
            data_status = obj.channel_data_status(channel);
            stage_status = obj.channel_stage_status(channel);
            status_icon = obj.get_status_icon(data_status, stage_status);
        end
        
        function obj = calc_knn(obj)
            point_names = obj.getNames();
            for i=1:numel(point_names)
                point_name = point_names{i};
                if obj.point_data_status(point_name)
                    point_path = obj.namesToPaths(point_name);
                    point = obj.pathsToPoints(point_path);
                    point.calc_knn();
                    obj.pathsToPoints(point_path) = point;
                end
            end
        end
        
        function obj = manage_memory(obj)
            point_names = obj.getNames();
            labels = obj.labels();
            for i=1:numel(point_names)
                point_name = point_names{i};
                point_path = obj.namesToPaths(point_name);
                point = obj.get('name', point_name);
                if obj.point_stage_status(point_name)==1
                    point.manage_memory(obj.channel_stage_status);
                else
                    point.flush_memory();
                end
                obj.pathsToPoints(point_path) = point;
            end
            disp(point_names)
            for i=1:numel(point_names)
                obj.point_data_status(point_names{i}) = obj.point_stage_status(point_names{i});
            end
            disp(obj.labels())
            for i=1:numel(labels)
                obj.channel_data_status(labels{i}) = obj.channel_stage_status(labels{i});
                disp(obj.channel_stage_status(labels{i}));
            end
        end
        
        function obj = set_point_stage_status(obj, point_names, status)
            for i=1:numel(point_names)
                point_name = point_names{i};
                obj.point_stage_status(point_name) = status;
            end
        end
        
        function obj = set_channel_stage_status(obj, channels, status)
            for i=1:numel(channels)
                channel = channels{i};
                obj.channel_stage_status(channel) = status;
            end
        end
        
        % given a path to a Point resource, adds a Point object
        function obj = addPoint(obj, pointPath, varargin)
            if ~obj.loaded('path', pointPath)
                point = Point(pointPath, 3, varargin{:});
                obj.namesToPaths(point.name) = pointPath;
                obj.pathsToNames(pointPath) = point.name;
                obj.pathsToPoints(pointPath) = point;
                obj.data_status.point_status(point.name) = 0;
                for i=1:numel(point.labels)
                    if ~isKey(obj.channel_data_status, point.labels{i})
                        obj.channel_data_status(point.labels{i}) = 0;
                        obj.channel_stage_status(point.labels{i}) = 0;
                    end
                    if ~isKey(obj.display_caps, point.labels{i})
                        obj.display_caps(point.labels{i}) = 5;
                    end
                end
                if ~isKey(obj.point_data_status, point.name)
                    obj.point_data_status(point.name) = 0;
                    obj.point_stage_status(point.name) = 0;
                end
            else
                % do nothing, the point has already been loaded
            end
        end
        
        function obj = add(obj, pointPaths, varargin)
            waitfig = waitbar(0, 'Loading TIFF data...');
            csvFail = '';
            for i=1:numel(pointPaths)
                obj.addPoint(pointPaths{i}, varargin{:});
                try
                    obj.addPoint(pointPaths{i}, varargin{:});
                catch err
                    csvFail = err.message;
                    break;
                end
                try
                    waitbar(i/numel(pointPaths), waitfig, 'Loading TIFF data...');
                catch
                    waitfig = waitbar(i/numel(pointPaths), 'Loading TIFF data...');
                end
            end
            close(waitfig);
            if ~obj.checkLabelSetEquality()
                warning('Not all loaded points have the same labels!')
            end
            if ~strcmp(csvFail, '')
                gui_warning(csvFail)
            end
            obj.initBgRmParams();
            obj.initDenoiseParams();
            obj.initAggRmParams();
            obj.initFFTRmParams();
        end
        
        function obj = remove(obj, argType, arg)
            if strcmp(argType, 'name')
                if obj.loaded('name', arg)
                    name = arg;
                    path = obj.namesToPaths(name);
                    
                    remove(obj.namesToPaths, name);
                    remove(obj.pathsToNames, path);
                    remove(obj.pathsToPoints, path);
                else
                    warning(['No point with name ', arg, ' found']);
                end
            elseif strcmp(argType, 'path')
                if obj.loaded('path', arg)
                    path = arg;
                    name = obj.pathsToNames(path);
                    
                    remove(obj.namesToPaths, name);
                    remove(obj.pathsToNames, path);
                    remove(obj.pathsToPoints, path);
                else
                    warning(['No point with path ', arg, ' found']);
                end
            else
                error('Invalid argType');
            end
            if isempty(keys(obj.pathsToPoints))
                obj.denoiseParams = {};
            end
        end

        % gets Point object by 
        function point = get(obj, argType, arg)
            if strcmp(argType, 'name')
                try
                    arg = tabSplit(arg);
                    arg = arg{1};
                    path = obj.namesToPaths(arg);
                    point = obj.pathsToPoints(path);
                catch
                    warning(['No point with name ', arg]);
                    point = [];
                end
            elseif strcmp(argType, 'path')
                try
                    point = obj.pathsToPoints(arg);
                catch
                    warning(['No point with path ', arg])
                    point = [];
                end
            else
                error('Invalid argType');
            end
        end
                
        % checks if name or path key exists
        function check = loaded(obj, argType, arg)
            if strcmp(argType, 'name')
                if any(strcmp(keys(obj.namesToPaths), arg))
                    path = obj.namesToPaths(arg);
                    if any(strcmp(keys(obj.pathsToPoints), path))
                        check = true;
                    else
                        check = false;
                    end
                else
                    check = false;
                end
            elseif strcmp(argType, 'path')
                if any(strcmp(keys(obj.pathsToPoints), arg))
                    check = true;
                else
                    check = false;
                end
            end
        end
        
        %% Some basic utility functions
        % returns a cell array of all names of loaded points, sorted in a
        % natural way (thank you Stephen Cobeldick!!!)
        
        function names = bgGetNames(obj)
            names = keys(obj.namesToPaths);
            for i=1:numel(names)
                point = obj.get('name', names{i});
                if ~point.inmemory
                    names{i} = ['~', names{i}];
                end
            end
        end
        
        function names = getNames(obj)
            names = keys(obj.namesToPaths);
            try
                names = natsortfiles(names);
            catch err
                names = {};
            end
        end
                
        function path = getPath(obj, name)
            if obj.loaded('name', name)
                path = obj.namesToPaths(name);
            else
                err0r(['Point ', name, ' not loaded, no path found'])
            end
        end
        
        function labels = getLabels(obj)
            paths = keys(obj.pathsToPoints);
            if ~isempty(paths)
                labels = obj.pathsToPoints(paths{1}).labels;
            else
                labels = {};
            end
        end
        
        function labels = labels(obj)
            paths = keys(obj.pathsToPoints);
            if ~isempty(paths)
                labels = obj.pathsToPoints(paths{1}).labels;
            else
                labels = {};
            end
        end
        
        function check = checkLabelSetEquality(obj)
            labels = obj.labels();
            check = true;
            if ~isempty(labels)
                paths = keys(obj.pathsToPoints);
                for i=1:numel(paths)
                    if ~isequal(labels, obj.pathsToPoints(paths{1}).labels)
                        check = false;
                    end
                end
            end
        end
        
        function datasize = get_data_size(obj)
            if ~isempty(obj.pathsToPoints)
                pointpaths = obj.pathsToPoints.keys();
                point = obj.pathsToPoints(pointpaths{1});
                datasize = size(point.counts);
            else
                error('No points are loaded');
            end
        end

        %% Initialize parameter functions        
        function obj = initBgRmParams(obj)
            if isempty(obj.bgRmParams)
                labels = obj.labels();
                max_name_length = 10;
                for i=1:numel(labels)
                    params = struct();
                    params.rm_value = 2;
                    params.label = labels{i};
                    params.display_name = labels{i}(1:(min(max_name_length, end)));
                    obj.bgRmParams{i} = params;
                end
            end
        end
        
        function obj = initDenoiseParams(obj)
            if isempty(obj.denoiseParams)
                labels = obj.labels();
                max_name_length = 10;
                for i=1:numel(labels)
                    params = struct();
                    params.dispcap = 20;
                    params.threshold = 3.5;
                    params.k_value = 25;
                    params.c_value = -1; % no value calculated yet, will be set to k_value when calculation done
                    params.label = labels{i};
                    params.status = 0;
                    params.loaded = 0;
                    params.display_name = labels{i}(1:(min(max_name_length, end)));
                    obj.denoiseParams{i} = params;
                end
            end
        end
        
        function obj = initAggRmParams(obj)
            if isempty(obj.aggRmParams)
                labels = obj.labels();
                max_name_length = 10;
                for i=1:numel(labels)
                    params = struct();
                    params.threshold = 100;
                    params.radius = 1;
                    params.capImage = 5;
                    params.label = labels{i};
                    params.display_name = labels{i}(1:(min(max_name_length, end)));
                    obj.aggRmParams{i} = params;
                end
            end
        end
        
        function obj = initFFTRmParams(obj)
            if isempty(obj.fftRmParams)
                labels = obj.labels();
                max_name_length = 10;
                for i=1:numel(labels)
                    params = struct();
                    params.blur = 0.001;
                    params.radius = 300;
                    params.scale = 1;
                    params.imagecap = 100;
                    params.label = labels{i};
                    params.display_name = labels{i}(1:(min(max_name_length, end)));
                    obj.fftRmParams{i} = params;
                end
            end
        end

        function obj = initEZ_SegmentParams(obj, init_channel)
            if isempty(obj.ez_segmentParams)
                
                params = struct();
                params.blur = 0;
                params.threshold = 10;
                params.minimum = 2;
                params.refine_threshold = 0;
                params.image_cap = 1000;
                % implement below later if rewriting underlying GUI (have everything run through PointManager instance)
                %params.data_channel = init_channel;
                %params.mask_channel = init_channel;
                %params.objects = [];

                obj.ez_segmentParams = params;
            end
        end
        
        %% Functions for interacting with parameters
        function channel_param = getBgRmParam(obj, label_index)
            channel_param = obj.bgRmParams{label_index};
        end
        
        function removeVals = getRemoveVals(obj)
            removeVals = zeros(size(obj.labels()));
            for i=1:numel(obj.labels())
                params = obj.getBgRmParam(i);
                removeVals(i) = params.rm_value;
            end
        end
        
        function channel_param = getDenoiseParam(obj, label_index)
            channel_param = obj.denoiseParams{label_index};
        end
        
        function channel_param = getAggRmParam(obj, label_index)
            channel_param = obj.aggRmParams{label_index};
        end
        
        function channel_param = getFFTRmParam(obj, label_index)
            channel_param = obj.fftRmParams{label_index};
        end
        
        function obj_param = getEZ_SegmentParams(obj)
            obj_param = obj.ez_segmentParams;
        end
        
        function obj = togglePointStatus(obj, pointName)
            point_path = obj.namesToPaths(pointName);
            point = obj.pathsToPoints(point_path);
            point.status = ~point.status;
            obj.pathsToPoints(point_path) = point;
        end
        
        function obj = setPointStatus(obj, pointName, status)
            point_path = obj.namesToPaths(pointName);
            point = obj.pathsToPoints(point_path);
            point.status = status;
            obj.pathsToPoints(point_path) = point;
        end
        
        function obj = setPointLoaded(obj, pointName, loaded)
            point_path = obj.namesToPaths(pointName);
            point = obj.pathsToPoints(point_path);
            point.loaded = loaded;
            obj.pathsToPoints(point_path) = point;
        end
        
        function obj = setBgRmParam(obj, label_index, param, varargin)
            if ~isempty(obj.bgRmParams)
                if strcmp(param, 'rm_value')
                    obj.bgRmParams{label_index}.rm_value = varargin{1};
                end
            end
        end
        
        function obj = setDenoiseParam(obj, label_index, param, varargin)
            if ~isempty(obj.denoiseParams)
                if strcmp(param, 'threshold')
                    obj.denoiseParams{label_index}.threshold = varargin{1};
                elseif strcmp(param, 'k_value')
                    obj.denoiseParams{label_index}.k_value = varargin{1};
                elseif strcmp(param, 'c_value')
                    obj.denoiseParams{label_index}.c_value = varargin{1};
                elseif strcmp(param, 'status')
                    if numel(varargin)==0
                        obj.denoiseParams{label_index}.status = ~obj.denoiseParams{label_index}.status;
                    else
                        obj.denoiseParams{label_index}.status = varargin{1};
                    end
                elseif strcmp(param, 'loaded')
                    obj.denoiseParams{label_index}.loaded = varargin{1};
                elseif strcmp(param, 'dispcap')
                    obj.denoiseParams{label_index}.dispcap = varargin{1};
                end
            end
        end
        
        function obj = setAggRmParam(obj, label_index, param, varargin)
            if ~isempty(obj.aggRmParams)
                if strcmp(param, 'threshold')
                    obj.aggRmParams{label_index}.threshold = varargin{1};
                elseif strcmp(param, 'radius')
                    obj.aggRmParams{label_index}.radius = varargin{1};
                elseif strcmp(param, 'capImage')
                    obj.aggRmParams{label_index}.capImage = varargin{1};
                else
                    % what did you do you monster
                end
            end
        end
        
        function obj = setFFTRmParam(obj, label_index, param, varargin)
            if ~isempty(obj.aggRmParams)
                if strcmp(param, 'blur')
                    obj.fftRmParams{label_index}.blur = varargin{1};
                elseif strcmp(param, 'radius')
                    obj.fftRmParams{label_index}.radius = varargin{1};
                elseif strcmp(param, 'scale')
                    obj.fftRmParams{label_index}.scale = varargin{1};
                elseif strcmp(param, 'imagecap')
                    obj.fftRmParams{label_index}.imagecap = varargin{1};
                else
                    % what did you do you monster
                end
            end
        end
        
        function obj = setEZ_SegmentParams(obj, param, varargin)
            if ~isempty(obj.ez_segmentParams)
                if strcmp(param, 'blur')
                    obj.ez_segmentParams.blur = varargin{1};
                elseif strcmp(param, 'threshold')
                    obj.ez_segmentParams.threshold = varargin{1};
                elseif strcmp(param, 'minimum')
                    obj.ez_segmentParams.minimum = varargin{1};
                elseif strcmp(param, 'refine_threshold')
                    obj.ez_segmentParams.refine_threshold = varargin{1};
                elseif strcmp(param, 'image_cap')
                    obj.ez_segmentParams.image_cap = varargin{1};
                % Implement during GUI rewrite later
                %elseif strcmp(param, 'data_channel')
                   %obj.ez_segmentParams.data_channel = varargin{1};
                %elseif strcmp(param, 'mask_channel')
                    %obj.ez_segmentParams.mask_channel = varargin{1};
                else
                    % what did you do you monster
                end
            end
        end
        
        %% Functions for getting listbox text
        function point_text = getPointText(obj, varargin)
            names = obj.getNames();
            point_text = cell(size(names));
            for i=1:numel(names)
                status = obj.pathsToPoints(obj.namesToPaths(names{i})).status;
                loaded = obj.pathsToPoints(obj.namesToPaths(names{i})).loaded;
                if status==0 && loaded==0
                    mark = '.';
                elseif status==0 && loaded==1
                    mark = 'x';
                elseif status==1 && loaded==0
                    mark = char(9633);
                elseif status==1 && loaded==1
                    mark = char(9632);
                else
                    mark = '?';
                end
                if numel(varargin)==1
                    mark = ' ';
                end
                point_text{i} = tabJoin({names{i}, mark}, 45);
            end
        end
        
        function bgRmParamsText = getBgRmText(obj, varargin)
            if isempty(varargin)
                if ~isempty(obj.bgRmParams)
                    bgRmParamsText = cell(size(obj.labels()));
                    for i=1:numel(obj.labels())
                        params = obj.bgRmParams{i};
                        
                        label = params.display_name;
                        rm_value = params.rm_value;
                        bgRmParamsText{i} = tabJoin({label, num2str(rm_value)}, 15);
                    end
                else
                    bgRmParamsText = {};
                end
            end
        end
        
        function titrationText = getTitrationText(obj, varargin)
            if ~isempty(obj.denoiseParams)
                titrationText = cell(size(obj.labels()));
                for i=1:numel(obj.labels())
                    params = obj.denoiseParams{i};

                    label = params.display_name;
                    if params.status==0 && params.loaded==0
                        mark = '.';
                    elseif params.status==0 && params.loaded==1
                        mark = 'x';
                    elseif params.status==1 && params.loaded==0
                        mark = char(9633);
                    elseif params.status==1 && params.loaded==1
                        mark = char(9632);
                    elseif params.status==-1
                        mark = '!';
                    else
                        mark = '?';
                    end
                    titrationText{i} = tabJoin({label, num2str(params.dispcap), mark}, 22);
                end
            else
                titrationText = {};
            end
        end
        
        function denoiseParamsText = getDenoiseText(obj, varargin)
            if isempty(varargin)
                if ~isempty(obj.denoiseParams)
                    denoiseParamsText = cell(size(obj.labels()));
                    for i=1:numel(obj.labels())
                        params = obj.denoiseParams{i};
                        
                        label = params.display_name;
                        threshold = params.threshold;
                        k_val = params.k_value;
                        if params.status==0 && params.loaded==0
                            mark = '.';
                        elseif params.status==0 && params.loaded==1
                            mark = 'x';
                        elseif params.status==1 && params.loaded==0
                            mark = char(9633);
                        elseif params.status==1 && params.loaded==1
                            mark = char(9632);
                        elseif params.status==-1
                            mark = '!';
                        else
                            mark = '?';
                        end
                        denoiseParamsText{i} = tabJoin({label, num2str(threshold), num2str(k_val), mark}, 15);
                    end
                else
                    denoiseParamsText = {};
                end
            else
                point_name = varargin{1};
                
            end
        end
        
        function aggRmParamsText = getAggRmText(obj, varargin)
            if isempty(varargin)
                if ~isempty(obj.aggRmParams)
                    aggRmParamsText = cell(size(obj.labels));
                    for i=1:numel(obj.labels())
                        params = obj.aggRmParams{i};
                        label = params.display_name;
                        threshold = params.threshold;
                        radius = params.radius;
                        capImage = params.capImage;
                        aggRmParamsText{i} = tabJoin({label, num2str(threshold), num2str(radius), num2str(capImage)}, 15);
                    end
                else
                    aggRmParamsText = {};
                end
            end
        end
        
        function fftRmParamsText = getFFTRmText(obj, varargin)
            if isempty(varargin)
                if ~isempty(obj.fftRmParams)
                    fftRmParamsText = cell(size(obj.labels));
                    for i=1:numel(obj.labels())
                        params = obj.fftRmParams{i};
                        label = params.display_name;
                        blur = params.blur;
                        radius = params.radius;
                        scale = params.scale;
                        fftRmParamsText{i} = tabJoin({label, num2str(blur), num2str(radius), num2str(scale)}, 15);
                    end
                else
                    fftRmParamsText = {};
                end
            end
        end
        
        % Implement during GUI/log rewrite
        function ez_segmentParamsText = getEZ_SegmentText(obj, varargin)
            if isempty(varargin)
                if ~isempty(obj.ez_segmentParams)
                    params = obj.ez_segmentParams;
                    blur = params.blur;
                    threshold = params.threshold;
                    minimum = params.minimum;
                    refine_threshold = params.refine_threshold;
                    image_cap = params.image_cap;
                    data_channel = params.data_channel;
                    mask_channel = params.mask_channel;
                    
                    ez_segmentParamsText = tabJoin({label, num2str(blur), num2str(threshold), num2str(minimum), num2str(refine_threshold)}, num2str(image_cap), data_channel, mask_channel, 15);
                else
                    ez_segmentParamsText = {};
                end
            end
        end
        
        function plotTiters(obj, label_index, varargin)
            pointpaths = obj.pathsToPoints.keys();
            for i=1:numel(pointpaths)
                pointpath = pointpaths{i};
                point = obj.pathsToPoints(pointpath);
                try
                    if isvalid(point.t_figure)
                        point.plotTiter(label_index, obj.denoiseParams{label_index}.dispcap);
                    end
                catch
                    
                end
            end
        end
        
        %% Functions for getting selected elements
        function point_names = getSelectedPointNames(obj)
            all_point_paths = keys(obj.pathsToPoints);
            point_names = {};
            for i=1:numel(all_point_paths)
                if obj.pathsToPoints(all_point_paths{i}).status == 1
                    point_names{end+1} = obj.pathsToPoints(all_point_paths{i}).name;
                end
            end
        end
        
        function label_indices = getSelectedLabelIndices(obj)
            label_indices = [];
            for i=1:numel(obj.labels())
                if obj.denoiseParams{i}.status == 1
                    label_indices(end+1) = i;
                end
            end
        end

        %% Data management functions 
        function obj = knn(obj, point_name, label, k_value)
            point_path = obj.namesToPaths(point_name);
            point = obj.pathsToPoints(point_path);
            point.knn(label, k_value);
            obj.setDenoiseParam(label, 'c_value', k_value);
            point.loaded = 1;
            obj.pathsToPoints(point_path) = point;
        end
        
        function obj = flush_data(obj)
            flush_indices = [];
            for i=1:numel(obj.denoiseParams)
                if obj.denoiseParams{i}.status==0 && obj.denoiseParams{i}.loaded==1
                    flush_indices(end+1) = i;
                    obj.setDenoiseParam(i, 'loaded', 0);
                end
            end
            % first we look through all points with status==0
            point_paths = keys(obj.pathsToPoints);
            for i=1:numel(point_paths)
                point = obj.pathsToPoints(point_paths{i});
                if point.status==0 && point.loaded==1
                    point.flush_all_data();
                    point.loaded = 0;
                    obj.pathsToPoints(point_paths{i}) = point;
                elseif point.status==1
                    point.flush_labels(flush_indices);
                    obj.pathsToPoints(point_paths{i}) = point;
                end
            end
        end
        
        function save_no_background(obj)
            global pipeline_data;
            bgChannel = pipeline_data.bgChannel;
            gausRad = pipeline_data.gausRad;
            t = pipeline_data.t;
            % removeVal = pipeline_data.removeVal;
            capBgChannel = pipeline_data.capBgChannel;
            capEvalChannel = pipeline_data.capEvalChannel;
            
            point_paths = keys(obj.pathsToPoints);
            if numel(point_paths)>=1
                [logpath, ~, ~] = fileparts(point_paths{1});
                [logpath, ~, ~] = fileparts(logpath);
                logpath = [logpath, filesep, 'no_background'];
                mkdir(logpath)
                timestring = strrep(datestr(datetime('now')), ':', char(720));
                fid = fopen([logpath, filesep, '[', timestring, ']_background_removal.log'], 'wt');
                fprintf(fid, 'background channel: %s\nbackground cap: %f\nevaluation cap: %f\ngaussian radius: %f\nthreshold: %f\n\n', bgChannel, capBgChannel, capEvalChannel, gausRad, t);
                for label_index=1:numel(obj.labels())
                    params = obj.getBgRmParam(label_index);
                    fprintf(fid, '%s {rm_val: %f}\n', params.label, params.rm_value);
                end
                fprintf(fid, '\n');
                waitfig = waitbar(0, 'Removing background...');
                for i=1:numel(point_paths)
                    waitbar(i/numel(point_paths), waitfig, ['Removing background from ', strrep(obj.pathsToNames(point_paths{i}), '_', '\_')]);
                    point = obj.pathsToPoints(point_paths{i});
                    point.save_no_background();
                    fprintf(fid, '%s\n', point_paths{i});
                end
                close(waitfig);
                fclose(fid);
                disp('Finished removing background.');
                gong = load('gong.mat');
                sound(gong.y, gong.Fs)
            end
        end
        
        function save_no_noise(obj)
            point_paths = keys(obj.pathsToPoints);
            if numel(point_paths)>=1
                [logpath, ~, ~] = fileparts(point_paths{1});
                [logpath, ~, ~] = fileparts(logpath);
                logpath = [logpath, filesep, 'no_noise'];
                mkdir(logpath)
                timestring = strrep(datestr(datetime('now')), ':', char(720));
                fid = fopen([logpath, filesep, '[', timestring, ']_noise_removal.log'], 'wt');
                all_labels = obj.labels();
                for i=1:numel(all_labels)
                    label = all_labels{i};
                    params = obj.getDenoiseParam(i);
                    if params.status~=0
                        fprintf(fid, [label, ': {', newline]);
                        fprintf(fid, [char(9), '  K-value: ', num2str(params.k_value), newline]);
                        fprintf(fid, [char(9), 'threshold: ', num2str(params.threshold), ' }', newline]); 
                    else % params.status==-1
                        fprintf(fid, [label, ': { not denoised }', newline]);
                    end
                end
                fprintf(fid, [newline, newline]);
                waitfig = waitbar(0, 'Removing noise...');
                for i=1:numel(point_paths)
                    waitbar(i/numel(point_paths), waitfig, ['Removing noise from ', strrep(obj.pathsToNames(point_paths{i}), '_', '\_')]);
                    point = obj.pathsToPoints(point_paths{i});
                    point.save_no_noise();
                    fprintf(fid, '%s\n', point_paths{i});
                end
                close(waitfig);
                fclose(fid);
                disp('Finished removing noise.');
                gong = load('gong.mat');
                sound(gong.y, gong.Fs)
            end
        end
        
        function save_denoise_params(obj)
            point_paths = keys(obj.pathsToPoints);
            if numel(point_paths)>=1
                [logpath, ~, ~] = fileparts(point_paths{1});
                [logpath, ~, ~] = fileparts(logpath);
                logpath = [logpath, filesep, 'no_noise'];
                mkdir(logpath)
                timestring = strrep(datestr(datetime('now')), ':', char(720));
                fid = fopen([logpath, filesep, '[', timestring, ']_noise_removal.log'], 'wt');
                all_labels = obj.labels();
                for i=1:numel(all_labels)
                    label = all_labels{i};
                    params = obj.getDenoiseParam(i);
                    fprintf(fid, [label, ': {', newline]);
                    fprintf(fid, [char(9), '  K-value: ', num2str(params.k_value), newline]);
                    fprintf(fid, [char(9), 'threshold: ', num2str(params.threshold), ' }', newline]);
                end
                fprintf(fid, [newline, newline]);
                for i=1:numel(point_paths)
                    fprintf(fid, '%s\n', point_paths{i});
                end
                fclose(fid);
            end
        end
        
        function save_no_aggregates(obj)
            point_paths = keys(obj.pathsToPoints);
            if numel(point_paths)>=1
                [logpath, ~, ~] = fileparts(point_paths{1});
                [logpath, ~, ~] = fileparts(logpath);
                logpath = [logpath, filesep, 'no_aggregates'];
                mkdir(logpath)
                timestring = strrep(datestr(datetime('now')), ':', char(720));
                fid = fopen([logpath, filesep, '[', timestring, ']_aggregate_removal.log'], 'wt');
                all_labels = obj.labels();
                for i=1:numel(all_labels)
                    label = all_labels{i};
                    params = obj.getAggRmParam(i);
                    fprintf(fid, [label, ': {', newline]);
                    fprintf(fid, [char(9), 'threshold: ', num2str(params.threshold), newline]); 
                    fprintf(fid, [char(9), 'radius: ', num2str(params.radius), ' }', newline]);
                end
                fprintf(fid, [newline, newline]);
                waitfig = waitbar(0, 'Removing aggregates...');
                for i=1:numel(point_paths)
                    waitbar(i/numel(point_paths), waitfig, ['Removing aggregates from ', strrep(obj.pathsToNames(point_paths{i}), '_', '\_')]);
                    point = obj.pathsToPoints(point_paths{i});
                    point.save_no_aggregates();
                    fprintf(fid, '%s\n', point_paths{i});
                end
                close(waitfig);
                fclose(fid);
                disp('Finished removing aggregates.');
                gong = load('gong.mat');
                sound(gong.y, gong.Fs)
            end
        end
        
        function save_no_fft_noise(obj)
            point_paths = keys(obj.pathsToPoints);
            if numel(point_paths)>=1
                [logpath, ~, ~] = fileparts(point_paths{1});
                [logpath, ~, ~] = fileparts(logpath);
                logpath = [logpath, filesep, 'no_fftnoise'];
                mkdir(logpath)
                timestring = strrep(datestr(datetime('now')), ':', char(720));
                fid = fopen([logpath, filesep, '[', timestring, ']_fft_noise_removal.log'], 'wt');
                all_labels = obj.labels();
                for i=1:numel(all_labels)
                    label = all_labels{i};
                    params = obj.getFFTRmParam(i);
                    fprintf(fid, [label, ': {', newline]);
                    fprintf(fid, [char(9), 'blur: ', num2str(params.blur), newline]); 
                    fprintf(fid, [char(9), 'radius: ', num2str(params.radius), newline]);
                    fprintf(fid, [char(9), 'scale: ', num2str(params.scale), ' }', newline]);
                end
                fprintf(fid, [newline, newline]);
                waitfig = waitbar(0, 'Removing noise...');
                for i=1:numel(point_paths)
                    waitbar(i/numel(point_paths), waitfig, ['Removing noise from ', strrep(obj.pathsToNames(point_paths{i}), '_', '\_')]);
                    point = obj.pathsToPoints(point_paths{i});
                    point.save_no_fftnoise();
                    fprintf(fid, '%s\n', point_paths{i});
                end
                close(waitfig);
                fclose(fid);
                disp('Finished removing noise.');
                gong = load('gong.mat');
                sound(gong.y, gong.Fs)
            end
        end
        
        % Implement during GUI/log rewrite
        function save_ez_segmenter(obj)
        end
        
        function run_name = suggest_run(obj)
            point_paths = keys(obj.pathsToPoints);
            runs = cell(size(point_paths));
            for i=1:numel(point_paths)
                if numel(point_paths)>=1
                    point = obj.pathsToPoints(point_paths{i});
                    runs{i} = point.check_run();
                end
            end
            if all(cellfun(@(x) strcmp(x, runs{1}), runs))
                run_name = runs{1};
            else
                run_name = runs;
            end
        end
        
        function opts = prep_opts(obj)
            
            % each point will keep track of it's own folder and point name
            % each will also find the run_path and panel_path, since they
            % have access to their folder
            
            % slide, size, run_label, instrument, tissue, aperture, and
            % output_directory
            opts = struct();
            opts.slide = obj.run_object.slide_ids.id;
            opts.size = obj.run_object.fov_size;
            opts.run_label = obj.run_object.label;
            
%             try
%                 instrument = obj.run_object.instrument.name;
%                 opts.instrument = instrument; catch
%             end
%             try
%                 tissue = obj.run_object.description;
%                 opts.tissue = tissue; catch
%             end
%             try
%                 aperture = obj.run_object.aperture.label;
%                 aperture = strsplit(aperture);
%                 aperture = aperture{1};
%                 opts.aperture = aperture; catch
%             end
            
        end
        
        function new_paths = save_ionpath_multitiff(obj, varargin)
            point_paths = keys(obj.pathsToPoints);
            waitfig = waitbar(0, 'Saving multi-page tiffs...');
            
            opts = obj.prep_opts();
            
            new_paths = {};
            for i=1:numel(point_paths)
                waitbar(i/numel(point_paths), waitfig, 'Saving multi-page tiffs...');
                point = obj.pathsToPoints(point_paths{i});
                % point.set_default_info();
                new_paths{i} = point.save_ionpath(opts, varargin{:});
            end
            close(waitfig);
        end
        
        function run_name = check_run_names(obj)
            point_paths = keys(obj.pathsToPoints);
            run_names = {};
            for i=1:numel(point_paths)
                point_path = point_paths{i};
                point = obj.pathsToPoints(point_path);
                run_names{i} = point.getRunName();
            end
            run_name = run_names{1};
            for i=1:numel(run_names)
                if ~strcmp(run_name, run_names{i})
                    error('Run names do not match');
                end
            end
        end
        
        function label_index = get_label_index(obj, label)
            paths = obj.pathsToPoints.keys();
            pointpath = paths{1};
            point = obj.pathsToPoints(pointpath);
            labels = point.labels;
            label_index = find(strcmp(label, labels));
        end
    end
end

