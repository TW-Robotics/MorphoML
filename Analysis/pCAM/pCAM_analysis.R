# This script implements the pCAM analysis including 
# principal coordinate analysis for the datasets.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls())
library(fastICA) #The fastICA implementation
#source("../../R/utils.R") #Data loading functions
#source("../../R/logisticRegression.R") #Data converting functions
source("./pCAM.R") #The probabilistic co-association matrix calculation
source("./BF_test.R") #The bayes factor test
source("./clusterVis.R") #Custom cluster and high dimensional data visualization
#--- Global drawing functions ---#
drawpCAM <- function(pCAM,target, cex=1,offset = 0, lwd=2){
  plot(imager::as.cimg(pCAM))
  nr.pre <- 0 #Where to start drawing
  for(i in unique(sort(target))[seq(2,max(target))]){ #Do not use first,last element
    nr.post <- length(which(target==(i-1)))+nr.pre
    lines(1+c(0,length(target)-1),
          1+c(nr.post,nr.post-1),
          lwd=lwd,col='red') #horizontal lines
    lines(1+c(nr.post,nr.post-1),
          1+c(0,length(target)-1),
          lwd=lwd,col='red')
    nr.pre <- nr.post
  }
}
warning("Use same scale on BF plot for all\n")
#---------------------------------#
#--- Main modelling parameters ---#
#---------------------------------#
Ethiopia.analysisSeq <- seq(2,45) #Sequence of ks to analyze
Uganda.analysisSeq <- seq(2,45) #Sequence of ks to analyze
#--------------------#
#--- Get Metadata ---#
#--------------------#
Ethiopia.target <- suppressMessages(as.matrix(read_csv("../../preProc/Ethiopia_target.csv", col_names = FALSE)))+1
Ethiopia.classes <- suppressMessages(as.matrix(read_csv("../../preProc/Ethiopia_classes.csv", col_names = FALSE)))
Ethiopia.classes.short <- unlist(lapply(Ethiopia.classes,function(x){substr(x,1,4)}))
Uganda.target <- suppressMessages(as.matrix(read_csv("../../preProc/Uganda_fin_target.csv", col_names = FALSE)))+1
Uganda.classes <- suppressMessages(as.matrix(read_csv("../../preProc/Uganda_fin_classes.csv", col_names = FALSE)))
Uganda.classes.short <- Uganda.classes
#--- Do pCAM ---#
#---------------#
cat("Estimating pCAM\n")
#----------------#
#--- Ethiopia ---#
#----------------#
#GPLVM
cat(" - Ethiopia GPLVM\n")
Ethiopia.CAM.GPLVM.model <- dopCAM(path = "./Data/", #Path to clustering data
                                nr_ind = length(Ethiopia.target), iters = c(1),Gs = Ethiopia.analysisSeq, #Number of possible number of clusters
                                pop = "EthiopiaGPLVM" #Population and model name used during clustering (path in cluster folder)
)
Ethiopia.CAM.GPLVM <- Ethiopia.CAM.GPLVM.model$lpCAM
model.ICA <- plotStuff2(pCAM = Ethiopia.CAM.GPLVM,target = Ethiopia.target,classes = Ethiopia.classes.short,model = "GPLVM", h.displ = -1.2, pdfNAME = "pCAM_GPLVM_ETHIOPIA.pdf")
Ethiopia.ACC.GPLVM <- Bayes.factor.ACC(Ethiopia.CAM.GPLVM,Ethiopia.target)
Ethiopia.BF.GPLVM <- Bayes.factor(Ethiopia.CAM.GPLVM,Ethiopia.target)
cat(" - Ethiopia GPLVM ACC: ",Ethiopia.ACC.GPLVM, "\n")
cat(" - Ethiopia GPLVM BF: ",Ethiopia.BF.GPLVM, "\n")
#Landmarks
cat(" - Ethiopia LM\n")
Ethiopia.CAM.LM.model <- dopCAM(path = "./Data/", #Path to clustering data
                             nr_ind = length(Ethiopia.target), iters = c(1),Gs = Ethiopia.analysisSeq, #Number of possible number of clusters
                             pop = "EthiopiaLM" #Population and model name used during clustering (path in cluster folder)
)
Ethiopia.CAM.LM <- Ethiopia.CAM.LM.model$lpCAM
plotStuff2(pCAM = Ethiopia.CAM.LM,target = Ethiopia.target,classes = Ethiopia.classes.short,model = "LM", h.displ = -1.2, pdfNAME = "pCAM_LM_ETHIOPIA.pdf")
Ethiopia.ACC.LM <- Bayes.factor.ACC(Ethiopia.CAM.LM,Ethiopia.target)
Ethiopia.BF.LM <- Bayes.factor(Ethiopia.CAM.LM,Ethiopia.target)
cat(" - Ethiopia LM ACC: ",Ethiopia.ACC.LM, "\n")
cat(" - Ethiopia LM BF: ",Ethiopia.BF.LM, "\n")
#cAE
cat(" - Ethiopia cAE\n")
Ethiopia.CAM.cAE.model <- dopCAM(path = "./Data/", #Path to clustering data
                                nr_ind = length(Ethiopia.target), iters = c(1),Gs = Ethiopia.analysisSeq, #Number of possible number of clusters
                                pop = "EthiopiaAE" #Population and model name used during clustering (path in cluster folder)
)
Ethiopia.CAM.cAE <- Ethiopia.CAM.cAE.model$lpCAM
plotStuff2(pCAM = Ethiopia.CAM.cAE,target = Ethiopia.target,classes = Ethiopia.classes.short,model = "AE", h.displ = -1.2, pdfNAME = "pCAM_cAE_ETHIOPIA.pdf")
Ethiopia.ACC.cAE <- Bayes.factor.ACC(Ethiopia.CAM.cAE,Ethiopia.target)
Ethiopia.BF.cAE <- Bayes.factor(Ethiopia.CAM.cAE,Ethiopia.target)
cat(" - Ethiopia cAE ACC: ",Ethiopia.ACC.cAE, "\n")
cat(" - Ethiopia cAE BF: ",Ethiopia.BF.cAE, "\n")
#--------------#
#--- Uganda ---#
#--------------#
#GPLVM
cat(" - Uganda GPLVM\n")
Uganda.CAM.GPLVM.model <- dopCAM(path = "./Data/", #Path to clustering data
                             nr_ind = length(Uganda.target), iters = c(1),Gs = Uganda.analysisSeq, #Number of possible number of clusters
                             pop = "UgandaGPLVM" #Population and model name used during clustering (path in cluster folder)
)
Uganda.CAM.GPLVM <- Uganda.CAM.GPLVM.model$lpCAM
plotStuff2(pCAM = Uganda.CAM.GPLVM,target = Uganda.target,classes = Uganda.classes.short,model = "LM", h.displ = -2.25, pdfNAME = "pCAM_GPLVM_UGANDA.pdf")
Uganda.ACC.GPLVM <- Bayes.factor.ACC(Uganda.CAM.GPLVM,Uganda.target)
Uganda.BF.GPLVM <- Bayes.factor(Uganda.CAM.GPLVM,Uganda.target)
cat(" - Uganda GPLVM ACC: ",Uganda.ACC.GPLVM, "\n")
cat(" - Uganda GPLVM BF: ",Uganda.BF.GPLVM, "\n")
#Landmark
cat(" - Uganda LM\n")
Uganda.CAM.LM.model <- dopCAM(path = "./Data/", #Path to clustering data
                           nr_ind = length(Uganda.target), iters = c(1),Gs = Uganda.analysisSeq, #Number of possible number of clusters
                           pop = "UgandaLM" #Population and model name used during clustering (path in cluster folder)
)
Uganda.CAM.LM <- Uganda.CAM.LM.model$lpCAM
plotStuff2(pCAM = Uganda.CAM.LM,target = Uganda.target,classes = Uganda.classes.short,model = "LM", h.displ = -2.25, pdfNAME = "pCAM_LM_UGANDA.pdf")
Uganda.ACC.LM <- Bayes.factor.ACC(Uganda.CAM.LM,Uganda.target)
Uganda.BF.LM <- Bayes.factor(Uganda.CAM.LM,Uganda.target)
cat(" - Uganda LM ACC: ",Uganda.ACC.LM, "\n")
cat(" - Uganda LM BF: ",Uganda.BF.LM, "\n")
#cAE
cat(" - Uganda cAE\n")
Uganda.CAM.cAE.model <- dopCAM(path = "./Data/", #Path to clustering data
                              nr_ind = length(Uganda.target), iters = c(1),Gs = Uganda.analysisSeq, #Number of possible number of clusters
                              pop = "UgandaAE" #Population and model name used during clustering (path in cluster folder)
)
Uganda.CAM.cAE <- Uganda.CAM.cAE.model$lpCAM
plotStuff2(pCAM = Uganda.CAM.cAE,target = Uganda.target,classes = Uganda.classes.short,model = "LM", h.displ = -2.25,  pdfNAME = "pCAM_cAE_UGANDA.pdf")
Uganda.ACC.cAE <- Bayes.factor.ACC(Uganda.CAM.cAE,Uganda.target)
Uganda.BF.cAE <- Bayes.factor(Uganda.CAM.cAE,Uganda.target)
cat(" - Uganda cAE ACC: ",Uganda.ACC.cAE, "\n")
cat(" - Uganda cAE BF: ",Uganda.BF.cAE, "\n")