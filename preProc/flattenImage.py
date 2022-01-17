# flattenImage.py takes a grayscale image and flatten it.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>
import numpy as np                      #You should know that
import cv2
#-------------------------------------------#
# Funciton: flatten(...)                    #
# Descr: Flatten a given grayscale image.   #
# Param: img        2D numpy array          #
# Return: vec       Flattened image         #
#-------------------------------------------#
def flatten(img):
    img=np.transpose(img)
    vector = img.flatten()
    return vector

#-----------------------#
#--- Main processing ---#
#-----------------------#
if __name__=="__main__":
    img=np.array((1,3,2,4)).reshape((2,2))    #Create dummy image
    print("Original image:\n", img) 
    print("Flattened image:\n", flatten(img) )
