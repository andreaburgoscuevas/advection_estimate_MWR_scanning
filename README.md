# advection_estimate_MWR_scanning
Codes and supplementary material for estimation of horizontal advection and uncertainties from synergistic ground-based remote sensing observations

The advection estimates are performed first for only one day and netcdf outputs are created, this is performed with codes "Advection_temperature_netcdfout.m" and "Advection_humidity_netcdfout.m". Then, a second code reads those netcdf output files and merge netcdf for two consecutive days utilizing the required hours for each day (these codes are "Advection_temperature_plots_merging2days.m" and "Advection_humidity_plots_merging2days.m").

For the uncertainty analysis the code "Retrieving_TempHum_MonteCarlo.m" performs the Monte Carlo analysis, in which retrievals of temperature and humidity are made, and also the brightness temperature covariance matrices are produced. It is possible to visualize the perturbed temperature and humidity difference retrievals based on 500 brightness temperature Monte Carlo samples. 

There is also the code "uncertainties_2D_histograms.m" that produces the histograms that show in what ranges of wind and horizontal contrasts it is possible to obtain advection estimates that are larger than their uncertainties.

