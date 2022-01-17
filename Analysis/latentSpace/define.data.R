# This file simply contains the main variables to load the data.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
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

#"AlK"  "AlN"  "BF"   "EdK"  "EdR"  "Ge"   "Ka"   "KaC"  "KyB"  "KyK"  "Mu"   "Ni"   "RF"   "SF"   "ViG"  "ViKa" "ViKa" "ViM"  "ViSB"
# 1      1      2      3      3     4       5      6     7      7       8      9      10     11     12     12     12     12     12   
UgandaTranslator <- c(1,1,2,3,3,4,5,6,7,7,8,9,10,11,12,12,12,12,12)
UgandashortNew <- c("Al","BF","Ed","Ge","Ka", "KaC", "Ky", "Mu", "Ni", "RF","SF","Vi")
#Summarizes waterbodies
convertTarget <- function(label.raw, CLASS, CLASS.short, converter, shortNEW){
  lab.new <- c() #New labels (ints)
  cl.new <- c() #New class string
  cl.new.short <- c() #New short class string
  for(i in seq(1,length(label.raw))){
    lab.new <- c(lab.new,converter[label.raw[i]]) # Get converted
    cl.new <- c(cl.new, paste(CLASS[which(converter==converter[label.raw[i]])],collapse = ","))
    cl.new.short <- c(cl.new.short, shortNEW[converter[label.raw[i]]])
  }
  return(list(label=lab.new,classes=cl.new,classes.short=cl.new.short))
}
#Procrustes ordering to plot
center.Ethiopia <-   c(1,2,1,3,4,5,13,6,7,11,12,10,8,9,8,10,14,1)
LM.names.Ethiopia <- c("UTP","EYE","AOD","POD","DIC","VOC","PIA","BPF","PEO","VEO","AOA","AOP","HCF", "EMO")
center.Uganda <-     c(1,2,1,3,4,5,6, 7,10, 8,9, 8, 10,1)
LM.names.Uganda <- c("UTP","EYE","AOD","POD","DIC","VOC","PIA","BPF","PEO","VEO")