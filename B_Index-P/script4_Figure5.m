clear; close all; clc
tic

S = shaperead('NUTS_RG_01M_2021_4326_LEVL_3.shp\NUTS_RG_01M_2021_4326_LEVL_3.shp');
northEU = {'UK','DK','EE','FI','IS','IE','LV','LT','NO','SE','GB'};
westEU  = {'AT','BE','FR','DE','LI','LU','MC','NL','CH'};
ceEU    = {'BG','CZ','HU','PL','RO','SK','SI','HR','BA','ME','MK','RS','AL','XK'};
southEU = {'AD','CY','ES','EL','IT','MT','PT','SM','TR'};

north_idx = find(ismember({S.CNTR_CODE}, northEU));
west_idx  = find(ismember({S.CNTR_CODE}, westEU));
ce_idx    = find(ismember({S.CNTR_CODE}, ceEU));
south_idx = find(ismember({S.CNTR_CODE}, southEU));

regionStruct.north = north_idx;
regionStruct.west  = west_idx;
regionStruct.ce    = ce_idx;
regionStruct.south = south_idx;

regions = fieldnames(regionStruct);
hind_years = 2010:2024;
proj_nf = 2061:2075;
proj_ff = 2076:2090;

threshold = 1;
days_in_month = 30.44;

for r = 1:numel(regions)

    region = regions{r};
    nuts_list = regionStruct.(region);

    season.(region).hind = [];
    season.(region).rcp45_nf = [];
    season.(region).rcp45_ff = [];
    season.(region).rcp85_nf = [];
    season.(region).rcp85_ff = [];

    for y = hind_years

        dailyTable = table();

        for i = nuts_list

            f = fullfile('hindcast',[num2str(i) '.csv.estimated_indexP.csv']);
            if ~isfile(f), continue; end

            T = readtable(f);
            fy = year(T.date)==y;

            T = T(fy,{'date','indexP'});
            dailyTable = [dailyTable; T];
        end

        if isempty(dailyTable), continue; end

        [uDates,~,idx] = unique(dailyTable.date);
        maxVals = accumarray(idx,dailyTable.indexP,[],@max);

        active = maxVals > threshold;

        if any(active)
            firstDay = uDates(find(active,1,'first'));
            lastDay  = uDates(find(active,1,'last'));
            duration_days = days(lastDay - firstDay) + 1;
            duration_months = duration_days / days_in_month;

            season.(region).hind = ...
                [season.(region).hind; duration_months];
        end
    end

    for y = [proj_nf proj_ff]

        dailyTable = table();

        for i = nuts_list

            if y <= 2075
                f = ['2061-2075/proj45/proj45_' num2str(i) '.csv.estimated_indexP.csv'];
            else
                f = ['2076-2090/proj45/proj45_' num2str(i) '.csv.estimated_indexP.csv'];
            end

            if ~isfile(f), continue; end

            T = readtable(f);
            fy = year(T.date)==y;

            T = T(fy,{'date','indexP'});
            dailyTable = [dailyTable; T];
        end

        if isempty(dailyTable), continue; end

        [uDates,~,idx] = unique(dailyTable.date);
        maxVals = accumarray(idx,dailyTable.indexP,[],@max);

        active = maxVals > threshold;

        if any(active)
            firstDay = uDates(find(active,1,'first'));
            lastDay  = uDates(find(active,1,'last'));
            duration_days = days(lastDay - firstDay) + 1;
            duration_months = duration_days / days_in_month;

            if y <= 2075
                season.(region).rcp45_nf = ...
                    [season.(region).rcp45_nf; duration_months];
            else
                season.(region).rcp45_ff = ...
                    [season.(region).rcp45_ff; duration_months];
            end
        end
    end

    for y = [proj_nf proj_ff]

        dailyTable = table();

        for i = nuts_list

            if y <= 2075
                f = ['2061-2075/proj85/proj85_' num2str(i) '.csv.estimated_indexP.csv'];
            else
                f = ['2076-2090/proj85/proj85_' num2str(i) '.csv.estimated_indexP.csv'];
            end

            if ~isfile(f), continue; end

            T = readtable(f);
            fy = year(T.date)==y;

            T = T(fy,{'date','indexP'});
            dailyTable = [dailyTable; T];
        end

        if isempty(dailyTable), continue; end

        [uDates,~,idx] = unique(dailyTable.date);
        maxVals = accumarray(idx,dailyTable.indexP,[],@max);

        active = maxVals > threshold;

        if any(active)
            firstDay = uDates(find(active,1,'first'));
            lastDay  = uDates(find(active,1,'last'));
            duration_days = days(lastDay - firstDay) + 1;
            duration_months = duration_days / days_in_month;

            if y <= 2075
                season.(region).rcp85_nf = ...
                    [season.(region).rcp85_nf; duration_months];
            else
                season.(region).rcp85_ff = ...
                    [season.(region).rcp85_ff; duration_months];
            end
        end
    end
end

toc

regionTitles = {'Northern Europe', 'Western Europe', 'Central & Eastern Europe', 'Southern Europe'};
colors = [0.0, 0.4, 0.7;  
          1.0, 0.6, 0.2;  
          1.0, 0.6, 0.2;  
          0.8, 0.2, 0.2;  
          0.8, 0.2, 0.2]; 

periodLabels = {'Historical', 'Scnr 4.5 (Near)', 'Scnr 4.5 (Far)', 'Scnr 8.5 (Near)', 'Scnr 8.5 (Far)'};

for r = 1:numel(regions)
    region = regions{r};
    figure('Color', 'w', 'Position', [100, 100, 800, 600]);
    hold on;
    
    data_cells = {season.(region).hind, ...
                  season.(region).rcp45_nf, season.(region).rcp45_ff, ...
                  season.(region).rcp85_nf, season.(region).rcp85_ff};
    
    overlap = 0.8; 
    
    for i = 1:5 
        d = data_cells{i};
        if isempty(d), continue; end
        
        [f, x] = ksdensity(d, 'BoundaryCorrection', 'reflection', 'Bandwidth', 0.2);
        f = f / max(f) * overlap;
        
        fill([x(1) x x(end)], [i i+f i], colors(i,:), ...
            'FaceAlpha', 0.8, 'EdgeColor', 'k', 'LineWidth', 1.2);
        
        med = median(d);
        [~, idx] = min(abs(x - med));
        line([med med], [i i+f(idx)], 'Color', 'w', 'LineWidth', 2, 'LineStyle', '--');
    end
    set(gca, 'YTick', 1:5, 'YTickLabel', periodLabels, ...
        'FontSize', 12, 'FontWeight', 'bold');
    
    
    xlabel('Duration of active WNV transmission (months)', 'FontSize', 12);
    title(['Climatic Suitability for WNV Transmission (Index-P): ' regionTitles{r}])
    
    grid on; set(gca, 'XGrid', 'on', 'YGrid', 'off', 'GridAlpha', 0.3);
    xlim([2 7]); ylim([0.5 6]);
    
    set(gca, 'Box', 'off', 'TickDir', 'out');
    hold off;
end
