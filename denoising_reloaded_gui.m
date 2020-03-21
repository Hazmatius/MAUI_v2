function varargout = denoising_reloaded_gui(varargin)
% DENOISING_RELOADED_GUI MATLAB code for denoising_reloaded_gui.fig
%      DENOISING_RELOADED_GUI, by itself, creates a new DENOISING_RELOADED_GUI or raises the existing
%      singleton*.
%
%      H = DENOISING_RELOADED_GUI returns the handle to a new DENOISING_RELOADED_GUI or the handle to
%      the existing singleton*.
%
%      DENOISING_RELOADED_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in DENOISING_RELOADED_GUI.M with the given input arguments.
%
%      DENOISING_RELOADED_GUI('Property','Value',...) creates a new DENOISING_RELOADED_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before denoising_reloaded_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to denoising_reloaded_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help denoising_reloaded_gui

% Last Modified by GUIDE v2.5 18-Mar-2020 13:52:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @denoising_reloaded_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @denoising_reloaded_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before denoising_reloaded_gui is made visible.
function denoising_reloaded_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to denoising_reloaded_gui (see VARARGIN)
global pipeline_data;
json.startup;
pipeline_data = struct();
pipeline_data.points = PointManager();
pipeline_data.labels = {};
pipeline_data.figures = struct();
[rootpath, name, ext] = fileparts(mfilename('fullpath'));
options = json.read([rootpath, filesep, 'src', filesep, 'options.json']);
fontsize = options.fontsize;
pipeline_data.woahdude = imread([rootpath, filesep, 'src', filesep, 'gui_lib', filesep, 'resources', filesep, 'awaitinganalysis.png']);
warning('off', 'MATLAB:hg:uicontrol:StringMustBeNonEmpty');
warning('off', 'MATLAB:imagesci:tifftagsread:expectedTagDataFormat');
rootpath = strsplit(rootpath, filesep);
rootpath(end) = [];
rootpath = strjoin(rootpath, filesep);
pipeline_data.defaultPath = rootpath;
pipeline_data.figures = struct();
pipeline_data.figures.raw_data_figure = figure('Name', 'Raw data', 'NumberTitle', 'off');
pipeline_data.figures.denoised_data_figure = figure('Name', 'Denoised data', 'NumberTitle', 'off');
pipeline_data.figures.noise_diff_figure = figure('Name', 'Difference', 'NumberTitle', 'off');
pipeline_data.figures.histogram_figure = figure('Name', 'KNN-distribution', 'NumberTitle', 'off');
pipeline_data.point_indices = [NaN, NaN];
% Choose default command line output for denoising_reloaded_gui
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes denoising_reloaded_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = denoising_reloaded_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    try
        val = get(hObject,'value');
        set(handles.threshold_edit, 'string', num2str(val));
        set_threshold(handles, num2str(val));
        plot_data(handles);
    catch err
        disp(err)
    end
    update_channel_table(handles);

% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function display_cap_slider_Callback(hObject, eventdata, handles)
    global pipeline_data;
    try
        val = get(hObject,'value');
        set(handles.display_cap_edit, 'string', num2str(val));
        channels = getSelectedChannels(handles);
        for i=1:numel(channels)
            pipeline_data.points.display_caps(channels{i}) = displaycap;
        end
        plot_data(handles);
    catch err
        disp(err)
    end


% --- Executes during object creation, after setting all properties.
function display_cap_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to display_cap_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

function points = getSelectedPoints(handles)
    points = {};
    global pipeline_data;
    contents = get(handles.point_table, 'data');
    indices = pipeline_data.point_indices; index = indices(:,1);
    for i=1:numel(index)
        point_name = contents(index(i),2);
        points{end+1} = pipeline_data.points.get('name', point_name{1});
    end

function channels = getSelectedChannels(handles)
    global pipeline_data;
    channels = {};
    try
        contents = get(handles.channel_table, 'Data');
        indices = pipeline_data.channel_indices; index = indices(:,1);
        for i=1:numel(index)
            channels{end+1} = contents{index(i),2};
        end
    catch err
        
    end
    
function update_point_params(handles)
    try
        points = getSelectedPoints(handles);
        for j=1:numel(points)
            point = points{j};
            new_data = get(handles.channel_table, 'data');
            for i=1:numel(point.labels)
                label = new_data{i,2};
                k_value = new_data{i,3};
                threshold = new_data{i,4};
                min_threshold = new_data{i,5};
                point.set_params(label, k_value, threshold, min_threshold);
            end
        end
    catch err
        disp(err);
    end
    
function update_channel_table(handles)
    points = getSelectedPoints(handles);
    if numel(points)==1
        point = points{1};
        try
            old_data = get(handles.channel_table, 'data');
            for i=1:numel(point.labels)
                label = old_data{i,2};
                parameters = point.denoising_params(label);
                old_data{i,3} = parameters.k_value;
                old_data{i,4} = parameters.threshold;
                old_data{i,5} = parameters.min_threshold;
            end
            % disp(size(old_data,1));
            % color_data = zeros(size(old_data,1),3)+0.5;
            % set(handles.channel_table, 'BackgroundColor', color_data);
            
            set(handles.channel_table, 'data', old_data);
        catch err
            throw(err)
        end
    else
        old_data = get(handles.channel_table, 'data');
        labels = old_data{2,:};
        % disp(labels)
    end
    fix_sliders(handles);


% --- Executes on button press in add_points_button.
function add_points_button_Callback(hObject, eventdata, handles)
    % hObject    handle to add_points_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    pointdiles = uigetdiles(pipeline_data.defaultPath);
    if ~isempty(pointdiles)
        [pipeline_data.defaultPath, ~, ~] = fileparts(pointdiles{1});
        pipeline_data.points.add(pointdiles, 'no_load');
        point_names = pipeline_data.points.getNames();
        old_points_data = get(handles.point_table, 'Data');
        new_points_data = cell(numel(point_names, 2));
        for i=1:numel(point_names)
            point_name = point_names{i};
            try new_points_data{i,1} = old_points_data{i,2}; catch new_points_data{i,2} = 'x'; end
            new_points_data{i,2} = point_name;
        end
        set(handles.point_table, 'Data', new_points_data);
        
        labels = pipeline_data.points.getLabels();
        old_labels_data = get(handles.channel_table, 'Data');
        new_labels_data = cell(numel(labels), 4);
        for i=1:numel(labels)
            label = labels{i};
            try
                new_labels_data{i,1} = old_labels_data{i,2};
            catch
                new_labels_data{i,2} = 'x';
            end
            new_labels_data{i,2} = label;
        end
        set(handles.channel_table, 'Data', new_labels_data);
        % set(handles.points_listbox, 'string', pipeline_data.points.getPointText())
        % set(handles.points_listbox, 'max', numel(point_names));
        % denoise_text = pipeline_data.points.getDenoiseText();
        % set(handles.channels_listbox, 'string', denoise_text);
        % set(handles.channels_listbox, 'max', numel(denoise_text));
        % pipeline_data.labels = pipeline_data.points.labels();
        
        set(handles.run_knn_button, 'Visible', 'On');
        set(handles.point_table, 'Visible', 'On');
        set(handles.channel_panel, 'Visible', 'On');
        set(handles.load_data_button, 'Visible', 'On');
    end

% --- Executes on button press in run_knn_button.
function run_knn_button_Callback(hObject, eventdata, handles)
% hObject    handle to run_knn_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global pipeline_data;
disp('running knn');
pipeline_data.points.calc_knn();
update_channel_status_icons(handles);
update_point_status_icons(handles);


function load_selected_data(handles)
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    for i=1:numel(points)
        points{i}.loadData_asdict(channels);
    end

% --- Executes when selected cell(s) is changed in point_table.
function point_table_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to point_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
global pipeline_data;
if size(eventdata.Indices,1)~=0%  & (~all(size(pipeline_data.point_indices)==size(eventdata.Indices)) | ~all(pipeline_data.point_indices==eventdata.Indices))
    % disp('case 1');
    pipeline_data.point_indices = eventdata.Indices;
    update_channel_table(handles);
    update_channel_status_icons(handles);
    % disp(pipeline_data.point_indices(:,1))
    set_color(hObject, pipeline_data.point_indices(:,1), [0.5,0.8,0.8]);
    plot_data(handles);
    update_edit_boxes(handles)
else
    % disp('case 2');
    try
        % fix_table_selection(handles);
    catch
        
    end
end


% --- Executes when entered data in editable cell(s) in channel_table.
function channel_table_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to channel_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    update_point_params(handles);
    update_channel_status_icons(handles);
    fix_sliders(handles);
    plot_data(handles);

% --- Executes when selected cell(s) is changed in channel_table.
function channel_table_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to channel_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    if size(eventdata.Indices,1)~=0
        pipeline_data.channel_indices = eventdata.Indices;
        set_color(hObject, pipeline_data.channel_indices(:,1), [0.5,0.8,0.8]);
        % disp('hi'); % pipeline_data.channel_indices(:,1));
    end
    fix_sliders(handles);
    plot_data(handles);
    update_edit_boxes(handles);

% --- Executes on button press in load_data_button.
function load_data_button_Callback(hObject, eventdata, handles)
% hObject    handle to load_data_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    pipeline_data.points.manage_memory();
    update_point_status_icons(handles);
    update_channel_status_icons(handles);

function update_point_status_icons(handles)
    global pipeline_data;
    point_table_data = get(handles.point_table, 'data');
    point_names = point_table_data(:,2);
    for i=1:numel(point_names)
        status_icon = pipeline_data.points.get_point_status_icon(point_names{i});
        point_table_data{i,1} = status_icon;
    end
    set(handles.point_table, 'data', point_table_data);
    
function update_channel_status_icons(handles)
    global pipeline_data;
    points = getSelectedPoints(handles);
    if numel(points)==1
        point = points{1}; point_flag = true;
    else
        point_flag = false;
    end
    channel_table_data = get(handles.channel_table, 'data');
    channels = channel_table_data(:,2);
    for i=1:numel(channels)
        status_icon = pipeline_data.points.get_channel_status_icon(channels{i});
        if point_flag
            status_icon = [status_icon, point.get_knn_status_icon(channels{i})];
        end
        channel_table_data{i,1} = status_icon;
    end
    set(handles.channel_table, 'data', channel_table_data);

function update_status_icons(handles)
    global pipeline_data;
%     point_table_data = get(handles.point_table, 'data');
%     point_names = point_table_data(:,2);
%     for i=1:numel(point_names)
%         status_icon = pipeline_data.points.get_point_status_icon(point_names{i});
%         point_table_data{i,1} = status_icon;
%     end
%     set(handles.point_table, 'data', point_table_data);
    
    points = getSelectedPoints(handles);
    if numel(points)==1
        point = points{1}; point_flag = true;
    else
        point_flag = false;
    end
    channel_table_data = get(handles.channel_table, 'data');
    channels = channel_table_data(:,2);
    for i=1:numel(channels)
        status_icon = pipeline_data.points.get_channel_status_icon(channels{i});
        if point_flag
            status_icon = [status_icon, point.get_knn_status_icon(channels{i})];
        end
        channel_table_data{i,1} = status_icon;
    end
    set(handles.channel_table, 'data', channel_table_data);

% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% disp(eventdata.Key);
% if strcmp(eventdata.Key, 'enter')
%     disp('enter')


% --- Executes on key press with focus on point_table and none of its controls.
function point_table_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to point_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    points = getSelectedPoints(handles);
    point_names = cellfun(@(x) x.name, points, 'UniformOutput', false);
    if ~isempty(point_names)
        switch eventdata.Key
            case 's'
                pipeline_data.points.set_point_stage_status(point_names, 1);
                update_point_status_icons(handles);
            case 'd'
                pipeline_data.points.set_point_stage_status(point_names, 0);
                update_point_status_icons(handles);
        end
    end


% --- Executes on key press with focus on channel_table and none of its controls.
function channel_table_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to channel_table (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    channels = getSelectedChannels(handles);
    if ~isempty(channels)
        switch eventdata.Key
            case 's'
                pipeline_data.points.set_channel_stage_status(channels, 1);
                update_channel_status_icons(handles);
            case 'd'
                pipeline_data.points.set_channel_stage_status(channels, 0);
                update_channel_status_icons(handles);
        end
    end

function fix_table_selection(handles)
    global pipeline_data;
    % disp(pipeline_data.point_indices);
    point_row = pipeline_data.point_indices(:,1);
    point_col = pipeline_data.point_indices(:,2);
    % disp(point_row)
    point_jUIScrollPane = findjobj(handles.point_table);
    point_jUITable = point_jUIScrollPane.getViewport.getView;
    point_jUITable.changeSelection(point_row-1,point_col-1, false, false);
    % disp(pipeline_data.channel_indices)
    channel_row = pipeline_data.channel_indices(:,1);
    channel_col = pipeline_data.channel_indices(:,2);
    channel_jUIScrollPane = findjobj(handles.channel_table);
    channel_jUITable = channel_jUIScrollPane.getViewport.getView;
    channel_jUITable.changeSelection(channel_row-1,channel_col-1, false, false);
    
function plot_images(point, channel)
    global pipeline_data;
    if ~isvalid(pipeline_data.figures.raw_data_figure)
        pipeline_data.figures.raw_data_figure = figure('Name', 'Raw data', 'NumberTitle', 'off');
    end
    if ~isvalid(pipeline_data.figures.denoised_data_figure)
        pipeline_data.figures.denoised_data_figure = figure('Name', 'Denoised data', 'NumberTitle', 'off');
    end
    if ~isvalid(pipeline_data.figures.noise_diff_figure)
        pipeline_data.figures.noise_diff_figure = figure('Name', 'Difference', 'NumberTitle', 'off');
    end
    if ~isvalid(pipeline_data.figures.histogram_figure)
        pipeline_data.figures.histogram_figure = figure('Name', 'KNN-distribution', 'NumberTitle', 'off');
    end
    
    try
        sfigure(pipeline_data.figures.raw_data_figure);
        raw_data = point.counts_dict(channel);
        colormap(parula);
        imagesc(raw_data); axis off; title(['Raw ', channel, ' on ', strrep(point.name, '_', '\_')]);
        caxis([0, min(pipeline_data.points.display_caps(channel), max(raw_data(:)))]);
        
        try
            sfigure(pipeline_data.figures.denoised_data_figure);
            no_noise_data = point.get_no_noise_data(channel);
            colormap(parula);
            imagesc(no_noise_data); axis off; title(['Denoised ', channel, ' on ', strrep(point.name, '_', '\_')]);
            caxis([0, min(pipeline_data.points.display_caps(channel), max(raw_data(:)))]);

            sfigure(pipeline_data.figures.noise_diff_figure);
            diff_data = raw_data - no_noise_data;
            colormap(parula);
            imagesc(diff_data); axis off; title(['Noise ', channel, ' on ', strrep(point.name, '_', '\_')]);
        catch
            sfigure(pipeline_data.figures.denoised_data_figure); clf;
            sfigure(pipeline_data.figures.noise_diff_figure); clf;
        end
    catch err
        % disp(err)
        sfigure(pipeline_data.figures.raw_data_figure); clf;
        sfigure(pipeline_data.figures.denoised_data_figure); clf;
        sfigure(pipeline_data.figures.noise_diff_figure); clf;
        sfigure(pipeline_data.figures.histogram_figure); clf;
    end
    
function plot_data(handles)
    global pipeline_data;
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    if numel(channels)==1
        if numel(points)==1
            plot_images(points{1}, channels{1});
            try
                knn_hist = points{1}.get_knn_hist(channels{1});
                sfigure(pipeline_data.figures.histogram_figure); clf;
                hold on;
                hedges = 0:0.25:30; hedges = hedges(1:end-1);
                % bar(hedges, knn_hist, 'histc');
                plot(hedges, knn_hist);
                threshold = get_current_threshold(handles);
                min_threshold = get_current_min_threshold(handles);
                if isKey(points{1}.gmm_est_dict, channels{1})
                    gmm_est_struct = points{1}.gmm_est_dict(channels{1});
                    w = gmm_est_struct.w;
                    alpha = gmm_est_struct.alpha;
                    beta = gmm_est_struct.beta;
                    plot(hedges,w(1)*gampdf(hedges,alpha(1),beta(1)),'b');
                    plot(hedges,w(2)*gampdf(hedges,alpha(2),beta(2)),'r');
                end
                if ~strcmp(threshold, 'multiple')
                    lim = ylim;
                    plot([threshold, threshold], [0, lim(2)], 'Color', [1,0.5,0], 'LineWidth', 1);
                    plot([min_threshold, min_threshold], [0, lim(2)], 'Color', [0,0,0], 'LineWidth', 1);
                end
                hold off;
            catch err
                % disp(err);
            end
        else
            sfigure(pipeline_data.figures.raw_data_figure); clf;
            sfigure(pipeline_data.figures.noise_diff_figure); clf;
            sfigure(pipeline_data.figures.denoised_data_figure); clf;
            sfigure(pipeline_data.figures.histogram_figure); clf;
            try
                hold on;
                hedges = 0:0.25:30; hedges = hedges(1:end-1);
                point_names = cell(size(points));
                for i=1:numel(points)
                    point_names{i} = strrep(points{i}.name, '_', '\_');
                    knn_hist = points{i}.get_knn_hist(channels{1});
                    plot(hedges, knn_hist, 'DisplayName', points{i}.name);
                end
                threshold = get_current_threshold(handles);
                if ~strcmp(threshold, 'multiple')
                    lim = ylim;
                    plot([threshold, threshold], [0, lim(2)], 'r');
                end
                hold off;
                legend(point_names{:});
            catch
                
            end
        end
    end
    
function set_color(handle, rows, color)
    data = get(handle, 'data');
    color = repmat(color,numel(rows),1);
    background_color = ones(size(data,1),3);
    background_color(rows,:) = color;
    set(handle, 'BackgroundColor', background_color);
    
function k_value = get_current_kvalue(handles)
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    k_values = zeros(numel(points)*numel(channels),1);
    index = 1;
    for i=1:numel(points)
        for j=1:numel(channels)
            k_values(index) = points{i}.get_kvalue(channels{j});
            index = index + 1;
        end
    end
    if numel(k_values)==0
        k_value = '';
    else
        if all(k_values==k_values(1))
            k_value = k_values(1);
        else
            k_value = 'multiple';
        end
    end
    
function set_kvalue(handles, value)
    if ~isnan(str2double(value))
        value = str2double(value);
        points = getSelectedPoints(handles);
        channels = getSelectedChannels(handles);
        for i=1:numel(points)
            for j=1:numel(channels)
                points{i}.set_kvalue(channels{j}, value);
            end
        end
    else
        error('Threshold value must be a number');
    end
    
function threshold = get_current_threshold(handles)
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    threshold_values = zeros(numel(points)*numel(channels),1);
    index = 1;
    for i=1:numel(points)
        for j=1:numel(channels)
            threshold_values(index) = points{i}.get_threshold(channels{j});
            index = index + 1;
        end
    end
    if numel(threshold_values)==0
        threshold = '';
    else
        if all(threshold_values==threshold_values(1))
            threshold = threshold_values(1);
        else
            threshold = 'multiple';
        end
    end
    
function set_threshold(handles, value)
    if ~isnan(str2double(value))
        value = str2double(value);
        points = getSelectedPoints(handles);
        channels = getSelectedChannels(handles);
        for i=1:numel(points)
            for j=1:numel(channels)
                points{i}.set_threshold(channels{j}, value);
            end
        end
    else
        error('Threshold value must be a number');
    end

function min_threshold = get_current_min_threshold(handles)
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    min_threshold_values = zeros(numel(points)*numel(channels),1);
    index = 1;
    for i=1:numel(points)
        for j=1:numel(channels)
            min_threshold_values(index) = points{i}.get_min_threshold(channels{j});
            index = index + 1;
        end
    end
    if numel(min_threshold_values)==0
        min_threshold = '';
    else
        if all(min_threshold_values==min_threshold_values(1))
            min_threshold = min_threshold_values(1);
        else
            min_threshold = 'multiple';
        end
    end
    
function set_min_threshold(handles, value)
    if ~isnan(str2double(value))
        value = str2double(value);
        points = getSelectedPoints(handles);
        channels = getSelectedChannels(handles);
        for i=1:numel(points)
            for j=1:numel(channels)
                points{i}.set_min_threshold(channels{j}, value);
            end
        end
    else
        error('Threshold value must be a number');
    end
        
function displaycap = get_current_displaycap(handles)
    global pipeline_data;
    channels = getSelectedChannels(handles);
    displaycap_values = zeros(numel(channels),1);
    index = 1;
    for j=1:numel(channels)
        displaycap_values(index) = pipeline_data.points.display_caps(channels{j});
        index = index + 1;
    end
    if numel(displaycap_values)==0
        displaycap = '';
    else
        if all(displaycap_values==displaycap_values(1))
            displaycap = displaycap_values(1);
        else
            displaycap = 'multiple';
        end
    end
    
% --- Executes on button press in threshold_button.
function threshold_button_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    defaults = {num2str(get(handles.threshold_slider, 'min')), num2str(get(handles.threshold_slider, 'max'))};
    vals = inputdlg({'Threshold minimum', 'Threshold maximum'}, 'Threshold range', 1, defaults);
    try
        vals = str2double(vals);
        if vals(2)>vals(1)
            value = get(handles.threshold_slider, 'value');
            if value<vals(1) % value less than minimum
                value = vals(1);
            elseif value>vals(2) % value greater than maximum
                value = vals(2);
            else
                % value is fine
            end
            set(handles.threshold_slider, 'min', vals(1));
            set(handles.threshold_slider, 'max', vals(2));
            set(handles.threshold_slider, 'value', value);
            set(handles.threshold_edit, 'string', value);
            % setThresholdParam(handles);
            % plotDenoisingParams(handles);
        else
            gui_warning('Threshold maximum must be greater than threshold minimum');
        end
    catch
        % do nothing
    end
    
function update_edit_boxes(handles)
    threshold = get_current_threshold(handles);
    set(handles.threshold_edit, 'string', threshold);
    try set(handles.threshold_slider, 'value', threshold); catch; end
    
    k_value = get_current_kvalue(handles);
    set(handles.kvalue_edit, 'string', k_value);
    
    displaycap = get_current_displaycap(handles);
    set(handles.display_cap_edit, 'string', displaycap);
    try set(handles.display_cap_slider, 'value', displaycap); catch; end
    
    min_threshold = get_current_min_threshold(handles);
    set(handles.min_threshold_edit, 'string', min_threshold);

function threshold_edit_Callback(hObject, eventdata, handles)
% hObject    handle to threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of threshold_edit as text
%        str2double(get(hObject,'String')) returns contents of threshold_edit as a double
set_threshold(handles, get(hObject, 'string'));
threshold = str2double(get(hObject, 'string'));
update_channel_table(handles);
if threshold > get(handles.threshold_slider, 'max')
    set(handles.threshold_slider, 'max', threshold);
end
set(handles.threshold_slider, 'value', threshold);
% set the slider
plot_data(handles);

% --- Executes during object creation, after setting all properties.
function threshold_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function display_cap_edit_Callback(hObject, eventdata, handles)
    global pipeline_data;
    displaycap = get(hObject, 'string');
    if ~isnan(str2double(displaycap))
        displaycap = str2double(displaycap);
        channels = getSelectedChannels(handles);
        for i=1:numel(channels)
            pipeline_data.points.display_caps(channels{i}) = displaycap;
        end
        if displaycap>get(handles.display_cap_slider, 'max')
            set(handles.display_cap_slider, 'max', displaycap);
        end
        set(handles.display_cap_slider, 'value', displaycap);
    else
        set(hObject, 'string', '5');
    end
    plot_data(handles);

% --- Executes during object creation, after setting all properties.
function display_cap_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to display_cap_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function kvalue_edit_Callback(hObject, eventdata, handles)
% hObject    handle to kvalue_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of kvalue_edit as text
%        str2double(get(hObject,'String')) returns contents of kvalue_edit as a double
    set_kvalue(handles, get(hObject, 'string'));
    update_channel_table(handles);
    plot_data(handles);

% --- Executes during object creation, after setting all properties.
function kvalue_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to kvalue_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in opt_thresholds_button.
function opt_thresholds_button_Callback(hObject, eventdata, handles)
    points = getSelectedPoints(handles);
    channels = getSelectedChannels(handles);
    question = 'Would you like to optimize thresholds for ';
    for j=1:numel(channels)
        question = [question, channels{j}, ', '];
    end
    question = [question(1:(end-2)), '?'];
    answer = questdlg(question, 'Yes', 'No');
    switch answer
        case 'Yes'
            for i=1:numel(points)
                for j=1:numel(channels)
                    points{i}.optimize_threshold(channels{j});
                end
            end
    end
    
    update_channel_table(handles);

% --- Executes on button press in denoise_button.
function denoise_button_Callback(hObject, eventdata, handles)
% hObject    handle to denoise_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    point_names = pipeline_data.points.getNames();
    for i=1:numel(point_names)
        point = pipeline_data.points.get('name', point_names{i});
        point.flush_memory();
    end

    timestring = ['[', strrep(datestr(datetime('now')), ':', char(720)), ']'];
    logstring = '';

    point_paths = keys(pipeline_data.points.pathsToPoints);
    [logpath, ~, ~] = fileparts(point_paths{1});
    [logpath, ~, ~] = fileparts(logpath);
    logpath = [logpath, filesep, 'no_noise_', timestring];
    mkdir(logpath)

    for i=1:numel(point_names)
        point = pipeline_data.points.get('name', point_names{i});
        logstring = [logstring, point.remove_noise(timestring), newline];
    end
    fid = fopen([logpath, filesep, '[', timestring, ']_noise_removal.log'], 'wt');
    fprintf(fid, logstring);
    fclose(fid);

% --- Executes on button press in load_params_button.
function load_params_button_Callback(hObject, eventdata, handles)
    % hObject    handle to load_params_button (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    [file,p_path] = uigetfile('.log');
    filetext = fileread([p_path,file]);
    point_elements = strsplit(filetext, newline);
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
            disp(pointname);
            point = pipeline_data.points.get('name', pointname);
            disp([pointname, ' found, attempting to load denoising parameters...']);
            log_params = parse_json_map(point_element{2});
            log_labels = keys(log_params);
            point_labels = point.labels;
            common_labels = intersect(log_labels, point_labels);
            labels_missing_from_point = setdiff(log_labels, common_labels);
            labels_missing_from_logfile = setdiff(point_labels, common_labels);
            if ~isempty(labels_missing_from_point)
                for j=1:numel(labels_missing_from_point)
                    disp(['    Could not find ', labels_missing_from_point{j}, ' in loaded points, ignoring and proceeding.']);
                end
            end
            if ~isempty(labels_missing_from_logfile)
                for j=1:numel(labels_missing_from_logfile)
                    disp(['    Could not find ', labels_missing_from_logfile{j}, ' in selected logfile, ignoring and proceeding.']);
                end
            end
            for j=1:numel(common_labels)
                label = common_labels{j};
                logfile_params_struct = log_params(label);
                k_value = logfile_params_struct.k_value;
                threshold = logfile_params_struct.threshold;
                min_threshold = logfile_params_struct.min_threshold;
                point.set_kvalue(label, k_value);
                point.set_threshold(label, threshold);
                point.set_min_threshold(label, min_threshold);
            end
        end
    end
    update_channel_table(handles);
    

function min_threshold_edit_Callback(hObject, eventdata, handles)
    set_min_threshold(handles, get(hObject, 'string'));
    update_channel_table(handles);
    plot_data(handles);

% --- Executes during object creation, after setting all properties.
function min_threshold_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to min_threshold_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in save_parameters_button.
function save_parameters_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_parameters_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    timestring = strrep(datestr(datetime('now')), ':', '-');
    [file,path] = uiputfile([timestring, '_denoising_params.log']);
    filepath = [path, file];
    point_names = pipeline_data.points.getNames();
    logstring = '';

    for i=1:numel(point_names)
        point = pipeline_data.points.get('name', point_names{i});
        pointlogstring = [point.point_path, '::', jsonencode(point.denoising_params)];
        logstring = [logstring, pointlogstring, newline];
    end
    fid = fopen(filepath, 'wt');
    fprintf(fid, logstring);
    fclose(fid);

function fix_sliders(handles)
    value = get(handles.threshold_slider, 'value');
    if value<get(handles.threshold_slider, 'min')
        set(handles.threshold_slider, 'min', value);
    elseif value>get(handles.threshold_slider, 'max')
        set(handles.threshold_slider, 'max', value);
    end
    
    value = get(handles.display_cap_slider, 'value');
    if value<get(handles.display_cap_slider, 'min')
        set(handles.display_cap_slider, 'min', value);
    elseif value>get(handles.display_cap_slider, 'max')
        set(handles.display_cap_slider, 'max', value);
    end