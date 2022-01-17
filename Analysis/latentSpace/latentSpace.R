# This script analyzes the latent space and visualize n dimensions.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
rm(list=ls()) #Remove all vaiables in the space
library(readr) #We need to load stuff from csv files
source("myGraphs.R") #The drawing functions including some little helpers
library(GGally) #ggpair plots
library(ggpubr) #Additional ggplot functions
library(ggplot2) #GGplot ftw
library(purrr) #Some ggplot stuff
library(fastICA) #Latent space investigation
#--------------------------------#
#--- Main paths and variables ---#
#--------------------------------#
ggplot.list <- list() #Memory for plots for later arrangement
top.N.dims.boxplot <- 3 #Analyse top 2 dimensions for boxplots
source("define.data.R") #Gets the data DF
for(LST.iterator in seq(1,nrow(DF))){
#plotWrapper <- function(LST.iterator){ --> see below why this isn't working
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
  if(LST$name == "Uganda"){
    convertedTarget <- convertTarget(target,classes, classes.short, UgandaTranslator, UgandashortNew)
    target <- convertedTarget$label
    classes <- UgandashortNew#unique(convertedTarget$classes)
    classes.short <- UgandashortNew#convertedTarget$classes.short
  }
  design <- scale(design)
  #--------------------------------------#
  #--- We know have the design matrix ---#
  #--------------------------------------#
  #Boxplot analysis
  if(LST$model != "GPLVM"){
    design.preproc <- fastICA(design,n.comp = top.N.dims.boxplot)$S
  }else{
    design.preproc <- design[,1:top.N.dims.boxplot] #No need for GPLVM, already in the model
  }
  #model.PCA <- prcomp(design,center = T,scale. = T)
  #design.preproc <- model.PCA$x[,1:top.N.dims.boxplot]
  #DF.boxplot.data <- cbind(target,design[,1:top.N.dims.boxplot]) <-- RAW initial data
  DF.boxplot.data <- cbind(target,design.preproc)
  colnames(DF.boxplot.data) <- c("Label",unlist(lapply(seq(1,top.N.dims.boxplot),function(x){paste("Dim",x,sep = " ")})))
  DF.boxplot <- data.frame(DF.boxplot.data)
  #draw.Boxplot(myDF = DF.boxplot,labs.short = classes.short)
  #GGPlot2 stuff
  #DF.boxplot2 <- data.frame(Label=factor(DF.boxplot.data[,1],labels = classes.short),design[,1:top.N.dims.boxplot]) <-- Raw data
  DF.boxplot2 <- data.frame(Label=factor(DF.boxplot.data[,1],labels = classes.short),design.preproc)
  colnames(DF.boxplot2) <- c("Label",unlist(lapply(seq(1,top.N.dims.boxplot),function(x){paste("Dim",x,sep = " ")})))
  pdf(paste(LST$name,"_",LST$model,".pdf",sep = ""))
  p<-        ggpairs(DF.boxplot2,mapping = aes(color = Label,alpha=0.25), columns = colnames(DF.boxplot2)[-1] ) + 
            ggtitle(paste(LST$name,LST$model))
  print(p)
  dev.off()
  #ggplot.list[[length(ggplot.list)+1]] <- list(p)
}
# For the cor plots above, the cor values are the correlation of the data for a certain class,
# e.g.: or(DF.boxplot.data[DF.boxplot$Label==1,2:4]) produces the cor values for class 1 and so on. The 
# star and symbol afterwards shows the linear relation. E.G.: in the first corr cell the first element for ethiopia
# after corr is the linear relation of the dimension 2 to dimension 1 using chamo rows. 
# That means, the linear relation can be visualized using:
# LAB<-1;DF.test <- data.frame(DIM1 = DF.boxplot$Dim.1[DF.boxplot$Label==LAB], DIM2 = DF.boxplot$Dim.2[DF.boxplot$Label==LAB]); summary(lm(DIM1~.,DF.test))

#plot_list <- map(seq(1,nrow(DF)),plotWrapper) --> I Do think this is a ggplot an R version issue
#print(ggarrange(plotlist = plot_list,ncol = 2, nrow = 3))
#-------------------------#
#--- Do pdf processing ---#
#-------------------------#
system("pdfjam Ethiopia_LM.pdf Uganda_LM.pdf Ethiopia_GPLVM.pdf Uganda_GPLVM.pdf Ethiopia_AE.pdf Uganda_AE.pdf --nup 2x3 --landscape --outfile result.pdf")
system("pdfcrop --margins '0 0 0 0' --clip result.pdf result.pdf")

system("pdfjam Ethiopia_LM.pdf Uganda_LM.pdf --nup 2x1 --landscape --outfile LM.pdf")
system("pdfcrop --margins '0 0 0 0' --clip LM.pdf LM.pdf")

system("pdfjam Ethiopia_GPLVM.pdf Uganda_GPLVM.pdf --nup 2x1 --landscape --outfile GPLVM.pdf")
system("pdfcrop --margins '0 0 0 0' --clip GPLVM.pdf GPLVM.pdf")

system("pdfjam Ethiopia_AE.pdf Uganda_AE.pdf --nup 2x1 --landscape --outfile AE.pdf")
system("pdfcrop --margins '0 0 0 0' --clip AE.pdf AE.pdf")

system("rm Uganda*.pdf Ethiopia*.pdf ")
#--------------------------------#
#--- Procrustes visualization ---#
#--------------------------------#
for(LST.iterator in seq(5,6)){
  LST <- DF[LST.iterator,] #Get current data
  cat("Process ",LST$name, ", ", LST$model, "\n")
  #Get the data
  design <- suppressMessages(as.matrix(read_csv(paste(LST$basepath,LST$design.name,sep=""), col_names = FALSE)))
  target <- suppressMessages(as.matrix(read_csv(LST$target.path, col_names = FALSE)))+1
  classes <- suppressMessages(as.matrix(read_csv(LST$class.path, col_names = FALSE)))
  classes.short <- unlist(lapply(classes,function(x){if(nchar(x)>4){return(substr(x,1,4))}else{return(x)}}))
  centers <- center.Ethiopia
  LM.names <- LM.names.Ethiopia
  if(LST$name == "Uganda"){
    convertedTarget <- convertTarget(target,classes, classes.short, UgandaTranslator, UgandashortNew)
    target <- convertedTarget$label
    classes <- UgandashortNew#unique(convertedTarget$classes)
    classes.short <- UgandashortNew#convertedTarget$classes.short
    centers <- center.Uganda
    LM.names <- LM.names.Uganda
  }
  #--- Start processing ---#
  #Get the data
  nr_LM <- ncol(design)/2 #x and y coordiantes
  nr_spec <- nrow(design) #Number of specimens
  data.plot <- array(0, dim = c(nr_LM*nr_spec, 2+1) ) #For the rearranged matrix
  counter <- 1
  for(SPEC in seq(1,nr_spec)){ #YAH I know, there are simpler solutions. I did that due to clearness
    for(LM in seq(1,2*nr_LM,2)){
      data.plot[counter,1] <- target[SPEC]
      data.plot[counter,2] <- design[SPEC,LM]
      data.plot[counter,3] <- -design[SPEC,LM+1]
      counter <- counter +1
    }
  }#End data creation
  DF.GPA.plot <- data.frame(Label=factor(data.plot[,1],labels = classes.short),data.plot[,2:3]) #Create data  frame to plot scatter plot
  colnames(DF.GPA.plot) <- c("Label", "X Coordinate", "Y Coordinate") #Rearrance names
  point.means <- colMeans(design)[seq(1,nr_LM*2,2)] #Get center of points in x
  point.means <- rbind(point.means,-colMeans(design)[seq(2,nr_LM*2,2)]) #Get center of points in y and combine them
  point.means <- t(point.means)
  #point.means <- point.means[centers,] #Connections of points
  df.points <- data.frame(point.means)
  colnames(df.points) <- c("x","y")
  rownames(df.points) <- c()
  #Plot stuff
  pdf(paste("GPA_",LST$name,".pdf",sep = ""))
  p<- ggplot(DF.GPA.plot, aes(x=`X Coordinate`, y=`Y Coordinate`, color = Label)) +
    geom_point(alpha=0.5)#+
  for(i in seq(1,length(centers)-1)){
    p <- p + geom_line(data = df.points[c(centers[i],centers[i+1]),], aes(x=x, y=y), color = "gray")
  }#End add the connections between the centers
  #Add landmark names
  for(i in seq(1,length(LM.names))){
    p <- p + geom_text(data = df.points[i,], aes(x=x-0.025, y=y-0.015), label=LM.names[i], color ='black')
  }
  p<- p+ggtitle(paste(LST$name,"GPA"))
  print(p)
  dev.off()
}#End Procrustes visualization
system("pdfjam GPA_Ethiopia.pdf GPA_Uganda.pdf --nup 2x1 --landscape --outfile result_Pr.pdf")
system("pdfcrop --margins '0 0 0 0' --clip result_Pr.pdf result_Pr.pdf")
system("rm GPA_Ethiopia.pdf GPA_Uganda.pdf")