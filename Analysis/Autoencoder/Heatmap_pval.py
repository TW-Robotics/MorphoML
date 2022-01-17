# This script calls Sykacek's sampling for saliency maps.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
import os
import sys
import cv2
import numpy as np
sys.path.append("../../GPLVM/")    #Get p value sampling functions
from GPLVM_pval import *        #Import all p-val functions
#--- Global parameters ---#
kernel_width = 5    #Width and height of Gaussian kernel
kernel_sigma = 0    #Default, estimated from width
k=1000              #Number of iterations
alpha = 0.001       #Alpha threshold value
#--- Drawing parameters ---#
top_border=20
font_size=18
font_border=15
img_rows=3*2
img_cols=4
#--- Get folders to process ---#
data_folder=sys.argv[1] #Get folder to process
#experiments=os.listdir(data_folder)    #Get all folders in this data folder
#-----------------#
#--- Main loop ---#
#-----------------#
#for DIR in experiments:
#    print("Process folder: %s" % DIR)
    #best_model = int(np.loadtxt(data_folder+DIR+"/bestModel.csv"))  #Load estimated best model
    # The heatmaps already show the best model
    #path=data_folder+DIR+"/Heatmaps/"   #Build path to heatmaps
path=data_folder+"/Heatmaps/"   #Build path to heatmaps
files=[f for f in os.listdir(path) if f.endswith('.csv')]   #Get all heatmap files
for HEATMAP in files:   #Process all heatmaps
    heatmap = np.loadtxt(path+HEATMAP, delimiter=',')   #Load heatmap
    img_dim=heatmap.shape
    ID = HEATMAP[HEATMAP.find("_")+1:HEATMAP.find(".")] #Get heatmap ID = code dimension
    #--- Store heatmap ---#
    img = heatmap.copy()
    np.savetxt(path+"HM_"+ID+".csv", img)
    img = cv2.copyMakeBorder(img, top_border, 0, 0, 0, cv2.BORDER_CONSTANT, None, 0)
    plt.close()
    plt.imshow(img,cmap='jet')
    plt.text(5,font_border, "F"+ID,fontsize=font_size,color='red')
    plt.axis('off')
    plt.savefig(path+"HM_"+ID+".pdf",bbox_inches = 'tight',pad_inches = 0)
    plt.savefig(path+"HM_"+ID+".png",bbox_inches = 'tight',pad_inches = 0)
    #--- Do p val generation ---#
    img = heatmap.copy()
    pImg = getPimage(img,k)   #Get the p value image
    mask = (pImg<alpha).astype(np.int8)
    res = cv2.bitwise_and(img,img,mask = mask)
    np.savetxt(path+"HM_"+ID+"_p.csv", res)
    res = cv2.copyMakeBorder(addBorder(res), top_border, 0, 0, 0, cv2.BORDER_CONSTANT, None, 0)
    plt.close()
    plt.imshow(res,cmap='jet')
    plt.text(5,font_border, "F"+ID+" MSK",fontsize=font_size,color='red')
    plt.axis('off')
    plt.savefig(path+"HM_"+ID+"_p.pdf",bbox_inches = 'tight',pad_inches = 0)
    plt.savefig(path+"HM_"+ID+"_p.png",bbox_inches = 'tight',pad_inches = 0)
    #End Heatmap loop
#End directory loop
