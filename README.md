# advection_estimate_MWR_scanning
Codes and supplementary material for estimation of horizontal temperature and humidity advection and uncertainties from synergistic ground-based remote sensing observations at a single site.

The code requires measurements from:
- Doppler wind lidar (DWL): VAD-36 scans providing zonal and meridional wind. Vertical resolution: 30 m. Time resolution: 15 minutes.
- Microwave radiometer (MWR):  30° elevation scans that provides retrieved temperature and humidity. Vertical resolution varies (50 m near surface, 200 m at 1600 m height). Time resolution: 0.5 hours

The advection estimation for a period that spans along 2 days is performed in two steps:

1. `Advection_temperature_netcdfout.m` and `Advection_humidity_netcdfout.m`
   Needs 30° elevation scans from MWR of retrieved temperature and humidity correspondingly; and winds from DWL. Estimates temperature and humidity advection and creates the corresponding
   NetCDF outputs. There are 5 NetCDF files created for temperature and 5 for humidity, they are analogous, here the temperature ones are explained:
     - yyyymmdd_theta_directions.nc : theta in each (East, West, North and South) direction height and time resolved. Values of time and height also provided.
     - yyyymmdd_theta_dif_zonal_meridional.nc : zonal and meridional differences height and time resolved
     - yyyymmdd_theta_advection.nc : horizontal advection from surface up to the highest DWL available (typically ABL height), height and time-resolved
     - yyyymmdd_theta_advection_uncert.nc : time series of zonal and meridional advection and advection uncertainty, integrated over the boundary layer

2. `Advection_temperature_plots_merging2days.m` and `Advection_humidity_plots_merging2days.m`
   Reads the NetCDF files from the previous code from 2 consecutive days. It provides merged plots for two days in which it is possible to choose start time (horaini) on the first day and end time (horafin) on the second day
   
For the uncertainty analysis there is a code that performs the radiometric noise in the retrievals via Monte Carlo:
- "Retrieving_TempHum_MonteCarlo.m": this code inputs retrieval coefficients and brightness temperature covariance matrices. Also, it requieres the measured brightness temperatures for the day that is retrieved. Then, it performs a Monte Carlo sampling to provide 500 temperature and 500 humidity profiles. The differences in retrieved temperature and humidity in different azimuthal directions is estimated to provide zonal and meridional differences. The uncertainties are estimated with the standard deviation.

Finally, the code "uncertainties_2D_histograms.m" that produces the histograms that show in what ranges of wind and horizontal contrasts it is possible to obtain advection estimates that are larger than their uncertainties.

