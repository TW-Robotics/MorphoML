# visFeatures.py visualizes the selected features.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2020 <wilfried.woeber@technikum-wien.at>
import cv2
import csv
import numpy as np
import os
import sys
imgs_row=5      #number of images per row
folder = sys.argv[1] #Get path to folder
selectionFile = sys.argv[2] #Path to selection file
print("Process folder %s"%folder)
print("Use selection file %s"%selectionFile)
#--- Preproc folder name ---#
if not folder.endswith(os.path.sep): #Check if folder ends with /
    folder += os.path.sep #Add / if neededd
#---------------------#
#--- Get selection ---#
#---------------------#
selection= np.genfromtxt(selectionFile, delimiter=',',dtype=int) #Get selection
selection=np.sort(selection) #Sort selection
features = [] #List for heatmap p value images
#--- Load images ---#
for index in range(0,selection.shape[0]):
    path_img = folder+"HM_"+str(selection[index])+"_p.png"
    print("Load %s"%path_img)
    img_pmap = cv2.imread(path_img) #Get image
    img_pmap = cv2.copyMakeBorder(img_pmap,5,5,5,5,cv2.BORDER_CONSTANT,value=[0,0,0])
    features.append(img_pmap) #Store images
print("Loaded %d images"%len(features))
#--- Convert to single image ---#
looper = 0 #Looping variable
IMG=[]   #Init image summary memory
while True:
    print("looper: %d"%looper)
    img=features[looper] #Get current image
    for i in range(looper+1, looper+imgs_row): #Add other images in row
        img= np.concatenate((img, features[i]), axis = 1)
        print(i)
    if(len(IMG)==0):
        IMG=img
    else:
        IMG = np.concatenate((IMG, img), axis = 0)
    looper = looper+imgs_row
    if (looper+imgs_row) > (len(features)):
        break
print("looper: %d"%looper)
print("DIFF: %d"%(len(features)-looper))
#--- Create last line ---#
if( (len(features)-looper) >0 ):
    img_remain = np.concatenate(features[looper:len(features)], axis = 1)
    if((imgs_row-len(features)+looper) > 0): #Just if we need to add black boxes
        img_white = np.zeros((img_pmap.shape[0],img_pmap.shape[1]*(imgs_row-len(features)+looper),3),dtype=features[0].dtype)
        img_lastRow=np.concatenate((img_remain, img_white), axis = 1) #Add the black boxed last row
    else:
        img_lastRow=img_remain #No further images needed
    IMG=np.concatenate((IMG, img_lastRow), axis = 0)
#--- Show everything ---#
cv2.namedWindow("test",0)
cv2.imshow("test",IMG)
cv2.imwrite("features.png",IMG)
cv2.waitKey(0)
