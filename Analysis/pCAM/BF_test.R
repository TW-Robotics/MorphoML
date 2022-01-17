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
        stop("NA")
      }
      if(BF.local == 0){ #We must add a jitter here...
        BF.local <- 1e-9
        stop("Jitter")
      }
      if(is.infinite(BF.local)){
        BF.local <- sum(exp(log.p.vector))/1e-9 #Get local BF with jitter
        stop("Infinite values")
      }
      prod.mem <- c(prod.mem,BF.local) #Store local bayes factor
    }
    BF.mem <- c(BF.mem, #Extended Bayes factor mixture
                (sum(log(prod.mem))) #Get the sum of the log Bayes factors (is the product of all members of the population)
    )
  }
  return(BF.mem)
}
#A plot function for all results
plotStuff <- function(pCAM,target,classes,model,h.displ){
  layout(matrix(c(1,1,1,1,2,2,2,
                  1,1,1,1,3,3,3), 2, 7, byrow = TRUE))
  mycex <- 1.5
  cex.symbols <- 3
  cols <- rainbow(length(unique(target)))
  plot.cols <- unlist(lapply(target,function(x){return(cols[x])}))
  #par(mfrow=c(1,2))
  #---------------------#
  #--- Distance plot ---#
  #---------------------#
  #Distance matrix
  plot(imager::as.cimg(pCAM),interpolate = F,
       #cex.main = 2, main = paste("Prob. CAM (",model,")",sep=""),
       xlab = "", ylab = "", axes=FALSE)
  drawPop(target=target,classes = classes, cex = 1.75, offset = 1.1)
  #-----------------------------#
  #--- The ICA extended PCoA ---#
  #-----------------------------#
  #PCoa including ICA
  #Yeah, I double checked the target names
  model.ICA <- fastICA(scale(pCAM),n.comp = 2)
  #model.PCA <- prcomp(pCAM,scale.=TRUE, center=TRUE)
  #model.ICA$S <- model.PCA$x[,1:2]
  par.default <- par()
  par(mar=c(5.1, 4.8, 4.1, 10.1), xpd=TRUE)
  plot(model.ICA$S, bg = plot.cols,#target, 
       pch=21, cex=cex.symbols,
       cex.main = mycex, cex.lab = mycex, cex.axis = mycex,
       xlab="PCoA 1", ylab="PCoA 2"#, main="PCoA Analysis including ICA"
  )
  legend("topright", 
         inset=c(h.displ,0), #That moves the legend from left to right, -1,45 for ethiopia and -2.8 for Uganda
         legend=classes, pch=16,col=unique(plot.cols), pt.cex=cex.symbols,#(target), 
         title="", 
         cex=mycex, bty = "n",
         xjust = 4, x.intersp = 0.05, y.intersp = 0.3,
         box.col = 'black'
  )
  #-----------------------------#
  #--- The bayes factor plot ---#
  #-----------------------------#
  BF <- Bayes.factor(pCAM, target) #Get bayes factor
  BF.col <- as.numeric((BF < log(10)))+1 #If the BF > 10, we accept the hypothesis
  plot(BF,  #Plot the Bayes factors
       col = BF.col, #Use this colurs
       xlab = "Populations", ylab="log of Bayes Factor", cex.lab = mycex, cex.axis = mycex, #Add labels and define font size
       pch=16, cex=cex.symbols, xaxt ='n') #Remove x axis
  axis(1,at = 1:length(classes),labels = classes, cex.axis = mycex) #Add thext instead of numbers
  #if(any(BF<log(10))){ #Check if we must draw the threshold line
  #  lines(c(-0,length(classes)+0.7),c(log(10),log(10)),lwd=2) #Draw threshold line
  #}#End draw threshold line
  #--- reset visible settings ---#
  par(mar=par.default$mar, xpd = par.default$xpd) 
  layout(matrix(c(1,1), 1, 1, byrow = TRUE))
  return(model.ICA)
}
# Plot just the pCAM as well as the BF test
plotStuff2 <- function(pCAM,target,classes,model,h.displ, pdfNAME){
  #layout(matrix(c(1,2), 1, 2, byrow = TRUE))
  X.ax.diff <- 0.05
  mycex <- 1.25
  cex.symbols <- 3
  cols <- rainbow(length(unique(target)))
  plot.cols <- unlist(lapply(target,function(x){return(cols[x])}))
  #par(mfrow=c(1,2))
  #---------------------#
  #--- Distance plot ---#
  #---------------------#
  #Distance matrix
  pdf("PCAM.pdf")
  plot(imager::as.cimg(pCAM),interpolate = F,
       #cex.main = 2, main = paste("Prob. CAM (",model,")",sep=""),
       xlab = "", ylab = "", axes=FALSE)
  drawPop(target=target,classes = rep("",length(classes)), cex = 1.75, offset = 1.1)
  #Add labels
  if(length(classes) > 10){loc.classes <- classes; loc.classes[9]<-""}else{loc.classes<-classes} #3 element KyB is not goot to vis
  text(round(unlist(lapply(unique(target), function(x){indices <- which(target==x); return(mean(indices))}))), #Get centers for labels
       par("usr")[3]-diff(par("usr")[3:4])*X.ax.diff,  
       srt = 45, adj = 1, xpd = TRUE,
       labels = loc.classes, 
       cex = mycex)
  dev.off()
  #-----------------------------#
  #--- The bayes factor plot ---#
  #-----------------------------#
  pdf("BF.pdf")
  BF <- Bayes.factor(pCAM, target) #Get bayes factor
  BF.col <- as.numeric((BF < log(10)))+1 #If the BF > 10, we accept the hypothesis
  plot(BF,  #Plot the Bayes factors
       col = BF.col, #Use this colurs
       xlab = "", 
       ylab="log of Bayes Factor", cex.lab = mycex, cex.axis = mycex, #Add labels and define font size
       pch=16, cex=cex.symbols, xaxt ='n') #Remove x axis
  #axis(1,at = 1:length(classes),labels = classes, cex.axis = mycex) #Add thext instead of numbers
  #Add labels
  axis(side=1, at=seq(1,length(classes)), labels = FALSE)
  text(seq(1,length(classes))+0.25, #Get centers for labels
       par("usr")[3]-diff(par("usr")[3:4])*X.ax.diff,  
       srt = 45, adj = 1, xpd = TRUE,
       labels = classes, 
       cex = mycex)
  #Add BF 'alpha' line
  lines(c(0,100),c(log(10),log(10)))
  dev.off()
  system("pdfcrop --margins '0 0 0 0' --clip BF.pdf BF.pdf")
  system("pdfcrop --margins '0 0 10 0' --clip PCAM.pdf PCAM.pdf")
  system(paste("pdfjam PCAM.pdf BF.pdf --nup 2x1 --landscape --outfile ",pdfNAME))
  system(paste("pdfcrop --margins '0 0 0 0' --clip ",pdfNAME,pdfNAME))
  system("rm BF.pdf PCAM.pdf")
}
# Get accuracy for Bayes factor estimation
Bayes.factor.ACC <- function(pCAM,target){
  pred.mem <- c() #Prediction memory
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
      #--- Get the predicted binary label (true/false) ---#
      pred.pop <- FALSE #Init it with false
      # Check if we have a numeric problem and the denominator is larger
      if( is.na(BF.local) || is.infinite(BF.local)){
        stop("Numerical problem in BF Acc")
      }else{ #We got a valid number!
        if(BF.local > 10){ #Check the bayes factor  
          pred.pop <- TRUE #It is a test match!
        }#No else needed (already false)
      }
      pred.mem <- c(pred.mem, pred.pop)
    }
  }
  return(sum(as.numeric(pred.mem))/length(target))
}


#cex.symbols <- 3
#cols <- rainbow(length(unique(Ethiopia.target)))
#plot.cols <- unlist(lapply(Ethiopia.target,function(x){return(cols[x])}))
#par(mar=c(5.1, 4.8, 4.1, 10.1), xpd=TRUE)
#
#plot(model.ICA$S, bg = plot.cols,#target, 
#     pch=21, cex=cex.symbols,
#     xlab="PCoA 1", ylab="PCoA 2"#, main="PCoA Analysis including ICA"
#)
#target1 <- model.ICA$S[which(Ethiopia.target==1),]
#target2 <- model.ICA$S[which(Ethiopia.target==2),]
#target3 <- model.ICA$S[which(Ethiopia.target==3),]
#target4 <- model.ICA$S[which(Ethiopia.target==4),]
#target5 <- model.ICA$S[which(Ethiopia.target==5),]
#target6 <- model.ICA$S[which(Ethiopia.target==6),]
##plot(NA, ylim=c(-2,2),xlim=c(-2,2))
#points(t(colMeans(target1)),col=cols[1],pch=16); ellipse(mu=(colMeans(target1)),sigma = cov(target1),col=cols[1],lwd=2, alpha = 0.95)
#points(t(colMeans(target2)),col=cols[2],pch=16); ellipse(mu=(colMeans(target2)),sigma = cov(target2),col=cols[2],lwd=2, alpha = 0.95)
#points(t(colMeans(target3)),col=cols[3],pch=16); ellipse(mu=(colMeans(target3)),sigma = cov(target3),col=cols[3],lwd=2, alpha = 0.95)
#points(t(colMeans(target4)),col=cols[4],pch=16); ellipse(mu=(colMeans(target4)),sigma = cov(target4),col=cols[4],lwd=2, alpha = 0.95)
#points(t(colMeans(target5)),col=cols[5],pch=16); ellipse(mu=(colMeans(target5)),sigma = cov(target5),col=cols[5],lwd=2, alpha = 0.95)
#points(t(colMeans(target6)),col=cols[6],pch=16); ellipse(mu=(colMeans(target6)),sigma = cov(target6),col=cols[6],lwd=2, alpha = 0.95)
#legend("topright", 
#       inset=c(-0.5,0), #That moves the legend from left to right, -1,45 for ethiopia and -2.8 for Uganda
#       legend=Ethiopia.classes, pch=16,col=unique(plot.cols), pt.cex=2,#(target), 
#       title="", 
#       cex=1.25, bty = "n",
#       xjust = 4, x.intersp = 0.05, y.intersp = 0.75,
#       box.col = 'black'
#)
