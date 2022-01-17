# This script implements the cAE analysis based on the calculated 
# metric, e.g.: the mean squared error. 
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls())
library(readr) #CSV file handling
#-----------------------#
#--- Main parameters ---#
#-----------------------#
data.path <- "../../Autoencoder/IT_"
iterations <- seq(1,5)
code.size <- c(2, 5, 10, 25, 50, 75, 100, 125, 150)
pops.names <- c("Ethiopia","Uganda")
pops <- c("Ethiopia","Uganda")
#--- Analysis parameters ---#
epochs <- 1000 #cAE epochs
analysis.horizont <- 50 #Analysis horizon from metric (last n epochs)
#--- Optimal models ---#
opt.model <- data.frame(name=c("Ethiopia","Uganda"),
#                        val=c(10,25),
                        xlim.bot=c(1e-4,4e-4),xlim.top=c(1e-3,1.e-3)
                        )
#-----------------------#
#--- Start main loop ---#
#-----------------------#
DF.best.models <- data.frame() #Memory for best models
pop.looper <- 1 #Looper for populations
for(POP in pops){#For each population
  #pdf(paste(POP,".pdf"))
  plot(NA, xlim=c(opt.model$xlim.bot[which(opt.model[,1]==POP)],opt.model$xlim.top[which(opt.model[,1]==POP)]),ylim=c(0,19000)) #Create empty plot
  pop.metric.memory <- array(0,dim = c(length(iterations)*length(code.size),epochs)) #Metric memory
  pop.metric.looper <- 1 #Looper for above
  for(CODE in code.size){#For each trained Code
    for(ITERATION in iterations){#For each iteration
      mse.local <- suppressMessages(as.matrix(read_csv(paste(data.path,ITERATION,"/",POP,"/",CODE,"/mse.csv",sep=""), col_names = FALSE)))
      pop.metric.memory[pop.metric.looper,] <- mse.local
      pop.metric.looper <- pop.metric.looper+1
    }#End code size loop
  }#End iteration loop
  #--- Vis results ---#
  mem.metric <- array(0,dim = c(length(code.size),2)) #We store the peak of the kernel density estimator
  chunks <- split(seq(nrow(pop.metric.memory)), ceiling(seq_along(seq(nrow(pop.metric.memory)))/length(iterations))) #Get indices of iterations
  col.iterator<-1 #Color iterator
  #We now cut out the last analyzis.horizon for each iteration of each code size and do a histogram on them
  for(indices in chunks){ #Plot density for each chunk (=code size)
    #--- Get kernel densiry estimator data ---#
    DE <- density((pop.metric.memory[indices,(epochs-analysis.horizont):epochs]),n=10000)
    cat("Min metric of ", code.size[col.iterator], " is ", DE$x[which.max(DE$y)],"\n")
    mem.metric[col.iterator,1] <- code.size[col.iterator] #Store current code size
    val <- DE$x[which.max(DE$y)] #Store maximum value
    mem.metric[col.iterator,2] <- log(val/(1-val)) #Store logit
    #--- Plot stuff ---#
    lines(density((pop.metric.memory[indices,(epochs-analysis.horizont):epochs]),n=10000), col=col.iterator,lwd=2) #Plot density
    col.iterator<-col.iterator+1 #Update color
  }#End chunk processing
  legend('topright',legend=unlist(lapply(code.size, toString)), col=seq(1,length(code.size)),lwd=2)
  #--------------------------#
  #--- Visualize analysis ---#
  #--------------------------#
  plot(mem.metric,type='l',main=paste("Logit of cAE metric for",POP),xlab = "Code Size",ylab = "logit(MSE)")
  best.code <- code.size[which.min(mem.metric[,2])] #opt.model[which(opt.model[,1]==POP),2]
  points(best.code,mem.metric[which(code.size==best.code),2],cex=2,lwd=2,col='green')
  #--- Get best iteration ---#
  best.iteration.data <- pop.metric.memory[as.numeric(unlist(chunks[toString(which(code.size==best.code))])),(epochs-analysis.horizont):epochs]
  #We do not plot the stuff below - no need...
  #plot(NA, xlim=c(opt.model$xlim.bot[which(opt.model[,1]==POP)],opt.model$xlim.top[which(opt.model[,1]==POP)]),ylim=c(0,25000)) #Create again an empty plot
  #for(i in seq(1,nrow(best.iteration.data))){
  #  lines(density(best.iteration.data[i,],n=10000), col=i,lwd=2) #Plot density 
  #}
  KDE.result <- unlist(lapply(seq(1,nrow(best.iteration.data)), function(x){
    DE <- density(best.iteration.data[x,],n=10000)
    return(DE$x[which.max(DE$y)])
  }))
  best.iteration <- which.min(KDE.result) #Get lowest metric of selected code size
  cat("KDE result:", KDE.result,"\n")
  write.table(paste("IT_",best.iteration,"/",POP,"/",best.code,sep = ""),paste("bestModel.",POP,".csv",sep = ""),row.names = F,col.names = F,quote = F)
  cat("Selected:",paste("IT_",best.iteration,"/",POP,"/",best.code,sep = ""),"\n")
}#End population loop