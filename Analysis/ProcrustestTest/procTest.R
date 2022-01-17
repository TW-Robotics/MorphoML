# This script implements the procrustest test.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls()) #Remove all vaiables in the space
library(geomorph)
library(readr)
#Load the data
GPA.Ethiopia <- suppressMessages(as.matrix(read_csv("../../Procrustes/PROCRUSTES_DATA_Ethiopia.csv", col_names = FALSE)))
labels.Ethiopia <- suppressMessages(as.matrix(read_csv("../../preProc/Ethiopia_target.csv", col_names = FALSE)))
GPA.Uganda <- suppressMessages(as.matrix(read_csv("../../Procrustes/PROCRUSTES_DATA_Uganda_fin.csv", col_names = FALSE)))
labels.Uganda <- suppressMessages(as.matrix(read_csv("../../preProc/Uganda_fin_target.csv", col_names = FALSE)))
#Convert loaded data from [x1 y1 x2 y2 ... ] to mx2xn (landmarks x 2 dims x specimens)
landmarks.Ethiopia <- array(0, dim = c(ncol(GPA.Ethiopia)/2,2,nrow(GPA.Ethiopia)))
for(SPEC in seq(1,nrow(GPA.Ethiopia))){
  landmarks.Ethiopia[,1,SPEC] <- GPA.Ethiopia[SPEC,seq(1,ncol(GPA.Ethiopia),2)]
  landmarks.Ethiopia[,2,SPEC] <- GPA.Ethiopia[SPEC,seq(2,ncol(GPA.Ethiopia),2)]
}
landmarks.Uganda <- array(0, dim = c(ncol(GPA.Uganda)/2,2,nrow(GPA.Uganda)))
for(SPEC in seq(1,nrow(GPA.Uganda))){
  landmarks.Uganda[,1,SPEC] <- GPA.Uganda[SPEC,seq(1,ncol(GPA.Uganda),2)]
  landmarks.Uganda[,2,SPEC] <- GPA.Uganda[SPEC,seq(2,ncol(GPA.Uganda),2)]
}
#Do GPA
Y.gpa.Ethiopia <- gpagen(landmarks.Ethiopia)    #GPA-alignment  
gdf.Ethiopia <- geomorph.data.frame(Y.gpa.Ethiopia, site = as.factor(labels.Ethiopia)) # geomorph data frame
fit.Ethiopia <- procD.lm(coords ~ site, 
                 data = gdf.Ethiopia, 
                 iter = 999, turbo = TRUE,RRPP = FALSE, print.progress = FALSE) # randomize raw values
Y.gpa.Uganda <- gpagen(landmarks.Uganda)    #GPA-alignment  
gdf.Uganda <- geomorph.data.frame(Y.gpa.Uganda, site = as.factor(labels.Uganda)) # geomorph data frame
fit.Uganda <- procD.lm(coords ~ site, 
                         data = gdf.Uganda, 
                         iter = 999, turbo = TRUE,RRPP = FALSE, print.progress = FALSE) # randomize raw values
#Get values and plot
sum.Ethiopia <- summary(fit.Ethiopia)[[1]]
sum.Uganda <- summary(fit.Uganda)[[1]]
cat("Ethiopia: F val:", sum.Ethiopia$F[1], " -> Pr(>F):", sum.Ethiopia$`Pr(>F)`[1],"\n")
cat("Uganda: F val:", sum.Uganda$F[1], " -> Pr(>F):", sum.Uganda$`Pr(>F)`[1],"\n")