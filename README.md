# Woller-Enders
These files are the accompanying data sets and simulation files for the study.

The online supplement contains the full tables of the Type I error of the Wald tests, and the full trellis power plots. 

Within the data folder, you can find the estimated power from the simulations as well as the data set used in the real data example. For the estimated Type I error tables, please see the online supplement. The alternative priors csv is for the simulations ran with the varrying priors.

The simulation scripts folder contains the shell code that we used to run the simulations, as well as other accompanying scripts.
Within the simulations scripts folder:

shFiles: This folder contains the main shell scripts sim.sh (normal simulation) and simNonNorma.sh (nonnormal simulation) that we ran with bash. Also in this folder are the shell code for the two maximum likelihood scripts for Mplus and the two Bayes scripts for Blimp.

programs: This is the accompanying R code that we used to generate the data (datagen.R and nonnormaldatagen.R) as well as well as the code we used to summarize and aggregate the many results we obtained from the simulation (getresults.R and getresultsnonnormal.R).

outputs: This folder contains sections where the simulations place the raw output from the Mplus and Blimp estimations.

results: This folder contains sections where the simulations place the results to be analyzed later. This includes the slope coefficients, Wald tests/p-values, and the PSR for the Bayes results. Note, the ML and MLR results contain both the Wald test and coefficient results in one file.

finalized: This folder is where the aggregated results from the R scripts are placed. The results of each four estimators should be appended together in the same files. 

misc: This folder contains the seed list for the simulations.

temp: The location for simulations' temporary file handling and processing.

joboutputs: If ran on a cluster, this is where one can direct the process's job outputs to be.
