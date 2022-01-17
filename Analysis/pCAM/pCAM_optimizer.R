# This script implements the pCAM analysis including 
# principal coordinate analysis for the datasets.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls())
library(fastICA) #The fastICA implementation
source("../../R/utils.R") #Data loading functions
source("../../R/clusterVis.R") #Draw Pop function
source("../../R/logisticRegression.R") #Data converting functions
source("./pCAM.R") #The probabilistic co-association matrix calculation
#---------------------------------#
#--- Main modelling parameters ---#
#---------------------------------#
Ethiopia.analysisSeq <- seq(5,45) #Sequence of ks to analyze
Uganda.analysisSeq <- seq(5,45) #Sequence of ks to analyze
UGANDA.BF.mem <- c()
ETHIOPIA.BF.mem <- c()
for(BEGINNING in seq(2,15)){
  for(END in seq(20,45)){
    cat("Process ", BEGINNING, " and ", END, "\n")
    Ethiopia.analysisSeq <- seq(BEGINNING,END)
    Uganda.analysisSeq <- seq(BEGINNING,END)
    #--------------------#
    #--- Get Metadata ---#
    #--------------------#
    Ethiopia.GP.Metadata <- load.data(name.dataset= "Ethiopia", name.model = "GPLVM",path2base = "../../")
    Ethiopia.target <- sort(Ethiopia.GP.Metadata$target)
    Ethiopia.GP.Metadata$classes.short <- c("Ch","Ha","Ko","La","Ta","Zi")
    Uganda.GP.Metadata <- load.data(name.dataset= "Uganda", name.model = "GPLVM",path2base = "../../")
    Uganda.target <- sort(Uganda.GP.Metadata$target)
    Uganda.GP.Metadata$classes.short <- suppressMessages(as.matrix(read_csv("~/git/NT_nonparametric/Data/Images/Uganda/classes_short.csv", col_names = FALSE)))
    #----------------------#
    #--- pCAM modelling ---#
    #----------------------#
    cat("Estimating pCAM\n")
    #Note, that we use the models estimated in the CAM folder
    #Ethiopia
    Ethiopia.CAM.cAE.full <- dopCAM(path = "/home/wilfried/git/NT_nonparametric/Analysis/CAM/Data/", #Path to clustering data
                                    nr_ind = length(Ethiopia.target), iters = c(1),Gs = Ethiopia.analysisSeq, #Number of possible number of clusters
                                    pop = "EthiopiaAutoencoder" #Population and model name used during clustering (path in cluster folder)
    ) #Do CAM on existing cluster result
    Ethiopia.CAM.cAE <- Ethiopia.CAM.cAE.full$lpCAM
    Ethiopia.CAM.GP.full <- dopCAM(path = "/home/wilfried/git/NT_nonparametric/Analysis/CAM/Data/", #Path to clustering data
                                   nr_ind = length(Ethiopia.target), iters = c(1),Gs = Ethiopia.analysisSeq, #Number of possible number of clusters
                                   pop = "EthiopiaGPLVM"#Population and model name used during clustering (path in cluster folder)
    ) #Do CAM on existing cluster result
    Ethiopia.CAM.GP <- Ethiopia.CAM.GP.full$lpCAM
    #Uganda
    Uganda.CAM.cAE.full <- dopCAM(path = "/home/wilfried/git/NT_nonparametric/Analysis/CAM/Data/", #Path to clustering data
                                  nr_ind = length(Uganda.target), iters = c(1),Gs = Uganda.analysisSeq, #Number of possible number of clusters
                                  pop = "UgandaAutoencoder" #Population and model name used during clustering (path in cluster folder)
    ) #Do CAM on existing cluster result
    Uganda.CAM.cAE <- Uganda.CAM.cAE.full$lpCAM
    Uganda.CAM.GP.full <- dopCAM(path = "/home/wilfried/git/NT_nonparametric/Analysis/CAM/Data/", #Path to clustering data
                                 nr_ind = length(Uganda.target), iters = c(1),Gs = Uganda.analysisSeq, #Number of possible number of clusters
                                 pop = "UgandaGPLVM" #Population and model name used during clustering (path in cluster folder)
    ) #Do CAM on existing cluster result
    Uganda.CAM.GP <- Uganda.CAM.GP.full$lpCAM
    #--------------------#
    #--- Plot results ---#
    #--------------------#
    # Bayes factor test
    Bayes.factor <- function(pCAM,target){
      BF.mem <- c() #Bayes factor memory for all populations
      for(pop in seq(1,max(target))){ #Process each population
        index.pop <- which(target==pop) #Get specimen numbers of population
        prod.mem <- c() #Memory to store local Bayes factor
        for(i in index.pop){ #Process all specimens in current population
          #--- process positive indices ---#
          index.pop.noI <- index.pop[-which(index.pop==i)] #We have to remove the own label - it would introduce a bias
          log.p.vector <- pCAM[i,index.pop.noI] #Get log prob vector of own population
          #--- Process negative indices ---#
          log.n.vector <- pCAM[i,-index.pop] #Get log prob vector of other population
          BF.local <- sum(exp(log.p.vector))/sum(exp(log.n.vector)) #Get local BF
          #--- Check bayes factors ---#
          if((is.na(BF.local))){
            BF.local <- 1 #Both are somehow 0
          }
          if(BF.local == 0){ #We must add a jitter here...
            BF.local <- 1e-9
          }
          if(is.infinite(BF.local)){
            BF.local <- sum(exp(log.p.vector))/1e-9 #Get local BF with jitter
          }
          prod.mem <- c(prod.mem,BF.local) #Store local bayes factor
        }
        BF.mem <- c(BF.mem, #Extended Bayes factor mixture
                    (sum(log(prod.mem))) #Get the sum of the log Bayes factors (is the product of all members of the population)
        )
      }
      return(BF.mem)
    }
    #--- store BFs ---#
    BF.E.cAE <- Bayes.factor(Ethiopia.CAM.cAE, Ethiopia.target)
    BF.E.GP  <- Bayes.factor(Ethiopia.CAM.GP, Ethiopia.target)
    BF.U.cAE <-Bayes.factor(Uganda.CAM.cAE, Uganda.target)
    BF.U.GP  <-Bayes.factor(Uganda.CAM.GP, Uganda.target)
    ETHIOPIA.BF.mem <- rbind(ETHIOPIA.BF.mem, matrix(c(BEGINNING,END,sum(BF.E.cAE), sum(BF.E.GP) ),nrow = 1))
    UGANDA.BF.mem <- rbind(UGANDA.BF.mem, matrix(c(BEGINNING,END,sum(BF.U.cAE), sum(BF.U.GP) ),nrow = 1))
  }#End END loop
}#End beginning loop