# visFeatureSelector.py visualize the learend features as heatmaps and 
# p-value image. The user can select the feature using 'y' or 'n'. The
# result is stored in a textfile
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
folder = sys.argv[1] #Get path to folder
print("Process folder %s"%folder)
#--- Preproc folder name ---#
if not folder.endswith(os.path.sep): #Check if folder ends with /
    folder += os.path.sep #Add / if neededd
#--- Get files ---#
files = os.listdir(folder) #Get all files in folder
p_maps = [f for f in files if f.find("p.png") > 1] #Get heatmap files
heatmaps = [f[0:(len(f)-6)]+'.png' for f in p_maps] #Get inherent heatmaps
#---------------------#
#--- Process files ---#
#---------------------#
cv2.namedWindow("Img",0)    #Create an OpenCV window
selection=[] #List for selection
for INDEX in range(0,len(heatmaps)): #For each heatmap/p val map
    img_PMAP = cv2.imread(folder+p_maps[INDEX]) #get p map img
    img_HMAP = cv2.imread(folder+heatmaps[INDEX]) #get heatmap
    img=np.concatenate((img_HMAP,img_PMAP), axis=1) #Get single image
    #--- Show image ---#
    while(True):
        cv2.imshow("Img",img) #Show image
        key=cv2.waitKey(0) #Wait for user input
        #--- Check what is to do ---#
        if(key==121):#is 'y'
            print("Use map")
            map_name=heatmaps[INDEX] #Get name of heatmap
            selection.append(int(map_name[map_name.find("_")+1:-4])) #Get selection
            break
        elif(key==110):#is 'n'
            print("Do not use map")
            break
#End for loop
cv2.destroyAllWindows() #Close all windows
#--- Store selection ---#
with open("selection.csv", 'w', newline='') as myfile:
    wr = csv.writer(myfile)
    wr.writerow(selection)
