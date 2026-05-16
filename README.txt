This repository contains the scripts and workflows used to produce the analyses and figures for the scientific article entitled 
“Climate-driven expansion of West Nile infection virus risk in Europe”.
Authors: Anastasia Angelou, Nikolaos I. Stilianakis and Ioannis Kioutsioukis
The project is structured into two main methodological components:
A_DLNM: Distributed Lag Non-Linear Model (DLNM) framework
B_Index-P: Mosquito-borne viral suitability index (Index-P)

A_DLNM
file A_DLNM\scripts:
script1_from_cases_to_case_crossover.R, Converts case data into a case-crossover design. Source: adapted from external repository
script2_exp_res_health_impact.R, Estimates exposure-response relationships and health impacts. Source: adapted from external repository
script3_hindcast.R, Runs the DLNM analysis for the historical period (2010–2024).
script4_forecast.R, Runs the DLNM projections for the future period (2061–2090).
script5_Figure1.R, Produces 3D plots
file A_DLNM:
script6_Preprocessing_hindcast_data.m, Preprocesses hindcast data and stores intermediate results as .mat files to reduce computational time in downstream steps.
script7_Preprocessing_hind_forec_data.m, Preprocesses hindcast and forecast data and stores intermediate .mat files for efficiency.
script8_Figure2.m, Produces heatmaps for Figure 2.
script9_Figure3.m, Produces ridge plots for Figure 2..

B_Index-P
file B_Index-P:
Input data are provided in three separate compressed archives corresponding to different temporal periods:
"hindcast.zip", "2061-2075.zip", "2076-2090.zip".
Each archive contains the required input datasets for the corresponding simulation period.
script1_IndexP_hindcast.R, Computes Index P for the historical period. Source: adapted from MVSE tool
script2_IndexP_forecast.R, Computes Index P for the future period. Source: adapted from MVSE tool
script3_Figur4.m, Produces heatmaps for Figure 4.
script4_Figure5.m, Produces heatmaps for Figure 5.

Some scripts are adapted from previously published work:
Case-crossover & DLNM framework:
https://gitlab.earth.bsc.es/ghr/wnv_casecrossover
Index P (MVSE tool):
https://sourceforge.net/projects/mvse/files/latest/download
All externally sourced scripts have been modified and extended to fit the specific needs of this study.