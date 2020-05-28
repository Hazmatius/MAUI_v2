classdef Point < handle
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        name
        point_path
        path_ext
        
        counts
        labels
        tags
        
        runinfo
        % for denoising
        int_norm_d
        k_values
        count_hist
        status
        loaded
        inmemory
        number
        % for titration
        t_figure
        figure_state = [-1, 0, -1]; % [channel_index, presence of histogram, cap_value]
        
        counts_dict;
        tags_dict;
        denoising_params;
        
        int_normd_dict;
        gmm_est_dict;
    end
    
    methods
        function obj = Point(point_path, len, varargin)
            obj.counts_dict = containers.Map;
            obj.tags_dict = containers.Map;
            obj.denoising_params = containers.Map;
            obj.int_normd_dict = containers.Map;
            obj.gmm_est_dict = containers.Map;
            
            load_data = numel(varargin)==0 || ~strcmp(varargin{1}, 'no_load');
            obj.labels = load_labels(point_path);
            for i=1:numel(obj.labels)
                obj.denoising_params(obj.labels{i}) = cell2struct({25;.5;3}, {'k_value';'threshold';'min_threshold'});
            end
            % note: it is assumed that the order of counts will correspond
            % to the labels.
            obj.t_figure = NaN;
            obj.point_path = point_path;
            
            if load_data
                [obj.counts, obj.labels, obj.tags, obj.path_ext, obj.runinfo] = loadTIFF_data(point_path);
                obj.inmemory = true;

                sizes = [numel(obj.labels), numel(obj.tags), numel(obj.runinfo.masses), size(obj.counts,3)];
                try
                    assert(all(sizes==sizes(1)));
                catch
                    disp(['obj.labels: ', num2str(numel(obj.labels))]);
                    disp(['obj.tags: ', num2str(numel(obj.tags))]);
                    disp(['obj.masses: ', num2str(numel(obj.runinfo.masses))]);
                    disp(['obj.counts: ', num2str(size(obj.counts,3))]);
                end
            else
                [obj.path_ext, obj.runinfo] = loadTIFF_info(point_path);
                obj.inmemory = false;
            end
            
            [path, name, ~] = fileparts(point_path);
            name = [path, filesep, name];
            name = strsplit(name, filesep);
            try
                name = name((end-len+1):end);
            catch
                % do nothing
            end
            obj.name = strjoin(name, filesep);
            obj.checkAllLabelsUnique();
            
            obj.int_norm_d = containers.Map;
            obj.count_hist = containers.Map;
            obj.k_values = [];
            if load_data
                for i=1:numel(obj.labels)
                    obj.k_values(i) = -1;
                end
            end
            obj.status = 0;
            obj.loaded = 0;
        end
        
        function knn_status_icon = get_knn_status_icon(obj, channel)
            if ~isKey(obj.int_normd_dict, channel)
                knn_status_icon = '';
            else
                knn_struct = obj.int_normd_dict(channel);
                params = obj.denoising_params(channel);
                if knn_struct.k_value==params.k_value
                    knn_status_icon = '-';
                else
                    knn_status_icon = '!';
                end
            end
        end
        
        function obj = set_params(obj, key, k_value, threshold, min_threshold)
            params = obj.denoising_params(key);
            params.k_value = k_value;
            params.threshold = threshold;
            params.min_threshold = min_threshold;
            obj.denoising_params(key) = params;
        end
        
        function obj = loadData_asdict(obj, varargin)
            [c_dict, ~, t_dict] = loadTIFF_data_asdict(obj.point_path, varargin{:});
            obj.counts_dict = [obj.counts_dict; c_dict];
            obj.tags_dict = [obj.tags_dict; t_dict];
            obj.inmemory = true;
        end
        
        function obj = loadData(obj)
            [obj.counts, obj.labels, obj.tags, obj.path_ext, obj.runinfo] = loadTIFF_data(obj.point_path);
            obj.inmemory = true;
        end
        
        function no_noise_data = get_no_noise_data(obj, label)
            raw_counts = obj.counts_dict(label);
            params = obj.denoising_params(label);
            intnormd = obj.int_normd_dict(label);
            no_noise_data = gui_MibiFilterImageByNNThreshold(raw_counts, intnormd.int_norm_d, params.threshold);
        end
        
        function knn_hist = get_knn_hist(obj, label)
            intnormd = obj.int_normd_dict(label);
            knn_hist = intnormd.knn_hist;
        end
        
        function k_value = get_kvalue(obj, label)
            k_value = obj.denoising_params(label).k_value;
        end
        
        function obj = set_kvalue(obj, label, k_value)
            params = obj.denoising_params(label);
            params.k_value = k_value;
            obj.denoising_params(label) = params;
        end
        
        function threshold = get_threshold(obj, label)
            threshold = obj.denoising_params(label).threshold;
        end
        
        function obj = set_threshold(obj, label, threshold)
            params = obj.denoising_params(label);
            params.threshold = threshold;
            obj.denoising_params(label) = params;
        end
        
        function min_threshold = get_min_threshold(obj, label)
            min_threshold = obj.denoising_params(label).min_threshold;
        end
        
        function obj = set_min_threshold(obj, label, min_threshold)
            params = obj.denoising_params(label);
            params.min_threshold = min_threshold;
            obj.denoising_params(label) = params;
        end
        
        function obj = optimize_threshold(obj, label)
            if isKey(obj.int_normd_dict, label)
                data = obj.int_normd_dict(label).int_norm_d;
                
                params = obj.denoising_params(label);
                defThresh = params.threshold;
                minThresh = params.min_threshold;
                
                prc99 = prctile(data,99);
                
                if prc99>defThresh
                    dataTrunc = data(data<=prc99);
                else
                    dataTrunc = data;
                end
                guess = ones(1,length(dataTrunc));
                sdataTrunc = sort(dataTrunc);
                if sdataTrunc(end) < defThresh % Only small values
                    guess([end-5:end]) = 2;
                elseif sdataTrunc(1) > defThresh % Only big values
                    guess([1:end])=2;
                    guess([1:5])=1;
                else % normal range
                    guess(sdataTrunc>defThresh) = 2;
                end
                [w, alpha, beta] = GMMestimatorGetIn(sdataTrunc,2,500,guess,1e-3,0);
                autoThresh = fzero(@(x) w(1)*gampdf(x,alpha(1),beta(1)) - w(2)*gampdf(x,alpha(2),beta(2)), mean([alpha(1)*beta(1),alpha(2)*beta(2)]));
                disp(['Suggested Threshold for ', label, ' on Point ', obj.name, ' : ', num2str(autoThresh)]);
                if autoThresh < minThresh; autoThresh = minThresh; end
                
                params.threshold = autoThresh;
                obj.denoising_params(label) = params;
                
                gmm_est_struct = struct();
                gmm_est_struct.w = w;
                gmm_est_struct.alpha = alpha;
                gmm_est_struct.beta = beta;
                obj.gmm_est_dict(label) = gmm_est_struct;
            else
                % warning(['There is no KNN distribution for ', label]);
            end
        end
            
        function obj = flush_memory(obj)
            for i=1:numel(obj.labels)
                label = obj.labels{i};
                if isKey(obj.counts_dict, label)
                    remove(obj.counts_dict, label);
                    remove(obj.tags_dict, label);
                    remove(obj.int_normd_dict, label);
                end
            end
        end
        
        function check = should_remove_noise(obj, label)
            check = obj.denoising_params(label).k_value~=-1;
        end
        
        function logstring = remove_noise(obj, timestamp)
            disp(['Denoising ', obj.name, '...']);
            obj.loadData_asdict();
            denoised_counts_dict = containers.Map;
            for i=1:numel(obj.labels)
                label = obj.labels{i};
                if obj.should_remove_noise(label)
                    disp(['    running KNN for ', label, '...']);
                    obj.calc_knn_for_label(label)
                    % disp(['    generating denoised ', label, '...']);
                    denoised_counts_dict(label) = obj.get_no_noise_data(label);
                else
                    try
                        disp(['    ', label, ' was skipped']);
                        denoised_counts_dict(label) = obj.counts_dict(label);
                    catch err
                        disp(err);
                        disp(label);
                    end
                end
            end
            [nn_counts, nn_labels, nn_tags] = matrices_from_maps(denoised_counts_dict, obj.labels, obj.tags_dict);
            
            [dir, pointname, ~] = fileparts(obj.point_path);
            point_path = [dir, filesep, pointname];
            path_parts = strsplit(point_path, filesep);
            path_parts{end-1} = ['no_noise_', timestamp];
            new_path = strjoin(path_parts, filesep);
            
            disp(['    saving ', obj.name, '...']);
            saveTIFF_folder(nn_counts, nn_labels, nn_tags, [new_path, filesep, obj.path_ext]);
            obj.flush_memory();
            logstring = [obj.point_path, '=>', new_path, '::', jsonencode(obj.denoising_params)];
        end
        
        function obj = manage_memory(obj, channel_stage_status)
            channels_to_load = {};
            for i=1:numel(obj.labels)
                label = obj.labels{i};
                % we don't want the data loaded but it is, so flush it
                if channel_stage_status(label)==0
                    if isKey(obj.counts_dict, label)
                        remove(obj.counts_dict, label);
                        remove(obj.tags_dict, label);
                        remove(obj.int_normd_dict, label);
                    end
                else
                    channels_to_load{end+1} = label;
                end
            end
            if ~isempty(channels_to_load)
                obj.loadData_asdict(channels_to_load);
            end
        end
        
        function obj = unloadData(obj)
            obj.counts = [];
            obj.labels = {};
            obj.tags = {};
            obj.path_ext = '';
            obj.runinfo = struct();
            obj.inmemory = false;
        end
        
        function plotTiter(obj, label_index, cap)
            name_parts = strsplit(obj.name, filesep);
            titer_name = name_parts{end};
            try
                if isvalid(obj.t_figure)
                    sfigure(obj.t_figure);
                else
                    obj.t_figure = sfigure();
                    set(obj.t_figure, 'NumberTitle', 'off');
                    set(obj.t_figure, 'name', titer_name);
                end
            catch
                obj.t_figure = sfigure();
                set(obj.t_figure, 'NumberTitle', 'off');
                set(obj.t_figure, 'name', titer_name');
            end
            subplot(2,1,1);
            if label_index~=obj.figure_state(1) || cap~=obj.figure_state(3)
                cappedImage = obj.counts(:,:,label_index);
                cappedImage(cappedImage>cap) = cap;
                imagesc(cappedImage); plotbrowser on;
                obj.figure_state(1) = label_index;
            end
            title(obj.name);
            label = obj.labels{label_index};
            subplot(2,1,2);
            if ~isempty(obj.count_hist) && any(strcmp(obj.count_hist.keys(), label)) && obj.loaded~=0
                hedges = 0:0.25:30;
                hedges = hedges(1:end-1);
                bar(hedges, obj.count_hist(label), 'histc');
                title([strrep(titer_name, '_', '\_'), ' : ', label, ' - histogram']);
            else
                cla;
                title('No histogram');
            end
        end
        
        function check = checkAllLabelsUnique(obj)
            if numel(unique(obj.labels))==numel(obj.labels)
                check = true;
            else
                check = false;
                warning('NOT ALL LABELS ARE UNIQUE')
            end
        end
        
        function obj = calc_knn_for_label(obj, label)
            disp(label);
            params = obj.denoising_params(label);
            data = obj.counts_dict(label);
            knn_struct = struct();
            knn_struct.k_value = params.k_value;
            
            donotrunknn_check = params.k_value~=-1;
            if isKey(obj.int_normd_dict, label)
                old_knn_struct = obj.int_normd_dict(label);
                if knn_struct.k_value == old_knn_struct.k_value
                    knnalreadyrun_check = 0;
                else
                    knnalreadyrun_check = 1;
                end
            else
                knnalreadyrun_check = 1;
            end
            if donotrunknn_check && knnalreadyrun_check 
                knn_struct.int_norm_d = MIBI_get_int_norm_dist(data, params.k_value);
                hedges = 0:0.25:30;
                knn_struct.knn_hist = histcounts(knn_struct.int_norm_d, hedges, 'Normalization', 'probability');
                obj.int_normd_dict(label) = knn_struct;
            end
        end
        
        function obj = calc_knn(obj)
            for i=1:numel(obj.labels)
                label = obj.labels{i};
                if isKey(obj.counts_dict, label)
                    obj.calc_knn_for_label(label);
                end
            end
        end
        
        function obj = knn(obj, label, k_value)
            if ischar(label)
                label_index = find(strcmp(obj.labels, label));
            else
                label_index = label;
            end
            label = obj.labels{label_index};
            if isempty(label_index)
                error([label, ' not found in labels']);
            else
                if k_value~=obj.k_values(label_index)
                    obj.int_norm_d(label) = MIBI_get_int_norm_dist(obj.counts(:,:,label_index), k_value);
                    hedges = 0:0.25:30;
                    obj.count_hist(label) = histcounts(obj.int_norm_d(label), hedges, 'Normalization', 'probability');
                    obj.k_values(label_index) = k_value;
                end
            end
        end
        
        function [int_norm_d, k_val] = get_IntNormD(obj, label)
            try
                int_norm_d = obj.int_norm_d(label);
            catch
                int_norm_d = [];
            end
            label_index = find(strcmp(label, obj.labels));
            k_val = obj.k_values(label_index);
        end
        
        function count_hist = get_countHist(obj, label)
            try
                count_hist = obj.count_hist(label);
            catch
                count_hist = [];
            end
        end
        
        function loadstatus = get_label_loadstatus(obj)
            loadstatus = zeros(size(obj.labels));
            for i=1:numel(obj.labels)
                if ~isequaln(obj.int_norm_d(obj.labels(i)), [])
                    loadstatus(i) = 1;
                end
            end
        end
        
        function obj = flush_all_data(obj)
            for i=1:numel(obj.labels)
                obj.k_values(i) = -1;
                obj.int_norm_d(obj.labels{i}) = [];
                obj.count_hist(obj.labels{i}) = [];
            end
        end
        
        function obj = flush_labels(obj, label_indices)
            for i=label_indices
                obj.k_values(i) = -1;
                obj.int_norm_d(obj.labels{i}) = [];
                obj.count_hist(obj.labels{i}) = [];
            end
        end
        
        function save_no_background(obj)
            global pipeline_data;
            if isempty(obj.counts)
                [obj.counts, obj.labels, obj.tags, obj.path_ext, obj.runinfo] = loadTIFF_data(obj.point_path);
            end
            bgChannel = pipeline_data.bgChannel;
            gausRad = pipeline_data.gausRad;
            t = pipeline_data.t;
            % removeVals = pipeline_data.removeVals;
            removeVals = pipeline_data.points.getRemoveVals();
            capBgChannel = pipeline_data.capBgChannel;
            capEvalChannel = pipeline_data.capEvalChannel;
            [~,bgChannelInd] = ismember(bgChannel,obj.labels);
            mask = MIBI_get_mask(obj.counts(:,:,bgChannelInd),capBgChannel,t,gausRad,0,'');
            countsNoBg = gui_MibiRemoveBackgroundByMaskAllChannels(obj.counts,mask,removeVals);
            
            [temp_dir, pointname, ~] = fileparts(obj.point_path);
            point_path = [temp_dir, filesep, pointname];
            path_parts = strsplit(point_path, filesep);
            path_parts{end-1} = 'no_background';
            new_path = strjoin(path_parts, filesep);
            if ~isempty(obj.path_ext)
                disp(['Saving to ', new_path, filesep, obj.path_ext])
                saveTIFF_folder(countsNoBg, obj.labels, obj.tags, [new_path, filesep, obj.path_ext]);
                save([new_path, filesep, 'dataNoBg.mat'],'countsNoBg');
            else
                disp(['Saving to ', new_path])
                saveTIFF_folder(countsNoBg, obj.labels, obj.tags, new_path);
                save([new_path, filesep, 'dataNoBg.mat'],'countsNoBg');
            end
            obj.counts = [];
        end
        
        function save_no_noise(obj)
            global pipeline_data;
            IntNormDData = cell(size(obj.labels));
            noiseT = zeros(size(obj.labels));
            for i=1:numel(obj.labels)
                try
                    IntNormDData{i} = obj.int_norm_d(obj.labels{i});
                catch
                    IntNormDData{i} = [];
                end
                noiseT(i) = pipeline_data.points.getDenoiseParam(i).threshold;
            end
            countsNoNoise = gui_MibiFilterAllByNN(obj.counts,IntNormDData,noiseT);
            
            [dir, pointname, ~] = fileparts(obj.point_path);
            point_path = [dir, filesep, pointname];
            path_parts = strsplit(point_path, filesep);
            path_parts{end-1} = 'no_noise';
            new_path = strjoin(path_parts, filesep);
            
            if ~isempty(obj.path_ext)
                disp(['Saving to ', new_path, filesep, obj.path_ext])
                saveTIFF_folder(countsNoNoise, obj.labels, obj.tags, [new_path, filesep, obj.path_ext]);
                save([new_path, filesep, 'dataNoNoise.mat'],'countsNoNoise');
            else
                disp(['Saving to ', new_path])
                saveTIFF_folder(countsNoNoise, obj.labels, obj.tags, new_path);
                save([new_path, filesep, 'dataNoNoise.mat'],'countsNoNoise');
            end
        end
        
        function save_no_aggregates(obj)
            global pipeline_data;
            countsNoAgg = zeros(size(obj.counts));
            for i=1:numel(obj.labels)
                params = pipeline_data.points.getAggRmParam(i);
                threshold = params.threshold;
                radius = params.radius;
                if radius==0
                    gausFlag = 0;
                else
                    gausFlag = 1;
                end
                countsNoAgg(:,:,i) = gui_MibiFilterAggregates(obj.counts(:,:,i),radius,threshold,gausFlag);
            end
            
            [dir, pointname, ~] = fileparts(obj.point_path);
            point_path = [dir, filesep, pointname];
            path_parts = strsplit(point_path, filesep);
            path_parts{end-1} = 'no_aggregates';
            new_path = strjoin(path_parts, filesep);
            
            if ~isempty(obj.path_ext)
                disp(['Saving to ', new_path, filesep, obj.path_ext])
                saveTIFF_folder(countsNoAgg, obj.labels, obj.tags, [new_path, filesep, obj.path_ext]);
                save([new_path, filesep, 'dataNoAgg.mat'],'countsNoAgg');
            else
                disp(['Saving to ', new_path])
                saveTIFF_folder(countsNoAgg, obj.labels, obj.tags, new_path);
                save([new_path, filesep, 'dataNoAgg.mat'],'countsNoAgg');
            end
        end
        
        function save_no_fftnoise(obj)
            global pipeline_data;
            countsNoNoise = zeros(size(obj.counts));
            for i=1:numel(obj.labels)
                params = pipeline_data.points.getFFTRmParam(i);
                gauss_blur_radius = params.blur;
                spectral_radius = params.radius;
                scaling_factor = params.scale;
                countsNoNoise(:,:,i) = gui_FFTfilter(obj.counts(:,:,i), gauss_blur_radius, spectral_radius, scaling_factor);
            end
            
            [dir, pointname, ~] = fileparts(obj.point_path);
            point_path = [dir, filesep, pointname];
            path_parts = strsplit(point_path, filesep);
            path_parts{end-1} = 'no_fftnoise';
            new_path = strjoin(path_parts, filesep);
            
            if ~isempty(obj.path_ext)
                disp(['Saving to ', new_path, filesep, obj.path_ext])
                saveTIFF_folder(countsNoNoise, obj.labels, obj.tags, [new_path, filesep, obj.path_ext]);
                save([new_path, filesep, 'dataNoFFTNoise.mat'],'countsNoNoise');
            else
                disp(['Saving to ', new_path])
                saveTIFF_folder(countsNoNoise, obj.labels, obj.tags, new_path);
                save([new_path, filesep, 'dataNoFFTNoise.mat'],'countsNoNoise');
            end
        end
        
        function new_path = save_ionpath(obj, opts, varargin)
            [temp_dir, pointname, ~] = fileparts(obj.point_path);
            [parent_dir, ~, ~] = fileparts(temp_dir);
            
            path_parts = strsplit([temp_dir, filesep, pointname], filesep);
            path_parts{end-1} = 'ionpath_multitiff';
            if numel(varargin)==1
                path_parts{end-1} = varargin{1};
            end
            new_path = strjoin(path_parts, filesep);
            disp(['Saving to ', new_path]);
            [path_to_multitiff, ~, ~] = fileparts(new_path);
            rmkdir(path_to_multitiff);
            
            input_folder = [obj.point_path, filesep, obj.path_ext];
            out = [new_path, '.tiff'];
            
            xmlPath = [parent_dir, filesep, 'info'];
            disp(xmlPath)
            xmlList = dir([xmlPath, filesep, '*.xml']);
            xmlList(find(cellfun(@isHiddenName, {xmlList.name}))) = [];
            if numel(xmlList)==1
                run_path = [xmlList.folder, filesep, xmlList.name];
            else
                error('no dice');
            end
            
            csvPath = [parent_dir, filesep, 'info'];
            csvList = dir(fullfile(csvPath, '*.csv'));
            csvList(find(cellfun(@isHiddenName, {csvList.name}))) = [];
            if numel(csvList)==1
                panel_path = [csvList.folder, filesep, csvList.name];
            else
                error('no dice');
            end
            
            opts.point = pointname;
            opts.input_folder = input_folder;
            opts.run_path = run_path;
            opts.panel_path = panel_path;
            opts.out = out;
            
            saveTIFF_mibi(opts);
            
            % saveTIFF_multi(obj.counts, obj.labels, obj.tags, new_path);
        end
        
        function add_composites(obj, new_name, new_counts, new_label_index, new_tags)
            %add name of new channel to labels, counts to counts, and tags
            obj.labels(new_label_index) = cellstr(new_name);
            obj.counts(:,:,new_label_index) = new_counts;
            obj.tags(new_label_index) = new_tags(1);
        end
        
        % There are a couple of steps we should follow in as ordered a
        % manner as possible
        % 1) we need to find the correct runobject from the tracker
        % 2) we need to create an ImageDescription tag if it doesn't
        % already exist
        % 3) we need to fill the ImageDescription object with the correct
        % point-specific information
        % we need to fill the ImageDescription object with the correct
        % channel-specific information
        % we need to modify the tags objects with the correct information

        function imgdsc = get_ImageDescription(obj, index, run_object, pointObj)
            % first check if there is already an ImageDescription
            if isfield(obj.tags{index}, 'ImageDescription')
                % if there is, we simply return it
                imgdsc = ImageDescription(obj.tags{index}.ImageDescription);
            else
                % otherwise we create a new ImageDescription
                imgdsc = ImageDescription();
                imgdsc.dict('mibi.run') = obj.runinfo.runxml.xmlname;
                imgdsc.dict('mibi.dwell') = pointObj.Depth_Profile.Attributes.AcquisitionTime;
                imgdsc.dict('mibi.description') = pointObj.Attributes.PointName;
                imgdsc.dict('mibi.folder') = ['Point', num2str(obj.number), '/RowNumber0/Depth_Profile0'];
                imgdsc.dict('mibi.panel') = obj.runinfo.panelname;
                imgdsc.dict('mibi.mass_offset') = pointObj.Depth_Profile.Attributes.MassOffset;
                imgdsc.dict('mibi.mass_gain') = pointObj.Depth_Profile.Attributes.MassGain;
                imgdsc.dict('mibi.time_resolution') = pointObj.Depth_Profile.Attributes.TimeResolution;
                imgdsc.dict('mibi.filename') = obj.runinfo.runxml.xmlname;
                imgdsc.dict('image.type') = 'SIMS';
                imgdsc.dict('mibi.version') = 'Alpha';
                imgdsc.dict('mibi.instrument') = run_object.instrument.name;
                imgdsc.dict('mibi.miscalibrated') = 'false';
                imgdsc.dict('mibi.check_reg') = 'false';
                imgdsc.dict('channel.mass') = num2str(obj.runinfo.masses(index));
                imgdsc.dict('channel.target') = ['"', obj.labels{index}, '"'];
                imgdsc.dict('shape') = ['[', num2str(size(obj.counts(:,:,index),1)), ', ', num2str(size(obj.counts(:,:,index),2)), ']'];
                imgdsc.encode();
            end
        end
        
        % image description manipulation functions
        function run_name = check_run(obj)
            runs = {};
            for i=1:numel(obj.tags)
                imgdsc = ImageDescription(obj.tags{i}.ImageDescription);
                imgdsc.decode();
                runs{i} = imgdsc.dict('mibi.run');
            end
            if all(cellfun(@(x) strcmp(x, runs{1}), runs))
                run_name = runs{1};
            else
                run_name = runs;
            end
        end
        
        function isthere = check_image_desc(obj)
            isthere = zeros(size(obj.labels));
            for i=1:numel(obj.labels)
                isthere(i) = isfield(obj.tags{i}, 'ImageDescription');
                if ~isthere(i)
                    imgdsc = ImageDescription();
                    imgdsc.encode();
                    obj.tags{i}.ImageDescription = imgdsc.descstr;
                end
            end
        end
        
        function run_name = getRunName(obj)
            run_name = obj.runinfo.runxml.xmlname;
        end
    end
end

