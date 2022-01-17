# This script contains functions to plot stuff.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
#---------------------#
#--- Boxplot stuff ---#
#---------------------#
draw.Boxplot <- function(myDF,labs.short){
  for(DIM in seq(1,ncol(myDF)-1)){
    boxplot(as.formula(paste("Dim.",DIM,"~Label",sep = "")), #The formular
            DF.boxplot, 
            xlab="Pop.", xaxt ="n", 
            ylab = paste("Dimension",DIM))
    axis(1, at=1:length(labs.short), labels = NA) #Add small lines for each pop
    text(seq(1, length(labs.short), by=1), #Define ticks
         par("usr")[3]-0.075*(par("usr")[4]-par("usr")[3]), #Set space to axis
         labels = labs.short, #Set strings
         srt = 45, #Degrees to rotate
         cex = 0.75,
         pos = 1, xpd = TRUE)
    #cat(par("usr")[3],"\n")
  }
}