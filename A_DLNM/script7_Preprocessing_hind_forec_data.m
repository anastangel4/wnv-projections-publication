clear; clc;
northEU = {'UK','DK','EE','FI','IS','IE','LV','LT','NO','SE','GB'};
westEU  = {'AT','BE','FR','DE','LI','LU','MC','NL','CH'};
ceEU    = {'BG','CZ','HU','PL','RO','SK','SI','HR','BA','ME','MK','RS','AL','XK'};
southEU = {'AD','CY','ES','EL','IT','MT','PT','SM','TR'};

regions = struct();
regions.noEU = northEU;
regions.weEU = westEU;
regions.ceEU = ceEU;
regions.soEU = southEU;
regionNames = fieldnames(regions);
threshold = 1.5;
load('PlaceID_table.mat')
NUTS3_list = PlaceID_table.NUTS3;
hind = readtable('scripts/results/weekly_RR_hindcast.csv');
hind = removevars(hind, ["t_mean","prep_cum","RR_temp","RR_prep", ...
                         "RR_temp_bin","RR_prep_bin","RR_sum_bin"]);
hind.NUTS3 = cell(height(hind),1);
for i = 1:height(hind)
    hind.NUTS3{i} = NUTS3_list{hind.NUTS_ID(i)};
end
hind.Region = strings(height(hind),1);
hind.Region = strings(height(hind),1);
for i = 1:height(hind)
    cc = extractBetween(hind.NUTS3{i},1,2);
    for r = 1:numel(regionNames)
        if ismember(cc, regions.(regionNames{r}))
            hind.Region(i) = regionNames{r};
            break
        end
    end
end
save('hind.mat','hind')
sc45 = readtable('scripts/results/weekly_45.csv');
sc45 = removevars(sc45, ["t_mean","prep_cum","RR_temp","RR_prep", ...
                         "period","RR_temp_bin","RR_prep_bin","RR_sum_bin"]);
sc45.NUTS3 = cell(height(sc45),1);
for i = 1:height(sc45)
    sc45.NUTS3{i} = NUTS3_list{sc45.NUTS_ID(i)};
end
sc45.Region = strings(height(sc45),1);
for i = 1:height(sc45)
    cc = extractBetween(sc45.NUTS3{i},1,2);
    for r = 1:numel(regionNames)
        if ismember(cc, regions.(regionNames{r}))
            sc45.Region(i) = regionNames{r};
            break
        end
    end
end
save('sc45.mat','sc45')
sc85 = readtable('scripts/results/weekly_85.csv');
sc85 = removevars(sc85, ["t_mean","prep_cum","RR_temp","RR_prep", ...
                         "period","RR_temp_bin","RR_prep_bin","RR_sum_bin"]);
sc85.NUTS3 = cell(height(sc85),1);
for i = 1:height(sc85)
    sc85.NUTS3{i} = NUTS3_list{sc85.NUTS_ID(i)};
end
sc85.Region = strings(height(sc85),1);
for i = 1:height(sc85)
    cc = extractBetween(sc85.NUTS3{i},1,2);
    for r = 1:numel(regionNames)
        if ismember(cc, regions.(regionNames{r}))
            sc85.Region(i) = regionNames{r};
            break
        end
    end
end
save('sc85.mat','sc85')
