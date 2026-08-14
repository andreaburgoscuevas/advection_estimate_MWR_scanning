% code to merge 2 advection days
close all; clear all;

year=2022; month=6;
day1=18; day2=19;

horaini = 21; horafin=10;
starttime=horaini; endtime=horafin;

path_netcdf= '/path/to/outputNetCDF/';
path_figs = '/path/to/outputFigures/';

set(groot, 'DefaultAxesFontSize', 13);
set(groot, 'DefaultTextFontSize', 13);

min_height_abl=100; max_height_abl=1300; % all column ABL
mindist=1500; % m this is the minimum horiz dist to estimate advection
minheight_surf= round(mindist/2/tand(60));
maxheight_surf=700;
minheight_upperabl=maxheight_surf; maxheight_upperabl=1300;

%% theta directions:
file_thetadirections_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_theta_directions.nc']);
finfo = ncinfo(file_thetadirections_day1); variable_names = {finfo.Variables.Name};
thetaEast_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(1))); thetaWest_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(2)));
thetaNorth_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(3))); thetaSouth_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(4)));
thetaZenith_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(5)));
timemwr_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(6))); heightMWR_ta_day1 = ncread(file_thetadirections_day1,cell2mat(variable_names(7)));

file_thetadirections_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_theta_directions.nc']);
thetaEast_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(1))); thetaWest_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(2)));
thetaNorth_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(3))); thetaSouth_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(4)));
thetaZenith_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(5)));
timemwr_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(6))); heightMWR_ta_day2 = ncread(file_thetadirections_day2,cell2mat(variable_names(7)));

%merging variables:
timemwr2days = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);
thetaEast2days = [thetaEast_day1',thetaEast_day2']; thetaWest2days = [thetaWest_day1',thetaWest_day2'];
thetaNorth2days = [thetaNorth_day1',thetaNorth_day2']; thetaSouth2days = [thetaSouth_day1',thetaSouth_day2'];
thetaZenith2days = [thetaZenith_day1',thetaZenith_day2']; 

% fig temperature in each direction:
min_colorT=290; max_colorT=310; step_colorT=.5; extraabl=500;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
startdatetime= datetime(year,month,day1,starttime,0,0); enddatetime= datetime(year,month,day2,endtime,0,0);

figure('position',[1,1,1800,900],'Renderer','painters');
subplot(2,2,1)
pcolor(timemwr2days,heightMWR_ta_day1,thetaEast2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('a)    \theta East'); caxis([min_colorT max_colorT])
% hcb_temp=colorbar;
% colorTitleHandle_temp = get(hcb_temp,'Title');
% titleString_temp = '[K]';
% set(colorTitleHandle_temp ,'String',titleString_temp); 
%xlabel('date-time UTC [hr]'); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';
yticks(100*round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(2,2,2)
pcolor(timemwr2days,heightMWR_ta_day1,thetaWest2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   
    shading flat;
title('b)    \theta West'); caxis([min_colorT max_colorT])
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]';
set(colorTitleHandle_temp ,'String',titleString_temp);
%xlabel('date-time UTC [hr]'); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,2,3)
pcolor(timemwr2days,heightMWR_ta_day1,thetaNorth2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('d)    \theta North'); caxis([min_colorT max_colorT])
% hcb_temp=colorbar;
% colorTitleHandle_temp = get(hcb_temp,'Title');
% titleString_temp = '[K]';
% set(colorTitleHandle_temp ,'String',titleString_temp);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
xlabel('date-time UTC [hr]'); 
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,2,4)
pcolor(timemwr2days,heightMWR_ta_day1,thetaSouth2days); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');  
    shading flat;
title('e)    \theta South'); caxis([min_colorT max_colorT])
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]'; 
set(colorTitleHandle_temp ,'String',titleString_temp);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
xlabel('date-time UTC [hr]'); 
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

saveas(figure(1),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_theta_directions_2days.png'])

%% Temp dif zonal and meridional

file_thetadif_zonalmeridional_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_theta_dif_zonal_meridional.nc']);
finfodif = ncinfo(file_thetadif_zonalmeridional_day1); variabledif_name = {finfodif.Variables.Name};
thetazonal_day1 = ncread(file_thetadif_zonalmeridional_day1,cell2mat(variabledif_name(1)));
thetameridional_day1 = ncread(file_thetadif_zonalmeridional_day1,cell2mat(variabledif_name(2)));
timegrid_day1 = ncread(file_thetadif_zonalmeridional_day1,cell2mat(variabledif_name(3)));
heightfitfit_day1 = ncread(file_thetadif_zonalmeridional_day1,cell2mat(variabledif_name(4)));

file_thetadif_zonalmeridional_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_theta_dif_zonal_meridional.nc']);
thetazonal_day2 = ncread(file_thetadif_zonalmeridional_day2,cell2mat(variabledif_name(1)));
thetameridional_day2 = ncread(file_thetadif_zonalmeridional_day2,cell2mat(variabledif_name(2)));
timegrid_day2 = ncread(file_thetadif_zonalmeridional_day2,cell2mat(variabledif_name(3)));
heightfitfit_day2 = ncread(file_thetadif_zonalmeridional_day2,cell2mat(variabledif_name(4)));

%merging variables:
timegrid2days = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

theta_difzonal_2days = [thetazonal_day1', thetazonal_day2']; 
theta_difmeridional_2days = [thetameridional_day1', thetameridional_day2'];

% figure:
min_colorTdif=-0.5; max_colorTdif=-min_colorTdif; step_colorTdif=0.0005;
aaTempdif = (nclCM('cmp_b2r',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));
%dTempdxzonal=1000.*dTempdxzonal; dTempdymeridional=1000.*dTempdymeridional; % converting from m to km

figure('position',[1,1,800,1200],'Renderer','painters');
subplot(2,1,1)
pcolor(timegrid2days,heightfitfit_day1,theta_difzonal_2days); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]); grid on;
aaTempdif = (nclCM('CBR_coldhot',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('c)    (\theta_E-\theta_W)(\Deltax)^{-1}'); caxis([min_colorTdif max_colorTdif]); colorbar;
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[Kkm^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);
%xlabel('date-time UTC [hr]'); 
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
% ax = gca;
% ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,1,2)
pcolor(timegrid2days,heightfitfit_day1,theta_difmeridional_2days); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([startdatetime enddatetime]); grid on;
aaTempdif = (nclCM('CBR_coldhot',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('f)    (\theta_N-\theta_S)(\Deltay)^{-1}'); 
xlabel('date-time UTC [hr]'); caxis([min_colorTdif max_colorTdif]); colorbar
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[Kkm^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

saveas(figure(2),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_theta_dif_zonal_meridional_2days.png'])

%% wind
%heightWDL; u_ABL=uzonalvel; v_ABL=vmeridionalvel; yliminf=minheight_surf-50; ylimsup=maxheight_upperabl+50;
min_color_velocity = 0; step_color_velocity = 10;
min_color_vel = -400; max_color_vel =-min_color_vel; stepquiv=2; % spacing between vectors for quiver
minVcolor=-24; maxVcolor=-minVcolor;
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
timeWDL2days = [decimaltimeWDLday1,decimaltimeWDLday2];

windzonal_2days = [zonalwind_day1', zonalwind_day2']; 
windmeridional_2days = [meridionalwind_day1', meridionalwind_day2']; 

%% for plot wind rose
idx_abl = heightwind_day1 >= minheight_surf & heightwind_day1 <= maxheight_upperabl;
u_layer_abl = mean(windzonal_2days(idx_abl,100:108),1,'omitnan');
v_layer_abl = mean(windmeridional_2days(idx_abl,100:108),1,'omitnan');
ws_abl = hypot(u_layer_abl,v_layer_abl);
wd_abl = mod(270 - atan2d(v_layer_abl,u_layer_abl),360);
dirEdges = 0:10:360; spdEdges= [0 5 10 15 20];
N = histcounts2(ws_abl,wd_abl,spdEdges,dirEdges);
N = N/sum(N(:))*100;

spdEdges = [0 2 4 6 8 10 15 20]; nSpeedBins = length(spdEdges)-1; 
 colors = jet(nSpeedBins); %colors = parula(nSpeedBins);
bottom = zeros(1,size(N,2));

% figure
figure('position',[1,1,1500,550],'Renderer','painters');
subplot(2,3,1:2); pcolor(timeWDL2days,heightwind_day2(2:end),windzonal_2days(2:end,:)); %shading interp
% hold on; quiver(hour(decimaltimeWDL2days(1:stepquiv:end)),heightwind_day1(1:stepquiv:end),...
%     windzonal_2days(1:stepquiv:end,(1:stepquiv:end))',windmeirdional_2days(1:stepquiv:end,(1:stepquiv:end))', scale,'k','LineWidth',1.5);
title('a)    Zonal wind u')
aa1 = (nclCM('NCV_blue_red',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
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
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

subplot(2,3,4:5); pcolor(timeWDL2days,heightwind_day2(2:end),windmeridional_2days(2:end,:)); %shading interp
% hold on; quiver(hour(decimaltimeWDL2days(1:stepquiv:end)),heightwind_day1(1:stepquiv:end),...
%     windzonal_2days(1:stepquiv:end,(1:stepquiv:end))',windmeirdional_2days(1:stepquiv:end,(1:stepquiv:end))', scale,'k','LineWidth',1.5);
title('b)    Meridional wind v')
aa1 = (nclCM('NCV_blue_red',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
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
xtickformat('HH:mm')
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
title('c)     from 0200 to 0400 UTC')
end

saveas(figure(3),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_wind_2days.png'])


%% Temp uncertainty

file_theta_uncert_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_theta_advection_uncert.nc']);
finfodif = ncinfo(file_theta_uncert_day1); variableuncert_name = {finfodif.Variables.Name};
advectionthetazonal_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(1)));
uncert_advectionthetazonal_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(2)));
advectionthetameridional_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(3)));
uncert_advectionthetameridional_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(4)));
uncert_advectiontheta_total_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(5)));
timegrid_day1 = ncread(file_theta_uncert_day1,cell2mat(variableuncert_name(6)));

file_theta_uncert_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_theta_advection_uncert.nc']);
advectionthetazonal_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(1)));
uncert_advectionthetazonal_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(2)));
advectionthetameridional_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(3)));
uncert_advectionthetameridional_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(4)));
uncert_advectiontheta_total_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(5)));
timegrid_day2 = ncread(file_theta_uncert_day2,cell2mat(variableuncert_name(6)));

%merging variables:
timegrid2days_uncert = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

advection_zonal_2days = [advectionthetazonal_day1', advectionthetazonal_day2']; 
advection_meridional_2days = [advectionthetameridional_day1', advectionthetameridional_day2']; 
advection_total_allabl2days = advection_zonal_2days+advection_meridional_2days;
uncert_advection_zonal_2days = [uncert_advectionthetazonal_day1', uncert_advectionthetazonal_day2']; 
uncert_advection_meridional_2days = [uncert_advectionthetameridional_day1', uncert_advectionthetameridional_day2']; 
uncert_advection_total_2days = uncert_advection_zonal_2days+uncert_advection_meridional_2days;


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
xlabel('date-time UTC [hr]'); xlim([startdatetime enddatetime]); ylabel('\theta advection [K hr^{-1}]'); %ylim([min_height_abl, maxheight_upperabl])
% hold on
% fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
%      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on; grid on;
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [advection_zonal_2days-uncert_advection_zonal_2days...
    fliplr(advection_zonal_2days+uncert_advection_zonal_2days)], ...
     bluebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on; grid on; ylim([minlim, maxlim])
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [advection_meridional_2days-uncert_advection_meridional_2days...
    fliplr(advection_meridional_2days+uncert_advection_meridional_2days)], ...
     purplebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
legend([ 'u\cdot(\Delta\theta/\Deltax)'; 'v\cdot(\Delta\theta/\Deltay)'])
    %'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title(['                                                        a)         \theta advection in ABL (',num2str(minheight_surf),'-',...
    num2str(maxheight_upperabl),' m) ']);
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';


subplot(1,2,2)
plot(timegrid2days_uncert,advection_total_allabl2days,'color', redbonito, 'LineWidth',2); grid on
% title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
%     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
xlabel('date-time UTC [hr]'); xlim([startdatetime enddatetime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
hold on
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [advection_total_allabl2days+uncert_advection_total_2days...
    fliplr(advection_total_allabl2days)], ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on
fill([timegrid2days_uncert fliplr(timegrid2days_uncert)], [advection_total_allabl2days-uncert_advection_total_2days...
    fliplr(advection_total_allabl2days)], ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ '       u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)        '; ...
%     'uncertainty of u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title('b)');
legend([ 'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)'])
xticks(startdatetime: hours(1) :enddatetime) 
xtickformat('HH:mm')
ax = gca;
ax.XAxis.LabelHorizontalAlignment = 'left';

saveas(figure(4),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_theta_advect_uncert_2days.png'])


%% for plotting colors:
min_color=-1.5; max_color=-min_color; step_color=0.2;
colorzonal = [0.1 0.5 0.50]; colormeridional = [0.6 0.3 0.5];
%starttime=8; endtime=22; minhum=5; maxhum=10;
scale=1; % scale for quiver wind vectors
Gray1 = [128 128 128]/255; Gray2 = [100 100 128]/255; Gray3 = [75 75 128]/255; Gray4 = [60 60 128]/255;
 

%% Advection plots

file_theta_Advect_day1 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day1), '_theta_advection.nc']);
finfodif = ncinfo(file_theta_Advect_day1); variableuncert_name = {finfodif.Variables.Name};
advection_height_thetazonal_day1 = ncread(file_theta_Advect_day1,cell2mat(variableuncert_name(1)));
advection_height_thetameridional_day1 = ncread(file_theta_Advect_day1,cell2mat(variableuncert_name(2)));
timegrid_day1 = ncread(file_theta_Advect_day1,cell2mat(variableuncert_name(3)));
heightfitfit_day1 = ncread(file_theta_Advect_day1,cell2mat(variableuncert_name(4)));

file_theta_Advect_day2 = ([path_netcdf,num2str(year),sprintf('%02d', month),sprintf('%02d', day2), '_theta_advection.nc']);
advection_height_thetazonal_day2 = ncread(file_theta_Advect_day2,cell2mat(variableuncert_name(1)));
advection_height_thetameridional_day2 = ncread(file_theta_Advect_day2,cell2mat(variableuncert_name(2)));
timegrid_day2 = ncread(file_theta_Advect_day2,cell2mat(variableuncert_name(3)));
heightfitfit_day2 = ncread(file_theta_Advect_day2,cell2mat(variableuncert_name(4)));

%merging variables:
timegrid2days_advect = datetime(year,month,day1,0,0,0):hours(0.5):datetime(year,month,day2,23,30,0);

% day1 + day 2
advection_height_zonal_2days = [advection_height_thetazonal_day1', advection_height_thetazonal_day2']; 
advection_height_meridional_2days = [advection_height_thetameridional_day1', advection_height_thetameridional_day2']; 
advection_height_total_allabl2days = advection_height_zonal_2days+advection_height_meridional_2days;

% for potential temperature time series plot:
[szh, szt] = size(thetaZenith2days); thetaZenithABL = NaN.*ones(szh,szt);
for hi=1:szh; for ti=1:szt
        if heightMWR_ta_day1(hi)> minheight_surf 
            if heightMWR_ta_day1(hi)<maxheight_upperabl
            thetaZenithABL(hi,ti) = thetaZenith2days(hi,ti);
            end
        end
end;end

thetaZenith_timeseries = nanmean(thetaZenithABL);

min_colorAdv= -12; max_colorAdv=-min_colorAdv; step_colorAdv =0.01;

figure('position',[1,1,1000,3000],'Renderer','painters');

subplot(5,1,1)
plot(timemwr2days,thetaZenith_timeseries, 'LineWidth',2); grid on; colorbar
ylabel('\theta at zenith')
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm'); 
title(['a)   \theta at zenith (averaged ',num2str(minheight_surf), '-', num2str(max_height_abl), ' m)' ]);
%yticks(100*round(minheight_surf/100):100:maxheight_upperabl+extraabl)
xlim([startdatetime, enddatetime]); ylim([294, 307]); 

subplot(5,1,2); 
pcolor(timemwr2days,heightMWR_ta_day1,thetaZenith2days);
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('b)    \theta at zenith'); caxis([min_colorT max_colorT])
%xlabel('time UTC [hours]'); 
hcb_temp=colorbar;  ylim([minheight_surf+30, maxheight_upperabl+100]); 
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]';  xlim([startdatetime, enddatetime]); 
set(colorTitleHandle_temp ,'String',titleString_temp); 
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(round(minheight_surf/100):200:maxheight_upperabl+extraabl) 

subplot(5,1,3); 
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_zonal_2days); 
title('c)    u\cdot(\Delta\theta/\Deltax)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); %xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(round(minheight_surf/100):200:maxheight_upperabl+extraabl)

subplot(5,1,4); 
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_meridional_2days); 
title('d)    v\cdot(\Delta\theta/\Deltay)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); %xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(round(minheight_surf/100):200:maxheight_upperabl+extraabl)

subplot(5,1,5);
pcolor(timegrid2days_advect,heightfitfit_day2,advection_height_total_allabl2days); 
title('e)    u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]'); shading flat; xlim([startdatetime, enddatetime]); ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); xlabel('date-time UTC [hr]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);
xticks(startdatetime: hours(0.5) :enddatetime) 
xtickformat('HH:mm')
yticks(round(minheight_surf/100):200:maxheight_upperabl+extraabl)

saveas(figure(5),[path_figs,num2str(year),sprintf('%02d', month),'_',sprintf('%02d', day1),...
    'and',sprintf('%02d', day2),'_Advection_theta_2days.png'])

