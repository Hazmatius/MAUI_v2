function varargout = denoising_gui(varargin)
    % DENOISING_GUI MATLAB code for denoising_gui.fig
    %      DENOISING_GUI, by itself, creates a new DENOISING_GUI or raises the existing
    %      singleton*.
    %
    %      H = DENOISING_GUI returns the handle to a new DENOISING_GUI or the handle to
    %      the existing singleton*.
    %
    %      DENOISING_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in DENOISING_GUI.M with the given input arguments.
    %
    %      DENOISING_GUI('Property','value',...) creates a new DENOISING_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before denoising_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to denoising_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help denoising_gui

    % Last Modified by GUIDE v2.5 04-Mar-2019 13:10:35

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @denoising_gui_OpeningFcn, ...
                       'gui_OutputFcn',  @denoising_gui_OutputFcn, ...
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


% --- Executes just before denoising_gui is made visible.
function denoising_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to denoising_gui (see VARARGIN)
    global pipeline_data;
    json.startup;
    pipeline_data = struct();
    pipeline_data.points = PointManager();
    pipeline_data.labels = {};
    pipeline_data.figures = struct();
    
    pipeline_data.figures.beforeFigure = NaN;
    pipeline_data.figures.afterFigure = NaN;
    pipeline_data.figures.diffFigure = NaN;
    
    pipeline_data.figures.histFigure = NaN;
    % Choose default command line output for denoising_gui
    handles.output = hObject;
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
    % Update handles structure
    guidata(hObject, handles);
    
    set(handles.points_listbox, 'KeyPressFcn', {@points_listbox_keypressfcn, {eventdata, handles}});
    set(handles.channels_listbox, 'KeyPressFcn', {@channels_listbox_keypressfcn, {eventdata, handles}});
    setUIFontSize(handles, fontsize)

% UIWAIT makes denoising_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = denoising_gui_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;


function fix_handle(handle)
    try
        if get(handle, 'value') > numel(get(handle, 'string'))
            set(handle, 'value', numel(get(handle, 'string')));
        end
        if isempty(get(handle, 'string'))
            set(handle, 'string', '');
            set(handle, 'value', 1)
        end
        if ~isnumeric(get(handle, 'value'))
            set(handle, 'value', 1)
        end
    catch
        
    end

function fix_menus_and_lists(handles)
    fix_handle(handles.points_listbox);
    fix_handle(handles.channels_listbox);

function point_names = getPointNames(handles)
    contents = cellstr(get(handles.points_listbox,'string'));
    point_idx = get(handles.points_listbox,'value');
    if isempty(contents)
        point_names = [];
    else
        point_names = contents(point_idx);
    end
    for i=1:numel(point_names)
        point_names{i} = tabSplit(point_names{i});
        point_names{i} = point_names{i}{1};
    end

function channel_params = getChannelParams(handles)
    global pipeline_data;
    label_index = get(handles.channels_listbox,'value');
    channel_params = pipeline_data.points.getDenoiseParam(label_index);

function setThresholdParam(handles)
    global pipeline_data;
    label_index = get(handles.channels_listbox,'value'); 
    threshold = str2double(get(handles.threshold_edit, 'string'));
    pipeline_data.points.setDenoiseParam(label_index, 'threshold', threshold);
    set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
    
function setDispcapParam(handles)
    global pipeline_data;
    label_index = get(handles.channels_listbox,'value');
    dispcap = str2double(get(handles.dispcap_edit, 'string'));
    pipeline_data.points.setDenoiseParam(label_index, 'dispcap', dispcap);
    
function setKValParam(handles)
    global pipeline_data;
    k_val = str2double(get(handles.k_val_edit, 'string'));
    label_indices = get(handles.channels_listbox, 'value');
    if numel(label_indices)>0
        for index = label_indices
            pipeline_data.points.setDenoiseParam(index, 'k_value', k_val);
        end
    end
    set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
    
function plotDenoisingParams(handles)
    global pipeline_data;
    label_index = get(handles.channels_listbox,'value');
    point_name = getPointNames(handles);
    if numel(point_name)==1 && numel(label_index)==1
        point_name = point_name{1};
        point = pipeline_data.points.get('name', point_name);
        channel_params = pipeline_data.points.getDenoiseParam(label_index);
        label = channel_params.label;

        int_norm_d = point.get_IntNormD(label);
        
        % plot the raw image
        try
            sfigure(pipeline_data.figures.beforeFigure);
            xlims = xlim();
            ylims = ylim();
        catch
            pipeline_data.figures.beforeFigure = sfigure();
            pipeline_data.reset_button1 = uicontrol('Parent',pipeline_data.figures.beforeFigure,'Style','pushbutton','string','Reset','Units','normalized','Position',[0.015 .94 0.1 0.05],'Visible','on', 'Callback', @reset_plot_Callback);
        end
        temp_counts = point.counts(:,:,label_index);
        temp_counts(temp_counts>channel_params.dispcap)=channel_params.dispcap;
        imagesc(temp_counts)
        try
            xlim(xlims);
            ylim(ylims);
        catch
            
        end
        title([strrep(point_name, '_', '\_'), ' : ', label, ' - raw image']);
        
        if isequaln(int_norm_d, [])
            % then the knn calculation hasn't been performed, we should
            % just plot an empty histogram
            try sfigure(pipeline_data.histFigure);
            catch
                pipeline_data.histFigure = sfigure();
            end
            clf;
            % imagesc(pipeline_data.woahdude);
            imshow(pipeline_data.woahdude,'InitialMagnification','fit');
            title('No KNN calculation has been done for this data');
            
            try
                sfigure(pipeline_data.figures.afterFigure);
                clf;
                pipeline_data.reset_button2 = uicontrol('Parent',pipeline_data.figures.afterFigure,'Style','pushbutton','string','Reset','Units','normalized','Position',[0.015 .94 0.1 0.05],'Visible','on', 'Callback', @reset_plot_Callback);
            catch
            end
            
            try
                sfigure(pipeline_data.figures.diffFigure);
                clf;
                pipeline_data.reset_button3 = uicontrol('Parent',pipeline_data.figures.diffFigure,'Style','pushbutton','string','Reset','Units','normalized','Position',[0.015 .94 0.1 0.05],'Visible','on', 'Callback', @reset_plot_Callback);
            catch
            end
        else
            % the knn calculation HAS been performed, plot the denoise
            % image, the difference image, and the histogram
            
            counts_NoNoise = gui_MibiFilterImageByNNThreshold(point.counts(:,:,label_index), int_norm_d, channel_params.threshold);
            counts_noisediff = point.counts(:,:,label_index)-counts_NoNoise;
            hist_counts = point.get_countHist(label);
            
            try sfigure(pipeline_data.figures.afterFigure);
            catch
                pipeline_data.figures.afterFigure = sfigure();
                pipeline_data.reset_button2 = uicontrol('Parent',pipeline_data.figures.afterFigure,'Style','pushbutton','string','Reset','Units','normalized','Position',[0.015 .94 0.1 0.05],'Visible','on', 'Callback', @reset_plot_Callback);
            end
            counts_NoNoise(counts_NoNoise>channel_params.dispcap)=channel_params.dispcap;
            imagesc(counts_NoNoise)
            try
                xlim(xlims);
                ylim(ylims);
            catch
                
            end
            label_index = pipeline_data.points.get_label_index(label);
            denoise_params = pipeline_data.points.getDenoiseParam(label_index);
            c_value = denoise_params.c_value;
            title([strrep(point_name, '_', '\_'), ' : ', label, ' - denoised with K=', num2str(c_value)]);
            
            try sfigure(pipeline_data.figures.diffFigure);
            catch
                pipeline_data.figures.diffFigure = sfigure();
                pipeline_data.reset_button3 = uicontrol('Parent',pipeline_data.figures.diffFigure,'Style','pushbutton','string','Reset','Units','normalized','Position',[0.015 .94 0.1 0.05],'Visible','on', 'Callback', @reset_plot_Callback);
            end
            imagesc(counts_noisediff);
            try
                xlim(xlims);
                ylim(ylims);
            catch
                
            end
            title('Noise difference');
            
            try sfigure(pipeline_data.histFigure);
            catch
                pipeline_data.histFigure = sfigure();
            end
            clf;
            hedges = 0:0.25:30;
            hedges = hedges(1:end-1);
            hold off;
            bar(hedges, hist_counts, 'histc');
            hold on;
            lim = ylim;
            plot([channel_params.threshold, channel_params.threshold], [0, lim(2)], 'r');
            ylim(lim);
            title([strrep(point_name, '_', '\_'), ' : ', label, ' - histogram']);
            
            beforeAxes = findall(pipeline_data.figures.beforeFigure,'type','axes');
            afterAxes = findall(pipeline_data.figures.afterFigure,'type','axes');
            diffAxes = findall(pipeline_data.figures.diffFigure,'type','axes');
            
            linkaxes([beforeAxes, afterAxes, diffAxes]);
            
            try
                sfigure(pipeline_data.figures.beforeFigure);
                xlim(xlims);
                ylim(ylims);
            catch
                
            end
        end
    end
    
function reset_plot_Callback(hObject, eventdata, handles)
    global pipeline_data;
    obj = get(hObject, 'Parent');
    data_size = pipeline_data.points.get_data_size();
    xmax = data_size(1) + 0.5;
    ymax = data_size(2) + 0.5;
    xlim([0.5, xmax]);
    ylim([0.5, ymax]);

function set_gui_state(handles, state)
    handle_names = fieldnames(handles);
    for i=1:numel(handle_names)
        try
            set(handles.(handle_names{i}), 'enable', state);
        catch
        end
    end
    drawnow
% --- Executes on button press in add_point.

function run_knn(handles)
    global pipeline_data;
    point_names = pipeline_data.points.getSelectedPointNames();
    label_indices = pipeline_data.points.getSelectedLabelIndices();
    set(handles.figure1, 'pointer', 'watch')
    wait = waitbar(0, 'Calculating nearest neighbors');
    startTime = tic;
    set_gui_state(handles, 'off');
    labels = pipeline_data.points.labels();
    for i=1:numel(point_names)
        for j=1:numel(label_indices)
            fraction = ((i-1)*numel(label_indices)+j)/(numel(point_names)*numel(label_indices));
            timeLeft = (toc(startTime)/fraction)*(1-fraction);

            min = floor(timeLeft/60);
            sec = round(timeLeft-60*min);
            waitbar(fraction, wait, ['Calculating KNN for ' strrep(point_names{i}, '_', '\_'), ':', labels{label_indices(j)}, '.' newline, 'Time remaining: ', num2str(min), ' minutes and ', num2str(sec), ' seconds']);
            figure(wait);
            k_value = pipeline_data.points.getDenoiseParam(label_indices(j)).k_value;
            pipeline_data.points.knn(point_names{i}, label_indices(j), k_value);
        end
    end
    for i=1:numel(point_names)
        for j=1:numel(label_indices)
            pipeline_data.points.setDenoiseParam(label_indices(j), 'loaded', 1);
        end
    end
    set(handles.figure1, 'pointer', 'arrow')
    close(wait);
    set_gui_state(handles, 'on');
    pipeline_data.points.flush_data();
    plotDenoisingParams(handles);
    set(handles.points_listbox, 'string', pipeline_data.points.getPointText());
    set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());

function points_listbox_keypressfcn(hObject, eventdata, handles)
    global pipeline_data;
    if strcmp(eventdata.Key, 'return')
        point_names = getPointNames(handles{2});
        % point_names
        if numel(point_names)>1 || true
            for i=1:numel(point_names)
                pipeline_data.points.togglePointStatus(point_names{i});
            end
            set(handles{2}.points_listbox, 'string', pipeline_data.points.getPointText());
        end
    end
    
function channels_listbox_keypressfcn(hObject, eventdata, handles)
    global pipeline_data;
    if strcmp(eventdata.Key, 'return')
        channel_indices = get(handles{2}.channels_listbox,'value');
        if numel(channel_indices)>1 || true
            for i=1:numel(channel_indices)
                pipeline_data.points.setDenoiseParam(channel_indices(i), 'status');
            end
        end
        set(handles{2}.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
    end

function add_point_Callback(hObject, eventdata, handles)
    global pipeline_data;
    pointdiles = uigetdiles(pipeline_data.defaultPath);
    if ~isempty(pointdiles)
        [pipeline_data.defaultPath, ~, ~] = fileparts(pointdiles{1});
        pipeline_data.points.add(pointdiles);
        point_names = pipeline_data.points.getNames();
        set(handles.points_listbox, 'string', pipeline_data.points.getPointText())
        set(handles.points_listbox, 'max', numel(point_names));
        denoise_text = pipeline_data.points.getDenoiseText();
        set(handles.channels_listbox, 'string', denoise_text);
        set(handles.channels_listbox, 'max', numel(denoise_text));
        % pipeline_data.labels = pipeline_data.points.labels();
    end

% --- Executes on button press in remove_point.
function remove_point_Callback(hObject, eventdata, handles)
    global pipeline_data;
    pointIndex = get(handles.points_listbox, 'value');
    pointList = pipeline_data.points.getNames();
    % pointList = get(handles.points_listbox, 'string');
    try
        removedPoint = pointList{pointIndex};
        if ~isempty(removedPoint)
            pipeline_data.points.remove('name', removedPoint);
            set(handles.points_listbox, 'string', pipeline_data.points.getNames());
            set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
        end
        fix_menus_and_lists(handles);
    catch
    end

% --- Executes on button press in run_knn.
function run_knn_Callback(hObject, eventdata, handles)
    run_knn(handles);

% --- Executes on selection change in points_listbox.
function points_listbox_Callback(hObject, eventdata, handles)
    try
        global pipeline_data;
        label_index = get(handles.channels_listbox,'value');
        if ~isempty(label_index)
            channel_params = pipeline_data.points.getDenoiseParam(label_index);
            k_val = channel_params.k_value;
            threshold = channel_params.threshold;
            
            point_names = getPointNames(handles);
            if strcmp(get(gcf,'selectiontype'),'open') && numel(point_names)==1
                pipeline_data.points.togglePointStatus(point_names{1});
                set(handles.points_listbox, 'string', pipeline_data.points.getPointText());
            end
            
            set(handles.threshold_edit, 'string', threshold);
            set(handles.k_val_edit, 'string', k_val);
            if threshold<get(handles.threshold_slider, 'min')
                set(handles.threshold_slider, 'min', threshold);
            elseif threshold>get(handles.threshold_slider, 'max')
                set(handles.threshold_slider, 'max', threshold);
            else

            end
            set(handles.threshold_slider, 'value', threshold);
            plotDenoisingParams(handles);
            fix_menus_and_lists(handles);
        end
    catch err
        disp(err)
    end

% --- Executes on slider movement.
function threshold_slider_Callback(hObject, eventdata, handles)
    try
        val = get(hObject,'value');
        set(handles.threshold_edit, 'string', num2str(val));
        setThresholdParam(handles);
        plotDenoisingParams(handles);
    catch

    end

function threshold_edit_Callback(hObject, eventdata, handles)
    try
        val = str2double(get(hObject,'string'));
        if val<get(handles.threshold_slider, 'min')
            set(handles.threshold_slider, 'min', val);
        elseif val>get(handles.threshold_slider, 'max')
            set(handles.threshold_slider, 'max', val);
        else
            
        end
        set(handles.threshold_slider, 'value', val);
        setThresholdParam(handles);
        plotDenoisingParams(handles);
    catch
        
    end

function k_val_edit_Callback(hObject, eventdata, handles)
    setKValParam(handles);


% --- Executes on selection change in channels_listbox.
function channels_listbox_Callback(hObject, eventdata, handles)
    try
        global pipeline_data;
        label_index = get(handles.channels_listbox,'value');
        if ~isempty(label_index)
            channel_params = pipeline_data.points.getDenoiseParam(label_index);
            % channel_params = getChannelParams(handles);
            k_val = channel_params.k_value;
            threshold = channel_params.threshold;
            dispcap = channel_params.dispcap;

            if strcmp(get(gcf,'selectiontype'),'open')
                pipeline_data.points.setDenoiseParam(label_index, 'status');
                set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
            end
            set(handles.threshold_edit, 'string', threshold);
            set(handles.dispcap_edit, 'string', dispcap);
            set(handles.k_val_edit, 'string', k_val);
            if threshold<get(handles.threshold_slider, 'min')
                set(handles.threshold_slider, 'min', threshold);
            elseif threshold>get(handles.threshold_slider, 'max')
                set(handles.threshold_slider, 'max', threshold);
            else
            end
            
            if dispcap<get(handles.dispcap_slider, 'min')
                set(handles.dispcap_slider, 'min', dispcap)
            elseif dispcap>get(handles.dispcap_slider, 'max')
                set(handles.dispcap_slider, 'max', dispcap)
            else
            end
            set(handles.dispcap_slider, 'value', dispcap);
            plotDenoisingParams(handles);
            fix_menus_and_lists(handles);
        else
            
        end
    catch
    end
    
% --- Executes on button press in threshold_minmax_button.
function threshold_minmax_button_Callback(hObject, eventdata, handles)
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
            setThresholdParam(handles);
            plotDenoisingParams(handles);
        else
            gui_warning('Threshold maximum must be greater than threshold minimum');
        end
    catch
        % do nothing
    end

% --- Executes on button press in load_run_button.
function load_run_button_Callback(hObject, eventdata, handles)
    [file,path] = uigetfile('*.log');
    try
        global pipeline_data;
        logstring = fileread([path, filesep, file]);
        logstring = strsplit(logstring, filesep);
        logstring = logstring{1};
        label_params = strsplit(logstring, [' }', newline]);
        label_params(end) = [];
        % we should go through this and process them.
        for i=1:numel(label_params)
            if ~strcmp('not denoised', label_params{i}(end-11:end))
                % disp(label_params{i});
                label_param = label_params{i};
                label_param = strsplit(label_param, [': {', newline]);
                label = label_param{1}; % concerned there may be trailing space sometimes, could mess up stuff, check
                % we need to get the label_index to set the denoise_params
                % through PointManager
                label_index = pipeline_data.points.get_label_index(label);

                params = strsplit(label_param{2}, newline);

                k_val = params{1};
                k_val = strrep(k_val, ' ', '');
                k_val = strsplit(k_val, ':');
                k_val = str2double(k_val{2});

                threshold = params{2};
                threshold = strrep(threshold, ' ', '');
                threshold = strsplit(threshold, ':');
                threshold = str2double(threshold{2});

                pipeline_data.points.setDenoiseParam(label_index, 'k_value', k_val);
                pipeline_data.points.setDenoiseParam(label_index, 'threshold', threshold);
            else
                % this means this channel wasn't denoised
                label_param = strsplit(label_params{i}, ':');
                label = label_param{1};
                label_index = pipeline_data.points.get_label_index(label);
                pipeline_data.points.setDenoiseParam(label_index, 'status', -1);
            end
            set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
        end
    catch
        % probably we didn't even select a log file
    end
    
% we need a function that takes in the string from a .log file and outputs
% a listbox string
function listbox_string = parse_log_file(logstring)
    

% --- Executes on button press in save_run_button.
function save_run_button_Callback(hObject, eventdata, handles)
    [file,path] = uiputfile('*.mat');
    global pipeline_data;
    try
        pipeline_data.figures.beforeFigure = NaN;
        pipeline_data.figures.afterFigure = NaN;
        pipeline_data.figures.diffFigure = NaN;
        pipeline_data.figures.histFigure = NaN;
        save([path, filesep, file], 'pipeline_data')
    catch
        
    end

% --- Executes on button press in denoise_button.
function denoise_button_Callback(hObject, eventdata, handles)
    global pipeline_data;
    % first we have to finish running the knn calculation
    point_names = pipeline_data.points.getNames();
    for i=1:numel(point_names)
        pipeline_data.points.setPointStatus(point_names{i}, 1);
    end
    set(handles.points_listbox, 'string', pipeline_data.points.getPointText());
    set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
    
    run_knn(handles);
    set_gui_state(handles, 'off');
    set(handles.points_listbox, 'string', pipeline_data.points.getPointText());
    set(handles.channels_listbox, 'string', pipeline_data.points.getDenoiseText());
    
    % now we have to actually save the results
    pipeline_data.points.save_no_noise();
    set_gui_state(handles, 'on');
    msg = {'+----------------------------------------------+',...
           '|                                              |',...
           '|              Done removing noise             |',...
           '|                                              |',...
           '+----------------------------------------------+'};
    m = gui_msgbox(msg);

% --- Executes during object creation, after setting all properties.
function points_listbox_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

% --- Executes during object creation, after setting all properties.
function threshold_slider_CreateFcn(hObject, eventdata, handles)
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function threshold_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function k_val_edit_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function channels_listbox_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function dispcap_slider_Callback(hObject, eventdata, handles)
    try
        val = get(hObject,'value');
        set(handles.dispcap_edit, 'string', num2str(val));
        setDispcapParam(handles);
        plotDenoisingParams(handles);
    catch

    end

% --- Executes during object creation, after setting all properties.
function dispcap_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dispcap_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end



function dispcap_edit_Callback(hObject, eventdata, handles)
    try
        val = str2double(get(hObject,'string'));
        if val<get(handles.dispcap_slider, 'min')
            set(handles.dispcap_slider, 'min', val);
        elseif val>get(handles.dispcap_slider, 'max')
            set(handles.dispcap_slider, 'max', val);
        else
            
        end
        set(handles.dispcap_slider, 'value', val);
        setDispcapParam(handles);
        plotDenoisingParams(handles);
    catch
        
    end

% --- Executes during object creation, after setting all properties.
function dispcap_edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to dispcap_edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in dispcap_minmax_button.
function dispcap_minmax_button_Callback(hObject, eventdata, handles)
    defaults = {num2str(get(handles.dispcap_slider, 'min')), num2str(get(handles.dispcap_slider, 'max'))};
    vals = inputdlg({'Dispcap minimum', 'Dispcap maximum'}, 'Dispcap range', 1, defaults);
    try
        vals = str2double(vals);
        if vals(1)<0
            vals(1) = 0;
        end
        if vals(2)<0
            vals(2) = 0;
        end
        if vals(2)>vals(1)
            value = get(handles.dispcap_slider, 'value');
            if value<vals(1) % value less than minimum
                value = vals(1);
            elseif value>vals(2) % value greater than maximum
                value = vals(2);
            else
                % value is fine
            end
            set(handles.dispcap_slider, 'min', vals(1));
            set(handles.dispcap_slider, 'max', vals(2));
            set(handles.dispcap_slider, 'value', value);
            set(handles.dispcap_edit, 'string', value);
            setDispcapParam(handles);
            plotDenoisingParams(handles);
        else
            gui_warning('Threshold maximum must be greater than threshold minimum');
        end
    catch
        % do nothing
    end


function setUIFontSize(handles, fontSize)
    fields = fieldnames(handles);
    for i=1:numel(fields)
        ui_element_name = fields{i};
        ui_element = getfield(handles, ui_element_name);
        try
            ui_element.FontSize = fontSize;
        catch
            % probably no FontSize field to modify
        end
    end


% --- Executes on button press in save_run_params_button.
function save_run_params_button_Callback(hObject, eventdata, handles)
% hObject    handle to save_run_params_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    pipeline_data.points.save_denoise_params();