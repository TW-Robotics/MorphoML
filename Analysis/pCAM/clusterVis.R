# This file visualize clustering result in this fancy structure plot. I is
# similar to the original plot but way more sexy. 
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
library(distances)
library(fastICA)
#Create a distance plot of populations
plot.dist <- function(pmat,target, main.txt, invert=FALSE){
  #--- Pre-order the data ---#
  index <- order(target) #Order according to class label
  pmat <- pmat[index,] #Order probability matrix
  target <- target[index] #Order labels
  #--- Sort p matrix 
  pmat.sorted <- pmat[index,]
  DM <- distances(pmat.sorted)
  if(invert == TRUE){ #Invert the matrix for visualization
    DM <- as.matrix(DM)
    DM <- (DM-min(DM))/(max(DM)-min(DM))
    DM <- 1-DM
  }
  plot(imager::as.cimg(as.matrix(DM)),interpolate=F, axes=F, main=main.txt)
}
#Plot princiapl coordinates
plot.PCoA <- function(pmat,target,main.txt,classes){
  #--- Pre-order the data ---#
  index <- order(target) #Order according to class label
  pmat <- pmat[index,] #Order probability matrix
  target <- target[index] #Order labels
  #--- Sort p matrix 
  pmat.sorted <- pmat[index,]
  DM <- distances(pmat.sorted)
  #--- Do PCoA stuff ---#
  model.PCA <- prcomp(as.matrix(DM),scale.=T,center=T) #Do the PCA on distance matrix
  plot(model.PCA$x[,1],model.PCA$x[,2],pch=16, col=target, 
       main=main.txt, xlab="PCoA 1", ylab="PCoA 2")
  legend("topright",legend = classes,pch=16, bg="transparent",col=seq(1,length(classes)))
  #return(model.PCA$x)
}#End plot principal coordinates
#Plot independent coordinates
plot.ICoA <- function(pmat,target,main.txt,classes){
  #--- Pre-order the data ---#
  index <- order(target) #Order according to class label
  pmat <- pmat[index,] #Order probability matrix
  target <- target[index] #Order labels
  #--- Sort p matrix 
  pmat.sorted <- pmat[index,]
  DM <- distances(pmat.sorted)
  #--- Do PCoA stuff ---#
  DM.scale <- scale(DM)
  model.ICA <- fastICA(as.matrix(DM.scale),n.comp = 2) #Do the PCA on distance matrix
  plot(model.ICA$S[,1],model.ICA$S[,2],pch=16, col=target, 
       main=main.txt, xlab="PCoA 1", ylab="PCoA 2")
  legend("topright",legend = classes,pch=16, bg="transparent",col=seq(1,length(classes)))
  #return(model.PCA$x)
}#End plot principal coordinates

#Plot the clusters in a more robust way
plot.clusters.pop2 <- function(genetic.data, target, lab.short, class.names, cex.txt = 0.75){
  #--- Pre processing ---#
  pmat <- genetic.data #Get the genetic probability matrix
  #target <- unlist(lapply(as.matrix(labels),function(x){ #Calculate the target based on the label abb. in the labels
  #  for(i in seq(1,length(lab.short))){
  #    if(grepl(lab.short[i],x)){return(i)}
  #  }
  #  return(-1)
  #}))
  pmat.sorted <- pmat #No need to sort anymore
  pmat.sorted.CS <- t(apply(pmat.sorted,1,cumsum)) #Get the cumulated sum --> this is needed for fancy barplots
  #-------------------------#
  #--- Plot the matrices ---#
  #-------------------------#
  cols <- rainbow(ncol(pmat)) #Get colors for clusters
  nr.clusters <- ncol(pmat) #Get number of clusters
  plot(NA, xlim=c(1,nrow(pmat.sorted.CS)),ylim=c(0,1), axes=F,xlab="",ylab="") #An empty plot
  for(i in seq(1,nrow(pmat.sorted.CS))){ #For each sample
    rect(xleft = i-1, ybottom = 0, xright = i,ytop = pmat.sorted.CS[i,1],col = cols[1], lwd=0, border=cols[1]) #This is the default barplot = first cluster
    for(k in seq(2,ncol(pmat.sorted.CS))){ #For each cluster
      rect(xleft = i-1, ybottom = pmat.sorted.CS[i,k-1], xright = i,ytop = pmat.sorted.CS[i,k],col = cols[k], lwd=0, border=cols[k]) #Add remaining clusters
    }#End cluster loop
  }#end sample loop
  for(i in sort(unique(target))){
    X.pos <- mean(which(target==i))  #This should be the center value of the cluster in the plot
    Y.pos <- 1.5#0.7 #Default Y position
    if(i%%2 == 1){ #Check if we are secodn, fourth, ... element
      Y.pos <- 1. #Move  a little bit down
    }#End label up/down movement
    mtext(lab.short[i], #The text
          side=1, #Outside on the botto,
          line=Y.pos, at=X.pos, cex = cex.txt)
    #--- End end class lines ---#
    lines(c(max(which(target==i)),max(which(target==i))),c(0,1),col='black',lwd=2)
  }#End add labels
}#End plot dist 2
# Add lines and population to to a distance matrix
drawPop <- function(target,classes, cex=1,offset = 0, lwd=2){
  #stop("do not use draw Pop\n")
  #if(length(classes)>15){
  #  cex <- cex*0.65
  #}
  #The target has to be sorted
  #lwd <- 2
  nr.pre <- 0 #Where to start drawing
  for(CLASS in seq(1,length(classes)-1)){ #loop over all classes
    nr.post <- length(which(target==CLASS))+nr.pre
    lines(1+c(0,length(target)-1),
          1+c(nr.post,nr.post-1),
          lwd=lwd,col='red') #horizontal lines
    lines(1+c(nr.post,nr.post-1),
          1+c(0,length(target)-1),
          lwd=lwd,col='red')
    mtext(text = classes[CLASS],at = (nr.pre+nr.post)/2, side = 1, cex = cex, padj = offset + (CLASS%%2)*1.2)
    nr.pre <- nr.post
    #break
  }#End class looper
  mtext(text = classes[length(classes)],
        at = (nr.pre+length(which(target==length(classes)))+nr.pre)/2, 
        side = 1, 
        cex = cex,
        padj = offset + (length(classes)%%2)*1) #Last one
}#End drawPoop