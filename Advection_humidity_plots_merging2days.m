% code to merge 2 advection days
close all; clear all;

year=2021; month=10;
day1=8; day2=day1+1;

horaini = 15; horafin=9;
starttime=horaini; endtime=horafin;

path_netcdf= '/path/to/NetCDFoutput/';
path_figs = '/path/to/outputFigures/';

set(groot, 'DefaultAxesFontSize', 13);
set(groot, 'DefaultTextFontSize', 13);

min_height_abl=100; max_height_abl=1300; % all column ABL
minheight_surf=433; maxheight_surf=700;
minheight_upperabl=maxheight_surf; maxheight_upperabl=1300;

%% humidity directions:
file_humdirections_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_hum_directions.nc']);
finfo = ncinfo(file_humdirections_day1); variable_names = {finfo.Variables.Name};
humEast_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(1))); humWest_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(2)));
humNorth_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(3))); humSouth_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(4)));
humZenith_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(5)));
timemwr_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(6))); heightMWR_ta_day1 = ncread(file_humdirections_day1,cell2mat(variable_names(7)));

file_humiditydirections_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_hum_directions.nc']);
humEast_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(1))); humWest_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(2)));
humNorth_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(3))); humSouth_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(4)));
humZenith_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(5)));
timemwr_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(6))); heightMWR_ta_day2 = ncread(file_humiditydirections_day2,cell2mat(variable_names(7)));

%merging variables:
timemwr2days = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);
humEast2days = [humEast_day1',humEast_day2']; humWest2days = [humWest_day1',humWest_day2'];
humNorth2days = [humNorth_day1',humNorth_day2']; humSouth2days = [humSouth_day1',humSouth_day2'];
humZenith2days = [humZenith_day1',humZenith_day2']; 

% fig temperature in each direction:
min_color_hum=0; max_color_hum=8; step_colorq=.5; extraabl=500;
aaHum = (nclCM('CBR_drywet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
startdatetime= datetime(year,month,day1,starttime,0,0); enddatetime= datetime(year,month,day2,endtime,0,0);

figure('position',[1,1,1800,900],'Renderer','painters');
subplot(2,2,1)
pcolor(timemwr2days,heightMWR_ta_day1,humEast2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaHum = (nclCM('CBR_wet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
colormap(aaHum); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('a)    q East'); caxis([min_color_hum max_color_hum])
%xlabel('date-time UTC [hr]'); 
hcb_hum=colorbar;
colorTitleHandle_hum = get(hcb_hum,'Title');
titleString_hum = '[g kg^{-1} ]';
set(colorTitleHandle_hum ,'String',titleString_hum); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(2,2,2)
pcolor(timemwr2days,heightMWR_ta_day1,humWest2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaHum = (nclCM('CBR_wet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
colormap(aaHum); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('b)    q West'); caxis([min_color_hum max_color_hum])
%xlabel('date-time UTC [hr]');
hcb_hum=colorbar;
colorTitleHandle_hum = get(hcb_hum,'Title');
titleString_hum = '[g kg^{-1} ]';
set(colorTitleHandle_hum ,'String',titleString_hum);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(2,2,3)
pcolor(timemwr2days,heightMWR_ta_day1,humNorth2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaHum = (nclCM('CBR_wet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
colormap(aaHum); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('d)    q North'); caxis([min_color_hum max_color_hum])
xlabel('date-time UTC [hr]'); 
hcb_hum=colorbar;
colorTitleHandle_hum = get(hcb_hum,'Title');
titleString_hum = '[g kg^{-1} ]';
set(colorTitleHandle_hum ,'String',titleString_hum);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(2,2,4)
pcolor(timemwr2days,heightMWR_ta_day1,humSouth2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaHum = (nclCM('CBR_wet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
colormap(aaHum); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('e)    q South'); caxis([min_color_hum max_color_hum])
xlabel('date-time UTC [hr]'); 
hcb_hum=colorbar;
colorTitleHandle_hum = get(hcb_hum,'Title');
titleString_hum = '[g kg^{-1} ]';
set(colorTitleHandle_hum ,'String',titleString_hum);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

saveas(figure(1),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_humidity_directions_2days.png'])

%% Hum dif zonal and meridional

file_humdif_zonalmeridional_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_humidity_dif_zonal_meridional.nc']);
finfodif = ncinfo(file_humdif_zonalmeridional_day1); variabledif_name = {finfodif.Variables.Name};
humzonal_day1 = ncread(file_humdif_zonalmeridional_day1,cell2mat(variabledif_name(1)));
hummeridional_day1 = ncread(file_humdif_zonalmeridional_day1,cell2mat(variabledif_name(2)));
timegrid_day1 = ncread(file_humdif_zonalmeridional_day1,cell2mat(variabledif_name(3)));
heightfitfit_day1 = ncread(file_humdif_zonalmeridional_day1,cell2mat(variabledif_name(4)));

file_humdif_zonalmeridional_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_humidity_dif_zonal_meridional.nc']);
humzonal_day2 = ncread(file_humdif_zonalmeridional_day2,cell2mat(variabledif_name(1)));
hummeridional_day2 = ncread(file_humdif_zonalmeridional_day2,cell2mat(variabledif_name(2)));
timegrid_day2 = ncread(file_humdif_zonalmeridional_day2,cell2mat(variabledif_name(3)));
heightfitfit_day2 = ncread(file_humdif_zonalmeridional_day2,cell2mat(variabledif_name(4)));

%merging variables:
timegrid2days = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

hum_difzonal_2days = [humzonal_day1', humzonal_day2']; 
hum_difmeridional_2days = [hummeridional_day1', hummeridional_day2'];


% figure:
min_colorHumdif=-0.5; max_colorHumdif=-min_colorHumdif; step_colorHumdif=0.0005;
aaHumdif = (nclCM('cmp_b2r',(size(min_colorHumdif:step_colorHumdif:max_colorHumdif,2)-1)));
%dTempdxzonal=1000.*dTempdxzonal; dTempdymeridional=1000.*dTempdymeridional; % converting from m to km

figure('position',[1,1,800,1200],'Renderer','painters');
subplot(2,1,1)
pcolor(timegrid2days,heightfitfit_day1,hum_difzonal_2days); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]); grid on;
aaHumdif = (nclCM('BrownBlue12',(size(min_colorHumdif:step_colorHumdif:max_colorHumdif,2)-1)));
colormap(aaHumdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('c)    (q_E-q_W)(\Deltax)^{-1}'); caxis([min_colorHumdif max_colorHumdif])
colorbar;
hcb_humdif=colorbar;
colorTitleHandle_humdif = get(hcb_humdif,'Title');
titleString_humdif = '[g kg^{-1} km^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_humdif);
%xlabel('date-time UTC [hr]'); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(2,1,2)
pcolor(timegrid2days,heightfitfit_day1,hum_difmeridional_2days); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]); grid on;
aaHumdif = (nclCM('BrownBlue12',(size(min_colorHumdif:step_colorHumdif:max_colorHumdif,2)-1)));
colormap(aaHumdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('f)    (q_N-q_S)(\Deltay)^{-1}'); 
xlabel('date-time UTC [hr]'); caxis([min_colorHumdif max_colorHumdif]);
hcb_humdif=colorbar;
colorTitleHandle_humdif = get(hcb_humdif,'Title');
titleString_humdif = '[g kg^{-1} km^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_humdif);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

saveas(figure(2),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_humidity_dif_zonal_meridional_2days.png'])
%saveas(figure(2),[path_figs,'humidity_dif_zonal_meridional_2days.png'])

%% wind
%heightWDL; u_ABL=uzonalvel; v_ABL=vmeridionalvel; yliminf=minheight_surf-50; ylimsup=maxheight_upperabl+50;
min_color_velocity = 0; step_color_velocity = 10;
min_color_vel = -400; max_color_vel =-min_color_vel; stepquiv=2; % spacing between vectors for quiver
minVcolor=-12; maxVcolor=-minVcolor;
dontsaturate=1; eps=1;
scale=1.3; 

file_wind_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_wind.nc']);
finfowind = ncinfo(file_wind_day1); variablewind_name = {finfowind.Variables.Name};
zonalwind_day1 = ncread(file_wind_day1,cell2mat(variablewind_name(1))); meridionalwind_day1 = ncread(file_wind_day1,cell2mat(variablewind_name(2)));
timewind_day1 = ncread(file_wind_day1,cell2mat(variablewind_name(3))); heightwind_day1 = ncread(file_wind_day1,cell2mat(variablewind_name(4)));

file_wind_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_wind.nc']);
zonalwind_day2 = ncread(file_wind_day2,cell2mat(variablewind_name(1))); meridionalwind_day2 = ncread(file_wind_day2,cell2mat(variablewind_name(2)));
timewind_day2 = ncread(file_wind_day2,cell2mat(variablewind_name(3))); heightwind_day2 = ncread(file_wind_day2,cell2mat(variablewind_name(4)));

%merging variables:
decimaltimeWDLday1= datetime(year, month,day1,0,30,0):hours(0.25):datetime(year,month,day1,23,30,0);
decimaltimeWDLday2= datetime(year, month,day2,0,30,0):hours(0.25):datetime(year,month,day2,23,0,0);
decimaltimeWDL2days = [decimaltimeWDLday1,decimaltimeWDLday2]

windzonal_2days = [zonalwind_day1',zonalwind_day2']; 
windmeridional_2days = [meridionalwind_day1', meridionalwind_day2']; 

%% for plot wind rose
hrini = find(hour(decimaltimeWDL2days)==21); hrini=hrini(1);
hrfini = find(hour(decimaltimeWDL2days)==0); hrfini=hrfini(3);
idx_abl = heightwind_day1 >= minheight_surf & heightwind_day1 <= maxheight_upperabl;
u_layer_abl = mean(windzonal_2days(idx_abl,hrini:hrfini),1,'omitnan');
v_layer_abl = mean(windmeridional_2days(idx_abl,hrini:hrfini),1,'omitnan');
ws_abl = hypot(u_layer_abl,v_layer_abl);
wd_abl = mod(270 - atan2d(v_layer_abl,u_layer_abl),360);
dirEdges = 0:10:360; spdEdges= [0 5 10 15 20];
N = histcounts2(ws_abl,wd_abl,spdEdges,dirEdges);
N = N/sum(N(:))*100;
addpath('/home/andreaburgos/Documentos/Koeln/ideasPaper-20260204T224132Z-1-002/ideasPaper/mlocal_in_unam/wind_rose')
savepath

spdEdges = [0 2 4 6 8 10 15 20]; nSpeedBins = length(spdEdges)-1; 
 colors = jet(nSpeedBins); %colors = parula(nSpeedBins);
bottom = zeros(1,size(N,2));

% figure
figure('position',[1,1,1500,550],'Renderer','painters');
subplot(2,3,1:2); pcolor(decimaltimeWDL2days,heightwind_day2,windzonal_2days); %shading interp
% hold on; quiver(hour(decimaltimeWDL2days(1:stepquiv:end)),heightwind_day1(1:stepquiv:end),...
%     windzonal_2days(1:stepquiv:end,(1:stepquiv:end))',windmeirdional_2days(1:stepquiv:end,(1:stepquiv:end))', scale,'k','LineWidth',1.5);
title('a)    Zonal wind u')
aa1 = (nclCM('NCV_blu_red',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
% aa1(end,:) = [.8 .8 .8]; % xlim([startdatetime enddatetime]); 
% %cc = colorbar;  cc.Ticks = [min_color_vel:step_color_velocity*4:max_color_vel];
% %c.Color = 'black';    c.Box = 'off';    c.Location = 'EastOutside';
colormap(aa1); 
grid on; ylim([minheight_surf maxheight_upperabl]); ylabel('height [m]')
colorbar; ylim([400, 1300])
caxis([minVcolor maxVcolor])
xlabel('date-time UTC [hr]'); shading flat; 
hcb_velocities=colorbar; xlim([startdatetime enddatetime]); 
colorTitleHandle_velocities = get(hcb_velocities,'Title');
titleString_velocities = '[ms^{-1}]';
set(colorTitleHandle_velocities ,'String',titleString_velocities); 
xticks(startdatetime: hours(2) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,3,4:5); pcolor(decimaltimeWDL2days,heightwind_day2(2:end),windmeridional_2days(2:end,:)); %shading interp
% hold on; quiver(hour(decimaltimeWDL2days(1:stepquiv:end)),heightwind_day1(1:stepquiv:end),...
%     windzonal_2days(1:stepquiv:end,(1:stepquiv:end))',windmeirdional_2days(1:stepquiv:end,(1:stepquiv:end))', scale,'k','LineWidth',1.5);
title('b)    Meridional wind v')
aa1 = (nclCM('NCV_blu_red',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
% aa1(end,:) = [.8 .8 .8]; % xlim([startdatetime enddatetime]); 
% %cc = colorbar;  cc.Ticks = [min_color_vel:step_color_velocity*4:max_color_vel];
% %c.Color = 'black';    c.Box = 'off';    c.Location = 'EastOutside';
colormap(aa1); 
grid on; ylim([minheight_surf maxheight_upperabl]); ylabel('height [m]')
colorbar;  caxis([minVcolor maxVcolor])
xlabel('date-time UTC [hr]');  shading flat; 
hcb_velocities=colorbar; xlim([startdatetime enddatetime]); 
colorTitleHandle_velocities = get(hcb_velocities,'Title');
titleString_velocities = '[ms^{-1}]';
set(colorTitleHandle_velocities ,'String',titleString_velocities); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm'), ylim([400, 1300])
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,3,6)
%polarhistogram(deg2rad(wd_abl),dirEdges*pi/180); title('c)     from 0200 to 0400 UTC')
%wind_rose(wd_abl,ws_abl); 

for k = 1:size(N,1)

    polarhistogram( ...
        'BinEdges',deg2rad(dirEdges), ...
        'BinCounts',bottom + N(k,:), ...
        'FaceColor',colors(k,:), ...
        'EdgeColor','none');
    hold on
    bottom = bottom + N(k,:);
    pax = gca;
pax.ThetaZeroLocation = 'top';
pax.ThetaDir = 'clockwise';
legend%([' 0-5 m s^{-1}'; '5-10 m s^{-1}'; '10-15 m s^{-1}'; '15-20 m s^{-1}']);
title('c)     from 2100 to 0000 UTC')
end

saveas(figure(3),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_wind_2days.png'])

%% Hum uncertainty

file_hum_uncert_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_humidity_advection_uncert.nc']);
finfodif = ncinfo(file_hum_uncert_day1); variableuncert_name = {finfodif.Variables.Name};
advectionhumzonal_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(1)));
uncert_advectionhumzonal_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(2)));
advectionhummeridional_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(3)));
uncert_advectionhummeridional_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(4)));
uncert_advectionhum_total_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(5)));
timegrid_day1 = ncread(file_hum_uncert_day1,cell2mat(variableuncert_name(6)));

file_hum_uncert_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_humidity_advection_uncert.nc']);
advectionhumzonal_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(1)));
uncert_advectionhumzonal_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(2)));
advectionhummeridional_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(3)));
uncert_advectionhummeridional_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(4)));
uncert_advectionhum_total_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(5)));
timegrid_day2 = ncread(file_hum_uncert_day2,cell2mat(variableuncert_name(6)));

%merging variables:
timegrid2days_uncert = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

advection_zonal_2days = ([advectionhumzonal_day1', advectionhumzonal_day2']); 
advection_meridional_2days = ([advectionhummeridional_day1',advectionhummeridional_day2']); 
advection_total_allabl2days = (advection_zonal_2days+advection_meridional_2days);
for i=1:length(advection_total_allabl2days); if advection_total_allabl2days(i)<-10; advection_total_2days(i)=-10; end; end
for i=1:length(advection_zonal_2days); if advection_zonal_2days(i)<-10; advection_zonal_2days(i)=-10; end; end
for i=1:length(advection_meridional_2days); if advection_meridional_2days(i)<-10; advection_meridional_2days(i)=-10; end; end

uncert_advection_zonal_2days = smooth([uncert_advectionhumzonal_day1', uncert_advectionhumzonal_day2']); 
uncert_advection_meridional_2days = smooth([uncert_advectionhummeridional_day1', uncert_advectionhummeridional_day2']); 
uncert_advection_total_2days = smooth(uncert_advection_zonal_2days+uncert_advection_meridional_2days);

% sigma_advection_temp_adj=sigma_advection_temp(1:length(timegrid)); 
% sigma_advection_temp_adj_zonal=sigma_advection_temp_zonal(1:length(timegrid)); sigma_advection_temp_adj_meridional=sigma_advection_temp_meridional(1:length(timegrid)); 
%sigma_gradient_temp=sigma_gradient_temp;
minlim=-17; maxlim = -minlim;
bluebonito = [0.1 0.4 0.8]; redbonito = [0.8 0.3 0.3]; purplebonito = [0.7 0.3 0.7];

figure('position',[1,1,1400,500],'Renderer','painters'); 

subplot(1,2,1)
plot(timegrid2days_uncert,advection_zonal_2days, 'Color', bluebonito,'LineWidth',2); hold on; 
plot(timegrid2days_uncert, advection_meridional_2days,  'color', purplebonito, 'LineWidth',2); hold on
%plot(timegrid,advection_total_allabl,'r', 'LineWidth',1); grid on
xlabel('date-time UTC [hr]');  xlim([startdatetime enddatetime]); ylabel('q advection [g kg^{-1} hr^{-1}]'); %ylim([min_height_abl, maxheight_upperabl])
% hold on
% fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
%      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on; grid on;
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [smooth(advection_zonal_2days)'-uncert_advection_zonal_2days'...
    fliplr(smooth(advection_zonal_2days)'+uncert_advection_zonal_2days')], ...
     bluebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on; grid on; ylim([-11, 11])
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [smooth(advection_meridional_2days)'-uncert_advection_meridional_2days'...
    fliplr(smooth(advection_meridional_2days)'+uncert_advection_meridional_2days')], ...
     purplebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
xticks(startdatetime: hours(2) :enddatetime) 
xtickformat('HH:mm')
legend([ 'u\cdot(\Delta q/\Deltax)'; 'v\cdot(\Delta q/\Deltay)'])
    %'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title(['                                                        a)         q advection in ABL (',num2str(minheight_surf),'-',...
    num2str(maxheight_upperabl),' m) ']);
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';


subplot(1,2,2)
plot(timegrid2days_uncert,advection_total_allabl2days,'color', redbonito, 'LineWidth',2); grid on
% title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
%     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
xlabel('date-time UTC [hr]'); xlim([startdatetime enddatetime]); ylabel('q advection [g kg^{-1} hr^{-1}]'); ylim([-5, 5])
hold on
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [smooth(advection_total_allabl2days)'+uncert_advection_total_2days'...
    fliplr(smooth(advection_total_allabl2days)')], ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on; ylim([-11, 11])
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [smooth(advection_total_allabl2days)'-uncert_advection_total_2days'...
    fliplr(smooth(advection_total_allabl2days)')], ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none'); 
xticks(startdatetime: hours(2) :enddatetime) 
xtickformat('HH:mm')
% legend([ '       u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)        '; ...
%     'uncertainty of u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title('b)');
legend([ 'u\cdot(\Deltaq/\Deltax)+v\cdot(\Deltaq/\Deltay)'])
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

saveas(figure(4),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_humidity_Advection_Uncertainty_2days.png'])
%saveas(figure(4),[path_figs,'humidity_advect_uncert_2days.png'])


%% for plotting colors:
min_color=-1.5; max_color=-min_color; step_color=0.2;
colorzonal = [0.1 0.5 0.50]; colormeridional = [0.6 0.3 0.5];
%starttime=8; endtime=22; minhum=5; maxhum=10;
scale=1; % scale for quiver wind vectors
Gray1 = [128 128 128]/255; Gray2 = [100 100 128]/255; Gray3 = [75 75 128]/255; Gray4 = [60 60 128]/255;
 
%% Advection plots

file_humidity_Advect_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_humidity_advection.nc']);
finfodif = ncinfo(file_humidity_Advect_day1); variableuncert_name = {finfodif.Variables.Name};
advection_height_humzonal_day1 = ncread(file_humidity_Advect_day1,cell2mat(variableuncert_name(1)));
advection_height_hummeridional_day1 = ncread(file_humidity_Advect_day1,cell2mat(variableuncert_name(2)));
timegrid_day1 = ncread(file_humidity_Advect_day1,cell2mat(variableuncert_name(3)));
heightfitfit_day1 = ncread(file_humidity_Advect_day1,cell2mat(variableuncert_name(4)));

file_humidity_Advect_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_humidity_advection.nc']);
advection_height_humzonal_day2 = ncread(file_humidity_Advect_day2,cell2mat(variableuncert_name(1)));
advection_height_hummeridional_day2 = ncread(file_humidity_Advect_day2,cell2mat(variableuncert_name(2)));
timegrid_day2 = ncread(file_humidity_Advect_day2,cell2mat(variableuncert_name(3)));
heightfitfit_day2 = ncread(file_humidity_Advect_day2,cell2mat(variableuncert_name(4)));

%merging variables:
timegrid2days_advect = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

% day1 + day 2
advection_height_zonal_2days = [advection_height_humzonal_day1',advection_height_humzonal_day2']; 
advection_height_meridional_2days = [advection_height_hummeridional_day1', advection_height_hummeridional_day2']; 
advection_height_total_allabl2days = advection_height_zonal_2days+advection_height_meridional_2days;

min_colorAdv= -7; max_colorAdv=-min_colorAdv; step_colorAdv =0.1;
max_color_hum = 6;


%% for ploting IWV:

file_IWV_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_IWV.nc']);
finfoiwv = ncinfo(file_IWV_day1); variable_names = {finfoiwv.Variables.Name};
IWV_day1 = ncread(file_IWV_day1,cell2mat(variable_names(1))); IWV_day1=IWV_day1(1:100:end);
timeiwv_day1 = ncread(file_IWV_day1,cell2mat(variable_names(2))); timeiwv_day1 = timeiwv_day1(1:100:end);

file_IWV_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_IWV.nc']);
IWV_day2 = ncread(file_IWV_day2,cell2mat(variable_names(1))); IWV_day2=IWV_day2(1:100:end);
%timeiwv_day2 = ncread(file_IWV_day2,cell2mat(variable_names(2)));

%merging variables:
tdec = linspace(0,23.9833,696); t1 = datetime(year,month,day1); time1 = t1 + hours(tdec);
t2 = datetime(year,month,day2); time2 = t2 + round(hours(tdec)); 
time_iwv_2days = [time1, time2];
IWV_2days = [IWV_day1; IWV_day2];


figure('position',[1,1,1000,3000],'Renderer','painters');

subplot(5,1,1)
plot(time_iwv_2days,smooth(IWV_2days),'LineWidth',2); grid on; colorbar
ylabel('IWV [kg m^{-2}]')
xticks(time_iwv_2days(436:15:length(timeiwv_day1)+262)) 
xtickformat('HH:mm'); title('a)    IWV');
%yticks(100*round(minheight_surf/100):100:maxheight_upperabl+extraabl)
xlim([startdatetime, enddatetime]); ylim([9.5, 19]); 

subplot(5,1,2); 
pcolor(timemwr2days,heightMWR_ta_day1,humZenith2days); 
aaHum = (nclCM('CBR_wet',(size(min_color_hum:step_colorq:max_color_hum,2)-1)));
colormap(aaHum); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('b)    q at zenith'); caxis([min_color_hum max_color_hum])
%xlabel('time UTC [hours]'); 
hcb_hum=colorbar;  ylim([minheight_surf+30, maxheight_upperabl+100]); 
colorTitleHandle_hum = get(hcb_hum,'Title');
titleString_hum = '[g kg^{-1}]';  xlim([startdatetime, enddatetime]); 
set(colorTitleHandle_hum ,'String',titleString_hum); 
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(100*round(minheight_surf/100):400:maxheight_upperabl+extraabl)

subplot(5,1,3); 
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_zonal_2days); 
title('c)    u\cdot(\Deltaq/\Deltax)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); %xlabel('time UTC [hours]'); 
hcb_humdif=colorbar;
colorTitleHandle_humdif = get(hcb_humdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(100*round(minheight_surf/100):400:maxheight_upperabl+extraabl)

subplot(5,1,4); 
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_meridional_2days); 
title('d)    v\cdot(\Deltaq/\Deltay)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); %xlabel('time UTC [hours]'); 
hcb_humdif=colorbar;
colorTitleHandle_humdif = get(hcb_humdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(100*round(minheight_surf/100):400:maxheight_upperabl+extraabl)

subplot(5,1,5);
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_total_allabl2days); 
title('e)    u\cdot(\Deltaq/\Deltax)+v\cdot(\Deltaq/\Deltay)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]); ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); xlabel('date-time UTC [hr]'); 
hcb_humdif=colorbar;
colorTitleHandle_humdif = get(hcb_humdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(100*round(minheight_surf/100):400:maxheight_upperabl+extraabl)

saveas(figure(5),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_AdvectionHumidity_2days.png'])
%saveas(figure(5),[path_figs,'Advection_humidity_2days.png'])


