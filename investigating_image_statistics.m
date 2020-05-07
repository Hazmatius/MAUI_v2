% data_folder = '/Volumes/ALEX_SSD/ALEX G-DRIVE USB/Brain data/JP/JPO_data/19Apr19_Run3_1024/19Apr19_Run3_Final/NoAuNoBg_09Apr19/';
% x = imread([data_folder, 'Point1/TIFs/CD45.tif']);
% 
% % imagesc(x((653:676)-400, (850:894)));
% low_data = double(x((653:676)-400, (850:894)));
% high_data = double(x(653:676, 850:894));
% 
% figure()
% h = fspecial('disk',3); hlist = sort(unique(h)); t=hlist(2);
% h = h>t;
% 
% synth_low_data = zeros(size(low_data)) + mean(low_data(:)); synth_low_data = poissrnd(synth_low_data);
% subplot(2,2,1); imagesc(low_data); title('Real low data')
% subplot(2,2,2); imagesc(synth_low_data);

data_folder = '/Volumes/ALEX_SSD/BANGELO_LAB/Shirley/cohort_data/panelA/extracted/Point1/TIFs/';
channel = 'CD45';

data = double(imread([data_folder, channel, '.tif']));
% imagesc(data);

% when the gradient is high, we are on a boundary.
% when we are on a boundary, we should use a lower-blur
sc10 = imgaussfilt(data,10); grad10 = imgradient(sc10)./data;
sc5 = imgaussfilt(data,5); grad5 = imgradient(sc5)./data;
sc2 = imgaussfilt(data,2); grad2 = imgradient(sc2)./data;
sc1 = imgaussfilt(data,1); grad1 = imgradient(sc1)./data;
sc05 = imgaussfilt(data,0.5); grad05 = imgradient(sc05)./data;

t = .5;
filtered_img = zeros(size(data));
cimg = zeros(size(data));
scales = [10, 9, 8, 7, 6, 5, 4, 3, 2, 1];
for i=1:numel(scales)
    disp(i);
    scale = scales(i);
    fdata = imgaussfilt(data, scale);
    fgrad = imgradient(fdata)./data;
    filtered_img(fgrad<t & cimg==0) = fdata(fgrad<t & cimg==0);
    disp(numel(find(fgrad<t & cimg==0)));
    cimg(fgrad<t & cimg==0) = i;
end
ffinal = imgaussfilt(data, 0.5);
filtered_img(fgrad>t) = ffinal(fgrad>t);
cimg(fgrad>t) = i+1;
filtered_img = poissrnd(filtered_img);

figure();
cmax = max(max(data(:)), max(filtered_img(:)));
ax1 = subplot(1,2,1); imagesc(data); caxis([0,cmax]);
ax2 = subplot(1,2,2); imagesc(filtered_img); caxis([0,cmax]);
figure();
ax3 = subplot(1,1,1); imagesc(cimg);
linkaxes([ax1, ax2, ax3]);