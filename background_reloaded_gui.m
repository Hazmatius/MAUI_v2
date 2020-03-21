function varargout = background_reloaded_gui(varargin)
% BACKGROUND_RELOADED_GUI MATLAB code for background_reloaded_gui.fig
%      BACKGROUND_RELOADED_GUI, by itself, creates a new BACKGROUND_RELOADED_GUI or raises the existing
%      singleton*.
%
%      H = BACKGROUND_RELOADED_GUI returns the handle to a new BACKGROUND_RELOADED_GUI or the handle to
%      the existing singleton*.
%
%      BACKGROUND_RELOADED_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BACKGROUND_RELOADED_GUI.M with the given input arguments.
%
%      BACKGROUND_RELOADED_GUI('Property','Value',...) creates a new BACKGROUND_RELOADED_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before background_reloaded_gui_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to background_reloaded_gui_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help background_reloaded_gui

% Last Modified by GUIDE v2.5 06-Mar-2020 00:52:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @background_reloaded_gui_OpeningFcn, ...
                   'gui_OutputFcn',  @background_reloaded_gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
global pipedat;
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before background_reloaded_gui is made visible.
function background_reloaded_gui_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to background_reloaded_gui (see VARARGIN)

% Choose default command line output for background_reloaded_gui
feature('DefaultCharacterSet','UTF-8');
global pipeline_data;
pipeline_data = struct();
pipeline_data.bgChannel = '181';
pipeline_data.removingBackground = false;
pipeline_data.points = PointManager();
pipeline_data.background_point = '';
handles.output = hObject;
[path, name, ext] = fileparts(mfilename('fullpath'));
options = json.read([path, filesep, 'src', filesep, 'options.json']);
fontsize = options.fontsize;
warning('off', 'MATLAB:hg:uicontrol:StringMustBeNonEmpty');
warning('off', 'MATLAB:imagesci:tifftagsread:expectedTagDataFormat');
path = strsplit(path, filesep);
path(end) = [];
path = strjoin(path, filesep);
pipeline_data.defaultPath = path;
set(handles.bgparamtable, 'ColumnFormat', {[], {'Background', 'Au197', 'Ta181'}, 'numeric', 'numeric', 'numeric', 'numeric'});
set(handles.bgparamtable, 'Data', cell(0,6));
set(hObject, 'ResizeFcn', @resize_table);
set(handles.display_cap_slider, 'SliderStep', [1/256 , 1/256]);
set(handles.display_cap_slider, 'value', 255);
pipeline_data.display_caps = [];
guidata(hObject, handles);

% UIWAIT makes background_reloaded_gui wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = background_reloaded_gui_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on slider movement.
function display_cap_slider_Callback(hObject, eventdata, handles)
% hObject    handle to display_cap_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    try
        global pipeline_data;
        channel = getSelectedChannel(handles);
        labels = pipeline_data.points.labels;
        channel_index = find(strcmp(labels, channel));
        display_cap_value = round(get(hObject, 'value'));
        set(hObject, 'value', display_cap_value);
        set(handles.display_cap_text, 'string', display_cap_value);
        global pipeline_data;
        pipeline_data.display_caps(channel_index) = display_cap_value;
        display_background(handles);
    catch
        
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

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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
        set(handles.selected_points_listbox, 'string', pipeline_data.points.bgGetNames());
        set(handles.background_channel_menu, 'string', pipeline_data.points.labels());
    end
    fix_menus_and_lists(handles);
    % load_background(handles);


% --- Executes on selection change in background_channel_menu.
function background_channel_menu_Callback(hObject, eventdata, handles)
    % hObject    handle to background_channel_menu (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns background_channel_menu contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from background_channel_menu
    display_background(handles);

% --- Executes during object creation, after setting all properties.
function background_channel_menu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to background_channel_menu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in selected_points_listbox.
function selected_points_listbox_Callback(hObject, eventdata, handles)
    % hObject    handle to selected_points_listbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns selected_points_listbox contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from selected_points_listbox
    display_background(handles);

function names = cleanPointNames(names)
    for i=1:numel(names)
        if strcmp(names{i}(1), '~')
            names{i} = names{i}(2:end);
        end
    end

% --- Executes on key press with focus on selected_points_listbox and none of its controls.
function selected_points_listbox_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to selected_points_listbox (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
    % if strcmp(get(gcf,'selectiontype'),'open')
        global pipeline_data;
        contents = cellstr(get(handles.selected_points_listbox, 'string'));
        point_index = get(handles.selected_points_listbox, 'value');
        point_name = contents(point_index);
        if strcmp(eventdata.Key, 'l')
            if ~isempty(point_name)
                point_name = cleanPointNames(point_name);
                % disp(point_name)
                for i=1:numel(point_name)
                    point_path = pipeline_data.points.namesToPaths(point_name{i});
                    pipeline_data.points.remove('name', point_name{i});
                    pipeline_data.points.add({point_path});
                    set(handles.selected_points_listbox, 'string', pipeline_data.points.bgGetNames());
                    labels = pipeline_data.points.pathsToPoints(point_path).labels;
                    pipeline_data.points.setLabels(labels);
                    set(handles.bgparamtable, 'ColumnFormat', {[], [{' '}, labels], 'numeric', 'numeric', 'numeric', 'numeric'});
                    olddata = get(handles.bgparamtable, 'Data');
                    data = cell(numel(labels), 6);
                    for i=1:numel(labels)
                        data{i,1} = labels{i};
                        try data{i,2} = olddata{i,2}; catch data{i,2} = char([]); end
                        try data{i,3} = olddata{i,3}; catch data{i,3} = 255; end
                        try data{i,4} = olddata{i,4}; catch data{i,4} = 1; end
                        try data{i,5} = olddata{i,5}; catch data{i,5} = .5; end
                        try data{i,6} = olddata{i,6}; catch data{i,6} = 3; end
                        try
                            pipeline_data.display_caps(i) = pipeline_data.display_caps(i);
                        catch
                            pipeline_data.display_caps(i) = 255;
                        end
                    end
                    set(handles.bgparamtable, 'Data', data);
                end
                set(handles.background_channel_menu, 'string', pipeline_data.points.labels());
            end
        elseif strcmp(eventdata.Key, 'u')
            if ~isempty(point_name)
                point_name = cleanPointNames(point_name);
                % disp(point_name)
                for i=1:numel(point_name)
                    point = pipeline_data.points.get('name', point_name{i});
                    point.unloadData();
                    set(handles.selected_points_listbox, 'string', pipeline_data.points.bgGetNames());
                end
                set(handles.background_channel_menu, 'string', pipeline_data.points.labels());
            end
        else
            
        end
        
function point = getSelectedPoint(handles)
    point = [];
    contents = get(handles.selected_points_listbox, 'string');
    index = get(handles.selected_points_listbox, 'value');
    if numel(index)==1
        point_name = cleanPointNames(contents(index));
        point_name = point_name{1};
        global pipeline_data;
        point = pipeline_data.points.get('name', point_name);
    end

function channel = getSelectedChannel(handles)
    channel = '';
    try
        global pipeline_data;
        contents = get(handles.bgparamtable, 'Data');
        indices = pipeline_data.indices; index = indices(1);
        if numel(index)==1
            channel = contents{index};
        end
    catch
        
    end
    
function [contaminant, cap, blur, threshhold, rmval] = get_bg_params(handles, channel)
    bgparamsdata = get(handles.bgparamtable, 'Data');
    tablechannels = bgparamsdata(:,1);
    channelindex = find(strcmp(tablechannels, channel));
    bgparams = bgparamsdata(channelindex,:);
    contaminant = bgparams{2};
    cap = bgparams{3};
    blur = bgparams{4};
    threshhold = bgparams{5};
    rmval = bgparams{6};
    
function warn = check_validity_of_params(handles, channel)
    warn = 'unknown error occured';
    [contaminant, cap, blur, threshhold, rmval] = get_bg_params(handles, channel);
    if strcmp(contaminant, ' ') || strcmp(contaminant, '')
        warn = 'You must select a contaminating channel';
    end
    
function [data, capped, blurred, mask, removed, difference] = get_background(handles)
    % global pipeline_data;
    point = getSelectedPoint(handles);
    channel = getSelectedChannel(handles);
    [contaminant_channel, cap, blur, threshhold, rmval] = get_bg_params(handles, channel);
    if ~isempty(point) && point.inmemory
        channel_index = find(strcmp(point.labels, channel));
        contaminant_index = find(strcmp(point.labels, contaminant_channel));
        data = point.counts(:,:,channel_index);
        contaminant = point.counts(:,:,contaminant_index);
        capped = contaminant; capped(capped>cap) = cap;
        blurred = imgaussfilt(capped, blur);
        mask = mat2gray(blurred)>threshhold;
        removed = data; removed(mask)=removed(mask)-rmval; removed(removed<0)=0;
        difference = data-removed;
    end
    
function valid = check_figure(handle)
    global pipeline_data;
    valid = false;
    try
        if eval(['isvalid(', handle, ')'])
            valid = true;
        end
    catch e
        valid = false;
    end
    
function fix_figures()
    global pipeline_data;
    if ~check_figure('pipeline_data.data_figure')
        pipeline_data.data_figure = figure('Name', 'Raw data', 'NumberTitle', 'off');
    end
    if ~check_figure('pipeline_data.mask_figure')
        pipeline_data.mask_figure = figure('Name', 'Mask', 'NumberTitle', 'off');
    end
    if ~check_figure('pipeline_data.removed_figure')
        pipeline_data.removed_figure = figure('Name', 'Cleaned data', 'NumberTitle', 'off');
    end

function display_background(handles)
    global pipeline_data;
    point = getSelectedPoint(handles);
    channel = getSelectedChannel(handles);
    try
        if ~isempty(point) && point.inmemory
            [data, capped, blurred, mask, removed, difference] = get_background(handles);
            [contaminant, cap, blur, threshhold, rmval] = get_bg_params(handles, channel);
            fix_figures();
            channel_index = find(strcmp(pipeline_data.points.labels, channel));
            sfigure(pipeline_data.data_figure);
            display_cap = pipeline_data.display_caps(channel_index);
            cappedrawdata = data; cappedrawdata(cappedrawdata>display_cap)=display_cap;
            imagesc(cappedrawdata); title(['Raw ', channel, ': ', strrep(point.name, '_', '\_')]);
            sfigure(pipeline_data.mask_figure);
            imagesc(mask); title([contaminant, ' mask: ', strrep(point.name, '_', '\_')]);
            sfigure(pipeline_data.removed_figure);
            cappedcleandata = removed; cappedcleandata(cappedcleandata>display_cap)=display_cap;
            imagesc(cappedcleandata); title(['Cleaned ', channel, ': ', strrep(point.name, '_', '\_')]);
        end
    catch e
        warning(check_validity_of_params(handles, channel));
    end


% --- Executes during object creation, after setting all properties.
function selected_points_listbox_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to selected_points_listbox (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end


% --- Executes when selected cell(s) is changed in bgparamtable.
function bgparamtable_CellSelectionCallback(hObject, eventdata, handles)
% hObject    handle to bgparamtable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) currently selecteds
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    pipeline_data.indices = eventdata.Indices;
    channel_index = pipeline_data.indices(1);
    set(handles.display_cap_text, 'String', pipeline_data.display_caps(channel_index));
    set(handles.display_cap_slider, 'value', pipeline_data.display_caps(channel_index));
    display_background(handles);
    

function fix_menus_and_lists(handles)
    fix_handle(handles.selected_points_listbox);
    fix_handle(handles.background_channel_menu);

function fix_handle(handle)
    try
        if isempty(get(handle, 'string'))
            set(handle, 'string', {''});
            set(handle, 'value', 1)
        end
        if ~isnumeric(get(handle, 'value'))
            set(handle, 'value', 1)
        end
    catch

    end

function resize_table(varargin)
    handles = guidata(varargin{1});
    ratios = [.225,.27,.11,.11,.11,.11];
    position = getpixelposition(handles.bgparamtable);
    sizes = round(ratios*position(3));
    % sizes(end) = floor(position(3))-sum(sizes(1:(end-1)));
    % disp(sizes)
    columnwidths = cell(size(sizes));
    for i=1:numel(sizes)
        columnwidths{i} = sizes(i);
    end
    set(handles.bgparamtable, 'ColumnWidth', columnwidths);


% --- Executes when entered data in editable cell(s) in bgparamtable.
function bgparamtable_CellEditCallback(hObject, eventdata, handles)
% hObject    handle to bgparamtable (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.CONTROL.TABLE)
%	Indices: row and column indices of the cell(s) edited
%	PreviousData: previous data for the cell(s) edited
%	EditData: string(s) entered by the user
%	NewData: EditData or its converted form set on the Data property. Empty if Data was not changed
%	Error: error string when failed to convert EditData to appropriate value for Data
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;
    pipeline_data.indices = eventdata.Indices;
    display_background(handles);
