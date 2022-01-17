# FeatureVariance.py estiamtes the heatmaps for GP-LVM. It
# is based on the estimated models from getGPLVM.py.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2020 <wilfried.woeber@technikum-wien.at>
import matplotlib
matplotlib.use('Agg')
import sys                  #System stuff
sys.path.append('../Python/')  #Add path to project library
from bGPLVM import bGPLVM   #GPy wrapper
import numpy as np          #You should know that
import matplotlib.pyplot as plt #We aim to plot something...
image_dim = (int(sys.argv[3]), int(sys.argv[4])) #(91,224)
import os                   #For bash stuff
#---------------------#
#--- Set variables ---#
#---------------------#
proc_path = sys.argv[1] #Path, where data is
design_path = sys.argv[2]   #Path to design.csv
#--------------------------------------#
#--- Load IDP and optimal dimension ---#
#--------------------------------------#
latentDim        = np.loadtxt(proc_path+"/optModel_bgp_lDim.csv", dtype=int)
nrInd            = np.loadtxt(proc_path+"/optModel_bgp_nrInd.csv",dtype=int)
# --> note, we used 90% rule
print("Use %d inducing points and %d latent dimensions" % (nrInd,latentDim))
#-------------------------#
#--- Init bGPLVM model ---#
#-------------------------#
data_Model	= proc_path+"/optModel_bgp_model.npy"
data_latent	= proc_path+"/optModel_bgp_features_train.csv"
dataFolder	= design_path
#--- Create bGPLVM model ---#
model =bGPLVM(  dataFolder,         #Path to training data
                data_latent,        #Extracted features
              	data_Model,         #Path to model data
                "",                 #Sampels from faulty classes
                "",                 #Path to excluded featues
                nrInd,              #Number of inducing pts
                latentDim,          #Number of latent dimensions
                (image_dim[1],image_dim[0]))       #Reshaping image
#--------------------------------------#
#--- Estimate variance per features ---#
#--------------------------------------#
os.system("mkdir Heatmaps")
model.plotVarHeatmaps(prefix="./Heatmaps/",transpose=True)
##-------------------------------#
##--- Create summarized plots ---#
##-------------------------------#
#plot_top_n=(3,4)
#selection = np.loadtxt("../Data/unselectedFeatures.csv", dtype=int)
#f, arr = plt.subplots(plot_top_n[0],plot_top_n[1])  #Create 'grid' for plot
#x_looper=0
#y_looper=0
#for i in range(0,np.prod(plot_top_n)):
#    img=np.loadtxt('./Heatmaps/'+str(selection[i])+'.csv',delimiter=',')
#    arr[y_looper,x_looper].imshow(img,cmap='jet')
#    arr[y_looper,x_looper].text(5,30, "F"+str(selection[i]),fontsize=20,color='red')
#    arr[y_looper,x_looper].axis('off')
#    x_looper=x_looper+1
#    if(x_looper >= plot_top_n[1]):
#        x_looper=0
#        y_looper=y_looper+1
#    plt.subplots_adjust(wspace=0, hspace=0, left=0, right=1, bottom=0, top=1)
#plt.subplots_adjust(wspace=0, hspace=0, left=0, right=1, bottom=0, top=1)
#plt.savefig("./Heatmaps/selection.pdf",bbox_inches = 'tight',pad_inches = 0)
#plt.savefig("./Heatmaps/selection.png",bbox_inches = 'tight',pad_inches = 0)
##----------------------------------#
##--- sampe for ''bad'' features ---#
##----------------------------------#
#selection = [bad for bad in np.array(range(0,9)) if not np.isin(bad,selection)]
#f, arr = plt.subplots(1,len(selection))  #Create 'grid' for plot
#for i in range(0,len(selection)):
#    img=np.loadtxt('./Heatmaps/'+str(selection[i])+'.csv',delimiter=',')
#    arr[i].imshow(img,cmap='jet')
#    arr[i].text(5,30, "F"+str(selection[i]),fontsize=20,color='red')
#    arr[i].axis('off')
#plt.subplots_adjust(wspace=0, hspace=0, left=0, right=1, bottom=0, top=1)
#plt.savefig("./Heatmaps/technicalBackground.pdf",bbox_inches = 'tight',pad_inches = 0)
#
