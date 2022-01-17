# This script implements consensus clustering with a GMM backbone.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
library(readr) #CSV handling
suppressPackageStartupMessages(library(mclust)) #GMM clustering
source("./clusterVis.R") #Custom cluster and high dimensional data visualization
#------------------------#
#--- global functions ---#
#------------------------#
doGMM <- function(design, target ,Gs, store.path, classes, classes.short){
  
  #index <- sample(seq(1,length(target)),length(target))
  #index.back <- order(index) --> SHUFFELING LEAD TO THE EXACT SAME SOLUTION
  #design.sorted <- design[index,] #No need anymore
  
  design.sorted <- design #No need anymore
  system(paste("mkdir ",store.path,"/",1,sep = "")) #Create folder for results
  for(G in Gs){ #Do for all Gs
    model.mclust <- Mclust(design.sorted, G = G,verbose = F) #Do GMM !
    #model.mclust$z <- model.mclust$z[index.back,]
    #--- Create files ---#
    write.table(model.mclust$z, paste("myData.",G,".meanQ",sep = ""),row.names = F, col.names = F)
    system(paste(" echo \"Marginal Likelihood:  \"",model.mclust$loglik," > myData.",G,".log",sep=""))
    #--- Visualizations ---#
    pdf(paste("myData.",G,".pdf",sep = ""))
    plot.clusters.pop2(genetic.data = model.mclust$z, target = target, lab.short = classes.short, class.names = classes)
    dev.off()
    png(paste("myData.",G,"_D.png",sep = ""))
    plot.dist(pmat = model.mclust$z,target = target,main.txt = "")
    #drawPop(target,classes.short)
    #plot(imager::as.cimg(as.matrix(distances(model.mclust$z))))
    dev.off()
    #--- Move files ---#
    system(paste("mv myData* ",store.path,"/",1,"/.",sep = ""))
  }#End G loop
}#End GMM modelling and storing
#------------------------------#
#--- Do the main processing ---#
#------------------------------#
base.path.GPLVM <- "../../GPLVM/"
base.path.LM <- "../../Procrustes/"
base.path.AE <- "../Autoencoder_prediction/"
DF <- rbind(list(name="Ethiopia",model="GPLVM", basepath = paste(base.path.GPLVM,"Ethiopia/",sep=""), design.name = "/optModel_bgp_features_train.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= TRUE),
            list(name="Uganda",  model="GPLVM", basepath = paste(base.path.GPLVM,"Uganda/",sep=""), design.name = "/optModel_bgp_features_train.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= TRUE),
            #LM
            list(name="Ethiopia",model="LM", basepath = base.path.LM, design.name = "PROCRUSTES_DATA_Ethiopia.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= FALSE),
            list(name="Uganda",model="LM", basepath = base.path.LM, design.name = "PROCRUSTES_DATA_Uganda_fin.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= FALSE),
            #AE
            list(name="Ethiopia",model="AE", basepath = base.path.AE, design.name = "Ethiopia_code.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= FALSE),
            list(name="Uganda",model="AE", basepath = base.path.AE, design.name = "Uganda_code.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= FALSE)
            #list(name="Ethiopia",model="Autoencoder"),
            #list(name="Uganda",model="Autoencoder")
            )#DF describing the data to load
Gs <- seq(2,45) #Main hyperparameter: Numer of models to extract
DF.sum <- list() #Memory for all loaded data
if(!dir.exists("./Data/")){
  system("mkdir Data") #Create a data folder
}
for(LST.iterator in seq(1,nrow(DF))){ #Loop over all datasets
  #---------------------#
  #--- Load the data ---#  
  #---------------------#
  LST <- DF[LST.iterator,] #Get current data
  cat("Process ",LST$name, ", ", LST$model, "\n")
  #Get the data
  design.full <- suppressMessages(as.matrix(read_csv(paste(LST$basepath,LST$design.name,sep=""), col_names = FALSE)))
  target <- suppressMessages(as.matrix(read_csv(LST$target.path, col_names = FALSE)))+1
  classes <- suppressMessages(as.matrix(read_csv(LST$class.path, col_names = FALSE)))
  classes.short <- unlist(lapply(classes,function(x){if(nchar(x)>4){return(substr(x,1,4))}else{return(x)}}))
  #--- Start processing ---#
  if(LST$selection == TRUE){
    cat(" - Get selection\n")
    selection <- suppressMessages(as.matrix(read_csv(paste(LST$basepath,"/selection.csv",sep=""), col_names = FALSE)))
    selection <- selection +1
    selection <- sort(selection)
    #+1 is converting Python indices to R indices
    design <- design.full[,selection]
  }else{
    design <- design.full
  }
  #GMM training
  cat(" - Do GMM modelling\n")
  system(paste("mkdir Data/",LST$name,LST$model,sep = ""))
  warning("Do we need to scale? - we just scale the AE- others are already scaled\n")
  if(LST$model == "AE"){
    cat("Scale AE\n")
    design <- scale(design)
  }
  doGMM(design = design, #The features for GMM clustering 
        target = target,
        Gs = Gs,
        store.path = paste("./Data/",LST$name,LST$model,sep = ""), #Where to store result
        classes = classes, classes.short = classes.short
  )
}#End GMM modelling