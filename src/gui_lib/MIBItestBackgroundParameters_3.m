function [] = MIBItestBackgroundParameters_3(reuseFigure)
    global pipeline_data;
    point = pipeline_data.points.get('name', pipeline_data.background_point);
    countsAllSFiltCRSum = point.counts;
    labels = point.labels;
    
    capBgChannel = pipeline_data.capBgChannel;
    t = pipeline_data.thresholds;
    gausRad = pipeline_data.gausRad;
    bgChannel = pipeline_data.bgChannel;
    removeVals = pipeline_data.points.getRemoveVals();
    titletext = ['Mask: [ ', pipeline_data.background_point, ' ] Channel [ ', bgChannel, ' ] Params: ', pipeline_data.all_param_TITLEstring];
    titletext = strrep(titletext, '_', '\_');
    
    [~,bgChannelInd] = ismember(bgChannel,labels);
    
    mask = MIBI_get_mask_3(countsAllSFiltCRSum(:,:,bgChannelInd),capBgChannel,t,gausRad,1, titletext, reuseFigure);
    countsNoBg = gui_MibiRemoveBackgroundByMaskAllChannels_3(countsAllSFiltCRSum,mask,removeVals);
    pipeline_data.countsNoBg = countsNoBg;
end

