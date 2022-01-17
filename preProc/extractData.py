# extractData.py loads the ROI, image and landmark and stores the data
# in a machine learnign useable format.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>
import os
import sys
import numpy as np
import cv2 #OpenCV
from flattenImage import flatten #Flatten a grayscale image
#------------------------#
#--- Useful functions ---#
#------------------------#
#Converts DL annotation format to readable format
def convertROI(normed,img):
    #We get 0, centroid_x/img_w, centroid_y/img_h, w/img_w, h/img_h
    #Note, OpenCV != numpy dimensions
    w = normed[3]*img.shape[1] 
    h = normed[4]*img.shape[0]
    x = (normed[1]*img.shape[1])-w/2
    y = (normed[2]*img.shape[0])-h/2
    return int(x),int(y),int(w),int(h)
#Loads all ROI data and sees how big the smalles specimen is
# NOTE: Note needed anymore - we scale to 224x96
#def getShape(origin,names, img_ending):
#    WH_memory = np.zeros((len(names),2)) #Storage for normalized width and shape
#    looper=0 #A looper
#    for SPEC in names: #Loop over all 
#        img = cv2.imread(origin+"/"+SPEC+"."+img_ending) #Load image
#        ROI = np.loadtxt(origin+"/"+SPEC+".txt") #Load ROI annotation
#        x,y,w,h = convertROI(ROI,img) #Get real ROI data
#        WH_memory[looper,0]=w #Store width
#        WH_memory[looper,1]=h #Store height
#        looper+=1
#    return(WH_memory)
#Gets classes out of the specimen names
def getClasses(names):
    classes_raw = [] #Memory for processed strings
    for SPEC in names:
        name = ''.join([i for i in SPEC if not i.isdigit()]) #Remove number
        name_noLine = ''.join([i for i in name if(i!='_')]) #Remove "_"
        classes_raw.append(name_noLine) #Add to list
    return(np.unique(classes_raw)) #Remove duplicates and return them
#Returns the class ID
def getTarget(classes, spec):
    #[x for x in range(0,len(classes)) if(SPECIMEN.find(classes[x]) == 0)]
    name_no_digit = ''.join([i for i in spec if not i.isdigit()]) #Remove number
    name_noLine = ''.join([i for i in name_no_digit if(i!='_')]) #Remove "_"
    return(classes.tolist().index(name_noLine))

#---------------------#
#--- Get arguments ---#
#---------------------#
file_ending="JPG"
if( len(sys.argv)!=2):
    print("Usage: python extractData.py <path_folder_annotation> (I assume JPG files)")
    sys.exit(0)
#--- Get main data ---#
folderPath=sys.argv[1] #Get path to annotation folder
#folderPath="../Data/Ethiopia"
popName = os.path.splitext(os.path.basename(folderPath))[0] #Get folder name
print("Process files")
print(" - Use path: %s"%folderPath)
print(" - Use name: %s"%popName)
#--------------------#
#--- Get the data ---#
#--------------------#
files_folder = os.listdir(folderPath) #Get all the files in the folder
images = [IMG for IMG in files_folder if(IMG.find(file_ending) > 0)] #Get just image files
specimen_name = [os.path.splitext(IMG)[0] for IMG in images]  #Remove file ending
specimen_name.sort() #Sort the stuff
print("Found %d images"%len(specimen_name))
#----------------------------#
#--- Get mean image shape ---#
#----------------------------#
#WH = getShape(folderPath, specimen_name,file_ending)
scale = (224,96) #See Woeber et al., Identifying geographically differentiated features of Ethopian Nile tilapia (Oreochromis niloticus) morphology with machine learning 
#------------------------------------#
#--- Get classes and target value ---#
#------------------------------------#
classes = getClasses(specimen_name) #Get classes from specimen names
print("Got classes:", classes)
#-----------------------#
#--- Show annotation ---#
#-----------------------#
cv2.namedWindow("img",0) #Create a window
mem_files = [] #Storage of files - we need that ordering
mem_LM = np.array(()) #Empty memory for landmarks
mem_img = np.zeros((len(specimen_name),np.prod(scale))) #Empty array for flattned images
mem_target = np.ones((len(specimen_name),1))*-1 #Empty array for target
img_looper=0 #Looper :-)
for SPECIMEN in specimen_name: #Process all specimens
    print("Load %s"%SPECIMEN)
    #Get the data
    img     = cv2.imread(folderPath+"/"+SPECIMEN+"."+file_ending)#, cv2.IMREAD_GRAYSCALE) #Load image
    ann_ROI = np.loadtxt(folderPath+"/"+SPECIMEN+".txt") #Load ROI annotation
    ann_LM  = np.loadtxt(folderPath+"/"+SPECIMEN+".csv",delimiter=",") #Load landmarks
    #Process the image coorinates
    x,y,w,h = convertROI(ann_ROI,img) #Get real ROI i nimage coordinates
    img=cv2.cvtColor(img, cv2.COLOR_RGB2GRAY)
    img = img[y:(y+h),x:(x+w)] #Cut out the specimen
    img = cv2.resize(img, scale) #Resize image
    cv2.imwrite(SPECIMEN+"."+file_ending, img)
    img_flat = flatten(img) #Flatten image to a vector
    #Store result
    if( mem_LM.shape == (0,)):
        mem_LM = np.concatenate((ann_LM[:,0],ann_LM[:,1])).reshape((1,ann_LM.shape[0]*2))
    else:
        mem_LM =np.concatenate((mem_LM, 
                            np.concatenate((ann_LM[:,0],ann_LM[:,1])).reshape((1,ann_LM.shape[0]*2)) 
                            )) #Extend the landmark memory with x_0, x_1, ..., y_0, y_1, ...
    mem_img[img_looper,:] = img_flat #Store flattened image
    mem_target[img_looper,:] = getTarget(classes,SPECIMEN)# [x for x in range(0,len(classes)) if(SPECIMEN.find(classes[x]) == 0)]
    mem_files.append(SPECIMEN) #Add name of specimen to store ordering of files
    img_looper+=1
    #--- Show the results ---#
    cv2.imshow("img",img) #Show image
    key=cv2.waitKey(1) #Wait n MS
    if(key == 27):
        break
print("Processing done")
#--- Store results ---#
np.savetxt(popName+"_img.csv",      mem_img,delimiter=",")
np.savetxt(popName+"_target.csv",   mem_target,delimiter=",")
np.savetxt(popName+"_classes.csv",  classes,delimiter=",",fmt="%s")
np.savetxt(popName+"_files.csv",    np.array(mem_files),delimiter=",",fmt="%s")
CSV_header= "".join(["LM_X_"+str(f)+"," for f in range(0,ann_LM.shape[0])])+"".join(["LM_Y_"+str(f)+"," for f in range(0,ann_LM.shape[0])])
CSV_header=CSV_header[:-1]
np.savetxt(popName+"_LM.csv",       mem_LM,delimiter=",",header = CSV_header)
os.system("mkdir "+popName+"; mv *."+file_ending+" "+popName+"/.") #Move all generated images
