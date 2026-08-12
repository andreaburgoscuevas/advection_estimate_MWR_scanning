# advection_estimate_MWR_scanning
Codes and supplementary material for estimation of horizontal temperature and humidity advection and uncertainties from synergistic ground-based remote sensing observations at a single site.

The code requires measurements from:
- Doppler wind lidar (DWL): VAD-36 scans providing zonal and meridional wind. Vertical resolution: 30 m. Time resolution: 15 minutes.
- microwave radiometer (MWR):  30° elevation scans that provides retrieved temperature and humidity. Vertical resolution varies (50 m near surface, 200 m at 1600 m height). Time resolution: 0.5 hours

The advection estimation for a period that spans along 2 days is performed in two steps:

1. `Advection_temperature_netcdfout.m` and `Advection_humidity_netcdfout.m`
   Needs 30° elevation scans from MWR of retrieved temperature and humidity correspondingly; and winds from DWL. Estimates temperature and humidity advection and creates the corresponding
   NetCDF outputs. There are 5 NetCDF files created for temperature and 5 for humidity, they are analogous, here we explain the temperature ones:
     - yyyymmdd_theta_directions.nc : theta in each (East, West, North and South) direction height and time resolved. Values of time and height also provided.
     - yyyymmdd_theta_dif_zonal_meridional.nc : zonal and meridional differences height and time resolved
     - yyyymmdd_theta_advection.nc : advection height and time-resolved
     - yyyymmdd_theta_advection_uncert.nc : time series of zonal and meridional advection and advection uncertainty, integrated over the boundary layer

3. `Advection_temperature_plots_merging2days.m` and `Advection_humidity_plots_merging2days.m`
   Reads the NetCDF files from the previous code from 2 consecutive days
   
For the uncertainty analysis the code "Retrieving_TempHum_MonteCarlo.m" performs the Monte Carlo analysis, in which retrievals of temperature and humidity are made, and also the brightness temperature covariance matrices are produced. It is possible to visualize the perturbed temperature and humidity difference retrievals based on 500 brightness temperature Monte Carlo samples. 

There is also the code "uncertainties_2D_histograms.m" that produces the histograms that show in what ranges of wind and horizontal contrasts it is possible to obtain advection estimates that are larger than their uncertainties.

