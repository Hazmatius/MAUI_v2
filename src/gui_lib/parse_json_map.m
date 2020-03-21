function jsonmap = parse_json_map(jsonstring)
    jsonstring = jsonstring(2:end);
    jsonstring = strrep(jsonstring, '},', '}=');
    jsonstring = strrep(jsonstring, '}}', '}');
    elements = strsplit(jsonstring, '=');
    jsonmap = containers.Map;
    for i=1:numel(elements)
        elements{i} = strrep(elements{i}, ':{', '={');
        temp = strsplit(elements{i}, '=');
        label = strrep(temp{1}, '"', '');
        element = jsondecode(temp{2});
        jsonmap(label) = element;
    end
end

