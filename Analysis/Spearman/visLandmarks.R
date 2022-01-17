# This script visualizes the landmarks p-value of the 
# Spearmans rank correlation test.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls()) #Remove all vaiables in the space
library(readr) #We need to load stuff from csv 
#library(scales)
library(ggplot2)
#-----------------------------#
#--- Some global functions ---#
#-----------------------------#
#Convert the  [x1 y1 x2 y1 ...] format to a mxdxn tensor, where m is the number of LM and n is the number of specimens. d is here 2 (2D pts)
convertLM <- function(LM){
  nr.specimens <- nrow(LM) #Number of specimens
  nr.LM <- ncol(LM)/2 #Number of used landmarks
  LM.tensor <- array(0,dim = c(nr.LM,2,nr.specimens)) #Create memory for processing
  #Get the data!
  for(n in seq(1,nr.specimens)){
    LM.looper <- 1 #To be easy here...
    for(m in seq(1,nr.LM*2,2)){
      LM.tensor[LM.looper,1,n] <- LM[n,m] #Get x coordinate
      LM.tensor[LM.looper,2,n] <- LM[n,m+1] #Get y coordinate
      LM.looper <- LM.looper+1 #Increment looper -> its a func of m but we used a new variable to make things easier
    }#End landmark looper
  }#End loop over specimens
  return(LM.tensor)
}
converLM2d <- function(LM,target){
  nr.LM <- ncol(LM)/2 #Number of used landmarks
  nr.specimens <- nrow(LM) #Number of specimens
  LM.tensor <- array(0,dim = c(nr.LM*nr.specimens,2)) #Create memory for processing
  LM.target <- array(0,dim = c(nr.LM*nr.specimens,1)) #Create memory for processing
  line.looper <- 1 #Looping variable for cascaded loop
  for(SPEC in seq(1,nr.specimens)){
    for(m in seq(1,nr.LM*2,2)){
      LM.tensor[line.looper,1] <- LM[SPEC,m] #X coordinate
      LM.tensor[line.looper,2] <- LM[SPEC,m+1] #y coordinate
      LM.target[line.looper] <- target[SPEC] #Store target to landmark
      line.looper <- line.looper +1 #Increment row in data matrix
      
    }#End landmark loop
  }#End specimen loop
  return(list(LM=LM.tensor,target=LM.target))
}
#==================#
#=== Processing ===#
#==================#
DF <- rbind( list(datapath = "../../Procrustes/PROCRUSTES_DATA_Ethiopia.csv", name = "Ethiopia", target = "../../preProc/Ethiopia_target.csv"),
         list(datapath = "../../Procrustes/PROCRUSTES_DATA_Uganda_fin.csv", name = "Uganda", target = "../../preProc/Uganda_fin_target.csv")
        ) #List of landmarks to process
xlim <- c(-0.4,0.4) #PLot x limits
ylim <- c(-0.2,0.3) #PLot y limits
#------------------------------------#
#--- Main processing of data sets ---#
#------------------------------------#
for(LST_ITERATOR in seq(1,nrow(DF))){
  LST <- DF[LST_ITERATOR,] #Get current list
  #Load the stored data
  p_values <- suppressMessages(as.matrix(read_table2(paste("data/",LST$name,"_LM.csv",sep=""), col_names = FALSE))) #Get p values from spearmann
  Pr_LM <- suppressMessages(as.matrix(read_csv(LST$datapath, col_names = FALSE))) #Get procrustes landmarks
  labs <- suppressMessages(as.matrix(read_csv(LST$target, col_names = FALSE)))+1 #Get label of rows
  nr_LM <- ncol(Pr_LM)/2 #Number of landmarks
  nr_SPEC <- nrow(Pr_LM) #Number of specimens
  nr_Classes <- length(unique(labs))
  #Draw landmarks
  cols <- rainbow(nr_Classes)
  Pr_LM_nD <- convertLM(Pr_LM) #Convert to tensor
  plot(NA, xlim=xlim, ylim=ylim) #Plot empty plot
  # Change the plot region color
  #rect(par("usr")[1], par("usr")[3],
  #     par("usr")[2], par("usr")[4],
  #     col = "lightgray") # Color
  for(n in seq(1,nr_SPEC)){
    points(Pr_LM_nD[,,n]%*%diag(c(1,-1)),pch=16, cex=0.5, col = labs[n]) #Note we need to invert here. OpenCV differs from LM software
  }#Draw each specimen
  #for(LM_ID in seq(1,nr_LM)){
  #  for(CLASS in sort(unique(labs))){
  #    indices <- which(labs==CLASS)
  #    PTS_LM <- t(Pr_LM_nD[LM_ID,,indices])%*%diag(c(1,-1))
  #    HULL <- chull(PTS_LM)
  #    HULL <- c(HULL,HULL[1])
  #    #lines(PTS_LM[HULL,])
  #    polygon(PTS_LM[HULL,], col=alpha(cols[CLASS],0.75), border = FALSE)    
  #  }
  #}
  PR_LM_2D <- converLM2d(Pr_LM,labs)
  myframe <- data.frame(LM_x = PR_LM_2D$LM[1:800,1], LM_y = PR_LM_2D$LM[1:800,2], pop = as.factor(PR_LM_2D$target[1:800]))
  p1 <- ggplot(myframe, aes(x = LM_x, y = LM_y, color = pop)) +
    geom_point()
  plot(p1)
  break
}#End loop over populations