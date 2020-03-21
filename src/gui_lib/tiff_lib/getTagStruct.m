function [tags] = getTagStruct(tiffObj)
    tags = struct();
    allTagNames = {'SubFileType',...
                   'ImageWidth',...
                   'ImageLength',...
                   'BitsPerSample',...
                   'Compression',...
                   'Photometric',...
                   'ImageDescription',...
                   'Orientation',...
                   'SamplesPerPixel',...
                   'RowsPerStrip',...
                   'MinSampleValue',...
                   'MaxSampleValue',...
                   'XResolution',...
                   'YResolution',...
                   'PlanarConfiguration',...
                   'PageName',...
                   'XPosition',...
                   'YPosition',...
                   'ResolutionUnit',...
                   'Software',...
                   'DateTime',...
                   'SampleFormat',...
                   'SMinSampleValue',...
                   'SMaxSampleValue',...
                   'ZipQuality'};
               
    for tagIndex = 1:numel(allTagNames)
        try
            tag = allTagNames{tagIndex};
            tag_val = getTag(tiffObj, tag);
            tags = setfield(tags, tag, tag_val);
        catch error
            % disp(tag);
            % disp(error);
        end
    end
end
