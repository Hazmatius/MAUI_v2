%% GUI file for ez_segmenter_nextGen
    function varargout = ez_segment_gui(varargin)
    % EZ_SEGMENT_GUI MATLAB code for ez_segment_gui.fig
    %      EZ_SEGMENT_GUI, by itself, creates a new EZ_SEGMENT_GUI or raises the existing
    %      singleton*.
    %
    %      H = EZ_SEGMENT_GUI returns the handle to a new EZ_SEGMENT_GUI or the handle to
    %      the existing singleton*.
    %
    %      EZ_SEGMENT_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
    %      function named CALLBACK in EZ_SEGMENT_GUI.M with the given input arguments.
    %
    %      EZ_SEGMENT_GUI('Property','Value',...) creates a new EZ_SEGMENT_GUI or raises the
    %      existing singleton*.  Starting from the left, property value pairs are
    %      applied to the GUI before ez_segment_gui_OpeningFcn gets called.  An
    %      unrecognized property name or invalid value makes property application
    %      stop.  All inputs are passed to ez_segment_gui_OpeningFcn via varargin.
    %
    %      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
    %      instance to run (singleton)".
    %
    % See also: GUIDE, GUIDATA, GUIHANDLES

    % Edit the above text to modify the response to help ez_segment_gui

    % Last Modified by GUIDE v2.5 07-Jun-2019 09:35:47

    % Begin initialization code - DO NOT EDIT
    gui_Singleton = 1;
    gui_State = struct('gui_Name',       mfilename, ...
                       'gui_Singleton',  gui_Singleton, ...
                       'gui_OpeningFcn', @ez_segment_gui_OpeningFcn, ...
                       'gui_OutputFcn',  @ez_segment_gui_OutputFcn, ...
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


    % --- Executes just before ez_segment_gui is made visible.
    function ez_segment_gui_OpeningFcn(hObject, eventdata, handles, varargin)
    % This function has no output args, see OutputFcn.
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % varargin   command line arguments to ez_segment_gui (see VARARGIN)

    % UIWAIT makes ez_segment_gui wait for user response (see UIRESUME)
    % uiwait(handles.figure1);
    
    feature('DefaultCharacterSet','UTF-8');
    global pipeline_data;
    pipeline_data = struct();
    pipeline_data.initial_channel = '197';
    pipeline_data.points = PointManager();
    pipeline_data.initial_point = '';
    pipeline_data.displayImage = sfigure(figure());
    pipeline_data.displayHisto = sfigure(figure());
    pipeline_data.composite_names = {};
    pipeline_data.composite_w_individ_channels = containers.Map();
    pipeline_data.all_object_names = {};
    pipeline_data.start = 1;
    % Choose default command line output for background_removal_gui
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
    % Update handles structure
    guidata(hObject, handles);
    setUIFontSize(handles, fontsize)

    % --- Outputs from this function are returned to the command line.
    function varargout = ez_segment_gui_OutputFcn(hObject, eventdata, handles) 
    % varargout  cell array for returning output args (see VARARGOUT);
    % hObject    handle to figure
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Get default command line output from handles structure
    varargout{1} = handles.output;


%% ========== Manage Points and Select View Channel ==========

    % --- Executes on button press in add_points.
    function add_points_Callback(hObject, eventdata, handles)
    % hObject    handle to add_points (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        global pipeline_data;
        pointdiles = uigetdiles(pipeline_data.defaultPath);
        disp(pointdiles')
        
        %add first point or set of points
        if ~isempty(pointdiles) && pipeline_data.start == 1
            [pipeline_data.defaultPath, ~, ~] = fileparts(pointdiles{1});
            pipeline_data.points.add(pointdiles);
            set(handles.point_list, 'string', pipeline_data.points.getNames());
            set(handles.select_channel, 'string', pipeline_data.points.labels());
            set(handles.view_data, 'string', pipeline_data.points.labels());
            set(handles.view_mask, 'string', pipeline_data.points.labels());

            %set initial pipeline variables for later tasks, GUI values added to
            %params later on in PointManager variable.
            pipeline_data.composite_current_channel = handles.view_data.String(1);
            pipeline_data.composite_current_channel_index = handles.view_data.Value;
            pipeline_data.data_channel = handles.view_data.String(1);
            pipeline_data.mask_channel = handles.view_data.String(1);
            pipeline_data.name_of_composite_channel = '';
            pipeline_data.named_objects = '';
            
            pipeline_data.points.initEZ_SegmentParams();
            
            % create folders for later data
            create_results_folders(handles, pipeline_data)
            pipeline_data.start = 0;

        %add points to pre-existing list
        else
            [pipeline_data.defaultPath, ~, ~] = fileparts(pointdiles{1});
            pipeline_data.points.add(pointdiles);
            set(handles.point_list, 'string', pipeline_data.points.getNames());
            set(handles.select_channel, 'string', pipeline_data.points.labels());
            set(handles.view_data, 'string', pipeline_data.points.labels());
            set(handles.view_mask, 'string', pipeline_data.points.labels());
            
            
            temp = get(handles.view_data, 'string');
            disp(temp);
            
            append_results_folder(pipeline_data);

        end     
        fix_menus_and_lists(handles);
        % display tifs in pop-up box
        display_segment(handles, pipeline_data, 1);

    % --- Executes on button press in remove_points.
    function remove_points_Callback(hObject, eventdata, handles)
    % hObject    handle to remove_points (see GCBO)
        % eventdata  reserved - to be defined in a future version of MATLAB
        % handles    structure with handles and user data (see GUIDATA)
        global pipeline_data;
        % try
            pointIndex = get(handles.point_list, 'value');
            pointList = get(handles.point_list, 'string');
            removedPoint = pointList{pointIndex};
            if ~isempty(removedPoint)
                pipeline_data.points.remove('name', removedPoint);
                set(handles.point_list, 'string', pipeline_data.points.getNames());
                set(handles.select_channel, 'string', pipeline_data.points.labels());
                set(handles.view_data, 'string', pipeline_data.points.labels());
                set(handles.view_mask, 'string', pipeline_data.points.labels());

                % used to handle removal and updating of points in pointbox
                if strcmp(removedPoint, pipeline_data.points)
                    set(handles.view_point, 'string', '');
                end
                if pointIndex~=1
                    set(handles.point_list, 'value', pointIndex-1);
                else
                    set(handles.point_list, 'value', 1);
                end
                remove_results_folder(pipeline_data, removedPoint);
            end
        % catch err
            % throw(err)
        % end
        fix_menus_and_lists(handles);

    % --- Executes on key press with focus on remove_points and none of its controls.
    function remove_points_KeyPressFcn(hObject, eventdata, handles)
    % hObject    handle to remove_points (see GCBO)
    % eventdata  structure with the following fields (see MATLAB.UI.CONTROL.UICONTROL)
    %	Key: name of the key that was pressed, in lower case
    %	Character: character interpretation of the key(s) that was pressed
    %	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
    % handles    structure with handles and user data (see GUIDATA)

    % --- Executes on selection change in point_list.
    function point_list_Callback(hObject, eventdata, handles)
    % hObject    handle to point_list (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns point_list contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from point_list
    
        global pipeline_data;    
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function point_list_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to point_list (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        
    % --- Executes on button press in set_image_cap.
    function set_image_cap_Callback(hObject, eventdata, handles)
    % hObject    handle to set_image_cap (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        
        global pipeline_data;    
        defaults = {num2str(get(handles.slide_image_cap, 'min')), num2str(get(handles.slide_image_cap, 'max'))};
        vals = inputdlg({'image cap minimum', 'image cap maximum'}, 'Image intensity range', 1, defaults);
        vals = str2double(vals);
        
        min = vals(1);
        max = vals(2);
        value = vals(2);
        % set values for capped image visual
        set_gui_mask_values('range', handles.slide_image_cap, handles.image_cap_value, min, value, max);
        % set values for adjusting image intensity cap
        pipeline_data.points.setEZ_SegmentParams('image_cap', value);
        % view capped image
        display_segment(handles, pipeline_data);
    
    % --- Executes on slider movement.
    function slide_image_cap_Callback(hObject, eventdata, handles)
    % hObject    handle to slide_image_cap (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
    
        global pipeline_data;
        min = get(hObject, 'min');
        max = get(hObject, 'max');
        value = get(hObject, 'value');
        % set values for image cap visual
        set_gui_mask_values('slide', handles.slide_image_cap, handles.image_cap_value, min, value, max);
        % set values for adjusting image intensity cap
        pipeline_data.points.setEZ_SegmentParams('image_cap', value)
        % view adjusted image
        display_segment(handles, pipeline_data);
    
    % --- Executes during object creation, after setting all properties.
    function slide_image_cap_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to slide_image_cap (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
        if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor',[.9 .9 .9]);
        end
        global pipeline_data;
        set(hObject, 'min', 0);
        set(hObject, 'max', 1000);
        set(hObject, 'value', 1000);

    function image_cap_value_Callback(hObject, eventdata, handles)
    % hObject    handle to image_cap_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of image_cap_value as text
    %        str2double(get(hObject,'String')) returns contents of image_cap_value as a double
        
        global pipeline_data;
        min = get(handles.slide_image_cap, 'min');
        max = get(handles.slide_image_cap, 'max');
        value = str2double(get(hObject,'string'));
        % set values for mask visual
        set_gui_mask_values('text', handles.slide_image_cap, handles.image_cap_value, min, value, max);
        % set values for adjusting image intensity cape
        pipeline_data.points.setEZ_SegmentParams('image_cap', value);
        % view adjusted image
        display_segment(handles, pipeline_data);
        
    % --- Executes during object creation, after setting all properties.
    function image_cap_value_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to image_cap_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        global pipeline_data;
        set(hObject, 'value', 1000);


%% ========== Creating Composites ==========
% GUI functions for creating composite channels from points for objects

    % --- Executes on selection change in select_channel.
    function select_channel_Callback(hObject, eventdata, handles)
    % hObject    handle to select_channel (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: contents = cellstr(get(hObject,'String')) returns select_channel contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from select_channel
        global pipeline_data;
        contents = cellstr(get(hObject, 'String'));
        current_channel = contents{get(hObject, 'Value')};
        pipeline_data.composite_current_channel = current_channel; 

    % --- Executes during object creation, after setting all properties.
    function select_channel_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to select_channel (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end

    % --- Executes on selection change in composite_channels_box.
    function composite_channels_box_Callback(hObject, eventdata, handles)
    % hObject    handle to composite_channels_box (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: contents = cellstr(get(hObject,'String')) returns composite_channels_box contents as cell array
    %        contents{get(hObject,'Value')} returns selected item from composite_channels_box

    % --- Executes during object creation, after setting all properties.
    function composite_channels_box_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to composite_channels_box (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: listbox controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        set(hObject, 'String', {})
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end

    % --- Executes on button press in add_to_composite_box
    function add_to_composite_box_Callback(hObject, eventdata, handles)
    % hObject    handle to add_to_composite_box (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
    % Grabs selected channels and contents of listbox. Either shifts
    % contents of list to make room for new channel or adds the first
    % channel to the empty listbox.+
        global pipeline_data;
        channel_to_add = cellstr(pipeline_data.composite_current_channel);
        current_channel_list = cellstr(get(handles.composite_channels_box, 'String'));
    
    if (~isempty(current_channel_list))
           current_channel_list(2:end+1) = current_channel_list(1:end);
           current_channel_list{1} = channel_to_add;
           set(handles.composite_channels_box, 'String', string(current_channel_list));
    else
           current_channel_list{1} = channel_to_add;
           %resets Values field after clearing box that had previously already added channels
           set(handles.composite_channels_box, 'Value', 1);
           set(handles.composite_channels_box, 'String', string(current_channel_list));
    end
    
    % --- Executes on button press in delete_from_composite_box.
    function delete_from_composite_box_Callback(hObject, eventdata, handles)
    % hObject    handle to delete_from_composite_box (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        channel_index_to_remove = get(handles.composite_channels_box, 'Value');
        current_channel_list = cellstr(get(handles.composite_channels_box, 'String'));

        if (channel_index_to_remove == length(current_channel_list))
               current_channel_list(end) = [];
               set(handles.composite_channels_box, 'String', string(current_channel_list));
               set(handles.composite_channels_box, 'Value', channel_index_to_remove-1);
        else
               current_channel_list(channel_index_to_remove:end-1) = current_channel_list(channel_index_to_remove+1:end);
               current_channel_list(end) = [];
               set(handles.composite_channels_box, 'String', string(current_channel_list));
        end

    % --- Executes on button press in create_composite.
    function create_composite_Callback(hObject, eventdata, handles)
    % hObject    handle to create_composite (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        global pipeline_data;
        if strcmp(pipeline_data.name_of_composite_channel, "")
            msgbox('Enter a name for your composite (text field below)', 'Naming Error', 'error');
        else
            name_to_check = {pipeline_data.name_of_composite_channel};
            already_made = any(strcmp(pipeline_data.composite_names, name_to_check));
            %check to seee if name already used and if overwrite desired
            if already_made
                overwrite_file = questdlg("You already saved a composite channel with this name. Do you want to overwrite?");
                if strcmp(overwrite_file, 'No') || strcmp(overwrite_file, 'Cancel') || strcmp(overwrite_file, '')
                    msgbox('Choose new composite name ^_^');
                    error('Choose new composite name ^_^');
                end
            end
            
            % make files/folders and save names
            if isempty(pipeline_data.composite_names)
                pipeline_data.composite_names = {pipeline_data.name_of_composite_channel};
            else
                pipeline_data.composite_names = {pipeline_data.composite_names, pipeline_data.name_of_composite_channel};
            end
            % create and save the composites
            pipeline_data.channels_to_combine = get(handles.composite_channels_box, "String");
            create_composite(handles, pipeline_data);
            
            % save names + individual channels to variable for later logging purposes
            pipeline_data.composite_w_individ_channels(pipeline_data.name_of_composite_channel) = pipeline_data.channels_to_combine;
             
            msgbox('Composite created, tif added, csv updated!', 'Success!');
        end

    function name_composite_channel_text_field_Callback(hObject, eventdata, handles)
    % hObject    handle to name_composite_channel_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)

    % Hints: get(hObject,'String') returns contents of name_composite_channel_text_field as text
    %        str2double(get(hObject,'String')) returns contents of name_composite_channel_text_field as a double
        global pipeline_data;
        name = get(hObject, 'String');
        pipeline_data.name_of_composite_channel = name;

    % --- Executes during object creation, after setting all properties.
    function name_composite_channel_text_field_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to name_composite_channel_text_field (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end

%% ========== Creating Masks and Objects ==========
% GUI functions for creating and visualising masks for object segmentation

    % --- Executes on selection change in view_data.
    function view_data_Callback(hObject, eventdata, handles)
    % hObject    handle to view_data (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
        global pipeline_data;
        contents = cellstr(get(hObject,'String')); %returns view_data contents as cell array
        new_value = contents{get(hObject,'Value')}; %returns selected item from view_data
        pipeline_data.data_channel = new_value;
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function view_data_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to view_data (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    % --- Executes on selection change in view_mask.
    function view_mask_Callback(hObject, eventdata, handles)
    % hObject    handle to view_mask (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    
        global pipeline_data;    
        contents = cellstr(get(hObject,'String')); %returns view_mask contents as cell array
        new_value = contents{get(hObject,'Value')}; %returns selected item from view_mask
        pipeline_data.mask_channel = new_value;
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function view_mask_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to view_mask (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called

    % Hint: popupmenu controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
    if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
        set(hObject,'BackgroundColor','white');
    end

    % --- Executes on button press in set_blur_range.
    function set_blur_range_Callback(hObject, eventdata, handles)
    % hObject    handle to set_blur_range (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        
        global pipeline_data;
        defaults = {num2str(get(handles.slide_blur, 'min')), num2str(get(handles.slide_blur, 'max'))};
        vals = inputdlg({'Blur minimum', 'Blur maximum'}, 'Blur range', 1, defaults);
        vals = str2double(vals);
        
        min = vals(1);
        max = vals(2);
        value = vals(2);
        % set values for mask visual
        set_gui_mask_values('range', handles.slide_blur, handles.blur_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('blur', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
        
    % --- Executes on slider movement.
    function slide_blur_Callback(hObject, eventdata, handles)
    % hObject    handle to slide_blur (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA) 
    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
        
        global pipeline_data;
        min = get(hObject, 'min');
        max = get(hObject, 'max');
        value = get(hObject, 'value');
        % set values for mask visual
        set_gui_mask_values('slide', handles.slide_blur, handles.blur_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('blur', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function slide_blur_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to slide_blur (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
        
        if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor',[.9 .9 .9]);
        end
        global pipeline_data;
        set(hObject, 'min', 0);
        set(hObject, 'max', 10);
        set(hObject, 'value', 5);

    function blur_value_Callback(hObject, eventdata, handles)
    % hObject    handle to blur_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of blur_value as text
    %        str2double(get(hObject,'String')) returns contents of blur_value as a double
        
        global pipeline_data;
        min = get(handles.slide_blur, 'min');
        max = get(handles.slide_blur, 'max');
        value = str2double(get(hObject,'string'));
        % set values for mask visual
        set_gui_mask_values('text', handles.slide_blur, handles.blur_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('blur', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.  
    function blur_value_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to blur_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        global pipeline_data;
        set(hObject, 'value', 0);
        
    % --- Executes on button press in set_threshold_range.
    function set_threshold_range_Callback(hObject, eventdata, handles)
    % hObject    handle to set_threshold_range (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        
        global pipeline_data;    
        defaults = {num2str(get(handles.slide_thresh, 'min')), num2str(get(handles.slide_thresh, 'max'))};
        vals = inputdlg({'Threshold minimum', 'Threshold maximum'}, 'Threshold range', 1, defaults);
        vals = str2double(vals);
        
        min = vals(1);
        max = vals(2);
        value = vals(2);
        % set values for mask visual
        set_gui_mask_values('range', handles.slide_thresh, handles.thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
    
    % --- Executes on slider movement.
    function slide_thresh_Callback(hObject, eventdata, handles)
    % hObject    handle to slide_thresh (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)   
    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
        
        global pipeline_data;
        min = get(hObject, 'min');
        max = get(hObject, 'max');
        value = get(hObject, 'value');
        % set values for mask visual
        set_gui_mask_values('slide', handles.slide_thresh, handles.thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function slide_thresh_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to slide_thresh (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
        
        if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor',[.9 .9 .9]);
        end
        global pipeline_data;
        set(hObject, 'min', 0);
        set(hObject, 'max', 10);
        set(hObject, 'value', 5);
        
    function thresh_value_Callback(hObject, eventdata, handles)
    % hObject    handle to thresh_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of thresh_value as text
    %        str2double(get(hObject,'String')) returns contents of thresh_value as a double
        
        global pipeline_data;
        min = get(handles.slide_thresh, 'min');
        max = get(handles.slide_thresh, 'max');
        value = str2double(get(hObject,'string'));
        % set values for mask visual
        set_gui_mask_values('text', handles.slide_thresh, handles.thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
    
    % --- Executes during object creation, after setting all properties.
    function thresh_value_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to thresh_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        global pipeline_data;
        set(hObject, 'value', 0);
        
    % --- Executes on button press in set_minimum_range.
    function set_minimum_range_Callback(hObject, eventdata, handles)
    % hObject    handle to set_minimum_range (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        
        global pipeline_data;
        defaults = {num2str(get(handles.slide_min, 'min')), num2str(get(handles.slide_min, 'max'))};
        vals = inputdlg({'Pixel minimum', 'Pixel maximum'}, 'Pixel size range', 1, defaults);
        vals = str2double(vals);
        
        min = vals(1);
        max = vals(2);
        value = vals(2);
        % set values for mask visual
        set_gui_mask_values('range', handles.slide_min, handles.min_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('minimum', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
    
    % --- Executes on slider movement.
    function slide_min_Callback(hObject, eventdata, handles)
    % hObject    handle to slide_min (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
        
        global pipeline_data;
        min = get(hObject, 'min');
        max = get(hObject, 'max');
        value = get(hObject, 'value');
        % set values for mask visual
        set_gui_mask_values('slide', handles.slide_min, handles.min_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('minimum', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function slide_min_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to slide_min (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
        
        if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor',[.9 .9 .9]);
        end
        global pipeline_data;
        set(hObject, 'min', 0);
        set(hObject, 'max', 10);
        set(hObject, 'value', 5);
        
    function min_value_Callback(hObject, eventdata, handles)
    % hObject    handle to min_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of min_value as text
    %        str2double(get(hObject,'String')) returns contents of min_value as a double
        
        global pipeline_data;
        min = get(handles.slide_min, 'min');
        max = get(handles.slide_min, 'max');
        value = str2double(get(hObject,'string'));
        % set values for mask visual
        set_gui_mask_values('text', handles.slide_min, handles.min_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('minimum', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);

    % --- Executes during object creation, after setting all properties.
    function min_value_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to min_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        global pipeline_data;
        set(hObject, 'value', 0);
        
    % --- Executes on button press in enable_refinement_box.
    function enable_refinement_box_Callback(hObject, eventdata, handles)
    % hObject    handle to enable_refinement_box (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hint: get(hObject,'Value') returns toggle state of enable_refinement_box

    % --- Executes on button press in set_refine_thresh_range.
    function set_refine_thresh_range_Callback(hObject, eventdata, handles)
    % hObject    handle to set_refine_thresh_range (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
        
        global pipeline_data;
        defaults = {num2str(get(handles.slide_refine_thresh, 'min')), num2str(get(handles.slide_refine_thresh, 'max'))};
        vals = inputdlg({'Refine thresh minimum', 'Refine thresh maximum'}, 'Refine thresh range', 1, defaults);
        vals = str2double(vals);
        
        min = vals(1);
        max = vals(2);
        value = vals(2);
        % set values for mask visual
        set_gui_mask_values('range', handles.slide_refine_thresh, handles.refine_thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('refine_threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
        
    % --- Executes on slider movement.
    function slide_refine_thresh_Callback(hObject, eventdata, handles)
    % hObject    handle to slide_refine_thresh (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'Value') returns position of slider
    %        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
        
        global pipeline_data;
        min = get(hObject, 'min');
        max = get(hObject, 'max');
        value = get(hObject, 'value');
        % set values for mask visual
        set_gui_mask_values('slide', handles.slide_refine_thresh, handles.refine_thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('refine_threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
        
    % --- Executes during object creation, after setting all properties.
    function slide_refine_thresh_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to slide_refine_thresh (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: slider controls usually have a light gray background.
        
        if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor',[.9 .9 .9]);
        end
        global pipeline_data;
        set(hObject, 'min', 0);
        set(hObject, 'max', 10);
        set(hObject, 'value', 5);
        
    function refine_thresh_value_Callback(hObject, eventdata, handles)
    % hObject    handle to refine_thresh_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    structure with handles and user data (see GUIDATA)
    % Hints: get(hObject,'String') returns contents of refine_thresh_value as text
    %        str2double(get(hObject,'String')) returns contents of refine_thresh_value as a double
        
        global pipeline_data;
        min = get(handles.slide_min, 'min');
        max = get(handles.slide_min, 'max');
        value = str2double(get(hObject,'string'));
        % set values for mask visual
        set_gui_mask_values('text', handles.slide_refine_thresh, handles.refine_thresh_value, min, value, max);
        % set values for mask parameters (for segmentation)
        pipeline_data.points.setEZ_SegmentParams('refine_threshold', value);
        % view data + mask overlay
        display_segment(handles, pipeline_data);
        
    % --- Executes during object creation, after setting all properties.
    function refine_thresh_value_CreateFcn(hObject, eventdata, handles)
    % hObject    handle to refine_thresh_value (see GCBO)
    % eventdata  reserved - to be defined in a future version of MATLAB
    % handles    empty - handles not created until after all CreateFcns called
    % Hint: edit controls usually have a white background on Windows.
    %       See ISPC and COMPUTER.
        
        if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
            set(hObject,'BackgroundColor','white');
        end
        global pipeline_data;
        set(hObject, 'value', 0);
           

%% ========== Processing Masks and Object Creation to FCS ==========
% GUI functions for creating objects based on masks and FCS formation

% --- Executes on button press in create_objects_and_fcs.
function create_objects_and_fcs_Callback(hObject, eventdata, handles)
% hObject    handle to create_objects_and_fcs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    global pipeline_data;  
  
    if strcmp(string(handles.name_objects_entry.String), "")
        msgbox('Enter a name for your objects (text field to your left)', 'Naming Error', 'error');
    else
        name_to_check = {pipeline_data.named_objects};
        already_made = any(strcmp(pipeline_data.all_object_names, name_to_check));
        %check to seee if name already used and if overwrite desired
        if already_made
            overwrite_file = questdlg("You already saved objects with this name. Do you want to overwrite?");
            if strcmp(overwrite_file, 'No') || strcmp(overwrite_file, 'Cancel') || strcmp(overwrite_file, '')
                msgbox('Choose new object name ^_^');
                error('Choose new object name ^_^');
            end
        end
        % make files/folders and save names
        if isempty(pipeline_data.composite_names)
            pipeline_data.all_object_names = {pipeline_data.named_objects};
        else
            pipeline_data.all_object_names = {pipeline_data.all_object_names, pipeline_data.named_objects};
        end
        %create objects and save them as FCS files in results folders
        msg = waitbar(0, ['"Processing points"', newline, ' - Carl, Llamas with Hats']);
        for point_index=1:numel(handles.point_list.String)
            waitbar(point_index/numel(handles.point_list), msg, ['"Processing points"', newline, ' - Carl, Llamas with Hats']);        
            create_objects(point_index, pipeline_data);
        end
        close(msg);
        %save a log
        msg = waitbar(0, ['"Saving log"', newline, ' - Frederick the Penguin']);
        write_log(pipeline_data);
        close(msg);
        msgbox('Objects created and FCS files saved. Have fun!', 'Success');
    end

function name_objects_entry_Callback(hObject, eventdata, handles)
% hObject    handle to name_objects_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Hints: get(hObject,'String') returns contents of name_objects_entry as text
%        str2double(get(hObject,'String')) returns contents of name_objects_entry as a double
    global pipeline_data;
    pipeline_data.named_objects = get(hObject,'String');

% --- Executes during object creation, after setting all properties.
function name_objects_entry_CreateFcn(hObject, eventdata, handles)
% hObject    handle to name_objects_entry (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


%% Other functions for GUI
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

function fix_menus_and_lists(handles)
    fix_handle(handles.point_list);
    fix_handle(handles.view_data);

    
