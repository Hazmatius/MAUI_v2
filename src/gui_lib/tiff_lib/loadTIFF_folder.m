function [counts, labels, tags] = loadTIFF_folder(path)
   % First we look for all TIFF files in the given path
   fileList = [dir(fullfile(path, '*.tiff'));...
               dir(fullfile(path, '*.tif'))];
   if isempty(fileList)
       error(['No TIFF files found in ', path]);
   end
   files = {fileList.name}';
   rmIdx = [find(strcmp(files, 'totalIon.tif')), find(strcmp(files, 'totalIon.tiff'))];
   files(rmIdx) = []; % removes totalIon.tif and/or totalIon.tiff
   rmIdx = find(cellfun(@isHiddenName, {fileList.name}));
   files(rmIdx) = [];
   num_pages = numel(files);
   counts = [];
   labels = {};
   tags = {};
   for index=1:num_pages
       tiff = Tiff([path, filesep, files{index}]);
       data = read(tiff);
       if size(data,3)==3
           warning('you did some weird stuff to your tiffs, huh?');
           data1=data(:,:,1); data2=data(:,:,2); data3=data(:,:,3);
           if all(data1==data2) & all(data2==data3)
               data = data(:,:,1);
           else
               error('invalid data format');
           end
       end
       counts(:,:,index) = data;
       tags{index} = getTagStruct(tiff);
       tags{index}.SamplesPerPixel = 1;
       tags{index}.Compression = 32946;
       tags{index}.RowsPerStrip = 16;
       tags{index}.Photometric = 1;
       try tags{index} = rmfield(tags{index}, 'Software'); catch; end
       try tags{index} = rmfield(tags{index}, 'DateTime'); catch; end
       try
           desc = json.load(tags{index}.ImageDescription);
           labels{index} = desc.channel0x2Etarget;
       catch
           [~, labels{index}, ~] = fileparts(files{index});
       end
   end
end