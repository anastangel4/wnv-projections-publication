clear; close all; clc
tic
S = shaperead('NUTS_RG_01M_2021_4326_LEVL_3.shp\NUTS_RG_01M_2021_4326_LEVL_3.shp');
northEU = {'UK','DK','EE','FI','IS','IE','LV','LT','NO','SE','GB'};
westEU  = {'AT','BE','FR','DE','LI','LU','MC','NL','CH'};
ceEU    = {'BG','CZ','HU','PL','RO','SK','SI','HR','BA','ME','MK','RS','AL','XK'};
southEU = {'AD','CY','ES','EL','IT','MT','PT','SM','TR'};

north_idx = ismember({S.CNTR_CODE}, northEU);
west_idx  = ismember({S.CNTR_CODE}, westEU);
ce_idx    = ismember({S.CNTR_CODE}, ceEU);
south_idx = ismember({S.CNTR_CODE}, southEU);

regions = {'north','west','ce','south'};
regionTitles = {'Northern Europe','Western Europe','Central & Eastern Europe','Southern Europe'};

hind_years = 2010:2024;
proj_years = 2061:2090;
all_years  = [hind_years proj_years];

m1 = 5;  
m2 = 9; 
for r = 1:numel(regions)
    for y = all_years
        data.hind.(regions{r}){y}  = [];
        data.rcp45.(regions{r}){y} = [];
        data.rcp85.(regions{r}){y} = [];
    end
end
for i = 1:numel(S)

    f_hind = fullfile('hindcast',[num2str(i) '.csv.estimated_indexP.csv']);
    if isfile(f_hind)
        T = readtable(f_hind);
        for y = hind_years
            fx = year(T.date)==y & month(T.date)>=m1 & month(T.date)<=m2;
            vals = T.indexP(fx);
            if isempty(vals), continue; end

            if north_idx(i)
                data.hind.north{y} = [data.hind.north{y}; vals];
            elseif west_idx(i)
                data.hind.west{y}  = [data.hind.west{y}; vals];
            elseif ce_idx(i)
                data.hind.ce{y}    = [data.hind.ce{y}; vals];
            elseif south_idx(i)
                data.hind.south{y} = [data.hind.south{y}; vals];
            end
        end
    end

    f45_01 = ['2061-2075/proj45/proj45_' num2str(i) '.csv.estimated_indexP.csv'];
    f45_02 = ['2076-2090/proj45/proj45_' num2str(i) '.csv.estimated_indexP.csv'];

    if isfile(f45_01)
        T1 = readtable(f45_01);
        T2 = readtable(f45_02);
        T = [T1; T2];

        for y = proj_years
            fx = year(T.date)==y & month(T.date)>=m1 & month(T.date)<=m2;
            vals = T.indexP(fx);
            if isempty(vals), continue; end

            if north_idx(i)
                data.rcp45.north{y} = [data.rcp45.north{y}; vals];
            elseif west_idx(i)
                data.rcp45.west{y}  = [data.rcp45.west{y}; vals];
            elseif ce_idx(i)
                data.rcp45.ce{y}    = [data.rcp45.ce{y}; vals];
            elseif south_idx(i)
                data.rcp45.south{y} = [data.rcp45.south{y}; vals];
            end
        end
    end

    f85_01 = ['2061-2075/proj85/proj85_' num2str(i) '.csv.estimated_indexP.csv'];
    f85_02 = ['2076-2090/proj85/proj85_' num2str(i) '.csv.estimated_indexP.csv'];

    if isfile(f85_01)
        T1 = readtable(f85_01);
        T2 = readtable(f85_02);
        T = [T1; T2];

        for y = proj_years
            fx = year(T.date)==y & month(T.date)>=m1 & month(T.date)<=m2;
            vals = T.indexP(fx);
            if isempty(vals), continue; end

            if north_idx(i)
                data.rcp85.north{y} = [data.rcp85.north{y}; vals];
            elseif west_idx(i)
                data.rcp85.west{y}  = [data.rcp85.west{y}; vals];
            elseif ce_idx(i)
                data.rcp85.ce{y}    = [data.rcp85.ce{y}; vals];
            elseif south_idx(i)
                data.rcp85.south{y} = [data.rcp85.south{y}; vals];
            end
        end
    end
end

toc
x_stops = [0, 1, 2]; 
color_points = [
    0.0, 0.0, 0.6; 
    1.0, 1.0, 1.0; 
    0.7, 0.0, 0.0  
];

n = 256;
custom_map = interp1(x_stops, color_points, linspace(0, 2, n));
all_years_list = [hind_years, proj_years];
hist_end_idx = find(all_years_list == 2024);
scenarios = {'rcp45', 'rcp85'};
main_titles = {'Annual 75th percentile of Index-P climatic suitability for WNV under Scenario 4.5', 'Annual 75th percentile of Index-P climatic suitability for WNV under Scenario 8.5'};

for s = 1:2
    current_scenario = scenarios{s};
    plot_matrix = nan(4, length(all_years_list));
    
    for r = 1:4
        reg = regions{r};
        for j = 1:length(all_years_list)
            yr = all_years_list(j);
            if yr <= 2024
                vals = data.hind.(reg){yr};
            else
                vals = data.(current_scenario).(reg){yr};
            end
            
            if ~isempty(vals)
                plot_matrix(r, j) = quantile(vals,0.75);
                max(max(plot_matrix))
            end
        end
    end
    
    figure('Color', 'w', 'Position', [100, 100, 1100, 420]);
    imagesc(plot_matrix);
    colormap(custom_map);
    
    clim([0, 1.8]); 
    cb = colorbar;
    ylabel(cb, 'Index-P_{Q75}', 'FontSize', 13, 'Interpreter', 'tex', 'FontWeight', 'bold');
    
    title(main_titles{s}, 'FontSize', 15, 'FontWeight', 'bold');
    set(gca, 'YTick', 1:4, 'YTickLabel', regionTitles, 'TickDir', 'out', 'FontSize', 12, 'FontWeight', 'bold');
    
    xticks_pos = 1:5:length(all_years_list);
    set(gca, 'XTick', xticks_pos, 'XTickLabel', all_years_list(xticks_pos));
    xtickangle(45);
    
    hold on;
    line([hist_end_idx + 0.5, hist_end_idx + 0.5], [0.5, 4.5], 'Color', 'k', 'LineWidth', 3);
    
    ylabel('Regions', 'FontWeight', 'bold');
    xlabel('Year', 'FontWeight', 'bold');
    
    axis tight;
    grid off;
    set(gca,'Fontsize',18)
end