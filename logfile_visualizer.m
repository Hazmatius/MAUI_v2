%%
[logs_dict, points] = load_logfiles('/Users/raymondbaranski/Downloads/Denoising log files');

%%
timestamps = logs_dict.keys();
timestamps = sort(cellfun(@(x) str2double(x), timestamps));
timestamps = cellfun(@(x) num2str(x), num2cell(timestamps,1), 'UniformOutput', false);

% points = logs_dict(timestamps{1}).keys();

temp = logs_dict(timestamps{1});
labels = temp(points{1}).keys();

temp = temp(points{1}); temp = temp(labels{1});
params = temp.keys();

% 4d matrix of [timestamps x points x labels x params]
data = zeros(numel(timestamps), numel(points), numel(labels), numel(params));
for i=1:numel(timestamps)
    disp(timestamps{i});
    logfile = logs_dict(timestamps{i});
    for j=1:numel(points)
        point = logfile(points{j});
        for k=1:numel(labels)
            label = point(labels{k});
            for l=1:numel(params)
                param_val = label(params{l});
                data(i,j,k,l) = param_val;
            end
        end
    end
end

%% Fixing the logfile
datetimes = cellfun(@(x) char(datetime(str2double(x),'ConvertFrom','posixtime')), timestamps, 'UniformOutput', false);
newest_logfile = load_logfile('/Users/raymondbaranski/Downloads/Denoising log files/05-May-2020 15-58-12_denoising_params.log');
old_logfile = load_logfile('/Users/raymondbaranski/Downloads/Denoising log files/27-Apr-2020 17-18-45_denoising_params.log');

fixed_logfile = newest_logfile;

labels_to_fix = {'BCAT', 'CD3', 'CD4', 'CD8', 'CD31', 'CD45', 'CD56', 'CD57', 'CR45RO', 'FoxP3' 'HH3', 'HLA1', 'Ki67', 'MPO_Calp', 'NAKATPASE', 'PD1'};

% loop through all points
for i=1:numel(points)
    new_dict = fixed_logfile(points{i});
    old_dict = old_logfile(points{i});
    for j=1:numel(labels_to_fix)
        disp(labels_to_fix{j});
        disp(old_dict(labels_to_fix{j}));
        new_dict(labels_to_fix{j}) = old_dict(labels_to_fix{j});
    end
    fixed_logfile(points{i}) = new_dict;
end

save_logfile(fixed_logfile, '/Users/raymondbaranski/Desktop/fixed_logfile.log');

%%
ylabels = cellfun(@(x) char(datetime(str2double(x),'ConvertFrom','posixtime')), timestamps, 'UniformOutput', false);
xlabels = points;
xlabels = cellfun(@(x) strrep(x, '_', '\_'), xlabels, 'UniformOutput', false);
savefolder = '/Users/raymondbaranski/Desktop/figures_for_leeat/';

for i=1:numel(labels)
    f = figure('Name', labels{i}, 'NumberTitle', 'off');
    set(f, 'Position', [342   291   990   940]);
    imagesc(data(:,:,i,3)); title(['Thresholds for ', labels{i}]);
    yticks(1:numel(timestamps));
    yticklabels(ylabels);
    xticks(1:numel(xlabels));
    xticklabels(xlabels);
    xtickangle(65);
    savefig(f, [savefolder, labels{i}, '_thresholds']);
    close(f);
end

%%


function [logs_dict, point_names] = load_logfiles(log_folder)
    contents = dir(log_folder);
    contents(cellfun(@(x) strcmp(x(1), '.'), {contents.name})) = [];
    
    logs_dict = containers.Map;
    
    for i=1:numel(contents)
        timestamp = strrep(contents(i).name, '_denoising_params.log', '');
        timestamp([15,18]) = '::';
        timestamp = num2str(posixtime(datetime(timestamp)));
        disp(timestamp);
        [logs_dict(timestamp), point_names] = load_logfile([contents(i).folder, filesep, contents(i).name]);
    end
end

function [points_dict, point_names] = load_logfile(logfile_path)
    filetext = fileread(logfile_path);
    point_elements = strsplit(filetext, newline);
    
    points_dict = containers.Map;
    point_names = {};
    for i=1:numel(point_elements)
        point_element = point_elements{i};
        if ~isempty(point_element)
            point_element = strsplit(point_element, '::');
            point_path = point_element{1};
            if contains(point_path, '=>')
                point_path = strsplit(point_path, '=>');
                point_path = point_path{1};
            end

            [p_path, pointname, ~] = fileparts(point_path);
            pointname = [p_path, filesep, pointname];
            pointname = strsplit(pointname, filesep);
            len = 3;
            try
                pointname = pointname((end-len+1):end);
            catch
                % do nothing
            end
            pointname = strjoin(pointname, filesep);
            % try
            
            point = containers.Map;
            
            log_params = parse_json_map(point_element{2});
            log_labels = keys(log_params);
            
            for j=1:numel(log_labels)
                label = log_labels{j};
                logfile_params_struct = log_params(label);
                k_value = logfile_params_struct.k_value;
                threshold = logfile_params_struct.threshold;
                min_threshold = logfile_params_struct.min_threshold;
                
                params = containers.Map;
                params('k_value') = k_value;
                params('threshold') = threshold;
                params('min_threshold') = min_threshold;
                
                point(label) = params;
            end
            
            points_dict(pointname) = point;
            point_names{end+1} = pointname;
        end
    end
end

function save_logfile(logfile, filepath)
    data_folder = '/Users/lkeren/Documents/Cohort/';
    point_names = logfile.keys();
    logstring = '';

    for i=1:numel(point_names)
        point_name = point_names{i};
        pointlogstring = [data_folder, point_name, '::', jsonencode(logfile(point_name))];
        logstring = [logstring, pointlogstring, newline];
    end
    fid = fopen(filepath, 'wt');
    fprintf(fid, logstring);
    fclose(fid);
end