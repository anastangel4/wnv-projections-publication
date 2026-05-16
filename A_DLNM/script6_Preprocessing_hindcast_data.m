clear all
load('PlaceID_table.mat')
nuts=PlaceID_table.rows;
S=shaperead('NUTS_RG_01M_2021_4326_LEVL_3.shp\NUTS_RG_01M_2021_4326_LEVL_3.shp');
OR=readtable('scripts\results\mean_RR_days_hindcast.csv');
tfx=find(OR.RR_sum_bin<1.5);
OR(tfx,:)=[];
OR = groupsummary(OR, "NUTS_ID", "sum", "mean_days_per_year");
OR_days=round(OR.sum_mean_days_per_year);
munia=1:1514;
del=[];
for i=1:1514 
    tfx=find(PlaceID_table.rows==i); 
    if (~isempty(tfx))
        tfind=find(OR.NUTS_ID==tfx);
    else
        tfind=[];
    end
    if (isempty(tfx))
        S(i).OR=NaN;
        del=[del;i];
    elseif  (~isempty(tfx) && isempty(tfind))
        S(i).OR=0;
    else
        S(i).OR=OR_days(tfind);
        
    end
end
S2.Hind=[S.OR];
save('S2.mat',"S2")
