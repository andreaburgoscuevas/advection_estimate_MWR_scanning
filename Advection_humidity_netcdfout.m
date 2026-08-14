% Code for saving netcdfs of humidity advection case

clear all; close all

% here we should enter the date to be analized:
year=2021; month=10; day=8;

inverse=0; % if this is 1, the angles East-West are the other way around, it depends on what orientation the azimuths in the MWR have

yearT=2022; monthT=4; dayT=29; % usados alrededor de linea 390
% antes con angulos al reves, despues con angulos convencionales East and West

pathfigs = '/path/to/outputfigures/';
pathoutnet = '/path/to/outputNetCDF/';

% heights in which time series are performed:
minH_adv=600; maxH_adv=1300;
minH_surf=200; maxH_surf=600;

% do we want to take out heights not considered in the final advection estimate or not
avoid_low_heights=0; % this should be =1 to take out heights for which horizontal distance is too small

temporal_resolution = .5; % en hora decimal para juntar tiempos MWR y WDL
% vertical resolution:
height_resolutionABL = 100; % m

%%%
starttime=0; endtime=24;
neglectsmalldist=1; % turn this =1 for taking low levels where horizontal distance is small
mindist=1500; % m this is the minimum horiz dist to estimate advection
minhei= round(mindist/2/tand(60)); % tangent of 60 cause that's the cone and 

% heights to average the column:
min_height_abl=100; max_height_abl=1300; % all column ABL
minheight_surf=100; maxheight_surf=600;
minheight_upperabl=600; maxheight_upperabl=1300;
if neglectsmalldist==1; minheight_surf= max([minhei, minheight_surf]); end
%%%

minheight = 0; % m 
maxheightABL = 2100;
maxheightMWR100m = 1100; % maximum height till which MWR vertical resolution is better than 100 m, or 100 m 
height100 = [minheight:height_resolutionABL:maxheightMWR100m, maxheightMWR100m+200:200:maxheightABL]; 
fractionABL=0.8;
numdesvstd=3;
mindist=1000; % m
numstdallow=3; %max numb of standard deviations allow below whitch hum adv is not NaN
maxHumallowed_kgkg=0.010;

%% for plotting colors:
min_color=-1.5; max_color=-min_color; step_color=0.2;
colorzonal = [0.1 0.5 0.50]; colormeridional = [0.6 0.3 0.5];
starttime=0; endtime=22; minhum=3; maxhum=10;
scale=0.5; % scale for quiver wind vectors
Gray = [128 128 128]/255;

%% 1. stating paths and defining variables and constants that are gonna be used:

path_root_hatpro = '/path/to/MWRdata/';
path_root_lidar = '/path/to/WDLdata/';

pathoutAdvection = '/path/to/output/';
pathoutUncertainty = pathoutAdvection;

% aqui debo hacer un ciclo para saber si el filename esta empty y en ese
% caso que se pase al siguiente dia

%filenames:
    filenameMWR_hua = (dir(strcat([path_root_hatpro, 'sups_joy_mwr00_l2_hua_p00_',....
        num2str(year),sprintf('%02d', month),...
        sprintf('%02d',day),'*.nc'])));
    filename_IWV = (dir(strcat([path_root_hatpro, 'sups_joy_mwr00_l2_prw_p00_',....
        num2str(year),sprintf('%02d', month),...
        sprintf('%02d',day),'*.nc'])));

    %filenameMWR_BL_hua = (dir(strcat([path_root_hatpro, '/sups_joy_mwrBL00_l2_hua_*.nc'])));
    filenameMWR_ta = (dir(strcat([path_root_hatpro, '/sups_joy_mwr00_l2_ta_p00_',...
        num2str(year), sprintf('%02d', month),...
        sprintf('%02d',day),'*.nc'])));

    filenameWDL = (dir(strcat([path_root_lidar, '/wind_vad-36_',...
        num2str(year), sprintf('%02d', month),...
        sprintf('%02d', day),'.nc'])));

    %filesopen:    
    fileMWR_hua = ([path_root_hatpro, filenameMWR_hua.name]);
    % fileMWR_BL_hua = ([path_root_hatpro, num2str(year), '/', sprintf('%02d', month), '/',...
    %     sprintf('%02d',day), '/', filenameMWR_BL_hua.name]);
    fileMWR_ta = ([path_root_hatpro, filenameMWR_ta.name]);

    file_IWV = ([path_root_hatpro, filename_IWV.name]);

    fileWDL = ([path_root_lidar, filenameWDL.name]);
 % en las lineas anteriores se usa ese comando poderoso de strcat que sirve
    % para completar el nombre de un archivo sea el que sea, esto es mas
    % poderoso que *, porque asi acompleto nombres de files%% Reading variables from MWR

%% Reading variables from MWR

%ncdisp(fileMWR_BL_ta);
%ncdisp(fileMWR_hua);

humidityMWR_hua = ncread(fileMWR_hua,'hua');
heightMWR_hua = ncread(fileMWR_hua,'height');
azimuthMWR_hua = ncread(fileMWR_hua,'azi');
elevationMWR_hua = ncread(fileMWR_hua,'ele');

flagMWR_hua = ncread(fileMWR_hua,'flag');
rawtimeMWR_hua = double(ncread(fileMWR_hua, 'time'));
hua_error = ncread(fileMWR_hua,'hua_err'); % Dimensions: n_ret,height
%hua_error_hei = nanmean(hua_error); % because hua_error is mostly function of only height 
error_hum = nanmean(nanmean(hua_error));

%for fl=1:length(flagMWR_hua); if(isnan(flagMWR_hua(fl))==0); humidityMWR_hua(:,fl)=NaN; end; end

tempMWR_ta = ncread(fileMWR_ta,'ta');
ta_error = ncread(fileMWR_ta, 'ta_err'); %Dimensions: n_ret,height
ta_error_hei = nanmean(ta_error);
heightMWR_ta = ncread(fileMWR_ta,'height');
azimuthMWR_ta = ncread(fileMWR_ta,'azi');
elevationMWR_ta = ncread(fileMWR_ta,'ele');

flagMWR_ta = ncread(fileMWR_ta,'flag');
rawtimeMWR_ta = double(ncread(fileMWR_ta, 'time'));

% IWV:
prw = ncread(file_IWV,'prw'); % 'kg m-2' 'atmosphere_mass_content_of_water_vapor', These values denote the vertically integrated amount of water vapor from the surface to TOA.'

% writing time in a way that makes sense: 
secsin1day=60*60*24;
base=datenum(1970,1,1); % according to what the cdf file says with ncdisp(file)
datetimefileMWR = datestr(rawtimeMWR_hua/secsin1day+base);
timesindayMWR = length(datetimefileMWR);

for cht =1:timesindayMWR
    datetimeMWR(cht) = convertCharsToStrings(datetimefileMWR(cht,:));
end
 
decimaltimeMWR = hour(datetimeMWR)+ minute(datetimeMWR)./60;
    
%humidityMWR_BL_hua = ncread(fileMWR_BL_hua,'hua');
%heightMWR_BL_hua = ncread(fileMWR_BL_hua,'height');
%azimuthMWR_BL_hua = ncread(fileMWR_BL_hua,'azi');
%elevationMWR_BL_hua = ncread(fileMWR_BL_hua,'ele');
%flagMWR_BL_hua = ncread(fileMWR_BL_hua,'flag');
%rawtimeMWR_BL_hua = double(ncread(fileMWR_BL_hua, 'time'));

flagsonMWR_hua = find(isnan(flagMWR_hua)==0);
whichflag_MWR_hua = flagMWR_hua(flagsonMWR_hua);

% flagsonMWR_BL_ta = find(isnan(flagMWR_BL_ta)==0);
% whichflag_MWR_BL_ta = flagMWR_BL_ta(flagsonMWR_BL_ta);

%% estimating specific humidity:
Rw = 461.52; %J/kgK
heightJue= 111; %m asl
g=9.8;
p_0 = 1006; % hPa  surface pressure 
p_0 = 100*p_0; % Pa
g_0 = 9.8; % m/s2
R_gas = 287.0; % J/(kgK) for dry atmosphere
c_p = 1004; %  J/(kgK) Holton

M_air=0.02896968; % kg/mol
T_0=288.16; %K sea level standard temperature 
R_0 = 8.31446; %J/molK
%p_0 = 101325; % Pa
%values from https://en.wikipedia.org/wiki/Atmospheric_pressure
e_partialpres = Rw.*tempMWR_ta.*humidityMWR_hua; 
%pres = p_0.*exp(-(g.*(heightMWR_hua+heightJue)*M_air)./(T_0*R_0));
H_scaleheight = R_gas.*tempMWR_ta./g_0;     
presi = p_0.*exp(-heightMWR_hua./H_scaleheight);

q_specificHum = (0.622.*e_partialpres)./(presi-0.378.*e_partialpres); % kg/kg
%q_specificHum = humidityMWR_hua;
%eq from https://cran.r-project.org/web/packages/humidity/vignettes/humidity-measures.html

%% for uncertainty:
temp_error_ABL  = 0.4; % value taken from Tobi Boeck paper
e_partialpresmax = Rw.*((tempMWR_ta)+temp_error_ABL).*((abs(humidityMWR_hua))+error_hum); 
e_partialpresmin = Rw.*((tempMWR_ta)-temp_error_ABL).*((abs(humidityMWR_hua))-error_hum); 
%pres = p_0.*exp(-(g.*(heightMWR_hua+heightJue)*M_air)./(T_0*R_0));
H_scaleheightmax = R_gas.*((tempMWR_ta)+temp_error_ABL)./g_0;  
H_scaleheightmin = R_gas.*((tempMWR_ta)-temp_error_ABL)./g_0;
presimax = p_0.*exp(-heightMWR_hua./H_scaleheightmax);
presimin = p_0.*exp(-heightMWR_hua./H_scaleheightmin);

q_specificHummax = (0.622.*e_partialpresmax)./(presimax-0.378.*e_partialpresmax);
q_specificHummin = (0.622.*e_partialpresmin)./(presimin-0.378.*e_partialpresmin);
q_difmax = abs(q_specificHum-q_specificHummax); q_difmin = abs(q_specificHum-q_specificHummin);
q_uncert = (q_difmax+q_difmin)./2;

%% Reading variables from WDL: 

%ncdisp(fileWDL);
horizontalwindspeed = ncread(fileWDL, 'speed'); % 'm s^-1'
dirhorizontalwindspeed = ncread(fileWDL, 'dir'); % degrees
%verticalwindspeed = ncread(fileWDL, 'w_speed'); % 'm s^-1'
heightWDL = ncread(fileWDL, 'height'); % meters a.g.l.
rawtimeWDL = ncread(fileWDL, 'time'); % julian day, i.e. fractional days since January 1, 4713 BC Greenwich noon; can be converted to unix epoch with t_unix=(time-2440587.5)*86400'
datetimeWDL = datetime(rawtimeWDL,'convertfrom','juliandate');
timesindayWDL = length(datetimeWDL);
windvector = ncread(fileWDL, 'wind_vec');
u=windvector(:,:,1);
v=windvector(:,:,2);
w=windvector(:,:,3);
delta_speed = ncread(fileWDL, 'delta_speed'); % uncertainty of horizontal wind speed in m/s

%% ABL classif TM

path_bl = '/path/to/dataWDL_ABL_classification/';

data_bl = [];
%for i = 1:length(dates)
%i=14;
    %daten = datenum(num2str(dates(i)),'yyyymmdd');
    file_bl = dir(strcat([path_bl ...
    [num2str(year),sprintf('%02d', month),sprintf('%02d', day)]...
    '_juelich_halo-doppler-lidar_BL-classification.nc']));
    data_bl.time_3min = ncread(strcat([path_bl, file_bl.name]),'time_3min');
    data_bl.bl_classification_3min = ncread(strcat([path_bl file_bl.name]),'bl_classification_3min')';
    data_bl.height = ncread(strcat([path_bl file_bl.name]),'height');
    mlh = ones(size(data_bl.time_3min)) * nan;
    for j = 1:length(mlh)
        xf = find(data_bl.bl_classification_3min(j,:) == 4,1,'last');
        if ~isempty(xf)
            mlh(j) = data_bl.height(xf);
        end
    end
aerosol_layer_top = ncread(strcat([path_bl  file_bl.name]),'aerosol_layer_top_3min');
heightTM = ncread(strcat([path_bl file_bl.name]),'height');

    timeTM = data_bl.time_3min;
    CBLHTM=mlh;
%     CBLHTM = smooth(mlh);
%     for i=1:length(CBLHTM)
%         if CBLHTM(i)>max(mlh); CBLHTM(i)= nanmax(mlh); end
%         if CBLHTM(i)<0; CBLHTM(i)= nanmax(mlh); end
%     end

%% FINDING MWR SCANS WITH 30 DEG ELEVATION and simultaneously N S E W  at each height and time
% now I am going to calculate horizontal displacement in that 30 deg elev cone for each height:
% but I am only starting now with the easy points: EW and NS

%angle_rad = 0.5236; % 30 deg in radians
angle_rad = 1.05; % 60 deg in radians cause my geometry is with respect to zenital, i.e. 90-elev

[heightsize, timesize] = size(humidityMWR_hua);

eastdistance = NaN.*ones(1,heightsize); westdistance = NaN.*ones(1,heightsize); 
northdistance = NaN.*ones(1,heightsize); southdistance = NaN.*ones(1,heightsize);
easttime = NaN.*ones(timesize,1); westtime = NaN.*ones(timesize,1);
northtime = NaN.*ones(timesize,1); southtime = NaN.*ones(timesize,1);
eastHumidity = NaN.*ones(heightsize,48); westHumidity = NaN.*ones(heightsize,1);
northHumidity = NaN.*ones(heightsize,1); southHumidity = NaN.*ones(heightsize,1);

decimaltime30indice = NaN.*ones(timesize,1); 
tiempo30indice = NaN.*ones(timesize,1); tiempo30east = NaN.*ones(timesize,1);
tiempo90indice = NaN.*ones(timesize,1);

teastcount = 0; twestcount = 0; tnorthcount = 0; tsouthcount = 0;
flaghum30elev= NaN.*ones(heightsize,timesize);

time30elev=NaN.*ones(heightsize,timesize); time90elev=NaN.*ones(heightsize,timesize);
dista30elev=NaN.*ones(heightsize,timesize); dista90elev=NaN.*ones(heightsize,timesize);
humidity30elev=NaN.*ones(heightsize,timesize); humidity90elev=NaN.*ones(heightsize,timesize);
uncert30elev=NaN.*ones(heightsize,timesize); azimuth30elev=NaN.*ones(heightsize,timesize);

for hh = 1:heightsize
    for tt = 1:timesize
        
         if abs(elevationMWR_hua(tt)-30) < 1 % aqui si esta bien poner 30 deg, porque en el file son 30 deg

             tiempo30indice(tt) = tt; % encontrando tiempos del scan para los cuales elevation=30
            if (isnan(tiempo30indice(tt))==0)
                time30elev(hh,tt) = hour(datetimeMWR(tt))+ minute(datetimeMWR(tt))./60;
                dista30elev(hh,tt) = heightMWR_hua(hh).*tan(angle_rad);
                humidity30elev(hh,tt) = q_specificHum(hh,tt);
                uncert_hum30elev(hh,tt) = q_uncert(hh,tt);
                azimuth30elev(tt) = azimuthMWR_hua(tt);
                flaghum30elev(hh,tt) = flagMWR_hua(tt);
                %prw_t(tt) = prw(tt);
            end
         end
    end

end

for hh = 1:heightsize
    for tt9 = 1:timesize
          if abs(elevationMWR_hua(tt9)-90) < 1 % aqui si esta bien poner 90 deg, porque en el file son 30 deg

             tiempo90indice(tt9) = tt9; % encontrando tiempos del scan para los cuales elevation=90
            if (isnan(tiempo90indice(tt9))==0)
                % time90elev(hh,tt9) = hour(datetimeMWR(tt9))+ minute(datetimeMWR(tt9))./60;
                % dista90elev(hh,tt9) = heightMWR_hua(hh).*tan(angle_rad);
                humidity90elev(hh,tt9) = q_specificHum(hh,tt9);
                % uncert_hum90elev(hh,tt) = q_uncert(hh,tt);
                % azimuth90elev(tt) = azimuthMWR_hua(tt);
                % flaghum90elev(hh,tt) = flagMWR_hua(tt);
                %prw_t(tt) = prw(tt);
            end

         end
    end

end

count=0;
for titi=1:length(humidity30elev)
    if(humidity30elev(5,titi))>0
        count = count+1;
        indi(count)=titi;
        %timescan(count)=time30elev(titi);
        %ti(count)=tiempo30indice(count);
    end
    
end

count90=0;
for titi9=1:length(humidity90elev)
    if(humidity90elev(5,titi9))>0
        count90 = count90+1;
        indi90(count90)=titi9;
        %timescan(count)=time30elev(titi);
        %ti(count)=tiempo30indice(count);
    end
    
end

numscans=length(indi)/36;
indistart =indi(1:36:end); % este indice del tiempo raw inicia un nuevo scan

numscans90 = length(indi90)/36; indistart90= indi90(1:36:end);

 for hei=1:heightsize
%     for tim=1:numscans
%       humMat(hei,tim) = humidity30elev(hei,indistart(tim));
%         
%     end
        for ondi=1:length(indi)
            humMat(hei,ondi) = humidity30elev(hei,indi(ondi));
            flagMat(hei,ondi)= flaghum30elev(hei,indi(ondi));
            uncertHumMat(hei,ondi) = uncert_hum30elev(hei,indi(ondi));
            azim(ondi) = azimuth30elev(indi(ondi));
            timescan(ondi) = time30elev(hei,indi(ondi));
            distaHoriz(hei,ondi) = dista30elev(hei,indi(ondi));
            
        end

          for ondi90=1:length(indi90)
            humMat90(hei,ondi90) = humidity90elev(hei,indi90(ondi90));
            %flagMat(hei,ondi)= flaghum30elev(hei,indi(ondi));
            %uncertHumMat(hei,ondi) = uncert_hum30elev(hei,indi(ondi));
            %azim(ondi) = azimuth30elev(indi(ondi));
            timescan90(ondi90) = time90elev(hei,indi90(ondi90));
            distaHoriz90(hei,ondi90) = dista90elev(hei,indi90(ondi90));
            
        end

 end

%filter to remove physically unrealisttically variations
 for hei=1:heightsize
        for ondi=1:length(indi)
            if ondi>2 && ondi< length(indi)
                if abs(humMat(hei,ondi)) > abs(nanmean([humMat(hei,ondi-1),humMat(hei,ondi+1)]))+ abs(std(humMat(hei,ondi-1:ondi+1)))
                    humMat(hei,ondi) = nanmean([humMat(hei,ondi-1),humMat(hei,ondi+1)]);
                end
            end

        end
 end

% making a 3D matrix for humidity in each scan, in each height, in each angle
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
         humMat3D(hh,az(tim),scan(tim))= humMat(hh,tim);
         flagMat3D(hh,az(tim),scan(tim))=flagMat(hh,tim);
         hum_uncertMat3D(hh,az(tim),scan(tim)) = uncertHumMat(hh,tim);
         azim2D(az(tim),scan(tim)) = azim(tim);
         timescan2D(az(tim),scan(tim)) = timescan(tim);
         distaHoriz2D(hh,az(tim))= distaHoriz(hh,tim);
         iwv(az(tim),scan(tim))= prw(tim);
         %humMatAzimuths(hh,az(tim)) = 
         
end
end

scan90=ones(1,ondi90); az90=ones(1,ondi90);
for tim90=1:length(indi90)
for hh=1:heightsize
if tim90>1
    az90(tim90)=tim90-36*scan90(tim90-1)+36;
    if  mod(tim90,36)==0
        scan90(tim90)=scan90(tim90-1)+1;
    else
    scan90(tim90)=scan90(tim90-1);
    end
end
         humMat3D90(hh,az90(tim90),scan90(tim90))= humMat90(hh,tim90);
         timescan2D90(az90(tim90),scan90(tim90)) = timescan90(tim90);
         distaHoriz2D90(hh,az90(tim90))= distaHoriz90(hh,tim90);
         iwv90(az90(tim90),scan90(tim90))= prw(tim90);
         %humMatAzimuths(hh,az(tim)) = 
         
end
end

% 
[altura,angulo,tiempo] = size(humMat3D); tiempo=tiempo-1;
 for h=1:altura
      for t=1:tiempo
         for an=1:angulo
             if abs(humMat3D(h,an,t))>maxHumallowed_kgkg % higer q than this is not physically realistic
                 humMat3D(h,an,t) =NaN;
             end
         end
      end
 end

[altura90,angulo90,tiempo90] = size(humMat3D90); tiempo90=tiempo90-1;
 for h9=1:altura90
      for t9=1:tiempo90
         for an9=1:angulo90
             if abs(humMat3D90(h9,an9,t9))>maxHumallowed_kgkg % higer q than this is not physically realistic
                 humMat3D90(h9,an9,t9) =NaN;
             end
         end
      end
 end

 for h9=1:altura90
      for t9=1:tiempo90
         for an9=1:angulo90
            hum_zenith_all(h9,an9,t9) = humMat3D90(h9,an9,t9);
         end

         humZenith(h9,t9)= nanmean(nonzeros(hum_zenith_all(h9,:,t9)));

      end
 end

 % making zenith with time of others
idx = round(linspace(1,length(humZenith),48)); humZenith = humZenith(:,idx);

 for h=1:altura
      for t=1:tiempo
         for an=1:angulo

         if azim2D(an,t)== 0 || azim2D(an,t) >=350 || azim2D(an,t) <=10 %azimuth=0 North
             humNorth_all(h,an,t) = humMat3D(h,an,t);
             humNorth_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
               
         end
         if azim2D(an,t)== 180 || azim2D(an,t) ==170 || azim2D(an,t) ==190% azimuth=180 South
             humSouth_all(h,an,t) = humMat3D(h,an,t);
             humSouth_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
         end

         %% cuando estan al reves los angulos
%antes:
%if year<=yearT && month<=monthT && day<dayT
if inverse==1
         if azim2D(an,t)== 270 || azim2D(an,t) ==280 || azim2D(an,t) ==260% azimuth=90 East
             humEast_all(h,an,t) = humMat3D(h,an,t);
             humEast_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
         end
         if azim2D(an,t)== 90 || azim2D(an,t) ==80 || azim2D(an,t) ==100% azimuth=270 West
             humWest_all(h,an,t) = humMat3D(h,an,t);
             humWest_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
         end
end

%despues:
%if year>=yearT && month>=monthT && day>=dayT
if inverse==0
         if azim2D(an,t)== 270 || azim2D(an,t) ==280 || azim2D(an,t) ==260% azimuth=90 East
             humWest_all(h,an,t) = humMat3D(h,an,t);
             humWest_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
         end
         if azim2D(an,t)== 90 || azim2D(an,t) ==80 || azim2D(an,t) ==100% azimuth=270 West
             humEast_all(h,an,t) = humMat3D(h,an,t);
             humEast_uncertall(h,an,t) = hum_uncertMat3D(h,an,t);
         end
end
%%
        flagHum_all(h,an,t) = flagMat3D(h,an,t);

         if abs(timescan2D(an,t)-12)<0.4
             humNoon(h,an)=humMat3D(h,an,t);
         end

         end
         humNorth(h,t)= nanmean(nonzeros(humNorth_all(h,:,t))); humNorth_uncert(h,t)= nanmean(nonzeros(humNorth_uncertall(h,:,t)));
         humSouth(h,t)= nanmean(nonzeros(humSouth_all(h,:,t))); humSouth_uncert(h,t)= nanmean(nonzeros(humSouth_uncertall(h,:,t)));
         humEast(h,t)= nanmean(nonzeros(humEast_all(h,:,t))); humEast_uncert(h,t)= nanmean(nonzeros(humEast_uncertall(h,:,t)));
         humWest(h,t)= nanmean(nonzeros(humWest_all(h,:,t))); humWest_uncert(h,t)= nanmean(nonzeros(humWest_uncertall(h,:,t)));
         flagHum(h,t) = nanmean(nonzeros(flagHum_all(h,:,t)));
     end
 end

% next cycles to take out data with smaller than the advection used horizontal distance
if avoid_low_heights ==1
 for h=1:altura
     for an=1:angulo
     for t=1:tiempo

if (humNorth(h,t)==0) || (distaHoriz2D(h,an)<mindist); humNorth(h,t)=NaN; end
if humSouth(h,t)==0 || (distaHoriz2D(h,an)<mindist); humSouth(h,t)=NaN; end
if humEast(h,t)==0 || (distaHoriz2D(h,an)<mindist); humEast(h,t)=NaN; end
if humWest(h,t)==0 || (distaHoriz2D(h,an)<mindist); humWest(h,t)=NaN; end
    end
    end
 end
end

%% disregarding flagged data:
for hh = 1:altura; for tt = 1:tiempo
        %if (isnan(flagHum(hh,tt))==0) && (flagHum(hh,tt)>8)
        if  (flagHum(hh,tt)==64) || (flagHum(hh,tt)==2048) || (flagHum(hh,tt)==8)
            humNorth(hh,tt)=NaN;humSouth(hh,tt)=NaN; humEast(hh,tt)=NaN;humWest(hh,tt)=NaN;
        end
end; end
%%
distanciaenaltura = nanmean(distaHoriz2D');

%% Making gradients of humidity and distance:

zonalHumiditydif = humEast-humWest;
meridionalHumiditydif = humNorth-humSouth;

dist_horiz_ABL=distanciaenaltura;
for te=1:length(heightMWR_ta); if heightMWR_ta(te)>1100 || heightMWR_ta(te)<600;dist_horiz_ABL(te)=NaN;end;end
dist_horiz_ABL=2*nanmean(dist_horiz_ABL);

% uncertainty: 
% zonalHumiditydif_uncert = sqrt(humEast_uncert.^2 + humWest_uncert.^2);
% meridionalHumiditydif_uncert = sqrt(humNorth_uncert.^2 + humSouth_uncert.^2);
zonalHumidity_uncert = (abs(humEast_uncert) + abs(humWest_uncert))./2;
meridionalHumidity_uncert = (abs(humNorth_uncert) + abs(humSouth_uncert))./2;

%next cycles are for disregarding data of uncertanty at heights that we dont use:
[szll1, szll2] = size(zonalHumiditydif);
for l=1:szll1; for ll=1:szll2
        if isnan(humEast(l,ll))==1 || heightMWR_ta(l) >1300
            humEast_uncert(l,ll) =NaN; humWest_uncert(l,ll)=NaN;
            humNorth_uncert(l,ll)=NaN; humSouth_uncert(l,ll)=NaN;
            zonalHumidity_uncert(l,ll)=NaN; meridionalHumidity_uncert(l,ll)=NaN;
        end
end; end
distanciaenaltura(1)=distanciaenaltura(2);
zonaldistdif = 2*distanciaenaltura;
meridionaldistdif = 2*distanciaenaltura;
 
%% so I have a zonal and meridional humidity gradients of MWR data:
for hi=1:altura
dHumdxzonal(hi,:) = zonalHumiditydif(hi,:)./zonaldistdif(hi); 
dHumdymeridional(hi,:) = meridionalHumiditydif(hi,:)./meridionaldistdif(hi);

% % uncertainty: 
% dHumdxzonal_uncert(hi,:) = zonalHumiditydif_uncert(hi,:)./zonaldistdif(hi);
% dHumdymeridional_uncert(hi,:) = meridionalHumiditydif_uncert(hi,:)./meridionaldistdif(hi);

%and the corresponding time and heights are
timezonal = nanmean(timescan2D(:,1:end-1));
timemeridional = nanmean(timescan2D(:,1:end-1));
heightMWR_hua;
end
%% and for the WDL I have:
uzonalvel = u;
vmeridionalvel = v;
datetimeWDL;
decimaltimeWDL = hour(datetimeWDL)+ minute(datetimeWDL)./60+.3;
heightWDL;
[sztw, szhw] = size(u); thresholdVsurf=30; thresholdUsurf=30; thresholdU=30;

%% homogenization form RiB code: of time, so data from MWR and WDL coincides in temporal resolution: 

    [sztempmwr1, sztempmwr2] =size(dHumdymeridional); % the size of temp matrix = height x time
    [szhws1, szhws2] =size(uzonalvel); % the size from horizontal wspeed matrix = time x height
%     decimaltimeMWR = hour(datetimeMWR)+ minute(datetimeMWR)./60;
%     decimaltimeWDL = hour(datetimeWDL)+ minute(datetimeWDL)./60;

% in the following loop with tiempoMerge, I am defining the min and max
% indices for each iteration for which there are measurements from both MWR
% and WDL between the time tiempoMerge and the following time tiempoMerge+1. With this, I
% am averaging the corresponding measurements of both instruments in that
% time lapse and leaving the height untoched but smoothing in time for both
% instrument measurements to have the same temporal resolution

% this is a variable for merging the times:
tim_grid_hum_res = 0:temporal_resolution:23.75; % temporal resolution every 15 min

tiempoInicial = find(min(abs(tim_grid_hum_res-timezonal(1)))==abs(tim_grid_hum_res-timezonal(1)));

for tiempoMerge =tiempoInicial:length(tim_grid_hum_res)-1
  
 minindiMWR(tiempoMerge) = nanmin(find((timezonal) >= tim_grid_hum_res(tiempoMerge))); % el minimo indice mayor al grid en esa iteracion
 maxindiMWR(tiempoMerge) = nanmax(find((timezonal) <= tim_grid_hum_res(tiempoMerge+1))); % el max indice menor an grid inmediato superior

 minindiWDL(tiempoMerge) = nanmin(find((decimaltimeWDL) >= tim_grid_hum_res(tiempoMerge)));
 maxindiWDL(tiempoMerge) = nanmax(find((decimaltimeWDL) <= tim_grid_hum_res(tiempoMerge+1)));
end

minindiMWR = [minindiMWR,minindiMWR(end)]; maxindiMWR = [maxindiMWR,maxindiMWR(end)];
minindiWDL = [minindiWDL,minindiWDL(end)]; maxindiWDL = [maxindiWDL,maxindiWDL(end)];

for tiempoMerge =tiempoInicial:length(tim_grid_hum_res)
 for height_mwr = 1:sztempmwr1 %porque la variable tempMWR es 43 x 96 = height x time
    zonalHumGradMWRfit(height_mwr,tiempoMerge) =  nanmean(dHumdxzonal...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),sztempmwr2)));
    meridionalHumGradMWRfit(height_mwr,tiempoMerge) =  nanmean(dHumdymeridional...
        (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),sztempmwr2)));

%     zonalHumGradMWRfit_uncert(height_mwr,tiempoMerge) =  nanmean(dHumdxzonal_uncert...
%         (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),sztempmwr2)));
%     meridionalHumGradMWRfit_uncert(height_mwr,tiempoMerge) =  nanmean(dHumdymeridional_uncert...
%         (height_mwr,minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),sztempmwr2)));
 end

 for height_wdl = 1: szhws2 % porque la variable horizontalwindspeed es de size 275 x 320 = time x height
%      WDL_hwspeedfit(tiempoMerge,height_wdl) =  nanmean(uzonalvel(minindiWDL(tiempoMerge)...
%         :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));

     u_fit(tiempoMerge,height_wdl) = nanmean(uzonalvel(minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
     v_fit(tiempoMerge,height_wdl) = nanmean(vmeridionalvel(minindiWDL(tiempoMerge)...
        :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
     timefit(tiempoMerge) = nanmean(decimaltimeWDL(minindiWDL(tiempoMerge):...
         nanmin(maxindiWDL(tiempoMerge),szhws1)));
%      w_fit(tiempoMerge,height_wdl) = nanmean(w(minindiWDL(tiempoMerge)...
%         :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
          
%     WDL_vwspeedfit(tiempoMerge,height_wdl) =  nanmean(verticalwindspeed(minindiWDL(tiempoMerge)...
 %       :nanmin(maxindiWDL(tiempoMerge),szhws1),height_wdl));
 end

 %datetimeMWRfit(tiempoMerge) = nanmean(datetime(convertStringsToChars(datetimeMWR(minindiMWR(tiempoMerge)...
    % :nanmin(maxindiMWR(tiempoMerge))))));
 timezonalfit(tiempoMerge) = nanmean(timezonal(minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge))));
 timemeridionalfit(tiempoMerge) = nanmean(timemeridional(minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge))));
 %datetimeWDLfit(tiempoMerge) = nanmean(datetimeWDL(minindiWDL(tiempoMerge)...
  %   :nanmin(maxindiWDL(tiempoMerge),szhws1)));

 %heightMWRtimefit(tiempoMerge) = nanmean(heightMWR(minindiMWR(tiempoMerge):nanmin(maxindiMWR(tiempoMerge),length(heightMWR))));
 %heightWDLtimefit(tiempoMerge) = nanmean(heightWDL(minindiWDL(tiempoMerge):nanmin(maxindiWDL(tiempoMerge),length(heightMWR))));
 
end % here the homogenization of temporal resolution ends

% figure; pcolor(timefit,heightMWR_ta,zonalTempGradMWRfit); colorbar; caxis([-.001, .001]); title('dT/dx timefit'); ylim([0, 2000])
% figure; pcolor(timefit,heightMWR_ta,meridionalTempGradMWRfit); colorbar; caxis([-.001, .001]); title('dT/dy timefit'); ylim([0, 2000])
% figure; pcolor(timefit,heightWDL,u_fit'); title('vel zonal con fit'); shading interp; colorbar; ylim([0, 2000]); caxis([-15, 15])
% figure; pcolor(timefit,heightWDL,v_fit'); title('vel meridional con fit'); shading interp; colorbar; ylim([0, 2000]); caxis([-15, 15])
% 
% 

%% 4. homogenization of heights in the ABL (0 - 2000 m):

%tempMWRfitfit
[time_mwr1, time_mwr2] = size(timefit);
[time_wdl, height_wdl] = size(u_fit);

for heightMerge = 1:length(height100)-1
 minindiheMWR(heightMerge) = nanmin(find((heightMWR_hua) >= height100(heightMerge)));
 maxindiheMWR(heightMerge) = nanmax(find((heightMWR_hua) <= height100(heightMerge+1)));

 minindiheWDL(heightMerge) = nanmin(find((heightWDL) >= height100(heightMerge)));
 maxindiheWDL(heightMerge) = nanmax(find((heightWDL) <= height100(heightMerge+1)));
end

% the next two lines are necessary to have consistent height levels,
% otherwise one gets double at higher level and doesn't make sense
maxindiheMWR=unique(maxindiheMWR); minindiheMWR=unique(minindiheMWR);
lengthHeight=min([length(maxindiMWR),length(minindiheMWR)]);

for heightMerge = 1:lengthHeight-1
%  for time_fit = 1:time_mwr2 %porque la variable tempMWRfit es 43 x 92 = height x time
%     tempMWRfitfit(heightMerge,time_fit) = nanmean(tempMWRfit...
%         (minindiheMWR(heightMerge):nanmin(maxindiMWR(heightMerge))),time_fit);
%  end

  for time_fit = 1:min(time_mwr2,time_wdl)
     %WDL_hwspeedfitfit(time_fit,heightMerge) =  nanmean(horizontalwindspeed(time_fit, minindiheWDL(heightMerge)...
      %  :nanmin(maxindiheWDL(heightMerge))));
     u_fitfit(time_fit,heightMerge) =  nanmean(u_fit(time_fit, minindiheWDL(heightMerge)...
        :nanmin(maxindiheWDL(heightMerge))));
     v_fitfit(time_fit,heightMerge) =  nanmean(v_fit(time_fit, minindiheWDL(heightMerge)...
        :nanmin(maxindiheWDL(heightMerge))));
     %w_component_fitfit(time_fit,heightMerge) =  nanmean(w(time_fit, minindiheWDL(heightMerge)...
      %  :nanmin(maxindiheWDL(heightMerge))));

%     WDL_vwspeedfitfit(time_fit,heightMerge) =  nanmean(verticalwindspeed(time_fit, minindiheWDL(heightMerge)...
 %       :nanmin(maxindiheWDL(heightMerge))));
  end

  for time_fit = 1:min(time_mwr2,time_wdl)
    dHumdx_fitfit(time_fit,heightMerge) =  nanmean(zonalHumGradMWRfit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));
    dHumdy_fitfit(time_fit,heightMerge) =  nanmean(meridionalHumGradMWRfit(minindiheMWR(heightMerge)...
        :nanmin(maxindiheMWR(heightMerge)),time_fit));

%     dHumdx_fitfit_uncert(time_fit,heightMerge) =  nanmean(zonalHumGradMWRfit_uncert(minindiheMWR(heightMerge)...
%         :nanmin(maxindiheMWR(heightMerge)),time_fit));
%     dHumdy_fitfit_uncert(time_fit,heightMerge) =  nanmean(meridionalHumGradMWRfit_uncert(minindiheMWR(heightMerge)...
%         :nanmin(maxindiheMWR(heightMerge)),time_fit));
  end
     heightfitfit(heightMerge) =  nanmean(heightMWR_hua(minindiheMWR(heightMerge)...
     :nanmin(maxindiheMWR(heightMerge))));

end % ends the homogeneization of heights between MWR and WDL

%% for  uncertainty:
% for velocities:
velo =mean([(abs(nanmean(nanmean((v_fitfit(:,2:end)))))), (abs(nanmean(nanmean((u_fitfit(:,2:end))))))]);% mean([nanmean(nanmean(u)),nanmean(nanmean(v))]);
 % now limiting in time and height:
 velocity_error = ncread(fileWDL, 'delta_speed'); %Dimensions: time,height
 hora_ini=10; hora_fin=16;  velocity_uncert=NaN.*ones(length(decimaltimeWDL),height_wdl);
for tiu=1:length(decimaltimeWDL)
    if decimaltimeWDL(tiu)>hora_ini && decimaltimeWDL(tiu) < hora_fin
        velocity_uncert(tiu,:) = velocity_error(tiu,:);
    end
end
heightmaxABL = fractionABL*nanmax(CBLHTM);
for heu=1:height_wdl
    if heightWDL(heu)>heightmaxABL
        velocity_uncert(:,heu) = NaN;
    end
    if nanmean(velocity_uncert(:,heu))>1.1
        velocity_uncert(:,heu) = NaN;
    end
end

%% uncertainties:
%mindist=500; % m this is the minimum horiz dist to estimate advection
%minhei= round(mindist/2/tand(60)); % tangent of 60 cause that's the cone and 
dist_maxhei = 2*maxheight_upperabl*tand(60);
dist_A_to_B = nanmean([mindist, dist_maxhei])./1000;

dHumdx_fitfit=dHumdx_fitfit'; dHumdy_fitfit= dHumdy_fitfit';

indihei_abl = find(abs(heightMWR_ta-maxheightABL)<200); indihei_abl= indihei_abl(1);
gradient_hum_zonal =nanmean(abs(dHumdx_fitfit)); gradient_hum_meridional =nanmean(abs(dHumdy_fitfit));
gradient_hum_mean =(gradient_hum_zonal+gradient_hum_meridional)/2;

vel = nanmean(abs(u_fitfit'))+nanmean(abs(v_fitfit'));

wspd= [vel, NaN,NaN,NaN,NaN];  %in m/s         ; Mean wind speed from A to B [m/s]
    sigma_wspd= 0.8; % in m/s     ; Uncertainty in wind speed [m/s]
    % Adjust the wind speed to have the units needed
    wspd_adj= wspd;% here no longer adjust cause velocities are in km/hr already * (1/1000.) * (3600/1.); %              ; Convert [m/s] to [km/hr] 
    sigma_wspd_adj = sigma_wspd * (1/1000.) * (3600/1.);  %        ; Convert [m/s] to [km/hr] 

var_gradient_hum = 0.13/dist_A_to_B; % 0.13 g/kg see excel file
var_gradient_temp = 0.4/dist_A_to_B; % 0.4 K see excel file

sigma_gradient_hum = (var_gradient_hum);% a bit different our calculation here but very similar 
sigma_gradient_hum = (var_gradient_temp); % this is uncert delta_T/delta_x uncert (K/km) in my table in excel

    var_advection_hum   = (sigma_gradient_hum)^2 * (wspd_adj(1:length(gradient_hum_mean))).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_hum_mean).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
    var_advection_hum_zonal   = (sigma_gradient_hum)^2 * (wspd_adj(1:length(gradient_hum_mean))).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_hum_zonal).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
    var_advection_hum_meridional   = (sigma_gradient_hum)^2 * (wspd_adj(1:length(gradient_hum_mean))).^2 +...
                      (sigma_wspd_adj)^2 * (gradient_hum_meridional).^2         ;% [X/km]^2 * [km/hr]^2 = [X/hr]^2
       
    
    sigma_advection_hum_zonal = sqrt(var_advection_hum_zonal);
    sigma_advection_hum_meridional = sqrt(var_advection_hum_meridional);
    sigma_advection_hum = sqrt(sigma_advection_hum_zonal.^2 +sigma_advection_hum_meridional.^2);

%  %%
% figure; pcolor(timefit',heightfitfit,dTdx_fitfit'); colorbar; caxis([-.001, .001]); title('dT/dx fit'); ylim([0, 2000])
% figure; pcolor(timefit,heightfitfit,dTdy_fitfit'); colorbar; caxis([-.001, .001]); title('dT/dy fit fit'); ylim([0, 2000])
% figure; pcolor(timefit,heightfitfit,u_fitfit'); title('vel zonal fit fit'); colorbar; ylim([0, 2000]); caxis([-15, 15])
% figure; pcolor(timefit,heightfitfit,v_fitfit'); title('vel meridional fit fit'); colorbar; ylim([0, 2000]); caxis([-15, 15])

%% averaging winds to make wind vanes
 heightfitfit; time_fitfit=timezonalfit; u_fitfit; v_fitfit; % variables I need
% now average in the heights I need:
for ti=1:length(timezonalfit)
for hi=1:length(heightfitfit)
    if  heightfitfit(hi)>minH_surf && heightfitfit(hi)<maxH_surf
        u_surf(ti,hi)=u_fitfit(ti,hi); else; u_surf(ti,hi)=NaN;
    end
    if  heightfitfit(hi)>minH_surf && heightfitfit(hi)<maxH_surf
        v_surf(ti,hi)=v_fitfit(ti,hi); else; v_surf(ti,hi)=NaN;
    end

    if heightfitfit(hi)>minH_adv && heightfitfit(hi)<maxH_adv
        u_adv(ti,hi)=u_fitfit(ti,hi); else; u_adv(ti,hi)=NaN;
    end
    if heightfitfit(hi)>minH_adv && heightfitfit(hi)<maxH_adv
        v_adv(ti,hi)=v_fitfit(ti,hi); else; v_adv(ti,hi)=NaN;
    end
end
u_meansurf(ti)=nanmean(u_surf(ti,:)); v_meansurf(ti)=nanmean(v_surf(ti,:));
u_meanadv(ti)=nanmean(u_adv(ti,:)); v_meanadv(ti)=nanmean(v_adv(ti,:));
end

%figure; quiver(u_meanadv(1:2:end),v_meanadv(1:2:end)); grid on

%% estimating advection

%mean_vel_uncert = nanmean(nanmean(velocity_uncert));

x_advection = -dHumdx_fitfit(2:end,:).*u_fitfit(:,2:end)';
y_advection = -dHumdy_fitfit(2:end,:).*v_fitfit(:,2:end)';

% x_adv_uncert = dHumdx_fitfit_uncert(:,2:end)'.*v_fitfit(:,2:end)';
% y_adv_uncert = dHumdy_fitfit_uncert(:,2:end)'.*u_fitfit(:,2:end)';

[si, sj] = size(x_advection);

for i=1:si; for j=1:sj
        if isnan(x_advection(i,j))==1; x_adv_uncert(i,j)=NaN; end
        if isnan(y_advection(i,j))==1; y_adv_uncert(i,j)=NaN; end
end; end

x_advection_smooth = NaN*ones(si,sj);
y_advection_smooth = NaN*ones(si,sj);
mean_value_x = x_advection;%smooth(nanmean(x_advection));
mean_value_y = y_advection;%smooth(nanmean(y_advection));

%% changing units from kg/kg/s to g/kg/hr:

x_advection= 3600*1000.*x_advection;
y_advection = 3600*1000.*y_advection;

%%
humidityadvectioncolumn_x = smooth(nanmean(x_advection));
humidityadvectioncolumn_y = smooth(nanmean(y_advection));


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

% saveas(figure(3),[pathfigs,'velocity_directions_...' ...
%      num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 3:
%saving netcdf for wind
nc_wind = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_wind.nc'];

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

for tw=2:sztw-1; for hw=1:round(szhw/4)
        uvel(tw,hw)= uzonalvel(tw,hw); vvel(tw,hw)=vmeridionalvel(tw,hw);
        if  (heightWDL(hw) < maxheight_surf) % && (heightWDL(hw) > minheight_surf)
            uzonalvel_surf(tw,hw)=uzonalvel(tw,hw); vmeridionalvel_surf(tw,hw)=vmeridionalvel(tw,hw);
        end
        if  (heightWDL(hw) < maxheight_upperabl)  && (heightWDL(hw) > minheight_upperabl)
            uzonalvel_upperabl(tw,hw)=uzonalvel(tw,hw); vmeridionalvel_upperabl(tw,hw)=vmeridionalvel(tw,hw);
        end
end; end

%% %% aeraging winds to make wind vanes
 heightfitfit; time_fitfit=timezonalfit; u_fitfit; v_fitfit; % variables I need
% now average in the heights I need:
for ti=1:length(timezonalfit)
for hi=1:length(heightfitfit)
    if  heightfitfit(hi)>minH_surf && heightfitfit(hi)<maxH_surf
        u_surf(ti,hi)=u_fitfit(ti,hi); else; u_surf(ti,hi)=NaN;
    end
    if  heightfitfit(hi)>minH_surf && heightfitfit(hi)<maxH_surf
        v_surf(ti,hi)=v_fitfit(ti,hi); else; v_surf(ti,hi)=NaN;
    end

    if heightfitfit(hi)>minH_adv && heightfitfit(hi)<maxH_adv
        u_adv(ti,hi)=u_fitfit(ti,hi); else; u_adv(ti,hi)=NaN;
    end
    if heightfitfit(hi)>minH_adv && heightfitfit(hi)<maxH_adv
        v_adv(ti,hi)=v_fitfit(ti,hi); else; v_adv(ti,hi)=NaN;
    end
end
u_meansurf(ti)=nanmean(u_surf(ti,:)); v_meansurf(ti)=nanmean(v_surf(ti,:));
u_meanadv(ti)=nanmean(u_adv(ti,:)); v_meanadv(ti)=nanmean(v_adv(ti,:));
end

%figure; quiver(u_meanadv(1:2:end),v_meanadv(1:2:end)); grid on

%% estimating advection

%mean_vel_uncert = nanmean(nanmean(velocity_uncert));

x_advection = -dHumdx_fitfit(2:end,:).*u_fitfit(:,2:end)';
y_advection = -dHumdy_fitfit(2:end,:).*v_fitfit(:,2:end)';

% x_adv_uncert = dHumdx_fitfit_uncert(:,2:end)'.*v_fitfit(:,2:end)';
% y_adv_uncert = dHumdy_fitfit_uncert(:,2:end)'.*u_fitfit(:,2:end)';

[si, sj] = size(x_advection);

for i=1:si; for j=1:sj
        if isnan(x_advection(i,j))==1; x_adv_uncert(i,j)=NaN; end
        if isnan(y_advection(i,j))==1; y_adv_uncert(i,j)=NaN; end
end; end

x_advection_smooth = NaN*ones(si,sj);
y_advection_smooth = NaN*ones(si,sj);
mean_value_x = x_advection;%smooth(nanmean(x_advection));
mean_value_y = y_advection;%smooth(nanmean(y_advection));

%% changing units from kg/kg/s to g/kg/hr:
x_advection= 3600*1000.*x_advection;
y_advection = 3600*1000.*y_advection;

%%
humidityadvectioncolumn_x = smooth(nanmean(x_advection));
humidityadvectioncolumn_y = smooth(nanmean(y_advection));

%% for time series in ifferent directions:

[hh, tt] = size(humEast);
heightMWR_ta; timezonal;

% humidities are specific q in kg/kg, we convert to g/kg:
humEast=1000.*humEast; humWest=1000.*humWest; humSouth=1000.*humSouth; humNorth=1000.*humNorth; humZenith=1000.*humZenith;

% cycle for the heights in which advection is calculated and averaged:
for t=1:tt
    for h=1:hh
        if (heightMWR_ta(h)> minH_adv)  && (heightMWR_ta(h)<maxH_adv)
            humEast_timeseries_adv(h,t)=humEast(h,t);
            humWest_timeseries_adv(h,t)=humWest(h,t);
            humNorth_timeseries_adv(h,t)=humNorth(h,t);
            humSouth_timeseries_adv(h,t)=humSouth(h,t);
        else
            humEast_timeseries_adv(h,t)= NaN;
            humWest_timeseries_adv(h,t)= NaN;
            humNorth_timeseries_adv(h,t)= NaN;
            humSouth_timeseries_adv(h,t)= NaN;
        end
    end
end

% cycle for heights closer to the surface than advection estimates:
for t=1:tt
    for h=1:hh
        if (heightMWR_ta(h)> minH_surf)  && (heightMWR_ta(h)<maxH_surf)
            humEast_timeseries_surf(h,t)=humEast(h,t);
            humWest_timeseries_surf(h,t)=humWest(h,t);
            humNorth_timeseries_surf(h,t)=humNorth(h,t);
            humSouth_timeseries_surf(h,t)=humSouth(h,t);
        else
            humEast_timeseries_surf(h,t)= NaN;
            humWest_timeseries_surf(h,t)= NaN;
            humNorth_timeseries_surf(h,t)= NaN;
            humSouth_timeseries_surf(h,t)= NaN;
        end
    end
end

% tempEast_timeseries=nanmean(tempEast_timeseries); tempWest_timeseries=nanmean(tempWest_timeseries);
% tempNorth_timeseries=nanmean(tempNorth_timeseries); tempSouth_timeseries=nanmean(tempSouth_timeseries);

humEast_timeseries_adv=smooth(nanmean(humEast_timeseries_adv)); humWest_timeseries_adv=smooth(nanmean(humWest_timeseries_adv));
humNorth_timeseries_adv=smooth(nanmean(humNorth_timeseries_adv)); humSouth_timeseries_adv=smooth(nanmean(humSouth_timeseries_adv));

humEast_timeseries_surf=smooth(nanmean(humEast_timeseries_surf)); humWest_timeseries_surf=smooth(nanmean(humWest_timeseries_surf));
humNorth_timeseries_surf=smooth(nanmean(humNorth_timeseries_surf)); humSouth_timeseries_surf=smooth(nanmean(humSouth_timeseries_surf));

%% now before plotting I am putting here what's needed for wind vectors:

windmagnitude=sqrt(u_meanadv.^2+v_meanadv.^2);
arbitraty = zeros(size(windmagnitude));
%figure; quiver(time_fitfit,humEast_timeseries_adv(1:size(time_fitfit)),u_meanadv,v_meanadv); grid on
scaling_velHum_advH=humEast_timeseries_adv(1:length(time_fitfit))';
scaling_velHum_surfH=humEast_timeseries_surf(1:length(time_fitfit))';
windmagnitude=sqrt(u_meanadv.^2+v_meanadv.^2)+scaling_velHum_advH;

%%

figure('position',[1,1,1200,800],'Renderer','painters');
subplot(2,2,1)
% title(['Temp. directions (',num2str(minH_adv),'-', num2str(maxH_adv),')',...
%     num2str(year),sprintf('%02d', month),sprintf('%02d',day)])
plot(timezonal,humEast_timeseries_adv,'b', 'LineWidth',1.5)
hold on; plot(timezonal,humWest_timeseries_adv,'r', 'LineWidth',1.5); grid on
hold on; quiver(time_fitfit,scaling_velHum_advH,u_meanadv,v_meanadv, scale, 'Color', Gray,'LineWidth',1.5);
title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')             zonal humidity             '])
xlim([starttime endtime]); ylabel('Humidity [g kg^{-1}]'); xlabel('time UTC [hours]'); ylim([minhum maxhum]);
legend(['Hum East (',num2str(minH_adv),'-', num2str(maxH_adv),' m ) ';...
    'Hum West (',num2str(minH_adv),'-', num2str(maxH_adv),' m ) ';...
    'Wind Vector(', num2str(minH_adv),'-', num2str(maxH_adv),' m)'], 'Location','northeast')

subplot(2,2,2); plot(timezonal,humNorth_timeseries_adv,'b', 'LineWidth',1.5)
hold on; plot(timezonal,humSouth_timeseries_adv,'r', 'LineWidth',1.5); grid on
hold on; quiver(time_fitfit,scaling_velHum_advH,u_meanadv,v_meanadv, scale, 'Color', Gray,'LineWidth',1.5);
xlim([starttime endtime]); ylabel('Humidity [g kg^{-1}]'); xlabel('time UTC [hours]'); ylim([minhum maxhum]);
title(['meridional humidity '])
legend(['Hum North (',num2str(minH_adv),'-', num2str(maxH_adv),' m) ';...
    'Hum South (',num2str(minH_adv),'-', num2str(maxH_adv),' m) ';...
    'Wind Vector(', num2str(minH_adv),'-', num2str(maxH_adv),' m)'], 'Location','northeast')

subplot(2,2,3)
title(['Hum. directions (',num2str(minH_surf),'-', num2str(maxH_surf),')',...
    num2str(year),sprintf('%02d', month),sprintf('%02d',day)])
plot(timezonal,humEast_timeseries_surf,'b', 'LineWidth',1.5)
hold on; plot(timezonal,humWest_timeseries_surf,'r', 'LineWidth',1.5); grid on
hold on; quiver(time_fitfit,scaling_velHum_surfH,u_meansurf,v_meansurf, scale, 'Color', Gray,'LineWidth',1.5);
xlim([starttime endtime]); ylabel('Humidity [g kg^{-1}]'); xlabel('time UTC [hours]'); ylim([minhum maxhum]);
legend(['Hum East (',num2str(minH_surf),'-', num2str(maxH_surf),' m ) ';...
    'Hum West (',num2str(minH_surf),'-', num2str(maxH_surf),' m ) ';...
    'Wind Vector(', num2str(minH_surf),'-', num2str(maxH_surf),' m)'], 'Location','northeast')

subplot(2,2,4); plot(timezonal,humNorth_timeseries_surf,'b', 'LineWidth',1.5)
hold on; plot(timezonal,humSouth_timeseries_surf,'r', 'LineWidth',1.5); grid on
hold on; quiver(time_fitfit,scaling_velHum_surfH,u_meansurf,v_meansurf, scale, 'Color', Gray,'LineWidth',1.5);
xlim([starttime endtime]); ylabel('Humidity [g kg^{-1}]'); xlabel('time UTC [hours]'); ylim([minhum maxhum]);
%title(['meridional T (',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')'])
legend(['Hum North (',num2str(minH_surf),'-', num2str(maxH_surf),' m) ';...
    'Hum South (',num2str(minH_surf),'-', num2str(maxH_surf),' m) ';...
    'Wind Vector(', num2str(minH_surf),'-', num2str(maxH_surf),' m)'], 'Location','northeast')


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

%% figures:

%figure; pcolor(timegrid,heightfitfit,Tdif_zonal); colorbar; caxis([-5e-4 5e-4]); title('(T_E -T_W)/\Deltax')
%figure; pcolor(timegrid,heightfitfit,Tdif_meridional); colorbar; caxis([-5e-4 5e-4]); title('(T_N-T_S)/\Deltay')

min_colorDIR=0; max_colorDIR=9; step_colorAdv =0.01;

% fig temperature in each direction:
min_colorT=290; max_colorT=310; step_colorT=.5; extraabl=500;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));

figure('position',[1,1,1400,900],'Renderer','painters');
subplot(2,2,1)
pcolor(timezonal,heightMWR_ta,humEast); %colorbar;
title('q East')
aaAdv = (nclCM('CBR_drywet',(size(min_colorDIR:step_colorAdv:max_colorDIR,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
ylabel('height [m]'); shading flat; xlim([starttime, endtime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorDIR max_colorDIR]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1} ]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);


subplot(2,2,2)
pcolor(timezonal,heightMWR_ta,humWest);title('q West')
aaAdv = (nclCM('CBR_drywet',(size(min_colorDIR:step_colorAdv:max_colorDIR,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;  ylim([minheight_surf-10, maxheight_upperabl+100]);  xlim([starttime, endtime])
caxis([min_colorDIR max_colorDIR]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar; 
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1} ]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(2,2,3)
pcolor(timezonal,heightMWR_ta,humNorth); title('q North')
aaAdv = (nclCM('CBR_drywet',(size(min_colorDIR:step_colorAdv:max_colorDIR,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat; ylim([minheight_surf-10, maxheight_upperabl+100]); xlim([starttime, endtime])
caxis([min_colorDIR max_colorDIR]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(2,2,4)
pcolor(timezonal,heightMWR_ta,humSouth); title('q South')
aaAdv = (nclCM('CBR_drywet',(size(min_colorDIR:step_colorAdv:max_colorDIR,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat; ylim([minheight_surf-10, maxheight_upperabl+100]); xlim([starttime, endtime])
caxis([min_colorDIR max_colorDIR]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

% saveas(figure(4),[pathfigs,'qhum_directions_heighttime_', ...
%       num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 1:
%saving netcdf for theta in directions

nc_hum_directions = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_hum_directions.nc'];

nccreate(nc_hum_directions,'humEast','Dimensions',{'time',length(timezonal),'height',length(heightMWR_ta)});
nccreate(nc_hum_directions,'humWest','Dimensions',{'time',length(timezonal),'height',length(heightMWR_ta)});
nccreate(nc_hum_directions,'humNorth','Dimensions',{'time',length(timezonal),'height',length(heightMWR_ta)});
nccreate(nc_hum_directions,'humSouth','Dimensions',{'time',length(timezonal),'height',length(heightMWR_ta)});
nccreate(nc_hum_directions,'humZenith','Dimensions',{'time',length(timezonal),'height',length(heightMWR_ta)});
nccreate(nc_hum_directions,'timemwr','Dimensions',{'time',length(timezonal)});
nccreate(nc_hum_directions,'heightMWR_ta','Dimensions',{'height',length(heightMWR_ta)});

ncwrite(nc_hum_directions,'humEast',humEast');
ncwrite(nc_hum_directions,'humWest',humWest');
ncwrite(nc_hum_directions,'humNorth',humNorth');
ncwrite(nc_hum_directions,'humSouth',humSouth');
ncwrite(nc_hum_directions,'humZenith',humZenith');
ncwrite(nc_hum_directions,'timemwr',timezonal);
ncwrite(nc_hum_directions,'heightMWR_ta',heightMWR_ta);
%n = ncread(nc_theta_directions, '_thetaEast')

%% now zonal and meridional humidity differences
distanciaenaltura;
humzonaldif =1000.*(humEast-humWest)./distanciaenaltura'; % la multiplicacion por mil para pasar a km
hummeridionaldif =1000.*(humNorth-humSouth)./distanciaenaltura'; % la multiplicacion por mil para pasar a km

%% figures
%
min_colorTdif=-0.5; max_colorTdif=-min_colorTdif; step_colorTdif=0.0005;
aaTempdif = (nclCM('cmp_b2r',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));
%humzonaldif = 1000.*dHumdx_fitfit; hummeridionaldif = 1000.*dHumdy_fitfit;
%dTempdxzonal=1000.*dTempdxzonal; dTempdymeridional=1000.*dTempdymeridional; % converting from m to km

figure('position',[1,1,800,1200],'Renderer','painters');
subplot(2,1,1)
pcolor(timezonal',heightMWR_hua,humzonaldif); 
ylim([minheight_surf-10 maxheight_upperabl]); xlim([starttime endtime]);  grid on;
aaTempdif = (nclCM('CBR_drywet',(size(min_color:step_color:max_color,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('(q_E-q_W)(\Deltax)^{-1}'); %caxis([min_colorqdif max_colorqdif])
xlabel('time UTC [hours]'); colorbar;
hcb_tempdif=colorbar;
colorTitleHandle_humdif = get(hcb_tempdif,'Title');
titleString_humdif = '[g kg^{-1} km^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_humdif);

subplot(2,1,2)
pcolor(timezonal',heightMWR_hua,hummeridionaldif); 
ylim([minheight_surf-10 maxheight_upperabl]); xlim([starttime endtime]);  grid on;
aaTempdif = (nclCM('CBR_drywet',(size(min_color:step_color:max_color,2)-1)));
colormap(aaTempdif); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;
title('(q_N-q_S)(\Deltay)^{-1}'); 
xlabel('time UTC [hours]'); %caxis([min_colorTdif max_colorTdif]); colorbar
hcb_tempdif=colorbar;
colorTitleHandle_humdif = get(hcb_tempdif,'Title');
titleString_humdif = '[g kg^{-1} km^{-1}]';
set(colorTitleHandle_humdif ,'String',titleString_humdif);


%% saving variables 2:
%saving netcdf for theta in directions
nc_humidity_zonaldifmeriddif = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_humidity_dif_zonal_meridional.nc'];

nccreate(nc_humidity_zonaldifmeriddif,'_humidity_zonaldif','Dimensions',{'time',length(timezonal),'height',length(heightMWR_hua)});
nccreate(nc_humidity_zonaldifmeriddif,'_humidity_meridionaldif','Dimensions',{'time',length(timezonal),'height',length(heightMWR_hua)});
nccreate(nc_humidity_zonaldifmeriddif,'_timegrid','Dimensions',{'time',length(timezonal)});
nccreate(nc_humidity_zonaldifmeriddif,'_heightMWR_hua','Dimensions',{'height',length(heightMWR_hua)});

ncwrite(nc_humidity_zonaldifmeriddif,'_humidity_zonaldif',humzonaldif');
ncwrite(nc_humidity_zonaldifmeriddif,'_humidity_meridionaldif',hummeridionaldif');
ncwrite(nc_humidity_zonaldifmeriddif,'_timegrid',timezonal);
ncwrite(nc_humidity_zonaldifmeriddif,'_heightMWR_hua',heightMWR_hua);
%n = ncread(nc_theta_zonaldifmeriddif, '_theta_zonaldif');
%%

%%
min_colorAdv= -8; max_colorAdv=-min_colorAdv;
step_colorAdv =0.001;
[szadv_height, szadv_time]=size(x_advection);

figure('position',[1,1,1500,1000],'Renderer','painters');
subplot(3,1,1); 
pcolor(timefit',heightfitfit(1:szadv_height),x_advection); title('u\cdot(\Deltaq/\Deltax)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
ylabel('height [m]'); shading flat; xlim([starttime, endtime]);  ylim([minheight_surf-10, maxheight_upperabl+100]); 
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);


subplot(3,1,2); 
pcolor(timefit',heightfitfit(1:szadv_height),y_advection); title('v\cdot(\Deltaq/\Deltay)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat;  ylim([minheight_surf-10, maxheight_upperabl+100]);  xlim([starttime, endtime])
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar; 
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]';
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);

subplot(3,1,3);
pcolor(timefit',heightfitfit(1:szadv_height),x_advection+y_advection); title('u\cdot(\Deltaq/\Deltax)+v\cdot(\Deltaq/\Deltay)')
aaAdv = (nclCM('CBR_drywet',(size(min_colorAdv:step_colorAdv:max_colorAdv,2)-1)));
colormap(aaAdv); %title(['u ({\Delta\theta}/{\Deltax})  ', num2str(year),'.',...
    %sprintf('%02d',month),'.',sprintf('%02d',day)]); 
    ylabel('height [m]');   shading flat; ylim([minheight_surf-10, maxheight_upperabl+100]); xlim([starttime, endtime])
caxis([min_colorAdv max_colorAdv]); xlabel('time UTC [hours]'); 
hcb_tempdif=colorbar;
colorTitleHandle_tempdif = get(hcb_tempdif,'Title');
titleString_tempdif = '[g kg^{-1} hr^{-1}]'; 
set(colorTitleHandle_tempdif ,'String',titleString_tempdif);


%% saving variables 4:
%saving netcdf for advection
nc_humidity_advection = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_humidity_advection.nc'];

nccreate(nc_humidity_advection,'_Advection_humidity_zonal','Dimensions',{'time',length(timefit),'height',length(heightfitfit)});
nccreate(nc_humidity_advection,'_Advection_humidity_meridional','Dimensions',{'time',length(timefit),'height',length(heightfitfit)});
nccreate(nc_humidity_advection,'_timegrid','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection,'_heightfitfit','Dimensions',{'height',length(heightfitfit)});

ncwrite(nc_humidity_advection,'_Advection_humidity_zonal',x_advection');
ncwrite(nc_humidity_advection,'_Advection_humidity_meridional',y_advection');
ncwrite(nc_humidity_advection,'_timegrid',timefit);
ncwrite(nc_humidity_advection,'_heightfitfit',heightfitfit');

%n = ncread(nc_theta_advection, '_Advection_theta_zonal');
%%

%% figures:

%figure; pcolor(timegrid,heightfitfit,Tdif_zonal); colorbar; caxis([-5e-4 5e-4]); title('(T_E -T_W)/\Deltax')
%figure; pcolor(timegrid,heightfitfit,Tdif_meridional); colorbar; caxis([-5e-4 5e-4]); title('(T_N-T_S)/\Deltay')

% fig temperature in each direction:
min_colorT=290; max_colorT=310; step_colorT=.5; extraabl=500;
aaTemp = (nclCM('cmp_b2r',(size(min_colorT:step_colorT:max_colorT,2)-1)));
%%

min_colorTdif=-0.5; max_colorTdif=-min_colorTdif; step_colorTdif=0.0005;
aaTempdif = (nclCM('cmp_b2r',(size(min_colorTdif:step_colorTdif:max_colorTdif,2)-1)));

%n = ncread(nc_theta_advection, '_Advection_theta_zonal');
%%
timegrid=timezonal;
% now advection in lower and upper layers:
for i=1:length(timefit); for j=1:length(heightfitfit)
        if heightfitfit(j)>minheight_surf && heightfitfit(j)<maxheight_surf
            advection_zonal_lowerabl(j,i)=x_advection(j,i);
            advection_meridional_lowerabl(j,i)=y_advection(j,i);
        else; advection_zonal_lowerabl(j,i)=NaN; advection_meridional_lowerabl(j,i)=NaN;
        end
        if heightfitfit(j)>minheight_upperabl && heightfitfit(j)<maxheight_upperabl
            advection_zonal_upperabl(j,i)=x_advection(j,i);
            advection_meridional_upperabl(j,i)=y_advection(j,i);
        else; advection_zonal_upperabl(j,i)=NaN; advection_meridional_upperabl(j,i)=NaN;
        end
        if heightfitfit(j)>minheight_surf && heightfitfit(j)<maxheight_upperabl
            advection_zonal_allabl(j,i)=x_advection(j,i);
            advection_meridional_allabl(j,i)=y_advection(j,i);
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

% sigma_advection_temp_adj=sigma_advection_temp(1:length(timegrid)); 
% sigma_advection_temp_adj_zonal=sigma_advection_temp_zonal(1:length(timegrid)); sigma_advection_temp_adj_meridional=sigma_advection_temp_meridional(1:length(timegrid)); 
%sigma_gradient_temp=sigma_gradient_temp; 
minlim=-17; maxlim = -minlim;
bluebonito = [0.1 0.4 0.8]; redbonito = [0.8 0.3 0.3]; purplebonito = [0.7 0.3 0.7];

sigma_advection_hum_adj=sigma_advection_hum(1:szadv_time); 
sigma_advection_hum_adj_zonal=sigma_advection_hum_zonal(1:szadv_time); sigma_advection_hum_adj_meridional=sigma_advection_hum_meridional(1:szadv_time); 
sigma_gradient_hum=sigma_gradient_hum; minlim=-7; maxlim = -minlim;
bluebonito = [0.1 0.4 0.8]; redbonito = [0.8 0.3 0.3]; purplebonito = [0.7 0.3 0.7];

% advection_zonal_lowerabl = nanmean(advection_zonal_lowerabl); advection_meridional_lowerabl = nanmean(advection_meridional_lowerabl);
% advection_zonal_upperabl = nanmean(advection_zonal_upperabl); advection_meridional_upperabl = nanmean(advection_meridional_upperabl);
advection_zonal_allabl = nanmean(x_advection); advection_meridional_allabl = nanmean(y_advection);
% advection_total_lowerabl = (advection_zonal_lowerabl+advection_meridional_lowerabl);
% advection_total_upperabl = (advection_zonal_upperabl+advection_meridional_upperabl);
advection_total_allabl = (advection_zonal_allabl+advection_meridional_allabl);


figure('position',[1,1,1400,500],'Renderer','painters'); 

subplot(1,2,1)
plot(timefit,advection_zonal_allabl, 'Color', bluebonito,'LineWidth',2); hold on; 
plot(timefit, advection_meridional_allabl,  'color', purplebonito, 'LineWidth',2); hold on
%plot(timegrid,advection_total_allabl,'r', 'LineWidth',1); grid on
xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('q advection [g kg ^{-1} hr^{-1}]'); ylim([minlim, maxlim])
% hold on
 % fill([timefit fliplr(timefit)], [advection_total_allabl-sigma_advection_hum_adj fliplr(advection_total_allabl+sigma_advection_hum_adj)], ...
 %      [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on; grid on;
fill([timefit fliplr(timefit)], smooth([advection_zonal_allabl-sigma_advection_hum_adj_zonal...
    fliplr(advection_zonal_allabl+sigma_advection_hum_adj_zonal)]), ...
     bluebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
hold on; grid on
fill([timefit fliplr(timefit)], smooth([advection_meridional_allabl-sigma_advection_hum_adj_meridional...
    fliplr(advection_meridional_allabl+sigma_advection_hum_adj_meridional)]), ...
     purplebonito, 'FaceAlpha', 0.1,'EdgeColor','none');
legend([ 'u\cdot(\Deltaq/\Deltax)'; 'v\cdot(\Deltaq/\Deltay)'])
    %'u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title(['                                                        a)         q advection in ABL (',num2str(minheight_surf),'-',...
    num2str(maxheight_upperabl),' m) ']);


subplot(1,2,2)
plot(timefit,advection_total_allabl,'color', redbonito, 'LineWidth',2); grid on
% title(['(',num2str(year),'.',sprintf('%02d', month),'.',sprintf('%02d',day),')      ' ...
%     ,'\theta advection in ABL (',num2str(minheight_surf),'-', num2str(maxheight_upperabl),' m) ']);
xlabel('time [hr]'); xlim([starttime, endtime]); ylabel('q advection [g kg^{-1} hr^{-1}]'); ylim([minlim, maxlim])
%  hold on
% fill([timefit fliplr(timefit)], [advection_total_allabl-sigma_advection_hum_adj fliplr(advection_total_allabl+sigma_advection_hum_adj)], ...
%       [0.7 0.1 0.2], 'FaceAlpha', 0.1);
hold on
fill([timefit fliplr(timefit)], smooth([advection_total_allabl-sigma_advection_hum_adj...
    fliplr(advection_total_allabl+sigma_advection_hum_adj)]), ...
     redbonito, 'FaceAlpha', 0.1,'EdgeColor','none');
% legend([ '       u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)        '; ...
%     'uncertainty of u\cdot(\Delta\theta/\Deltax)+v\cdot(\Delta\theta/\Deltay)']); 
title('b)');
legend([ 'u\cdot(\Deltaq/\Deltax)+v\cdot(\Deltaq/\Deltay)'])

% saveas(figure(7),[pathfigs,'thermalAdvection_allABL_...' ...
%      num2str(year),sprintf('%02d', month),sprintf('%02d',day),'.png'])

%% saving variables 5:
%saving netcdf for theta in directions
nc_humidity_advection_uncert = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_humidity_advection_uncert.nc'];

nccreate(nc_humidity_advection_uncert,'_Advection_humidity_zonal_allABL','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_zonal','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection_uncert,'_Advection_humidity_meridional_allABL','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_meridional','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_total','Dimensions',{'time',length(timefit)});
nccreate(nc_humidity_advection_uncert,'_timefit','Dimensions',{'time',length(timefit)});

ncwrite(nc_humidity_advection_uncert,'_Advection_humidity_zonal_allABL',advection_zonal_allabl');
ncwrite(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_zonal',sigma_advection_hum_adj');
ncwrite(nc_humidity_advection_uncert,'_Advection_humidity_meridional_allABL',advection_meridional_allabl');
ncwrite(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_meridional',sigma_advection_hum_adj_meridional');
ncwrite(nc_humidity_advection_uncert,'_sigmaAdvection_humidity_total',sigma_advection_hum_adj');
ncwrite(nc_humidity_advection_uncert,'_timefit',timefit);

%n = ncread(nc_theta_advection_uncert, '_Advection_theta_zonal_allABL');

%%
figure; plot(datetime(datetimefileMWR),prw)

timedecimalMWR = hour(datetime(datetimefileMWR))+minute(datetime(datetimefileMWR))./60;

% saving variables 6 IWV:
%saving netcdf for IWV
nc_IWV = [pathoutnet, '/', num2str(year),...
    sprintf('%02d', month),sprintf('%02d', day),'_IWV.nc'];

nccreate(nc_IWV,'_IWV','Dimensions',{'time',length(datetimefileMWR)});
nccreate(nc_IWV,'_timedecimal_IWV','Dimensions',{'time',length(datetimefileMWR)});

ncwrite(nc_IWV,'_IWV',prw);
ncwrite(nc_IWV,'_timedecimal_IWV',timedecimalMWR);

%n = ncread(nc_theta_advection_uncert, '_Advection_theta_zonal_allABL');
%%
