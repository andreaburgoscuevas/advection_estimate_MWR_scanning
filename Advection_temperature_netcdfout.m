% Code that estimates temperature advection from DWL and MWR at 30° elevation. Zonal and meridional 
%differences are calculated height and time-resolved and matched with WDL data to estimate advection

clear all
close all

% here we should enter the date to be analized:
year=2022;
month=6;
day=19;
pathfigs = '/path/to/outputfigures/';
pathoutnet = '/path/to/outputNetCDF/';

temporal_resolution = .5; % en hora decimal para juntar tiempos MWR y WDL
% vertical resolution:
height_resolutionABL = 100; % m
smoothtimeseries=1; thermal_smooth=1;

starttime=0; endtime=21;
neglectsmalldist=1; % turn this =1 for taking low levels where horizontal distance is small
mindist=1500; % m this is the minimum horiz dist to estimate advection
minhei= round(mindist/2/tand(60)); % tangent of 60 cause that's the cone and 
maxerror_vel=3;%.7; %m/s
maxerror_dir_vel = 30; % degrees
maxvelsurf=3; surf_hei=100;

% heights to average the column:
min_height_abl=100; max_height_abl=1300; % all column ABL
minheight_surf=100; maxheight_surf=700;
minheight_upperabl=maxheight_surf; maxheight_upperabl=1300;
if neglectsmalldist==1; minheight_surf= max([minhei, minheight_surf]); end

% setting the required fractions of CLBLH where it makes sense to estimate
% advection as discussed with DT and UL :
%fraction_supABL = 0.8; fraction_infABL = 0.2;

%% for plotting colors:
min_color=-4.5; max_color=-min_color; step_color=0.2;

colorzonal = [0.1 0.5 0.50]; colormeridional = [0.6 0.3 0.5];

set(groot, 'DefaultAxesFontSize', 18);
set(groot, 'DefaultTextFontSize', 18);

%%

minheight = 0; % m 
maxheightABL = 2500;
maxheightMWR100m = 1100; % maximum height till which MWR vertical resolution is better than 100 m, or 100 m 
height100 = [minheight:height_resolutionABL:maxheightMWR100m, maxheightMWR100m+200:200:maxheightABL]; 
fractionABL=1; %0.8;
%numdesvstd=3;

numstdallow=3; %max numb of standard deviations allow below which hum adv is not NaN

p_0 = 1006; % hPa  surface pressure 
p_0 = 100*p_0; % Pa
%     filenameMWR_BL_hua = (dir(strcat([daypath_MWR, '/sups_joy_mwrBL00_l2_hua_*.nc'])));
g_0 = 9.8; % m/s2
R_gas = 287.0; % J/(kgK) for dry atmosphere
c_p = 1004; %  J/(kgK) Holton


%% 1. stating paths and defining variables and constants that are gonna be used:

path_root_hatpro = '/path/to/dataMWR/';
path_root_lidar = '/path/to/dataDWL/';
pathoutAdvection = '/path/to/outputAdvection/';
pathoutUncertainty = pathoutAdvection;
%pathoutAdvection = pathoutAdvection;

% aqui debo hacer un ciclo para saber si el filename esta empty y en ese
% caso que se pase al siguiente dia

%filenames:

    filenameMWR_taa = (dir(strcat([path_root_hatpro, 'sups_joy_mwr00_l2_ta_p00_',...
        num2str(year),sprintf('%02d', month),sprintf('%02d',day) ,'*.nc']))); 
    filenameMWR_ta=filenameMWR_taa(1);
    filenameWDLa = (dir(strcat([ path_root_lidar, '/wind_vad-36_',...
        num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.nc']))); 
    filenameWDL= filenameWDLa(1);

    fileMWR_ta = ([path_root_hatpro, filenameMWR_ta.name]);
    fileWDL = ([path_root_lidar, filenameWDL.name]);
 % en las lineas anteriores se usa ese comando poderoso de strcat que sirve
    % para completar el nombre de un archivo sea el que sea, esto es mas
    % poderoso que *, porque asi acompleto nombres de files

%% Reading variables from MWR

%ncdisp(fileMWR_ta);
%ncdisp(fileMWR_hua);

% humidityMWR_hua = ncread(fileMWR_hua,'hua');
% heightMWR_hua = ncread(fileMWR_hua,'height');
% azimuthMWR_hua = ncread(fileMWR_hua,'azi');
% elevationMWR_hua = ncread(fileMWR_hua,'ele');
% 
% flagMWR_ta = ncread(fileMWR_ta,'flag');
% rawtimeMWR_hua = double(ncread(fileMWR_hua, 'time'));
% hua_error = ncread(fileMWR_hua,'hua_err');

tempMWR_ta = ncread(fileMWR_ta,'ta');% Kelvin
heightMWR_ta = ncread(fileMWR_ta,'height'); % meters
azimuthMWR_ta = ncread(fileMWR_ta,'azi');
elevationMWR_ta = ncread(fileMWR_ta,'ele');

%for i=1:length(flagMWR_ta); if isnan(flagMWR_ta(i))==0; tempMWR_ta(:,i)=NaN; end; end

tempMWR_error = ncread(fileMWR_ta, 'ta_err');
temp_error_height = nanmean(tempMWR_error);
temp_error_mean_file = NaN.*ones(1,length(heightMWR_ta));
for te=1:length(heightMWR_ta); if heightMWR_ta(te)<1000 && heightMWR_ta(te)>600
        temp_error_mean_file(te) = temp_error_height(te);
end;end
temp_error_mean_file = nanmean(temp_error_mean_file);

flagMWR_ta = ncread(fileMWR_ta,'flag');
for i=1:length(flagMWR_ta); if isnan(flagMWR_ta(i))==0; tempMWR_ta(:,i)=NaN; end;end

rawtimeMWR_ta = double(ncread(fileMWR_ta, 'time'));

% writing time in a way that makes sense: 
secsin1day=60*60*24;
base=datenum(1970,1,1); % according to what the cdf file says with ncdisp(file)
datetimefileMWR = datestr(rawtimeMWR_ta/secsin1day+base);
timesindayMWR = length(datetimefileMWR);

for cht =1:timesindayMWR
    datetimeMWR(cht) = convertCharsToStrings(datetimefileMWR(cht,:));
end
 
decimaltimeMWR = hour(datetimeMWR)+ minute(datetimeMWR)./60;
%% Reading variables from WDL: 

%ncdisp(fileWDL);
horizontalwindspeed = ncread(fileWDL, 'speed'); % 'm s^-1'
dirhorizontalwindspeed = ncread(fileWDL, 'dir'); % degrees
%verticalwindspeed = ncread(fileWDL, 'w_speed'); % 'm s^-1'
heightWDL = ncread(fileWDL, 'height'); % meters a.g.l.
rawtimeWDL = ncread(fileWDL, 'time'); % julian day, i.e. fractional days since January 1, 4713 BC Greenwich noon; can be converted to unix epoch with t_unix=(time-2440587.5)*86400'
datetimeWDL = datetime(rawtimeWDL,'convertfrom','juliandate');
%timesindayWDL = length(datetimeWDL);
windvector = ncread(fileWDL, 'wind_vec');
u=windvector(:,:,1);
v=windvector(:,:,2);
w=windvector(:,:,3);
velocity_error = ncread(fileWDL, 'delta_speed'); %Dimensions: time,height
velocity_dir_error = ncread(fileWDL, 'delta_dir'); %Dimensions: time,height


[szv1, szv2]=size(u);
for i=1:szv1; for j=1:szv2
        if velocity_error(i,j)> maxerror_vel
            u(i,j)=NaN; v(i,j)=NaN;
        end
         if velocity_dir_error(i,j)> maxerror_dir_vel
            u(i,j)=NaN; v(i,j)=NaN;
         end
        if heightWDL(j)<surf_hei  && ( u(i,j)> maxvelsurf)
             v(i,j)=NaN; u(i,j)=NaN;
        end
end; end

%% ABL classif TM

%path_bl = '/path/to/data/ABLclassification/';
path_bl = '/path/to/dataABLclassif/';

data_bl = [];
%for i = 1:length(dates)
%i=14;
    %daten = datenum(num2str(dates(i)),'yyyymmdd');

   file_bl = dir(strcat([path_bl, [num2str(year),sprintf('%02d', month),sprintf('%02d', day)]...
    '_juelich_halo-doppler-lidar_BL-classification.nc']));
    data_bl.time_3min = ncread(strcat([path_bl '/' file_bl.name]),'time_3min');
    data_bl.bl_classification_3min = ncread(strcat([path_bl '/' file_bl.name]),'bl_classification_3min')';
    data_bl.height = ncread(strcat([path_bl '/' file_bl.name]),'height');
    mlh = ones(size(data_bl.time_3min)) * nan;
    for j = 1:length(mlh)
        xf = find(data_bl.bl_classification_3min(j,:) == 4,1,'last');
        if ~isempty(xf)
            mlh(j) = data_bl.height(xf);
        end
    end
aerosol_layer_top = ncread(strcat([path_bl '/' file_bl.name]),'aerosol_layer_top_3min');
heightTM = ncread(strcat([path_bl '/' file_bl.name]),'height');
% ncdisp(strcat([path_bl num2str(year) '/' file_bl.name]))

%     timeTM = data_bl.time_3min;
%     CBLHTM = mlh;

% % figure comparing heights:
% figure(8)
% plot(timeTM,CBLHTM, 'r'); hold on; plot(horadecim,height_max_u_wind, 'b');
% hold on; plot(horadecim,height_max_v_wind, 'c--'); hold on; plot(horadecim,height_max_w_wind, 'k*')
% legend('CBLH TM','max height u wind available','max height v wind available','max height w wind available'); grid on

%% FINDING MWR SCANS WITH 30 DEG ELEVATION and simultaneously N S E W  at each height and time
% now I am going to calculate horizontal displacement in that 30 deg elev cone for each height:
% but I am only starting now with the easy points: EW and NS

    tempMat3D = NaN.*ones(43,36,49);

%angle_rad = 0.5236; % 30 deg in radian
% s
%angle_rad = 1.05; % 60 deg in radians cause my geometry is with respect to zenital, i.e. 90-elev

[heightsize, timesize] = size(tempMWR_ta);

eastdistance = NaN.*ones(1,heightsize); westdistance = NaN.*ones(1,heightsize); 
northdistance = NaN.*ones(1,heightsize); southdistance = NaN.*ones(1,heightsize);
easttime = NaN.*ones(timesize,1); westtime = NaN.*ones(timesize,1);
northtime = NaN.*ones(timesize,1); southtime = NaN.*ones(timesize,1);
% eastHumidity = NaN.*ones(heightsize,48); westHumidity = NaN.*ones(heightsize,1);
% northHumidity = NaN.*ones(heightsize,1); southHumidity = NaN.*ones(heightsize,1);

decimaltime30indice = NaN.*ones(timesize,1); 
tiempo30indice = NaN.*ones(timesize,1); tiempo_zenith_indice = NaN.*ones(timesize,1);
tiempo90indice = NaN.*ones(timesize,1);

teastcount = 0; twestcount = 0; tnorthcount = 0; tsouthcount = 0;

time30elev=NaN.*ones(heightsize,timesize); time90elev=NaN.*ones(heightsize,timesize);
dista30elev=NaN.*ones(heightsize,timesize); dista90elev=NaN.*ones(heightsize,timesize);
temperature30elev=NaN.*ones(heightsize,timesize); temperaturezenith=NaN.*ones(heightsize,timesize);
uncert30elev=NaN.*ones(heightsize,timesize); azimuth30elev=NaN.*ones(heightsize,timesize);


for hh = 1:heightsize
    for tt = 1:timesize

        if abs(elevationMWR_ta(tt)-90) < 1
            tiempo_zenith_indice(tt)=tt;
            if (isnan(tiempo_zenith_indice(tt))==0)
                %timezenith(hh,tt) = hour(datetimeMWR(tt))+ minute(datetimeMWR(tt))./60;
                temperaturezenith(hh,tt) = tempMWR_ta(hh,tt);
                             
            end
        end
        
         if abs(elevationMWR_ta(tt)-30) < 1 % aqui si esta bien poner 30 deg, porque en el file son 30 deg

             tiempo30indice(tt) = tt; % encontrando tiempos del scan para los cuales elevation=30
            if (isnan(tiempo30indice(tt))==0)
                time30elev(hh,tt) = hour(datetimeMWR(tt))+ minute(datetimeMWR(tt))./60;
                dista30elev(hh,tt) = heightMWR_ta(hh).*tand(60);
                temperature30elev(hh,tt) = tempMWR_ta(hh,tt);
                azimuth30elev(tt) = azimuthMWR_ta(tt);
             
            end
               
        end
       
    end

end

count=0; [hii, scani] = size(temperature30elev);
for titi=1:min([timesize, scani])
    if(temperature30elev(5,titi))>0
        count = count+1;
        indi(count)=titi;
        %timescan(count)=time30elev(titi);
        %ti(count)=tiempo30indice(count);
    end
    
end

count90=0;
for titi9=1:length(temperaturezenith)
    if(temperaturezenith(5,titi9))>0
        count90 = count90+1;
        indi90(count90)=titi9;
        %timescan(count)=time30elev(titi);
        %ti(count)=tiempo30indice(count);
    end
    
end

numscans=length(indi)/36;
indistart =indi(1:36:end); % este indice del tiempo raw inicia un nuevo scan

 for hei=1:heightsize
%     for tim=1:numscans
%       humMat(hei,tim) = humidity30elev(hei,indistart(tim));
%         
%     end
        for ondi=1:length(indi)
            tempMat(hei,ondi) = temperature30elev(hei,indi(ondi));
            azim(ondi) = azimuth30elev(indi(ondi));
            timescan(ondi) = time30elev(hei,indi(ondi));
            distaHoriz(hei,ondi) = dista30elev(hei,indi(ondi));
          %  tempMat_zenith(hei,ondi) = temperaturezenith(hei,indi(ondi));
        end


         for ondi90=1:length(indi90)
            tempMat_zenith(hei,ondi90) = temperaturezenith(hei,indi90(ondi90));
            %flagMat(hei,ondi)= flaghum30elev(hei,indi(ondi));
            %uncertHumMat(hei,ondi) = uncert_hum30elev(hei,indi(ondi));
            %azim(ondi) = azimuth30elev(indi(ondi));
            timescan90(ondi90) = time90elev(hei,indi90(ondi90));
            distaHoriz90(hei,ondi90) = dista90elev(hei,indi90(ondi90));
            
        end


 end

% converting to potential temperature theta 
[sztempMat1, sztempMat2] = size(tempMat);
% 
%  for altura =1:sztempMat1
%      for tempi = 1:sztempMat2
%   % Use hypsometric equation to estimate pressure from height and temperature, then compute tempot
%     % Holton pag. 21:
%         H_scaleheight(altura,tempi) = R_gas.*tempMat(altura,tempi)./g_0;        
%         presion(altura,tempi) = p_0*exp(-heightMWR_ta(altura)./H_scaleheight(altura,tempi));
% 
%     % Now esimating potential temperature. Holton pag 50:
%         thetaMat(altura,tempi) = tempMat(altura,tempi).*(p_0./presion(altura,tempi)).^(R_gas/c_p);
%      end
%  end

  % Use hypsometric equation to estimate pressure from height and temperature, then compute tempot
    % Holton pag. 21:
        H_scaleheight = R_gas.*tempMat./g_0;        
        presion= p_0*exp(-heightMWR_ta./H_scaleheight);

    % Now esimating potential temperature. Holton pag 50:
    idx = round(linspace(1,length(tempMat_zenith),length(tempMat))); tempMat_zenith = tempMat_zenith(:,idx);
        thetaMat = tempMat.*(p_0./presion).^(R_gas/c_p);
        thetaMat_zenith = tempMat_zenith.*(p_0./presion).^(R_gas/c_p);
  
% %filter to remove physically unrealisttically variations
 for hei=1:heightsize
        for ondi=1:length(indi)
            if ondi>2 && ondi< length(indi)
                if abs(tempMat(hei,ondi)) > abs(nanmean([tempMat(hei,ondi-1),tempMat(hei,ondi+1)]))+ abs(std(tempMat(hei,ondi-1:ondi+1)))
                    tempMat(hei,ondi) = nanmean([tempMat(hei,ondi-1),tempMat(hei,ondi+1)]);
                end
            end

        end
 end

% making a 3D matrix for temperature in each scan, in each height, in each angle
scan=ones(1,ondi); az=ones(1,ondi);
for tim=1:length(indi)
for hh=1:heightsize
if tim>1
    az(tim)=tim-36*scan(tim-1)+36;
    if  mod(tim,36)==0
        scan(tim)=scan(tim-1)+1;
    else
    scan(tim)=scan(tim-1);
    end
end
     
         tempMat3D(hh,az(tim),scan(tim))= thetaMat(hh,tim);
         tempMat3D_zenith(hh,az(tim),scan(tim))= thetaMat_zenith(hh,tim);
         %tempMat_meanHeight(az(tim),scan(tim)) = nanmean(thetaMat(:,tim));
         azim2D(az(tim),scan(tim)) = azim(tim);
         timescan2D(az(tim),scan(tim)) = timescan(tim);
         distaHoriz2D(hh,az(tim))= distaHoriz(hh,tim);
         %humMatAzimuths(hh,az(tim)) = 

end
end
% 
[altura,angulo,tiempo] = size(tempMat3D); tiempo=tiempo-1;
  for h=1:altura
     for t=1:tiempo
         for an=1:angulo

         if  azim2D(an,t) >=350 || azim2D(an,t) <=10 %azimuth=0 North
             tempNorth_all(h,an,t) = tempMat3D(h,an,t);
         else tempNorth_all(h,an,t) = NaN;
               
         end
         if  azim2D(an,t) ==170 || azim2D(an,t) ==190 || azim2D(an,t) ==180 % || azim2D(an,t) ==160% azimuth=200 South azim2D(an,t)== 180 ||
             tempSouth_all(h,an,t) = tempMat3D(h,an,t);
         else tempSouth_all(h,an,t) = NaN;
         end

         if azim2D(an,t)== 90 || azim2D(an,t) ==80 || azim2D(an,t) ==100 %|| azim2D(an,t) ==70 || azim2D(an,t) ==110% azimuth=90 East
             tempWest_all(h,an,t) = tempMat3D(h,an,t);
         else; tempWest_all(h,an,t) = NaN;
         end
         if azim2D(an,t)== 270 || azim2D(an,t) ==260 || azim2D(an,t) ==280 %|| azim2D(an,t) ==250 || azim2D(an,t) ==290% azimuth=270 West
             tempEast_all(h,an,t) = tempMat3D(h,an,t);
         else; tempEast_all(h,an,t) = NaN;
         end

%          if abs(timescan2D(an,t)-12)<0.4
%              tempNoon(h,an)=tempMat3D(h,an,t);
%          end

         end
         tempNorth(h,t)= nanmean(nonzeros(tempNorth_all(h,:,t)));
         tempSouth(h,t)= nanmean(nonzeros(tempSouth_all(h,:,t)));
         tempEast(h,t)= nanmean(nonzeros(tempEast_all(h,:,t)));
         tempWest(h,t)= nanmean(nonzeros(tempWest_all(h,:,t)));
         temp_zenith(h,t) = nanmean(nonzeros(tempMat3D_zenith(h,:,t)));
     end
 end

%just checking there are no zeros:
 for h=1:altura
     for an=1:angulo
     for t=1:tiempo

%% the next cycle is to disregard values when horizontal distance is not enough

if neglectsmalldist==1

if (tempNorth(h,t)==0) || (distaHoriz2D(h,an)<mindist/2); tempNorth(h,t)=NaN; end % mindist/2 because later I multiply by 2
if tempSouth(h,t)==0 || (distaHoriz2D(h,an)<mindist/2); tempSouth(h,t)=NaN; end
if tempEast(h,t)==0 || (distaHoriz2D(h,an)<mindist/2); tempEast(h,t)=NaN; end
if tempWest(h,t)==0 || (distaHoriz2D(h,an)<mindist/2); tempWest(h,t)=NaN; end
end

end
    end
 end

distanciaenaltura = nanmean(distaHoriz2D');
temp_mean_direct = (tempNorth+tempSouth+tempEast+tempWest)./4;

%% Making gradients of temperature and distance:

zonalTemperaturedif = tempEast-tempWest;
meridionalTemperaturedif = (tempNorth-tempSouth);

zonaldistdif = 2*distanciaenaltura; meridionaldistdif = 2*distanciaenaltura; disthoriz = zonaldistdif;


%% so I have a zonal and meridional temperature gradients of MWR data:

for hi=1:altura
dTempdxzonal(hi,:) = zonalTemperaturedif(hi,:)./disthoriz(hi); 
dTempdymeridional(hi,:) = meridionalTemperaturedif(hi,:)./disthoriz(hi);

%and the corresponding time and heights are
timemwr = nanmean(timescan2D(:,1:end-1));
timemeridional = nanmean(timescan2D(:,1:end-1));
heightMWR_ta;
end
timemwr=[timemwr, 23.695];
%% Now building ingredients for advection in ABL at two different height layers:
% temperature:
dTempdxzonal; dTempdymeridional; heightMWR_ta; timemwr;
min_height_abl; max_height_abl; minheight_surf; maxheight_surf; minheight_upperabl; maxheight_upperabl;

tempEast_surf=NaN.*ones(length(heightMWR_ta),length(timemwr));tempEast_upperabl=NaN.*ones(length(heightMWR_ta),length(timemwr));
tempWest_surf=NaN.*ones(length(heightMWR_ta),length(timemwr));tempWest_upperabl=NaN.*ones(length(heightMWR_ta),length(timemwr));
tempNorth_surf=NaN.*ones(length(heightMWR_ta),length(timemwr));tempNorth_upperabl=NaN.*ones(length(heightMWR_ta),length(timemwr));
tempSouth_surf=NaN.*ones(length(heightMWR_ta),length(timemwr));tempSouth_upperabl=NaN.*ones(length(heightMWR_ta),length(timemwr));

for ti=1:length(timemwr); for hi=1:length(heightMWR_ta)
        if heightMWR_ta(hi)>=minheight_surf && heightMWR_ta(hi)<=maxheight_surf
            tempEast_surf(hi,ti)=tempEast(hi,ti); tempWest_surf(hi,ti)=tempWest(hi,ti);
            tempNorth_surf(hi,ti)=tempNorth(hi,ti); tempSouth_surf(hi,ti)=tempSouth(hi,ti);
            %diftemp_zonal_surf(hi,ti) = dTempdxzonal(hi,ti);
            %diftemp_meridional_surf(hi,ti) = dTempdymeridional(hi,ti);
        %else; diftemp_meridional_surf(hi,ti)=NaN; diftemp_zonal_surf(hi,ti)=NaN;
          %  tempEast_surf(hi,ti)=NaN; tempWest_surf(hi,ti)=NaN; tempNorth_surf(hi,ti)=NaN; tempSouth_surf(hi,ti)=NaN;
        end
         if heightMWR_ta(hi)>minheight_upperabl && heightMWR_ta(hi)<maxheight_upperabl
            tempEast_upperabl(hi,ti)=tempEast(hi,ti); tempWest_upperabl(hi,ti)=tempWest(hi,ti);
            tempNorth_upperabl(hi,ti)=tempNorth(hi,ti); tempSouth_upperabl(hi,ti)=tempSouth(hi,ti);
           % diftemp_zonal_upperabl(hi,ti) = dTempdxzonal(hi,ti); 
            %diftemp_meridional_upperabl(hi,ti) = dTempdymeridional(hi,ti);
        % else; diftemp_meridional_upperabl(hi,ti)=NaN; diftemp_zonal_surf(hi,ti)=NaN;
        end
end; end

%diftemp_zonal_surf=nanmean(diftemp_zonal_surf); diftemp_zonal_upperabl=nanmean(diftemp_zonal_upperabl);

%% and for the WDL I have to only keep phisically realistic values :
uzonalvel = u; vmeridionalvel = v; heightWDL; 
datetimeWDL; decimaltimeWDL = hour(datetimeWDL)+ minute(datetimeWDL)./60+.3;
[sztw, szhw] = size(u); thresholdVsurf=30; thresholdUsurf=30; thresholdU=30;

figure; pcolor(datetimeWDL,heightWDL,uzonalvel'); shading flat; caxis([-10, 10])
figure; pcolor(datetimeWDL,heightWDL,vmeridionalvel'); shading flat; caxis([-10, 10])

for tw=1:sztw; for hw=1:szhw
        if abs(uzonalvel(tw,hw))>= thresholdU
            uzonalvel(tw,hw)=NaN;
        end
        if abs(vmeridionalvel(tw,hw))>= thresholdU
            vmeridionalvel(tw,hw)=NaN;
        end
end
end

%% figures velocity:

heightWDL; u_ABL=uzonalvel; v_ABL=vmeridionalvel; yliminf=minheight_surf-50; ylimsup=maxheight_upperabl+50;
min_color_velocity = 0; step_color_velocity = 10;
min_color_vel = -400; max_color_vel =-min_color_vel; stepquiv=2; % spacing between vectors for quiver
minVcolor=-15; maxVcolor=-minVcolor;
dontsaturate=1; eps=1;
scale=1.3; starttimev=100; endtimev=endtime*100; 
if dontsaturate==1
[ti, hi]=size(u_ABL);
    for t=1:ti; for h=1:hi
            if (u_ABL(t,h))> maxVcolor; u_ABL(t,h)=maxVcolor-eps; end
            if (u_ABL(t,h))< minVcolor; u_ABL(t,h)=minVcolor+eps; end
            if (v_ABL(t,h))> maxVcolor; v_ABL(t,h)=maxVcolor-eps; end
            if (v_ABL(t,h))< minVcolor; v_ABL(t,h)=minVcolor+eps; end
    end
    end
end

for t=1:ti; for h=1:hi
            if heightWDL(h)<minheight_surf; u_ABL(t,h)=NaN;v_ABL(t,h)=NaN; end
end; end

% NCV_banded'
figure('position',[1,1,1700,350],'Renderer','painters');
subplot(1,2,1); pcolor(100*decimaltimeWDL,heightWDL(2:end),u_ABL(:,2:end)'); %shading interp
hold on; quiver(100*decimaltimeWDL(1:stepquiv:end),heightWDL(1:stepquiv:end),...
    u_ABL(1:stepquiv:end,(1:stepquiv:end))',v_ABL(1:stepquiv:end,(1:stepquiv:end))', scale,'k','LineWidth',1.5);
title('Zonal wind u')
aa1 = (nclCM('NCV_jaisnd',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
aa1(end,:) = [.8 .8 .8];  xlim([starttimev endtimev]); 
%cc = colorbar;  cc.Ticks = [min_color_vel:step_color_velocity*4:max_color_vel];
%c.Color = 'black';    c.Box = 'off';    c.Location = 'EastOutside';
colormap(aa1); grid on; ylim([yliminf ylimsup]); ylabel('height [m]')
colorbar;  caxis([minVcolor maxVcolor])
xlabel('time UTC [h]'); shading flat; 
hcb_velocities=colorbar; xlim([starttimev endtimev]); 
colorTitleHandle_velocities = get(hcb_velocities,'Title');
titleString_velocities = '[ms^{-1}]';
set(colorTitleHandle_velocities ,'String',titleString_velocities); 

subplot(1,2,2); pcolor(100*decimaltimeWDL,heightWDL(2:end),v_ABL(:,2:end)'); %shading interp
hold on; quiver(100*decimaltimeWDL(1:stepquiv:end),heightWDL(1:stepquiv:end),...
    u_ABL(1:stepquiv:end,(1:stepquiv:end))',v_ABL(1:stepquiv:end,(1:stepquiv:end))',scale, 'k','LineWidth',1.5);
title('Meridional wind v')
aa1 = (nclCM('NCV_jaisnd',(size(min_color_vel:step_color_velocity:max_color_vel,2)-1)));
aa1(end,:) = [.8 .8 .8];
cc = colorbar;  cc.Ticks = [min_color_vel:step_color_velocity:max_color_vel];
%c.Color = 'black';    c.Box = 'off';    c.Location = 'EastOutside';
colormap(aa1); grid on; ylim([yliminf ylimsup]); ylabel('height [m]'); colorbar
xlabel('time UTC [h]'); shading flat; caxis([minVcolor maxVcolor])
hcb_velocities=colorbar; xlim([starttimev endtimev]); 
colorTitleHandle_velocities = get(hcb_velocities,'Title');
titleString_velocities = '[ms^{-1}]';
set(colorTitleHandle_velocities ,'String',titleString_velocities); 

saveas(figure(3),[pathfigs,'velocity_directions_...' ...
     num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 3:
%saving netcdf for wind
nc_wind = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_wind.nc'];
% 
nccreate(nc_wind,'_zonal','Dimensions',{'time',length(decimaltimeWDL),'height',length(heightWDL(2:end))});
nccreate(nc_wind,'_meridional','Dimensions',{'time',length(decimaltimeWDL),'height',length(heightWDL(2:end))});
nccreate(nc_wind,'_decimaltimeWDL','Dimensions',{'time',length(decimaltimeWDL)});
nccreate(nc_wind,'_heightWDL','Dimensions',{'height',length(heightWDL(2:end))});

ncwrite(nc_wind,'_zonal',u_ABL(:,2:end));
ncwrite(nc_wind,'_meridional',v_ABL(:,2:end));
ncwrite(nc_wind,'_decimaltimeWDL',decimaltimeWDL);
ncwrite(nc_wind,'_heightWDL',heightWDL(2:end));

%n = ncread(nc_wind, '_zonal');
%%

%% now getting the velocities in the two layers:
uvel=NaN.*ones(size(uzonalvel));vvel=NaN.*ones(size(vmeridionalvel));
uzonalvel_surf=NaN.*ones(size(uzonalvel));vmeridionalvel_surf=NaN.*ones(size(vmeridionalvel));
uzonalvel_upperabl=NaN.*ones(size(uzonalvel));vmeridionalvel_upperabl=NaN.*ones(size(vmeridionalvel));

for tw=1:sztw; for hw=1:round(szhw/4)
        uvel(tw,hw)= uzonalvel(tw,hw); vvel(tw,hw)=vmeridionalvel(tw,hw);
        if  (heightWDL(hw) < maxheight_surf) % && (heightWDL(hw) > minheight_surf)
            uzonalvel_surf(tw,hw)=uzonalvel(tw,hw); vmeridionalvel_surf(tw,hw)=vmeridionalvel(tw,hw);
        end
        if  (heightWDL(hw) < maxheight_upperabl)  && (heightWDL(hw) > minheight_upperabl)
            uzonalvel_upperabl(tw,hw)=uzonalvel(tw,hw); vmeridionalvel_upperabl(tw,hw)=vmeridionalvel(tw,hw);
        end
end; end

%% Making the time fit:
timegrid=[0:0.5:23.5];
uzonalvel_surf=uzonalvel_surf'; vmeridionalvel_surf=vmeridionalvel_surf'; uvel=uvel'; vvel=vvel';
uzonalvel_upperabl=uzonalvel_upperabl'; vmeridionalvel_upperabl=vmeridionalvel_upperabl';

tiempoInicial = find(min(abs(timegrid-timemwr(1)))==abs(timegrid-timemwr(1)));

for tiempoMerge =tiempoInicial:length(timegrid)-1
  
 minindiMWR(tiempoMerge) = nanmin(find((timemwr) >= timegrid(tiempoMerge))); % el minimo indice mayor al grid en esa iteracion
 maxindiMWR(tiempoMerge) = nanmax(find((timemwr) <= timegrid(tiempoMerge+1))); % el max indice menor an grid inmediato superior

 minindiWDL(tiempoMerge) = nanmin(find((decimaltimeWDL) >= timegrid(tiempoMerge)));
 maxindiWDL(tiempoMerge) = nanmax(find((decimaltimeWDL) <= timegrid(tiempoMerge+1)));
end

minindiMWR = [minindiMWR,minindiMWR(end)]; maxindiMWR = [maxindiMWR,maxindiMWR(end)];
minindiWDL = [minindiWDL,minindiWDL(end)]; maxindiWDL = [maxindiWDL,maxindiWDL(end)];

for tiempoMerge =tiempoInicial:length(timegrid)
%  minindiWDL(tiempoMerge) = nanmin(find((decimaltimeWDL) >= tim15(tiempoMerge)));
%  maxiniWDL(tiempoMerge) = nanmax(find((decimaltimeWDL) <= tim15(tiempoMerge+1)));
 
 for height_mwr = 1:length(heightMWR_ta) %porque la variable tempMWR es 43 x 96 = height x time
    tempEast_surf_fit(height_mwr,tiempoMerge) =  nanmean(tempEast_surf...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempWest_surf_fit(height_mwr,tiempoMerge) =  nanmean(tempWest_surf...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempNorth_surf_fit(height_mwr,tiempoMerge) =  nanmean(tempNorth_surf...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempSouth_surf_fit(height_mwr,tiempoMerge) =  nanmean(tempSouth_surf...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));

    tempEast_upperabl_fit(height_mwr,tiempoMerge) =  nanmean(tempEast_upperabl...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempWest_upperabl_fit(height_mwr,tiempoMerge) =  nanmean(tempWest_upperabl...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempNorth_upperabl_fit(height_mwr,tiempoMerge) =  nanmean(tempNorth_upperabl...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempSouth_upperabl_fit(height_mwr,tiempoMerge) =  nanmean(tempSouth_upperabl...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));


    tempEast_fit(height_mwr,tiempoMerge) =  nanmean(tempEast...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempWest_fit(height_mwr,tiempoMerge) =  nanmean(tempWest...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempNorth_fit(height_mwr,tiempoMerge) =  nanmean(tempNorth...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    tempSouth_fit(height_mwr,tiempoMerge) =  nanmean(tempSouth...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));

% diferences fit:
   meridionalTemperaturedif_fit(height_mwr,tiempoMerge) = nanmean(meridionalTemperaturedif...
       (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
   zonalTemperaturedif_fit(height_mwr,tiempoMerge) = nanmean(zonalTemperaturedif...
       (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(timegrid))));
    
 end

 for height_wdl = 1:length(heightWDL) % porque la variable horizontalwindspeed es de size 275 x 320 = time x height
%      WDL_hwspeedfit(tiempoMerge,height_wdl) =  nanmean(uzonalvel(minindiWDL(tiempoMerge)...
%         :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));

     u_fit_surf(height_wdl,tiempoMerge) = nanmean(uzonalvel_surf(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));
     v_fit_surf(height_wdl,tiempoMerge) = nanmean(vmeridionalvel_surf(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));
     u_fit_upperabl(height_wdl,tiempoMerge) = nanmean(uzonalvel_upperabl(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));
     v_fit_upperabl(height_wdl,tiempoMerge) = nanmean(vmeridionalvel_upperabl(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));

     u_fit(height_wdl,tiempoMerge) = nanmean(uvel(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));
     v_fit(height_wdl,tiempoMerge) = nanmean(vvel(height_wdl,minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),length(heightWDL))));
     %timefit(tiempoMerge) = nanmean(decimaltimeWDL(minindiWDL(tiempoMerge):...
      %   nanmin(maxindiWDL(tiempoMerge),length(timegrid))));
%      w_fit(tiempoMerge,height_wdl) = nanmean(w(minindiWDL(tiempoMerge)...
%         :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
          
%     WDL_vwspeedfit(tiempoMerge,height_wdl) =  nanmean(verticalwindspeed(minindiWDL(tiempoMerge)...
 %       :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
 end

 %datetimeMWRfit(tiempoMerge) = nanmean(datetime(convertStringsToChars(datetimeMWR(minindiMWR(tiempoMerge)...
    % :nanmin(maxindiMWR(tiempoMerge))))));
 %timezonalfit(tiempoMerge) = nanmean(timemwr(minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge))));
 %timemeridionalfit(tiempoMerge) = nanmean(timemeridional(minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge))));

end % here the homogenization of temporal resolution ends

%% now make the averages in the two height levels

if smoothtimeseries==1 % do we vant or not to smooth the timeseries but in this loop they are defined either way

tempEast_timeseries_surf=smooth(nanmean(tempEast_surf_fit)); tempWest_timeseries_surf=smooth(nanmean(tempWest_surf_fit));
tempNorth_timeseries_surf=smooth(nanmean(tempNorth_surf_fit)); tempSouth_timeseries_surf=smooth(nanmean(tempSouth_surf_fit));
tempEast_timeseries_upperabl=smooth(nanmean(tempEast_upperabl_fit)); tempWest_timeseries_upperabl=smooth(nanmean(tempWest_upperabl_fit));
tempNorth_timeseries_upperabl=smooth(nanmean(tempNorth_upperabl_fit)); tempSouth_timeseries_upperabl=smooth(nanmean(tempSouth_upperabl_fit));

else 
tempEast_timeseries_surf=nanmean(tempEast_surf_fit); tempWest_timeseries_surf=nanmean(tempWest_surf_fit);
tempNorth_timeseries_surf=nanmean(tempNorth_surf_fit); tempSouth_timeseries_surf=nanmean(tempSouth_surf_fit);
tempEast_timeseries_upperabl=nanmean(tempEast_upperabl_fit); tempWest_timeseries_upperabl=nanmean(tempWest_upperabl_fit);
tempNorth_timeseries_upperabl=nanmean(tempNorth_upperabl_fit); tempSouth_timeseries_upperabl=nanmean(tempSouth_upperabl_fit);
end

%% now before plotting I am putting here what's needed for wind vectors:
timegrid=timegrid(1:end);
windmagnitude=sqrt(u_fit_upperabl.^2+v_fit_upperabl.^2);
arbitraty = zeros(size(windmagnitude));
%figure; quiver(time_fitfit,tempEast_timeseries_adv(1:size(time_fitfit)),u_meanadv,v_meanadv); grid on
% 
% scaling_velTemp_upperablH=tempWest_timeseries_upperabl(1:length(timegrid))';
% % scaling_velTemp_upperablH=scaling_velTemp_upperablH';
%  scaling_velTemp_surfH=tempWest_timeseries_surf(1:length(timegrid))';
%  %scaling_velTemp_surfH=scaling_velTemp_surfH;
%  %windmagnitude=sqrt(u_fit_upperabl.^2+v_fit_upperabl.^2)+scaling_velTemp_upperablH(1:length(timegrid));
 

%% making averages in velocities:
u_surf_timeseries = nanmean(u_fit_surf); v_surf_timeseries = nanmean(v_fit_surf);
u_upperabl_timeseries = nanmean(u_fit_upperabl); v_upperabl_timeseries = nanmean(v_fit_upperabl);
numstep=12;

% indifirst_low=find(isnan((u_fit_surf(:,1)))==0); indifirst_low=indifirst_low(1);
% u_surf_timeseries1=nanmean(u_fit_surf(indifirst_low:indifirst_low+numstep-1,:)); v_surf_timeseries1 = nanmean(v_fit_surf(indifirst_low:indifirst_low+numstep-1,:));
% u_surf_timeseries2=nanmean(u_fit_surf(indifirst_low+numstep:indifirst_low+2*numstep-1,:)); v_surf_timeseries2 = nanmean(v_fit_surf(indifirst_low+numstep:indifirst_low+2*numstep-1,:));
% u_surf_timeseries3=nanmean(u_fit_surf(indifirst_low+2*numstep:indifirst_low+3*numstep-1,:)); v_surf_timeseries3 = nanmean(v_fit_surf(indifirst_low+2*numstep:indifirst_low+3*numstep-1,:));
% u_surf_timeseries4=nanmean(u_fit_surf(indifirst_low+3*numstep:indifirst_low+4*numstep-1,:)); v_surf_timeseries4 = nanmean(v_fit_surf(indifirst_low+3*numstep:indifirst_low+4*numstep-1,:));
% 
% indifirst_up=find(isnan((u_fit_upperabl(:,1)))==0); indifirst_up=indifirst_up(1); 
% u_upperabl_timeseries1 = nanmean(u_fit_upperabl(indifirst_up:indifirst_up+numstep,:)); v_upperabl_timeseries1 = nanmean(v_fit_upperabl(indifirst_up:indifirst_up+numstep,:));
% u_upperabl_timeseries2 = nanmean(u_fit_upperabl(indifirst_up+numstep+1:indifirst_up+2*numstep,:)); v_upperabl_timeseries2 = nanmean(v_fit_upperabl(indifirst_up+numstep+1:indifirst_up+2*numstep,:));
% u_upperabl_timeseries3 = nanmean(u_fit_upperabl(indifirst_up+2*numstep+1:indifirst_up+3*numstep,:)); v_upperabl_timeseries3 = nanmean(v_fit_upperabl(indifirst_up+2*numstep+1:indifirst_up+3*numstep,:));


%% 4. homogenization of heights in the ABL (0 - 2000 m):

%tempMWRfitfit
[time_mwr1, time_mwr2] = size(timegrid);
[time_wdl, height_wdl] = size(u_fit);


for heightMerge = 1:length(height100)-2
 minindiheMWR(heightMerge) = nanmin(find((heightMWR_ta) >= height100(heightMerge)));
 maxindiheMWR(heightMerge) = nanmax(find((heightMWR_ta) <= height100(heightMerge+1)));

 minindiheWDL(heightMerge) = nanmin(find((heightWDL) >= height100(heightMerge)));
 maxindiheWDL(heightMerge) = nanmax(find((heightWDL) <= height100(heightMerge+1)));

end

% the next two lines are necessary to have consistent height levels,
% otherwise one gets double at higher level and doesn't make sense
maxindiheMWR=unique(maxindiheMWR); minindiheMWR=unique(minindiheMWR);
lengthHeight=min([length(maxindiMWR),length(minindiheMWR)]);
lengthHeight =lengthHeight-1;
lengthtime = min(time_mwr2,time_wdl);

for heightMerge = 1:lengthHeight

  for time_fit = 1:lengthtime
     %WDL_hwspeedfitfit(time_fit,heightMerge) =  nanmean(horizontalwindspeed(time_fit, minindiheWDL(heightMerge)...
      %  :nanmin(maxindiheWDL(heightMerge))));

     u_fitfit(time_fit,heightMerge) =  nanmean(u_fit(minindiheWDL(heightMerge)...
        :nanmin(maxindiheWDL(heightMerge)),time_fit));
     v_fitfit(time_fit,heightMerge) =  nanmean(v_fit(minindiheWDL(heightMerge)...
        :nanmin(maxindiheWDL(heightMerge)),time_fit));
     %w_component_fitfit(time_fit,heightMerge) =  nanmean(w(time_fit, minindiheWDL(heightMerge)...
      %  :nanmin(maxindiheWDL(heightMerge))));
%     WDL_vwspeedfitfit(time_fit,heightMerge) =  nanmean(verticalwindspeed(time_fit, minindiheWDL(heightMerge)...
 %       :nanmin(maxindiheWDL(heightMerge))));
  end

  for time_fit = 1:min(time_mwr2,time_wdl)
      
    tempEast_fitfit(time_fit,heightMerge) =  nanmean(tempEast_fit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));
    tempWest_fitfit(time_fit,heightMerge) =  nanmean(tempWest_fit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));
    tempNorth_fitfit(time_fit,heightMerge) =  nanmean(tempNorth_fit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));
    tempSouth_fitfit(time_fit,heightMerge) =  nanmean(tempSouth_fit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));

%     dTempdx_fitfit(time_fit,heightMerge) =  nanmean(nanmean(tempEast_fit(minindiheMWR(heightMerge)...
%         :nanmin(maxindiheMWR(heightMerge)-nanmean(tempWest_fit(minindiheMWR(heightMerge))...
%         :nanmin(maxindiheMWR(heightMerge))),time_fit)),time_fit));
%     dTempdy_fitfit(time_fit,heightMerge) =  nanmean(nanmean(tempNorth_fit(minindiheMWR(heightMerge)...
%         :nanmin(maxindiheMWR(heightMerge)-nanmean(tempSouth_fit(minindiheMWR(heightMerge))...
%         :nanmin(maxindiheMWR(heightMerge))),time_fit)),time_fit));
  end
     heightfitfit(heightMerge) =  nanmean(heightMWR_ta(minindiheMWR(heightMerge)...
     :nanmin(maxindiheMWR(heightMerge))));
     disthoriz_fit(heightMerge) = nanmean(disthoriz(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge))));

end % ends the homogeneization of heights between MWR and WDL

for heightMerge = 2:5%lengthHeight

  for time_fit = 1:lengthtime
     u_fitfit(time_fit,heightMerge) =  nanmean(u_fit(1:heightMerge,time_fit));
     v_fitfit(time_fit,heightMerge) =  nanmean(v_fit(1:heightMerge,time_fit));
  end
end

u_fitfit=u_fitfit'; v_fitfit=v_fitfit';
tempEast_fitfit=tempEast_fitfit'; tempWest_fitfit=tempWest_fitfit'; tempNorth_fitfit=tempNorth_fitfit'; tempSouth_fitfit=tempSouth_fitfit';

%% ends height homogeneization and starts estimating advection in height:

% horizontal temperature differences are defined:


for t=1:lengthtime; for h=1:lengthHeight
        Tdif_zonal(h,t)=(tempEast_fitfit(h,t)-tempWest_fitfit(h,t))./(disthoriz_fit(h));
        Tdif_meridional(h,t)=(tempNorth_fitfit(h,t)-tempSouth_fitfit(h,t))./(disthoriz_fit(h));

end; end

%% uncertainties:
%mindist=500; % m this is the minimum horiz dist to estimate advection
%minhei= round(mindist/2/tand(60)); % tangent of 60 cause that's the cone and 
dist_maxhei = 2*maxheight_upperabl*tand(60);
dist_A_to_B = nanmean([mindist, dist_maxhei])./1000;

indihei_abl = find(abs(heightMWR_ta-maxheightABL)<100);
gradient_temp_zonal =nanmean(abs(dTempdxzonal(3:indihei_abl,:))); gradient_temp_meridional =nanmean(abs(dTempdymeridional(3:indihei_abl,:)));
gradient_temp_mean =(gradient_temp_zonal+gradient_temp_meridional)/2; %gradient_temp_mean=gradient_temp_mean(1:end-1);

vel = nanmean(abs(u_fitfit))+nanmean(abs(v_fitfit));

wspd= [vel];  %in m/s         ; Mean wind speed from A to B [m/s]
    sigma_wspd= 0.8; % in m/s     ; Uncertainty in wind speed [m/s]
    % Adjust the wind speed to have the units needed
    wspd_adj       = wspd * (1/1000.) * (3600/1.); %              ; Convert [m/s] to [km/hr] 
    sigma_wspd_adj = sigma_wspd * (1/1000.) * (3600/1.);  %        ; Convert [m/s] to [km/hr] 

var_gradient_hum = 0.13/dist_A_to_B; % 0.13 g/kg see excel file
var_gradient_temp = 0.4/dist_A_to_B; % 0.4 K see excel file

sigma_gradient_hum = (var_gradient_hum);% a bit different our calculation here but very similar 
sigma_gradient_temp = (var_gradient_temp); % this is uncert delta_T/delta_x uncert (K/km) in my table in excel

    var_advection_temp   = (sigma_gradient_temp)^2 * (wspd_adj).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_temp_mean).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
    var_advection_temp_zonal   = (sigma_gradient_temp)^2 * (wspd_adj).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_temp_zonal).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
    var_advection_temp_meridional   = (sigma_gradient_temp)^2 * (wspd_adj).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_temp_meridional).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
       
    
    sigma_advection_temp_zonal = sqrt(var_advection_temp_zonal);
    sigma_advection_temp_meridional = sqrt(var_advection_temp_meridional);
    sigma_advection_temp = sqrt(sigma_advection_temp_zonal.^2 +sigma_advection_temp_meridional.^2);
    %sigma_advection_temp = sqrt(var_advection_temp);


%%

%a smooth is performed

if thermal_smooth==1
    numMovmean=4; numTd_std_z=7; numTd_std_m=7;
    meanTdif_zon = nanmean(Tdif_zonal'); stdTdif_zon = nanstd(Tdif_zonal'); 
    meanTdif_mer = nanmean(Tdif_meridional'); stdTdif_mer = nanstd(Tdif_meridional');
     for h=1:lengthHeight 
    %Tdif_zonal(h,:)= smooth((Tdif_zonal(h,:))); Tdif_meridional(h,:)= smooth((Tdif_meridional(h,:)));
    
    Tdif_zonal(h,:)= movmean((Tdif_zonal(h,:)),numMovmean); Tdif_meridional(h,:)= movmean((Tdif_meridional(h,:)),numMovmean);
    end

end

% Tdif_zonal and Tdif_meridional are in K/m for now, here 1000 multiplication converting from m to km
Tdif_zonal = 1000.*Tdif_zonal; Tdif_meridional = 1000.*Tdif_meridional; % this is in K/km

%% figures:

%figure; pcolor(timegrid,heightfitfit,Tdif_zonal); colorbar; caxis([-5e-4 5e-4]); title('(T_E -T_W)/\Deltax')
%figure; pcolor(timegrid,heightfitfit,Tdif_meridional); colorbar; caxis([-5e-4 5e-4]); title('(T_N-T_S)/\Deltay')

% fig temperature in each direction:
min_colorT=290; max_colorT=310; step_colorT=.5; extraabl=500;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));

figure('position',[1,1,1400,900],'Renderer','painters');
subplot(2,2,1)
pcolor(timemwr,heightMWR_ta,tempEast); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('\theta East'); caxis([min_colorT max_colorT])
xlabel('time UTC [hours]'); 
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]';
set(colorTitleHandle_temp ,'String',titleString_temp); 


subplot(2,2,2)
pcolor(timemwr,heightMWR_ta,tempWest); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('\theta West'); caxis([min_colorT max_colorT])
xlabel('time UTC [hours]');
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]';
set(colorTitleHandle_temp ,'String',titleString_temp);

subplot(2,2,3)
pcolor(timemwr,heightMWR_ta,tempNorth); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('\theta North'); caxis([min_colorT max_colorT])
xlabel('time UTC [hours]'); 
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]';
set(colorTitleHandle_temp ,'String',titleString_temp);

subplot(2,2,4)
pcolor(timemwr,heightMWR_ta,tempSouth); %colorbar;
ylim([minheight_surf maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
colormap(aaTemp); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('\theta South'); caxis([min_colorT max_colorT])
xlabel('time UTC [hours]'); 
hcb_temp=colorbar;
colorTitleHandle_temp = get(hcb_temp,'Title');
titleString_temp = '[K]'; 
set(colorTitleHandle_temp ,'String',titleString_temp);

saveas(figure(4),[pathfigs,'theta_directions_...' ...
     num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 1:
%saving netcdf for theta in directions
nc_theta_directions = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_theta_directions.nc'];

nccreate(nc_theta_directions,'thetaEast','Dimensions',{'time',length(timemwr),'height',length(heightMWR_ta)});
nccreate(nc_theta_directions,'thetaWest','Dimensions',{'time',length(timemwr),'height',length(heightMWR_ta)});
nccreate(nc_theta_directions,'thetaNorth','Dimensions',{'time',length(timemwr),'height',length(heightMWR_ta)});
nccreate(nc_theta_directions,'thetaSouth','Dimensions',{'time',length(timemwr),'height',length(heightMWR_ta)});
nccreate(nc_theta_directions,'thetaZenith','Dimensions',{'time',length(timemwr),'height',length(heightMWR_ta)});
nccreate(nc_theta_directions,'timemwr','Dimensions',{'time',length(timemwr)});
nccreate(nc_theta_directions,'heightMWR_ta','Dimensions',{'height',length(heightMWR_ta)});

ncwrite(nc_theta_directions,'thetaEast',tempEast');
ncwrite(nc_theta_directions,'thetaWest',tempWest');
ncwrite(nc_theta_directions,'thetaNorth',tempNorth');
ncwrite(nc_theta_directions,'thetaSouth',tempSouth');
ncwrite(nc_theta_directions,'thetaZenith',temp_zenith');
ncwrite(nc_theta_directions,'timemwr',timemwr);
ncwrite(nc_theta_directions,'heightMWR_ta',heightMWR_ta);
%n = ncread(nc_theta_directions, '_thetaEast')
%%

%
min_colorTdif=-0.5; max_colorTdif=-min_colorTdif; step_colorTdif=0.0005;
aaTempdif = (nclCM('cmp_b2r',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));
%dTempdxzonal=1000.*dTempdxzonal; dTempdymeridional=1000.*dTempdymeridional; % converting from m to km

figure('position',[1,1,800,1200],'Renderer','painters');
subplot(2,1,1)
pcolor(timegrid,heightfitfit,Tdif_zonal); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTempdif = (nclCM('CBR_coldhot',(size(min_color:step_color:max_color,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('(\theta_E-\theta_W)(\Deltax)^{-1}'); caxis([min_colorTdif max_colorTdif])
xlabel('time UTC [hours]'); colorbar;
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[Kkm^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(2,1,2)
pcolor(timegrid,heightfitfit,Tdif_meridional); 
ylim([minheight_surf-10 maxheight_upperabl+extraabl]); xlim([starttime endtime]);  grid on;
aaTempdif = (nclCM('CBR_coldhot',(size(min_color:step_color:max_color,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('(\theta_N-\theta_S)(\Deltay)^{-1}'); 
xlabel('time UTC [hours]'); caxis([min_colorTdif max_colorTdif]); colorbar
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[Kkm^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

saveas(figure(5),[pathfigs,'theta_diff_zonal_merid_...' ...
     num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 2:
%saving netcdf for theta in directions
nc_theta_zonaldifmeriddif = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_theta_dif_zonal_meridional.nc'];

nccreate(nc_theta_zonaldifmeriddif,'_theta_zonaldif','Dimensions',{'time',length(timegrid),'height',length(heightfitfit)});
nccreate(nc_theta_zonaldifmeriddif,'_theta_meridionaldif','Dimensions',{'time',length(timegrid),'height',length(heightfitfit)});
nccreate(nc_theta_zonaldifmeriddif,'_timegrid','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_zonaldifmeriddif,'_heightfitfit','Dimensions',{'height',length(heightfitfit)});

ncwrite(nc_theta_zonaldifmeriddif,'_theta_zonaldif',Tdif_zonal');
ncwrite(nc_theta_zonaldifmeriddif,'_theta_meridionaldif',Tdif_meridional');
ncwrite(nc_theta_zonaldifmeriddif,'_timegrid',timegrid);
ncwrite(nc_theta_zonaldifmeriddif,'_heightfitfit',heightfitfit);
%n = ncread(nc_theta_zonaldifmeriddif, '_theta_zonaldif');
%%

%% Estimating advection (height resolved):
u_fitfit= 3600.*u_fitfit./1000; v_fitfit = 3600.*v_fitfit./1000; % from m/s to km/hr

advection_zonal = (-u_fitfit.*Tdif_zonal); % (km/hr) (K/km) = K/hr
advection_meridional = -(v_fitfit.*Tdif_meridional);

min_colorAdv= -8; max_colorAdv=-min_colorAdv; step_colorAdv =0.01;

figure('position',[1,1,1500,800],'Renderer','painters');
subplot(3,1,1); 
pcolor(timegrid,heightfitfit,advection_zonal); title('u\cdot(\Delta\theta/\Deltax)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
ylabel('height [m]'); shading flat; xlim([starttime, endtime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(3,1,2); 
pcolor(timegrid,heightfitfit,advection_meridional); title('v\cdot(\Delta\theta/\Deltay)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;  ylim([minheight_surf-10, maxheight_upperabl+100]);  xlim([starttime, endtime])
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar; 
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(3,1,3);
pcolor(timegrid,heightfitfit,advection_zonal+advection_meridional); title('u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)')
aaAdv = (nclCM('cmp_b2r',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat; ylim([minheight_surf-10, maxheight_upperabl+100]); xlim([starttime, endtime])
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[K hr^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

saveas(figure(6),[pathfigs,'thermalAdvection_height_...' ...
     num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 4:
%saving netcdf for theta in directions
nc_theta_advection = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_theta_advection.nc'];

nccreate(nc_theta_advection,'_Advection_theta_zonal','Dimensions',{'time',length(timegrid),'height',length(heightfitfit)});
nccreate(nc_theta_advection,'_Advection_theta_meridional','Dimensions',{'time',length(timegrid),'height',length(heightfitfit)});
nccreate(nc_theta_advection,'_timegrid','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection,'_heightfitfit','Dimensions',{'height',length(heightfitfit)});

ncwrite(nc_theta_advection,'_Advection_theta_zonal',advection_zonal');
ncwrite(nc_theta_advection,'_Advection_theta_meridional',advection_meridional');
ncwrite(nc_theta_advection,'_timegrid',timegrid);
ncwrite(nc_theta_advection,'_heightfitfit',heightfitfit');

%n = ncread(nc_theta_advection, '_Advection_theta_zonal');
%%

% now advection in lower and upper layers:
for i=1:length(timegrid); for j=1:length(heightfitfit)
        if heightfitfit(j)>minheight_surf && heightfitfit(j)<maxheight_surf
            advection_zonal_lowerabl(j,i)=advection_zonal(j,i);
            advection_meridional_lowerabl(j,i)=advection_meridional(j,i);
        else; advection_zonal_lowerabl(j,i)=NaN; advection_meridional_lowerabl(j,i)=NaN;
        end
        if heightfitfit(j)>minheight_upperabl && heightfitfit(j)<maxheight_upperabl
            advection_zonal_upperabl(j,i)=advection_zonal(j,i);
            advection_meridional_upperabl(j,i)=advection_meridional(j,i);
        else; advection_zonal_upperabl(j,i)=NaN; advection_meridional_upperabl(j,i)=NaN;
        end
        if heightfitfit(j)>minheight_surf && heightfitfit(j)<maxheight_upperabl
            advection_zonal_allabl(j,i)=advection_zonal(j,i);
            advection_meridional_allabl(j,i)=advection_meridional(j,i);
        else; advection_zonal_allabl(j,i)=NaN; advection_meridional_allabl(j,i)=NaN;
        end
end; end

advection_zonal_lowerabl = nanmean(advection_zonal_lowerabl); advection_meridional_lowerabl = nanmean(advection_meridional_lowerabl);
advection_zonal_upperabl = nanmean(advection_zonal_upperabl); advection_meridional_upperabl = nanmean(advection_meridional_upperabl);
advection_zonal_allabl = nanmean(advection_zonal_allabl); advection_meridional_allabl = nanmean(advection_meridional_allabl);
advection_total_lowerabl = (advection_zonal_lowerabl+advection_meridional_lowerabl);
advection_total_upperabl = (advection_zonal_upperabl+advection_meridional_upperabl);
advection_total_allabl = (advection_zonal_allabl+advection_meridional_allabl);


minH_surf=minheight_surf;  maxH_surf=maxheight_surf; %timegrid=timegrid(1:end-4);
minH_upperabl=minheight_upperabl;  maxH_upperabl=maxheight_upperabl; 

% figure('position',[1,1,1000,800],'Renderer','painters'); 
% plot(timegrid,advection_total_lowerabl,'b', 'LineWidth',2); grid on
% hold on;  plot(timegrid,advection_total_upperabl, 'r', 'LineWidth',2);
% legend([ 'lower ABL (',num2str(minheight_surf),'-', num2str(maxheight_surf),' m) '; 'upper ABL (',...
%     num2str(minH_upperabl),'-', num2str(maxH_upperabl),' m)']); 
% title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      \theta advection (2 layers)']);
% xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([-15, 15])

sigma_advection_temp_adj=sigma_advection_temp(1:length(timegrid)); 
sigma_advection_temp_adj_zonal=sigma_advection_temp_zonal(1:length(timegrid)); sigma_advection_temp_adj_meridional=sigma_advection_temp_meridional(1:length(timegrid)); 
sigma_gradient_temp=sigma_gradient_temp; minlim=-17; maxlim = -minlim;
bluebonito = [0.1 0.4 0.8]; redbonito = [0.8 0.3 0.3]; purplebonito = [0.7 0.3 0.7];
% 
% figure('position',[1,1,1200,1000],'Renderer','painters'); 
% 
% subplot(2,2,1)
% plot(timegrid,advection_zonal_allabl, 'Color', bluebonito,'LineWidth',2); hold on; 
% %plot(timegrid,advection_total_allabl,'r', 'LineWidth',1); grid on
% xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
% % hold on
% % fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
% %      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
% hold on; grid on;
% fill([timegrid fliplr(timegrid)], [advection_zonal_allabl-sigma_advection_temp_adj_zonal...
%     fliplr(advection_zonal_allabl+sigma_advection_temp_adj_zonal)], ...
%      bluebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ 'u\cdot(\Delta\theta/\Deltax)                        '; 'uncertainty of u\cdot(\Delta\theta/\Deltax)         '])
%     %'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
% title(['                                                     (',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
%     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
% 
% subplot(2,2,2)
% plot(timegrid, advection_meridional_allabl,  'color', purplebonito, 'LineWidth',2); hold on
% %plot(timegrid,advection_total_allabl,'r', 'LineWidth',1); grid on
% % title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
% %     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
% % legend([ '     v\cdot(\Delta\theta/\Deltay)                        ';...
% %     'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
% xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
% % hold on
% % fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
% %      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
% hold on; grid on
% fill([timegrid fliplr(timegrid)], [advection_meridional_allabl-sigma_advection_temp_adj_meridional...
%     fliplr(advection_meridional_allabl+sigma_advection_temp_adj_meridional)], ...
%      purplebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ 'v\cdot(\Delta\theta/\Deltay)                        '; 'uncertainty of v\cdot(\Delta\theta/\Deltay)         '])
% 
% subplot(2,2,3:4)
% plot(timegrid,advection_total_allabl,'color', redbonito, 'LineWidth',2); grid on
% % title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
% %     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
% xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
% % hold on
% % fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
% %      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
% hold on
% fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj...
%     fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
%      redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ '       u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)        '; ...
%     'uncertainty of u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 


figure('position',[1,1,1400,500],'Renderer','painters'); 

subplot(1,2,1)
plot(timegrid,advection_zonal_allabl, 'Color', bluebonito,'LineWidth',2); hold on; 
plot(timegrid, advection_meridional_allabl,  'color', purplebonito, 'LineWidth',2); hold on
%plot(timegrid,advection_total_allabl,'r', 'LineWidth',1); grid on
xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
% hold on
% fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
%      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on; grid on;
fill([timegrid fliplr(timegrid)], [advection_zonal_allabl-sigma_advection_temp_adj_zonal...
    fliplr(advection_zonal_allabl+sigma_advection_temp_adj_zonal)], ...
     bluebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on; grid on
fill([timegrid fliplr(timegrid)], [advection_meridional_allabl-sigma_advection_temp_adj_meridional...
    fliplr(advection_meridional_allabl+sigma_advection_temp_adj_meridional)], ...
     purplebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
legend([ 'u\cdot(\Delta\theta/\Deltax)'; 'v\cdot(\Delta\theta/\Deltay)'])
    %'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title(['                                                        a)         \theta advection in ABL (',num2str(minheight_surf),'-',...
    num2str(maxheight_upperabl),' m) ']);


subplot(1,2,2)
plot(timegrid,advection_total_allabl,'color', redbonito, 'LineWidth',2); grid on
% title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
%     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('\theta advection [K hr^{-1}]'); ylim([minlim, maxlim])
% hold on
% fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
%      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on
fill([timegrid fliplr(timegrid)], [advection_total_allabl-sigma_advection_temp_adj...
    fliplr(advection_total_allabl+sigma_advection_temp_adj)], ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ '       u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)        '; ...
%     'uncertainty of u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title('b)');
legend([ 'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)'])

saveas(figure(7),[pathfigs,'thermalAdvection_allABL_...' ...
     num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 5:
%saving netcdf for theta in directions
nc_theta_advection_uncert = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_theta_advection_uncert.nc'];

nccreate(nc_theta_advection_uncert,'_Advection_theta_zonal_allABL','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection_uncert,'_sigmaAdvection_theta_zonal','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection_uncert,'_Advection_theta_meridional_allABL','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection_uncert,'_sigmaAdvection_theta_meridional','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection_uncert,'_sigmaAdvection_theta_total','Dimensions',{'time',length(timegrid)});
nccreate(nc_theta_advection_uncert,'_timegrid','Dimensions',{'time',length(timegrid)});

ncwrite(nc_theta_advection_uncert,'_Advection_theta_zonal_allABL',advection_zonal_allabl');
ncwrite(nc_theta_advection_uncert,'_sigmaAdvection_theta_zonal',sigma_advection_temp_adj');
ncwrite(nc_theta_advection_uncert,'_Advection_theta_meridional_allABL',advection_meridional_allabl');
ncwrite(nc_theta_advection_uncert,'_sigmaAdvection_theta_meridional',sigma_advection_temp_adj_meridional');
ncwrite(nc_theta_advection_uncert,'_sigmaAdvection_theta_total',sigma_advection_temp_adj');
ncwrite(nc_theta_advection_uncert,'_timegrid',timegrid);

%n = ncread(nc_theta_advection_uncert, '_Advection_theta_zonal_allABL');
%%


%% for plotting colors:
min_color=-1.5; max_color=-min_color; step_color=0.2;
colorzonal = [0.1 0.5 0.50]; colormeridional = [0.6 0.3 0.5];
%starttime=8; endtime=22; minhum=5; maxhum=10;
scale=1; % scale for quiver wind vectors
Gray1 = [128 128 128]/255; Gray2 = [100 100 128]/255; Gray3 = [75 75 128]/255; Gray4 = [60 60 128]/255;
 
%%
minH_surf=minheight_surf;  maxH_surf=maxheight_surf; %timegrid=timegrid(1:end-4);
minH_upperabl=minheight_upperabl;  maxH_upperabl=maxheight_upperabl; 
mintemp=290; maxtemp=310; scale=1;

