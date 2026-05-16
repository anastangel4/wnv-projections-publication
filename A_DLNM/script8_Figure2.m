clear all
load('hind.mat')
load('sc45.mat')
T_45 = [hind; sc45];
load('sc85.mat')
T_85 = [hind; sc85];

regions = struct();
regions.weEU = {'AT','BE','FR','DE','LI','LU','MC','NL','CH'};
regions.ceEU = {'BG','CZ','HU','PL','RO','SK','SI','HR','BA','ME','MK','RS','AL','XK'};
regions.soEU = {'AD','CY','ES','EL','IT','MT','PT','SM','TR'};

regionNames = fieldnames(regions);
regionTitles = {'Western Europe', 'Central & Eastern Europe', 'Southern Europe'};

years01 = 2010:2024; 
years02 = 2061:2090; 
all_years = [years01 years02];
hist_end_idx = length(years01); 

x_stops = [0, 0.5, 1.2]; 
color_points = [
    0.0, 0.0, 0.6; 
    1.0, 1.0, 1.0; 
    0.8, 0.0, 0.0  
];
n = 256;
custom_map = interp1(x_stops, color_points, linspace(0, 1.2, n)); 

Tables = {T_45, T_85};
scenario_names = {'4.5', '8.5'};

for s = 1:2
    current_T = Tables{s};
    plot_matrix = nan(length(regionNames), length(all_years));
    
    for r = 1:length(regionNames)
        regCode = regionNames{r};
        regIdx = ismember(current_T.Region, regCode);
        
        for j = 1:length(all_years)
            yr = all_years(j);
            idx = regIdx & (current_T.year == yr);
            data_subset = current_T.RR_model(idx);
            
            if ~isempty(data_subset)
                plot_matrix(r, j) = quantile(data_subset, 0.75);
            end
        end
    end

    figure('Color', 'w', 'Position', [100, 100, 1200, 450]);
    imagesc(plot_matrix);
    colormap(custom_map);
    
    clim([0, 1.2]); 
    
    cb = colorbar;
    cb.Ticks = 0:0.1:1.2; 
    ylabel(cb, 'OR_{Q75}', 'FontSize', 14, 'FontWeight', 'bold', 'Interpreter', 'tex');
    
    title(['Spatiotemporal evolution of the 75th percentile of WNV OR under Scenario ', scenario_names{s}], 'FontSize', 16, 'FontWeight', 'bold');
    
    set(gca, 'YTick', 1:length(regionTitles), 'YTickLabel', regionTitles, ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    xticks_pos = 1:5:length(all_years);
    set(gca, 'XTick', xticks_pos, 'XTickLabel', all_years(xticks_pos));
    xtickangle(45);
    
    hold on;
    
    line([hist_end_idx + 0.5, hist_end_idx + 0.5], [0.5, length(regionNames) + 0.5], ...
        'Color', 'k', 'LineWidth', 3);
    
    xlabel('Year', 'FontSize', 13, 'FontWeight', 'bold');
    ylabel('Regions', 'FontSize', 13, 'FontWeight', 'bold');
    
    axis tight;
    grid off;
    set(gca,'Fontsize',18)

end
