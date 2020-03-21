function [countsNoNoise] = gui_FFTfilter_old(counts, gauss_blur_radius, spectral_radius, scaling_factor)
    % Scale the image 
    im = counts * scaling_factor;
    
    % Mean of all values
    mean_value = mean(im(:));
    
    % Center the distribution
    im = im - mean_value;
    
    % Add custom blur
    if gauss_blur_radius > 0
        im = imgaussfilt(im, gauss_blur_radius);
    end
    
    % 2D FFT and shift low frequency components to the center
    F = fftshift(fft2(im));
    
    % Create a 2D gaussian filter
    h = fspecial('gaussian',size(F),spectral_radius);
    
    % Rescale to [0 1]
    h = h./max(h(:));
    
    % Apply the filter to the FFT data. Central components remain largely
    % unaffected, outer edge data gets multiplied by low values
    H = F.*h;
    
    % Reverse FFT
    % h = fspecial('gaussian',size(F),spectral_radius);
    [xGrid,yGrid] = meshgrid(1:size(F,1),1:size(F,2));
    h = sqrt((xGrid - 512.5).^2 + (yGrid - 512.5).^2) <= spectral_radius;
    H = F.*h;
    % H = real(F).*h + imag(F)*i;
    
    countsNoNoise = sqrt((pic/scaling_factor) .* counts);
end

% function [countsNoNoise] = gui_FFTfilter(counts, gauss_blur_radius, spectral_radius, scaling_factor)
%     % Scale the image 
%     im = counts * scaling_factor;
%     
%     % Mean of all values
%     mean_value = mean(im(:));
%     
%     % Center the distribution
%     im = im - mean_value;
%     
%     % Add custom blur
%     if gauss_blur_radius > 0
%         im = imgaussfilt(im, gauss_blur_radius);
%     end
%     
%     % 2D FFT and shift low frequency components to the center
%     F = fftshift(fft2(im));
% <<<<<<< Updated upstream
%     
%     % Create a 2D gaussian filter
%     h = fspecial('gaussian',size(F),spectral_radius);
%     
%     % Rescale to [0 1]
%     h = h./max(h(:));
%     
%     % Apply the filter to the FFT data. Central components remain largely
%     % unaffected, outer edge data gets multiplied by low values
%     H = F.*h;
%     
%     % Reverse FFT
% =======
%     % h = fspecial('gaussian',size(F),spectral_radius);
%     [xGrid,yGrid] = meshgrid(1:size(F,1),1:size(F,2));
%     h = sqrt((xGrid - 512.5).^2 + (yGrid - 512.5).^2) <= spectral_radius;
%     H = F.*h;
%     % H = real(F).*h + imag(F)*i;
% >>>>>>> Stashed changes
%     pic = real(ifft2(fftshift(H)));
%     
%     % Check how negative these get
%     pic(pic < 0) = 0;
%     
%     % Add mean intensity back to data
%     pic = floor(pic + mean_value);
% <<<<<<< Updated upstream
%     
%     countsNoNoise = sqrt((pic/scaling_factor) .* counts);
% =======
%     countsNoNoise = sqrt(pic.*counts/scaling_factor);
% >>>>>>> Stashed changes
% end
% 
