function [labels, runinfo] = sort_labels_by_mass(labels, path)
    [folder, ~, ~] = fileparts(path); % remember that path should be to a POINT folder
    [folder, ~, ~] = fileparts(folder);
    panelPath = [folder, filesep, 'info'];
    disp(panelPath);
    csvList = dir(fullfile(panelPath, '*.csv'));
    csvList(find(cellfun(@isHiddenName, {csvList.name}))) = [];
    if numel(csvList)==1
        filepath = [csvList.folder, filesep, csvList.name];
        panel = dataset('File', filepath, 'Delimiter', ',');
    elseif isempty(csvList)
        error(['No CSV file was found inside of ', panelPath]);
    else
        error(['Too many CSV files were found inside of ', panelPath]);
    end
    idx = zeros(size(labels));
    % disp(labels)
    if ~isempty(strmatch('Label', get(panel, 'VarNames')))
        panelLabel = panel.Label;
    elseif ~isempty(strmatch('Target', get(panel, 'VarNames')))
        panelLabel = panel.Target;
    else
        error('no label or target info in this panel');
    end
    for i=1:numel(labels)
        id = find(strcmp(labels, panelLabel{i}));
        % disp(['{',num2str(id),'} ', labels{i}])
        if numel(id)~=1
            disp('A label couldn''t be found')
            disp(panelLabel{id})
            disp(panelLabel{i})
            disp(labels')
        end
        idx(i) = id;
    end
%         disp(idx);
%         disp(panelLabel);
%         disp(labels(idx));
%         counts = counts(:,:,idx);
%         labels = labels(idx);
%         tags = tags(idx);
    if ~isempty(strmatch('Mass', get(panel, 'VarNames')))
        masses = panel.Mass;
    elseif ~isempty(strmatch('Isotope', get(panel, 'VarNames')))
        masses = panel.Isotope;
    else
        error('No mass or isotope info in this panel')
    end
    labels = labels(idx);
    
    runinfo = struct();
    runinfo.masses = masses;
    [~, runinfo.panelname, ~] = fileparts(csvList.name);
end