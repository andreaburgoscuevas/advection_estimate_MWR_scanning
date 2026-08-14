%% code for retrieving humidity and temperature from brightness temperature with the retrieval equation 
% that depends on height and on the channel. There are 7 relevant channels
% for humidity (and the other 7 relevant for temperature) but here the
% matrices with the coefficients that I read have the size (height,
% channel) and there are 14 rows for the channels but they only correspond
% to 7 channels and they are the coefficients for multiplying by Tb's
% linearly (7 of them) and multiplying squared Tb's (the other 7 of them).
% There is also one coeficient that only has the size of the hegrid onights (43)
% because it is not multiplied by any Tb
% Tb does not depend on height, the channels do get different height
% information

close all; clear all;
year=2022; month=6; day=19; timeABLdeveloped=12; epsilon_hora=0.25;

z_lim=2000; minq=0.003; maxq=0.009;

% for figures:
set(groot, 'DefaultAxesFontSize', 15);
set(groot, 'DefaultTextFontSize', 15);

% perturbation:
meanTb_perturbation=0; sigmaTb_maxnoise =1; number_Tb_perturb =500; randomTb_noise_hum=sigmaTb_maxnoise;

% sigmaTb_ch01 = 0.07; sigmaTb_ch02 = 0.07; sigmaTb_ch03 = 0.06; sigmaTb_ch04 = 0.07;
% sigmaTb_ch05 = 0.08; sigmaTb_ch06 = 0.06; sigmaTb_ch07 = 0.1; %values Cold Load T Boeck
% sigmaTb_ch08 = 0.15; sigmaTb_ch09 = 0.15; sigmaTb_ch10 = 15; sigmaTb_ch11 = 0.15;
% sigmaTb_ch12 = 0.1; sigmaTb_ch13 = 0.08; sigmaTb_ch14 = 0.06; % values Hot Load T Boeck

path_coeffs = '/path/to/data_coeffs/';
path_Tb_day = '/path/to/dataMWR/';
path_covariance_mat = '/path/to/data_covmat/';

pathouTfigs = '/path/to/output/';
pathoutRadiometricUncertainty = '/path/to/output/';

Tb_day_file = (dir(strcat([path_Tb_day, 'sups_joy_mwr00_l1_tb_p00_*.nc'])));
Tb_day = ([path_Tb_day, Tb_day_file.name]);

%reading covariance matrix:
name_covariance = 'ALL_COVARs_MEAN';
covmat = load([path_covariance_mat,name_covariance,'.mat']);
num_channels=7;
noise_matrix_N = normrnd(meanTb_perturbation,sigmaTb_maxnoise,[num_channels,number_Tb_perturb]);
noise_matrix_S = normrnd(meanTb_perturbation,sigmaTb_maxnoise,[num_channels,number_Tb_perturb]);
noise_matrix_E = normrnd(meanTb_perturbation,sigmaTb_maxnoise,[num_channels,number_Tb_perturb]);
noise_matrix_W = normrnd(meanTb_perturbation,sigmaTb_maxnoise,[num_channels,number_Tb_perturb]);
%noise_matrix;
cov_mat_joyhat_coldload=covmat.COVAR_COLD_MEAN_JOY; %this cold load I should take for humidity, so 1-7
cov_mat_joyhat_hotload=covmat.COVAR_HOT_MEAN_JOY; %this hot load I should take for temperature, so 8-14
%humidity channels 1-7. Temperature channels 8-14
cov_mat_hum = sqrtm(cov_mat_joyhat_coldload(1:7,1:7));
cov_mat_temp = sqrtm(cov_mat_joyhat_hotload(8:14,8:14));

%% plotting covariance matrices:
channels_1_7 = [1:1:7]; channels_7_14 = [8:1:14];
figure(88); imagesc(channels_1_7,channels_1_7,cov_mat_joyhat_coldload(1:7,1:7)); title('T_B covariance matrix cold load (for humidity)');
xlabel('channels'); ylabel('channels'); caxis([0 0.015]); 
hcb=colorbar; hcb.Title.String= '[K^2]';
figure(89); imagesc(channels_7_14,channels_7_14,cov_mat_joyhat_hotload(8:14,8:14)); title('T_B covariance matrix hot load (for temperature)');
xlabel('channels'); ylabel('channels'); caxis([0 0.015])
hcb=colorbar; hcb.Title.String= '[K^2]';

%%

% reading coefficients for humidity:
file_coeffs_hum = [path_coeffs,'hze_deb_rt00_30.nc'];
frequencies_hum = ncread(file_coeffs_hum,'freq'); %size 7x1, units: GHz, n_freq_ret
height_hum = ncread(file_coeffs_hum,'height_grid'); % in meters, 43x1
coefficients_retrieval_bc_hum = ncread(file_coeffs_hum, 'coefficient_mvr');
coefficient_offset_a_hum = ncread(file_coeffs_hum, 'offset_mvr');

% reading coefficients for temperature:
file_coeffs_temp = [path_coeffs,'tze_deb_rt00_30.nc'];
frequencies_temp = ncread(file_coeffs_temp,'freq'); %size 7x1, units: GHz, n_freq_ret
height_temp = ncread(file_coeffs_temp,'height_grid'); % in meters, 43x1
coefficients_retrieval_bc_temp = ncread(file_coeffs_temp, 'coefficient_mvr');
coefficient_offset_a_temp = ncread(file_coeffs_temp, 'offset_mvr');


%% now read brightness temperatures:
rawtime_Tb = ncread(Tb_day, 'time'); %seconds since 1970-01-01 00:00:00 UTC
azimuth_Tb = ncread(Tb_day, 'azi');
elevation_Tb = ncread(Tb_day, 'ele');
Tb = ncread(Tb_day, 'tb');% brightness_temperature K, 14x67391, n_freqxtime 
Tb_bias = ncread(Tb_day, 'tb_bias_estimate'); %brightness temperature offset subtracted from measured brightness temperature
Tb_accuracy = ncread(Tb_day, 'tb_absolute_accuracy'); %total calibration uncertainty of brightness temperature, one standard deviation
Tb_covariance = ncread(Tb_day, 'tb_cov'); % 14x14, error covariance matrix of brightness temperature channels

% writing time in a way that makes sense: (copied from RiB code)
secsin1day=60*60*24; base=datenum(1970,1,1); % according to what the cdf file says with ncdisp(file)
datetimeTb = datestr(rawtime_Tb./secsin1day+base); timesinday_Tb = length(datetimeTb);
for cht =1:timesinday_Tb
    datetimeTb(cht) = convertCharsToStrings(datetimeTb(cht,10));
end
decimaltime_Tb = hour(datetimeTb)+ minute(datetimeTb)./60;

%% only at 30 deg elevation:
timesize = length(rawtime_Tb);decimaltime30indice = NaN.*ones(timesize,1); 
%tiempo30indice = NaN.*ones(timesize,1); tiempo30east = NaN.*ones(timesize,1);
%teastcount = 0; twestcount = 0; tnorthcount = 0; tsouthcount = 0;
Tb_30elev=NaN.*ones(size(Tb)); azimuth30elev=NaN.*ones(size(Tb));
Tb_30elevNorth=NaN.*ones(size(Tb)); Tb_30elevSouth=NaN.*ones(size(Tb));
Tb_30elevEast=NaN.*ones(size(Tb)); Tb_30elevWest=NaN.*ones(size(Tb));
tiempo30indice = NaN.*ones(1,length(Tb));

for freq = 1:length(Tb_covariance)
    for tt = 1:timesize-length(nonzeros(abs(elevation_Tb-10)<1))        
         if abs(elevation_Tb(tt)-30) < 1 % aqui si esta bien poner 30 deg, porque en el file son 30 deg
             tiempo30indice(tt) = tt; % encontrando tiempos del scan para los cuales elevation=30
            if (isnan(tiempo30indice(tt))==0)
                time30elev(tt) = decimaltime_Tb(tt);
                Tb_30elev(freq,tt) = Tb(freq,tt);
                azimuth30elev(tt) = azimuth_Tb(tt);
                
                if azimuth30elev(tt)<11 || azimuth30elev(tt) >=350 || azimuth30elev(tt) ==0 %azimuth=0 North 
                    Tb_30elevNorth(freq,tt)=Tb(freq,tt);                    
                end
                if abs(azimuth30elev(tt)-180)<9 || abs(azimuth30elev(tt)-170)<5 || abs(azimuth30elev(tt)-190)<5 %azimuth=180 South 
                    Tb_30elevSouth(freq,tt)=Tb(freq,tt);                    
                end
                if abs(azimuth30elev(tt)-90)<9 || abs(azimuth30elev(tt)-80)<5 || abs(azimuth30elev(tt)-100)<5 %azimuth=90 East 
                    Tb_30elevEast(freq,tt)=Tb(freq,tt);                    
                end
                if abs(azimuth30elev(tt)-270)<9 || abs(azimuth30elev(tt)-280)<5 || abs(azimuth30elev(tt)-260)<5 %azimuth=270 West 
                    Tb_30elevWest(freq,tt)=Tb(freq,tt);                    
                end

            end
         end       
    end
end

% cicle to make Tb at 30deg, NSEW and at 13UTC:
TbNorth13h = NaN.*ones(14,length(time30elev)); TbSouth13h = NaN.*ones(14,length(time30elev));
TbEast13h = NaN.*ones(14,length(time30elev)); TbWest13h = NaN.*ones(14,length(time30elev));

for ti=1:length(tiempo30indice)
    if (abs((decimaltime_Tb(ti)-timeABLdeveloped))<epsilon_hora) && isnan(Tb_30elevNorth(1,ti))==0
        TbNorth13h(:,ti)=Tb_30elevNorth(:,ti);
    end
    if (abs((decimaltime_Tb(ti)-timeABLdeveloped))<epsilon_hora) && isnan(Tb_30elevSouth(1,ti))==0
        TbSouth13h(:,ti)=Tb_30elevSouth(:,ti);
    end
    if (abs((decimaltime_Tb(ti)-timeABLdeveloped))<epsilon_hora) && isnan(Tb_30elevEast(1,ti))==0
        TbEast13h(:,ti)=Tb_30elevEast(:,ti);
    end
    if (abs((decimaltime_Tb(ti)-timeABLdeveloped))<epsilon_hora) && isnan(Tb_30elevWest(1,ti))==0
        TbWest13h(:,ti)=Tb_30elevWest(:,ti);
    end
end

fifiN = find(isnan(TbNorth13h(1,:))==0); TbNorth13h=TbNorth13h(:,fifiN);
fifiS = find(isnan(TbSouth13h(1,:))==0); TbSouth13h=TbSouth13h(:,fifiS);
fifiE = find(isnan(TbEast13h(1,:))==0); TbEast13h=TbEast13h(:,fifiE);
fifiW = find(isnan(TbWest13h(1,:))==0); TbWest13h=TbWest13h(:,fifiW);

szTb1=length(Tb_covariance); szTb2=length(time30elev); count=0;

%% separating Tb covariance matrices in Temperature and humidity ones and adding noise: 

Tb_q_North13h=TbNorth13h(1:7,:); Tb_T_North13h=TbNorth13h(8:14,:);
Tb_q_South13h=TbSouth13h(1:7,:); Tb_T_South13h=TbSouth13h(8:14,:);
Tb_q_East13h=TbEast13h(1:7,:); Tb_T_East13h=TbEast13h(8:14,:);
Tb_q_West13h=TbWest13h(1:7,:); Tb_T_West13h=TbWest13h(8:14,:);

[l,ll] = size(noise_matrix_N);
for i=1:l; for j=1:ll
        if noise_matrix_N(i,j)>sigmaTb_maxnoise; noise_matrix_N(i,j)=sigmaTb_maxnoise; end
        if noise_matrix_N(i,j)<-sigmaTb_maxnoise; noise_matrix_N(i,j)= -sigmaTb_maxnoise; end
        if noise_matrix_S(i,j)>sigmaTb_maxnoise; noise_matrix_S(i,j)=sigmaTb_maxnoise; end
        if noise_matrix_S(i,j)<-sigmaTb_maxnoise; noise_matrix_S(i,j)= -sigmaTb_maxnoise; end
        if noise_matrix_E(i,j)>sigmaTb_maxnoise; noise_matrix_E(i,j)=sigmaTb_maxnoise; end
        if noise_matrix_E(i,j)<-sigmaTb_maxnoise; noise_matrix_E(i,j)= -sigmaTb_maxnoise; end
        if noise_matrix_W(i,j)>sigmaTb_maxnoise; noise_matrix_W(i,j)=sigmaTb_maxnoise; end
        if noise_matrix_W(i,j)<-sigmaTb_maxnoise; noise_matrix_W(i,j)= -sigmaTb_maxnoise; end
end; end

%% now matrix multiplication to get temperature and humidity

%trying =coefficients_retrieval_bc_hum'.*Tb(:,10); 
% but that trying is not correct, because I really have to just consider
% separately the channels from Tb that correspond to temperature and those
% who correspond to humidity. Then I need to choose the 7 coefficients for
% multiplying linearly and those 7 for multiplying squared and do the
% matrices multiplication and the complete equation for retrieving both
% temperature and humidity

linear_coeff_hum_b = coefficients_retrieval_bc_hum(:,1:7); %heights x channel
quadratic_coeff_hum_c = coefficients_retrieval_bc_hum(:,8:14); % height x channel

linear_coeff_temp_b = coefficients_retrieval_bc_temp(:,1:7); %heights x channel
quadratic_coeff_temp_c = coefficients_retrieval_bc_temp(:,8:14); % height x channel

Tb_T_North13h = Tb_T_North13h(:,1); Tb_T_South13h = Tb_T_South13h(:,1);

    for h=1:length(height_temp)
        q_humNorth13h(h) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_North13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_North13h(:,1)).^2;
        Temp_North13h(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_North13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_North13h(:,1)).^2;

        q_humSouth13h(h) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_South13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_South13h(:,1)).^2;
        Temp_South13h(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_South13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_South13h(:,1)).^2;

        q_humEast13h(h) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_East13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_East13h(:,1)).^2;
        Temp_East13h(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_East13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_East13h(:,1)).^2;

        q_humWest13h(h) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_West13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_West13h(:,1)).^2;
        Temp_West13h(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_West13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_West13h(:,1)).^2;
% now retrieving the horizontal differences:
        q_dif_zonal(h) = (coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_East13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_East13h(:,1)).^2) -... 
            coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_West13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_West13h(:,1)).^2;
        q_dif_meridional(h) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_North13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_North13h(:,1)).^2 -...
            coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_South13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_South13h(:,1)).^2;
        T_dif_zonal(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_East13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_East13h(:,1)).^2 -...
            coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*Tb_q_West13h(:,1) +...
            quadratic_coeff_hum_c(h,:)*(Tb_q_West13h(:,1)).^2;
        T_dif_meridional(h) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_North13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_North13h(:,1)).^2 -...
            coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*Tb_T_South13h(:,1) +...
            quadratic_coeff_temp_c(h,:)*(Tb_T_South13h(:,1)).^2;

    end


 % I need to correct that estimation cause multiplication of matrices is
 % not taking place the correct way 

figure; plot(q_humNorth13h,height_hum); grid on
figure; plot(Temp_North13h,height_temp); grid on

%% now perturbing with random radiometric noise
% from Boeck 2024: the radiometric noise for Generation 5 HATPROs is on 
% average 0.15 K within the V-band, according to the manufacturer
% (RPG-Radiometer Physics GmbH, 2015), with slightly 
% higher values in the optically thinner channels 8–10 and 
% slightly lower values for channels 11–14


% first doing the matrix multiplication and diagonal to find the noise to be added
perturbation_hum_noise_N = NaN.*ones(num_channels,number_Tb_perturb); perturbation_temp_noise_N = NaN.*ones(num_channels,number_Tb_perturb);
perturbation_hum_noise_S = NaN.*ones(num_channels,number_Tb_perturb); perturbation_temp_noise_S = NaN.*ones(num_channels,number_Tb_perturb);
perturbation_hum_noise_E = NaN.*ones(num_channels,number_Tb_perturb); perturbation_temp_noise_E = NaN.*ones(num_channels,number_Tb_perturb);
perturbation_hum_noise_W = NaN.*ones(num_channels,number_Tb_perturb); perturbation_temp_noise_W = NaN.*ones(num_channels,number_Tb_perturb);

for noise=1:number_Tb_perturb
    perturbation_hum_noise_N(:,noise) =  (cov_mat_hum*(noise_matrix_N(:,noise)));
    perturbation_temp_noise_N(:,noise) = (cov_mat_temp*(noise_matrix_N(:,noise)));
    perturbation_hum_noise_S(:,noise) =  (cov_mat_hum*(noise_matrix_S(:,noise)));
    perturbation_temp_noise_S(:,noise) = (cov_mat_temp*(noise_matrix_S(:,noise)));
    perturbation_hum_noise_E(:,noise) =  (cov_mat_hum*(noise_matrix_E(:,noise)));
    perturbation_temp_noise_E(:,noise) = (cov_mat_temp*(noise_matrix_E(:,noise)));
    perturbation_hum_noise_W(:,noise) =  (cov_mat_hum*(noise_matrix_W(:,noise)));
    perturbation_temp_noise_W(:,noise) = (cov_mat_temp*(noise_matrix_W(:,noise)));
end

% second: adding the noise to the Tb at each channel:

%q_humZonal13h_profs = NaN.*ones(length(height_temp),number_Tb_perturb); q_humMeridional13h_profs = NaN.*ones(length(height_temp),number_Tb_perturb);
%Temp_Zonal13h_profs = NaN.*ones(length(height_temp),number_Tb_perturb); Temp_Meridional13h_profs = NaN.*ones(length(height_temp),number_Tb_perturb);
for noise=1:number_Tb_perturb
    for h=1:length(height_temp)

for channel=1:num_channels
% randomTb_noise_hum(channel,channel,noise) = cov_mat_hum(channel,channel).*(noise_matrix(channel,noise));
% randomTb_noise_temp(channel,channel,noise) = cov_mat_temp(channel,channel).*(noise_matrix(channel,noise));

Tb_perturbed_North_hum(channel,noise) =  (Tb_q_North13h(channel,1)+perturbation_hum_noise_N(channel,noise));
Tb_perturbed_North_temp(channel,noise) =  (Tb_T_North13h(channel,1)+perturbation_temp_noise_N(channel,noise));
Tb_perturbed_South_hum(channel,noise) =  (Tb_q_South13h(channel,1)+perturbation_hum_noise_S(channel,noise));
Tb_perturbed_South_temp(channel,noise) =  (Tb_T_South13h(channel,1)+perturbation_temp_noise_S(channel,noise));

Tb_perturbed_East_hum(channel,noise) =  (Tb_q_East13h(channel,1)+perturbation_hum_noise_E(channel,noise));
Tb_perturbed_East_temp(channel,noise) =  (Tb_T_East13h(channel,1)+perturbation_temp_noise_E(channel,noise));
Tb_perturbed_West_hum(channel,noise) =  (Tb_q_West13h(channel,1)+perturbation_hum_noise_W(channel,noise));
Tb_perturbed_West_temp(channel,noise) =  (Tb_T_West13h(channel,1)+perturbation_temp_noise_W(channel,noise));

end
        q_humNorth13h_profs(h,noise) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_North_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_North_hum(:,noise).^2;
        Temp_North13h_profs(h,noise) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_North_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_North_temp(:,noise).^2;


        q_humSouth13h_profs(h,noise) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_South_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_South_hum(:,noise).^2;
        Temp_South13h_profs(h,noise) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_South_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_South_temp(:,noise).^2;

        q_humEast13h_profs(h,noise) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_East_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_East_hum(:,noise).^2;
        Temp_East13h_profs(h,noise) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_East_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_East_temp(:,noise).^2;


        q_humWest13h_profs(h,noise) = coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_West_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_West_hum(:,noise).^2;
        Temp_West13h_profs(h,noise) = coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_West_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_West_temp(:,noise).^2;

        % zonal & meridional:
        q_humZonal13h_profs(h,noise) = (coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_East_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_East_hum(:,noise).^2 -...
            (coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_West_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_West_hum(:,noise).^2));
        q_humMeridional13h_profs(h,noise) = (coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_North_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_North_hum(:,noise).^2 - ...
            (coefficient_offset_a_hum(h) + linear_coeff_hum_b(h,:)*...
            Tb_perturbed_South_hum(:,noise) +...
            quadratic_coeff_hum_c(h,:)*Tb_perturbed_South_hum(:,noise).^2));

        Temp_Zonal13h_profs(h,noise) = (coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_East_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_East_temp(:,noise).^2 -...
            (coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_West_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_West_temp(:,noise).^2));
        Temp_Meridional13h_profs(h,noise) = (coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_North_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_North_temp(:,noise).^2 -...
            (coefficient_offset_a_temp(h) + linear_coeff_temp_b(h,:)*...
            Tb_perturbed_South_temp(:,noise) +...
            quadratic_coeff_temp_c(h,:)*Tb_perturbed_South_temp(:,noise).^2));

    end

size(Temp_North13h_profs);

     %% figures hopefully nice:
  figure(50); subplot(1,2,1); hold on;
     plot(Temp_Zonal13h_profs(:,noise),height_temp, 'b'); hold on; ylim([0 z_lim]); grid on;
  hold on; ylim([0 z_lim]); grid on;
    hold on; title(['a)                \DeltaT_{zonal}']);%,num2str(year), '.',...
        %sprintf('%02d',month),'.', sprintf('%02d',day),...
        %' at ', num2str(timeABLdeveloped), '00UTC ']);
        xlabel('T (K)'); ylabel('height (m)')

   hold on; subplot(1,2,2); hold on;
    plot(Temp_Meridional13h_profs(:,noise),height_temp, 'r'); hold on; ylim([0 z_lim]); grid on;
    hold on; title(['     \DeltaT_{meridional}']); xlabel('T (K)');% ylabel('height (m)')

    figure(52); subplot(1,2,1); hold on;
    plot(1000.*q_humZonal13h_profs(:,noise),height_hum, 'b'); grid on; ylim([0 z_lim])
    hold on;  xlabel('absolute humidity (gm^{-3})'); ylabel('height (m)'); ylabel('height (m)')  
  grid on; ylim([0 z_lim])
    hold on;  xlabel('abs. hum. (gm^{-3})'); 
     title(['b)                \Delta hum_{zonal}   '])%,num2str(year), '.', sprintf('%02d',month),'.', sprintf('%02d',day),...
         %' at ', num2str(timeABLdeveloped),'00UTC'])

     hold on; subplot(1,2,2); hold on;
     plot(1000.*q_humMeridional13h_profs(:,noise),height_hum, 'r');  grid on; ylim([0 z_lim])
    hold on;  xlabel('abs. hum. (gm^{-3})'); 
     title(['  \Delta hum_{meridional}'])
%    if noise== number_Tb_perturb; saveas(figure(52),[pathouTfigs,num2str(year),sprintf('%02d',month),sprintf('%02d',day),...
%      'at',num2str(timeABLdeveloped), '00UTC_deltahumZonal_deltahumMeridional_MCretrievals','.png']); end
%     
% 

end

%% estimating the spread between retrievals with random noise to get uncertainty
lowlevabl = 9; highlevabl=25; numstd=2;

tempzonalABL13h = Temp_Zonal13h_profs(lowlevabl:highlevabl,:); [niv,profsMC] = size(tempzonalABL13h);
for i=1:niv; spreadTempzon(i)= numstd.*std(tempzonalABL13h(i,:)); end; spreadTempzon = mean(spreadTempzon);
tempmeridionalABL13h = Temp_Meridional13h_profs(lowlevabl:highlevabl,:);
for i=1:niv; spreadTempmerid(i)= numstd.*std(tempmeridionalABL13h(i,:)); end; spreadTempmerid = mean(spreadTempmerid);
uncert_Temp_std = mean([spreadTempzon,spreadTempmerid])

humzonalABL13h = Temp_Zonal13h_profs(lowlevabl:highlevabl,:); 
for i=1:niv; spreadHumzon(i)= numstd.*std(humzonalABL13h(i,:)); end; spreadHumzon = mean(spreadHumzon);
hummeridionalABL13h = q_humMeridional13h_profs(lowlevabl:highlevabl,:);
for i=1:niv; spreadHummerid(i)= numstd.*std(hummeridionalABL13h(i,:)); end; spreadHummerid = mean(spreadHummerid);
uncert_Hum_std = mean([spreadHumzon,spreadHummerid])

%% save figures:

figure(50); hold on; 
subplot(1,2,2); hold on;
plot((mean(Temp_Meridional13h_profs')+(numstd/2)*uncert_Temp_std),height_temp, 'r','LineWidth',2);
subplot(1,2,2); hold on; plot((mean(Temp_Meridional13h_profs')+(numstd/2)*uncert_Temp_std),height_temp, 'k+','LineWidth',2);
subplot(1,2,2); hold on; plot((mean(Temp_Meridional13h_profs')-(numstd/2)*uncert_Temp_std),height_temp, 'r','LineWidth',2);
subplot(1,2,2); hold on; plot((mean(Temp_Meridional13h_profs')-(numstd/2)*uncert_Temp_std),height_temp, 'k+','LineWidth',2);
subplot(1,2,1); hold on;
subplot(1,2,1); hold on; plot((mean(Temp_Zonal13h_profs')+(numstd/2)*uncert_Temp_std),height_temp, 'b','LineWidth',2);
subplot(1,2,1); hold on; plot((mean(Temp_Zonal13h_profs')+(numstd/2)*uncert_Temp_std),height_temp, 'k+','LineWidth',2);
subplot(1,2,1); hold on; plot((mean(Temp_Zonal13h_profs')-(numstd/2)*uncert_Temp_std),height_temp, 'b','LineWidth',2);
subplot(1,2,1); hold on; plot((mean(Temp_Zonal13h_profs')-(numstd/2)*uncert_Temp_std),height_temp, 'k+','LineWidth',2);


figure(52); subplot(1,2,2);
plot((1000.*mean(q_humMeridional13h_profs')+(numstd/2)*uncert_Hum_std),height_hum, 'r','LineWidth',2);
hold on; plot((1000.*mean(q_humMeridional13h_profs')+(numstd/2)*uncert_Hum_std),height_hum, 'k+','LineWidth',2);
hold on; plot((mean(1000.*q_humMeridional13h_profs')-(numstd/2)*uncert_Hum_std),height_hum, 'r','LineWidth',2);
hold on; plot((mean(1000.*q_humMeridional13h_profs')-(numstd/2)*uncert_Hum_std),height_hum, 'k+','LineWidth',2);

figure(52); subplot(1,2,1);
hold on; plot((1000.*mean(q_humZonal13h_profs')+(numstd/2)*uncert_Hum_std),height_hum, 'b','LineWidth',2);
hold on; plot((1000.*mean(q_humZonal13h_profs')+(numstd/2)*uncert_Hum_std),height_hum, 'k+','LineWidth',2);
hold on; plot((1000.*mean(q_humZonal13h_profs')-(numstd/2)*uncert_Hum_std),height_hum, 'b','LineWidth',2);
hold on; plot((1000.*mean(q_humZonal13h_profs')-(numstd/2)*uncert_Hum_std),height_hum, 'k+','LineWidth',2);


 if noise== number_Tb_perturb; saveas(figure(50),[pathouTfigs,num2str(year),sprintf('%02d',month),sprintf('%02d',day),...
  'at',num2str(timeABLdeveloped), '00UTC_deltatempZonal_deltatempMeridional_MCretrievals','.png']); end

 if noise== number_Tb_perturb; saveas(figure(52),[pathouTfigs,num2str(year),sprintf('%02d',month),sprintf('%02d',day),...
     'at',num2str(timeABLdeveloped), '00UTC_deltahumZonal_deltahumMeridional_MCretrievals','.png']); end
    

if  number_Tb_perturb==500


csvwrite([pathoutRadiometricUncertainty,num2str(year),sprintf('%02d',month),sprintf('%02d',day)...
     'RadiometricNoiseHorizontalGradTemp_difnoise_std_Kelvin_uncert.txt'],uncert_Temp_std)
csvwrite([pathoutRadiometricUncertainty,num2str(year),sprintf('%02d',month),sprintf('%02d',day)...
     'RadiometricNoiseHorizontalGradHum_difnoise_std_g_m3_uncert.txt'],uncert_Hum_std) 


end
