# This script implements the proposed pCAM functionality. 
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
library(readr) #CSV handling
dopCAM <- function(path,pop,iters,Gs,nr_ind,jitter.val=0.005){
  pCAM <- array(0,dim = c(nr_ind,nr_ind, length(iters)*length(Gs))) #Memory for co association
  pCAMlooper <- 1 #Looper for tensor dimension
  for(ITERATION in iters){#Iteration loop
    for(i in Gs){ #Loop over all defined G's
      #pCAM.local <- matrix(0,nrow = nr_ind,ncol = nr_ind) #Memory for co association
      jitter <- matrix(((runif(n=nr_ind*nr_ind,min = 0,max = 1)*jitter.val)+jitter.val), nrow=nr_ind) #matrix(rnorm(n=nr_ind*nr_ind,mean = 1e-9,sd = 1e-12), nrow=nr_ind) #Jitter for numerical stability
      pCAM.local <- jitter#matrix(1,nrow = nr_ind,ncol = nr_ind)*1e-12 #Memory for co association, add jitter
      probs.raw <- suppressMessages(as.matrix(read_table2(paste(path,"/",pop,"/",ITERATION,"/myData.",i,".meanQ",sep=""), col_names = FALSE)))
      #probs.sorted <- probs.raw#[index,] #Apply indices
      classification <- apply(probs.raw,1,which.max)
      #--- create co association ---#
      for(k in seq(1,i)){#Loop over all modelled clusters
        cluster.index <- which(classification==k) #Get index which elements are in the same cluster
        #We now check which elements are in the same cluster and increase the CAM entry if the are NOW in the same cluster
        for(m in cluster.index){#seq(1,length(cluster.index))){ #First index loop
          for(n in cluster.index){#seq(1,length(cluster.index))){ #Second index loop
            #pCAM.local[cluster.index[m],cluster.index[n]] <- probs.raw[cluster.index[m],i]*probs.raw[cluster.index[n],i] #prob #Increment co association
            #pCAM.local[cluster.index[m],cluster.index[n]] <- probs.raw[m,i]*probs.raw[n,i] #prob #Increment co association
            pCAM.local[m,n] <- probs.raw[m,k]*probs.raw[n,k] #prob #Increment co association
          }#End first cluster index loop
        }#End second cluster index loop
      }#End cluster looper
      pCAM[,,pCAMlooper] <- pCAM.local #Store current pCAM matrix
      pCAMlooper <- pCAMlooper+1 #Increment tensor looper
    }#End loop over all possible clustering k's
  }#End iteration loop
  #--------------------------------------------#
  #--- Process the pCAM matrix element wise ---#
  #--------------------------------------------#
  log.pCAM.sum <- array(0,dim = c(nr_ind,nr_ind)) #Memory for final log probabilities
  for(row in seq(1,nr_ind)){#Row looper
    for(col in seq(1,nr_ind)){ #Col looper
      #We now analyse p(z_j=1|f_k) * p(z_j=1|f_m), where k and m are the rows and cols in each tensor element
      prob.vector <- pCAM[row,col,] #All p(z_j=1|f_k) * p(z_j=1|f_m)
      log.prob.vector <- log(prob.vector) #Get log of all probability values
      inf.values <- which(is.infinite(log.prob.vector)) #Get infinite values
      if(length(inf.values) > 0){
        log.prob.vector <- log.prob.vector[-which(is.infinite(log.prob.vector))] #Remove infs
      }#End remove infs
      log.pCAM.sum[row,col] <- sum(log.prob.vector) #Store value
    }
  }
  return(list(lpCAM=log.pCAM.sum, pCAM=pCAM)) #Return CAM
}