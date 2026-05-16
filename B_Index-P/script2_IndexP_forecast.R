library(rstudioapi)
path <- rstudioapi::getActiveDocumentContext()$path
dir <- dirname(path)
setwd(dir)

source('MVSE/R/MVSE.R')
require('MVSE')
require("pbapply")
require("scales")
require("genlasso")

for (i in 1:1514){
  #change period (2061-2075 or 2076-2090) and scenario (4.5 or 8.5)
  string0 <- "2061-2075/proj45_"
  string1 <- c(i)
  string2 <- ".csv"
  string3 <- paste(string0,string1, string2, sep = "")

  setEmpiricalClimateSeries(string3)
  setOutputFilePathAndTag(string3)
  
  # plotClimate()
  
  # Ορισμός prior παραμέτρων
  setMosqLifeExpPrior(pmean=10, psd=3, pdist='gamma') 
  setMosqIncPerPrior(pmean=9, psd=4, pdist='gamma')  
  setMosqBitingPrior(pmean=0.22, psd=0.04, pdist='gamma') 
  setHumanLifeExpPrior(pmean=81, psd=2, pdist='gamma') 
  setHumanIncPerPrior(pmean=5.8, psd=1, pdist='gamma') 
  setHumanInfPerPrior(pmean=5.9, psd=1, pdist='gamma') 
  setHumanMosqTransProbPrior(pmean=0.2, psd=0.05, pdist='gamma') 
  
  # Εκτίμηση συντελεστών οικολογίας
  estimateEcoCoefficients(nMCMC=100000, bMCMC=0.5, cRho=1, cEta=1, gauJump=0.75)
  
  # # Άλλες εξαγωγές και plots 
  # exportEcoCoefficients()
  # exportEntoParameters(Ns=1000)
  # plotEntoParameters(outfilename='debug_ento', entoPostLim=c(0,30), bitPostLim=c(0,1))
  # plotEcoCoefPosteriors(outfilename='debug_dist', etaLim=c(0,12), alphaLim=c(0,12), rhoLim=c(0,12))
  # plotEcoCoefMCMCChains(outfilename='debug_chains')
  
  # Προσομοίωση και εξαγωγή Index-P
  simulateEmpiricalIndexP(nSample=1000, smoothing=c(7,15,30,60))
  exportEmpiricalIndexP()
  
  # plotEmpiricalIndexP(outfilename='debug_indexP')
  # exportEmpiricalQ()
  # plotEmpiricalQ(outfilename='debug_Q')
  # exportEmpiricalV0()
  # plotEmpiricalV0(outfilename='debug_V0')
  # plotEmpiricalIndexPV0Q()
  
  # setTheoreticalClimateSeries(Trange=seq(10,35,length.out=100), Hrange=seq(50,95,length.out=100))
  # simulateTheoreticalIndexP(nSample=1000)
  
  # simulateGenerationTime(Ns=1000)
  # plotGenerationTimes(entoLim=c(0,20), humLim=c(0,10), genLim=c(0,30))
  # exportGenerationTimes()
  
  # plot(MVSE_prior_a_ddist)
  # plot(MVSE_prior_ic_ddist)
  # plot(MVSE_prior_lev_ddist)
}