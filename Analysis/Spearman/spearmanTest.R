# This script implement spearmans rank correlation test for
# further feature selection. We initially define alpha and process all
# models afterwards.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls()) #Remove all vaiables in the space
library(readr) #We need to load stuff from csv files
library(pspearman) #For spearman rank test
library(ggplot2) #Plot p vals
library(reshape2) #melt ftw
#--------------------------------#
#--- Main paths and variables ---#
#--------------------------------#
base.path.GPLVM <- "../../GPLVM/"
base.path.LM <- "../../Procrustes/"
base.path.AE <- "../Autoencoder_prediction/"
DF <- rbind(list(name="Ethiopia",model="GPLVM", basepath = paste(base.path.GPLVM,"Ethiopia/",sep=""), design.name = "/optModel_bgp_features_train.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= TRUE),
            list(name="Uganda",  model="GPLVM", basepath = paste(base.path.GPLVM,"Uganda/",sep=""), design.name = "/optModel_bgp_features_train.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= TRUE),
            #AE
            list(name="Ethiopia",model="AE", basepath = base.path.AE, design.name = "Ethiopia_code.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= FALSE),
            list(name="Uganda",model="AE", basepath = base.path.AE, design.name = "Uganda_code.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= FALSE),
            #LM
            list(name="Ethiopia",model="LM", basepath = base.path.LM, design.name = "PROCRUSTES_DATA_Ethiopia.csv", 
                 target.path ="../../preProc/Ethiopia_target.csv", 
                 class.path = "../../preProc/Ethiopia_classes.csv", selection= FALSE),
            list(name="Uganda",model="LM", basepath = base.path.LM, design.name = "PROCRUSTES_DATA_Uganda_fin.csv", 
                 target.path ="../../preProc/Uganda_fin_target.csv", 
                 class.path = "../../preProc/Uganda_fin_classes.csv", selection= FALSE)            
            #list(name="Ethiopia",model="Autoencoder"),
            #list(name="Uganda",model="Autoencoder")
)#DF describing the data to load
#-----------------------#
#--- Main processing ---#
#-----------------------#
alpha <- 0.01 #Used alpha in this study
system("rm -rf data; mkdir data") #Remove previous results and create new folder
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
  if(LST$name == "Ethiopia"){
    classes.short <- unlist(lapply(classes,function(x){if(nchar(x)>4){return(substr(x,1,4))}else{return(x)}}))
  }else{
    classes.short <- classes
  }
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
  #---------------------------------------------#
  #--- Do the Spearman rank correlation test ---#
  #---------------------------------------------#
  p.val.matrix <- array(0,dim = c(ncol(design),length(classes))) #Memory for result
  for(CLASS in seq(1,length(classes))){ #Loop over all classes
    for(FEATURE in seq(1,ncol(design))){ #Loop over all features
      Y <- as.numeric(target==CLASS) #Get binary class vector
      X <- design[,FEATURE]
      sp.test <- spearman.test(X,Y) #Do the test
      p.val.matrix[FEATURE,CLASS] <- sp.test$p.value #Store p value
    } #End feature loop
  }#end Class looper
  plot(imager::as.cimg(p.val.matrix<alpha),interpolate = F)
  cat(colSums(p.val.matrix<alpha),"\n")
  #In p.val.matrix, the rows are the features and the cols are the classes
  write.table(p.val.matrix,paste("./data/",LST$name,"_",LST$model,".csv",sep = ""),row.names = F,col.names = F)
  #Do ggplot
  if(LST$model == "LM"){
    rownames(p.val.matrix) <- unlist(lapply(seq(1,nrow(p.val.matrix)/2),function(x){list(paste("LM",x,"X"),paste("LM",x,"Y"))}))
  }else{
    rownames(p.val.matrix) <- unlist(lapply(seq(1,nrow(p.val.matrix)),function(x){paste("F",x,sep = "")}))
  }
  colnames(p.val.matrix) <- classes.short
  pdf(paste(LST$name,"_",LST$model,"_pVAL.pdf",sep = ""))
  #DF.plot <- data.frame(p.val.matrix)
  DF.plot.melt <- melt(p.val.matrix)
  DF.plot.melt$value <- round(DF.plot.melt$value,digits = 2)
  p1 <- ggplot(data = DF.plot.melt, aes(Var1, Var2, fill = value))+
    geom_tile(color = "white")+
      scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                         midpoint = 0.5, limit = c(0,1), space = "Lab", 
                         name="p val.") +
      theme_minimal()+ 
      theme(axis.text.x = element_text(angle = 45, vjust = 1, size = 9, hjust = 1),
            axis.title.x = element_text(size = 0),
            axis.text.y = element_text(size = 15),
            axis.title.y = element_text(size = 0))+
      geom_text(  aes(x=Var1, y=Var2, label = value), color="black", size=2.5)+
      coord_fixed()
  print(p1)
  dev.off()
  system(paste("pdfcrop --margins '0 0 0 0' --clip ",LST$name,"_",LST$model,"_pVAL.pdf"," ",LST$name,"_",LST$model,"_pVAL.pdf",sep = ""))
}#End process all models and datasets