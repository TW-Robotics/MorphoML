# This script is the original implementation used in the publication
# for GPA estimation. 
#    
# The code in evalres.py is available under a GPL v3.0 license and
# comes without any explicit or implicit warranty.
#
# (C) W. Wöber 2021 <wilfried.woeber@technikum-wien.at>
rm(list = ls())                                   #Remove old variables
library(readr)
library(shapes)
#------------------------#
#--- Global functions ---#
#------------------------#
plotProcrustes <- function(PROC,TARGET){
  #Get min/max values for plotting
  min.val.x <- min(PROC$rotated[,1,])
  max.val.x <- max(PROC$rotated[,1,])
  min.val.y <- min(PROC$rotated[,2,])
  max.val.y <- max(PROC$rotated[,2,])
  plot(NA, 
       xlim=c(min.val.x,max.val.x), ylim = c(min.val.y,max.val.y),
       xlab="X Coordinate",ylab = "Inverted Y Coordinate"
  )#Create empty plot
  abline(v=seq(-2,2,by = 0.1),h = seq(-2,2,by = 0.05),col='gray') #Add lines
  for(i in seq(1,dim(PROC$rotated)[3])){
    for(k in seq(1,dim(PROC$rotated)[1])){
      points(PROC$rotated[k,1,i],PROC$rotated[k,2,i],
             pch='.', cex=2, col=TARGET[i]
      )
    }
  }
  for(i in seq(1,nrow(PROC$mshape))){
    text(x = PROC$mshape[i,1]-0.025,y = PROC$mshape[i,2]-0.025, toString(i))
  }
  #--- legend ---#
  #legend("topright",legend=class.names, col = seq(1,6),cex=0.75,bg='white', lty=1)
}#End plot procrustes
#----------------------------------#
#--- Define the paths and stuff ---#
#----------------------------------#
path.basepath <- "../preProc" #Path to all files
pop.basename.Ethiopia <- "Ethiopia" #File names of Ethiopian
pop.basename.Uganda <- "Uganda_fin" #File names of Uganda
pop.basenames <- c(pop.basename.Ethiopia,pop.basename.Uganda) #Store them for use
#-----------------------#
#--- Main processing ---#
#-----------------------#
for(POP in pop.basenames){
  cat("Process ",POP, "\n")
  #Load the data
  landmarks <- suppressMessages(as.matrix(read_csv(paste(path.basepath,"/",POP,"_LM.csv",sep="")))) #Get the landmarks
  targets <- suppressMessages(as.matrix(read_csv(paste(path.basepath,"/",POP,"_target.csv",sep=""),col_names = FALSE))) #Get the target values
  nr.landmarks <- ncol(landmarks)/2 #There are X and Y values
  nr.samples <- nrow(landmarks) #Number of specimens in dataset
  #Create data tensor for procrustes analysis
  procrustes.input.data <- array(0, #Init tensor with 0's in it
                                 dim=c(nr.landmarks, #For each landmark
                                       2, #... and dimension
                                       nr.samples) #... and specimen
                                 )
  for(SPEC in seq(1,nr.samples)){ #Loop over all sepcimens
    procrustes.input.data[,1,SPEC] <- landmarks[SPEC,1:nr.landmarks] #Get X values
    procrustes.input.data[,2,SPEC] <- landmarks[SPEC,(nr.landmarks+1):(nr.landmarks*2)] #Get Y values
  }#End loop for landmark tensor creation
  #Do procrustes analysis
  procrustes.output <- procGPA(procrustes.input.data, pcaoutput = T,eigen2d = T) #Do Procrustes analysis
  #Store result
  memory.design <- array(0,dim=c(nr.samples,nr.landmarks*2))  #14*2 = 28 + label + ID = 29
  for(i in seq(1,nr.samples)){
    #--- Add  X and Y coordinates ---#
    looper <- 1
    for(k in seq(1,nr.landmarks)){
      memory.design[i,looper] <- procrustes.output$rotated[k,1,i]
      looper <- looper+1
      memory.design[i,looper] <- procrustes.output$rotated[k,2,i]
      looper <- looper+1
    }
  }
  write.table(memory.design, paste("PROCRUSTES_DATA_",POP,".csv",sep=""),row.names = F,col.names = F, quote = F, sep = ",")
  #Plot result
  warning("Invert Y axis for plotting")
  procrustes.output$mshape[,2] <- -procrustes.output$mshape[,2]
  procrustes.output$rotated[,2,] <- -procrustes.output$rotated[,2,]
  plotProcrustes(procrustes.output,targets)
}#End population loop