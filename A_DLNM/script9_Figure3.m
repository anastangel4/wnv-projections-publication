clear all; clc;
load('hind.mat') 
load('sc45.mat')
load('sc85.mat')

northEU = {'UK','DK','EE','FI','IS','IE','LV','LT','NO','SE','GB'};
westEU  = {'AT','BE','FR','DE','LI','LU','MC','NL','CH'};
ceEU    = {'BG','CZ','HU','PL','RO','SK','SI','HR','BA','ME','MK','RS','AL','XK'};
southEU = {'AD','CY','ES','EL','IT','MT','PT','SM','TR'};

regions_struct.noEU = northEU;
regions_struct.weEU = westEU;
regions_struct.ceEU = ceEU;
regions_struct.soEU = southEU;

regionNames = fieldnames(regions_struct);
regionTitles = {'Northern Europe', 'Western Europe', 'Central & Eastern Europe', 'Southern Europe'};

threshold = 1.5;
weeks_in_month = 4;

hind.active = hind.RR_model > threshold;
sc45.active = sc45.RR_model > threshold;
sc85.active = sc85.RR_model > threshold;

colors = [0.0, 0.4, 0.7;  
          1.0, 0.6, 0.2;  
          1.0, 0.6, 0.2;  
          0.8, 0.2, 0.2;  
          0.8, 0.2, 0.2;]; 

periodLabels = {'Historical', 'Scnr 4.5 (Near)', 'Scnr 4.5 (Far)', ...
                'Scnr 8.5 (Near)', 'Scnr 8.5 (Far)'};

for r = 2:numel(regionNames)
    reg = string(regionNames{r});
    idx_h = hind.Region==reg & hind.year>=2010 & hind.year<=2024 & hind.active;
    years_h = unique(hind.year(idx_h));
    dur_h = [];
    for y = years_h', w = hind.week(idx_h & hind.year==y); 
        dur_h = [dur_h; (max(w)-min(w)+1)/weeks_in_month]; 
    end

    idx_45_nf = sc45.Region==reg & sc45.year>=2061 & sc45.year<=2075 & sc45.active;
    idx_45_ff = sc45.Region==reg & sc45.year>=2076 & sc45.year<=2090 & sc45.active;
    
    dur_45_nf = []; years_nf = unique(sc45.year(idx_45_nf));
    for y = years_nf', w = sc45.week(idx_45_nf & sc45.year==y); dur_45_nf = [dur_45_nf; (max(w)-min(w)+1)/weeks_in_month]; end
    
    dur_45_ff = []; years_ff = unique(sc45.year(idx_45_ff));
    for y = years_ff', w = sc45.week(idx_45_ff & sc45.year==y); dur_45_ff = [dur_45_ff; (max(w)-min(w)+1)/weeks_in_month]; end

    idx_85_nf = sc85.Region==reg & sc85.year>=2061 & sc85.year<=2075 & sc85.active;
    idx_85_ff = sc85.Region==reg & sc85.year>=2076 & sc85.year<=2090 & sc85.active;
    
    dur_85_nf = []; years_nf = unique(sc85.year(idx_85_nf));
    for y = years_nf', w = sc85.week(idx_85_nf & sc85.year==y); dur_85_nf = [dur_85_nf; (max(w)-min(w)+1)/weeks_in_month]; end
    
    dur_85_ff = []; years_ff = unique(sc85.year(idx_85_ff));
    for y = years_ff', w = sc85.week(idx_85_ff & sc85.year==y); dur_85_ff = [dur_85_ff; (max(w)-min(w)+1)/weeks_in_month]; end

    data_cells = {dur_h, dur_45_nf, dur_45_ff, dur_85_nf, dur_85_ff};

    figure('Color', 'w', 'Position', [100, 100, 850, 600]);
    hold on;
    overlap = 0.85; 

    for i = 1:5
        d = data_cells{i};
        if isempty(d), continue; end
        
        [f, x] = ksdensity(d, 'BoundaryCorrection', 'reflection', 'Bandwidth', 0.25);
        f = f / max(f) * overlap; 
        
        fill([x(1) x x(end)], [i i+f i], colors(i,:), ...
            'FaceAlpha', 0.7, 'EdgeColor', 'k', 'LineWidth', 1.1);
        
        med = median(d);
        [~, idx_m] = min(abs(x - med));
        line([med med], [i i+f(idx_m)], 'Color', 'w', 'LineWidth', 2, 'LineStyle', '--');
    end

    set(gca, 'YTick', 1:5, 'YTickLabel', periodLabels, 'FontSize', 11, 'FontWeight', 'bold');
    xlabel('Duration of active WNV transmission (months)', 'FontSize', 12);
    title(['Projected Epidemiological Season Duration (DLNM): ' regionTitles{r}])
    grid on; set(gca, 'XGrid', 'on', 'YGrid', 'off', 'GridAlpha', 0.3);
    xlim([1 8]); 
    ylim([0.5 6.5]);
    set(gca, 'Box', 'off', 'TickDir', 'out');
    hold off;
end