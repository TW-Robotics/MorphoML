# This script reads the code, rearrange the rows in accordance to the 
# target values and gets the relevant dimension using the
# selection.csv files.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
import numpy as np
import os
import sys
#------------------#
#--- Main paths ---#
#------------------#
basepath = "../../Autoencoder/" #Path where the code is stored
path_bestM = [  '../Autoencoder/bestModel.Ethiopia.csv',
                '../Autoencoder/bestModel.Uganda.csv'] #Best model based on our magical script
path_labels = [ '../../preProc/Ethiopia_files.csv',
                '../../preProc/Uganda_fin_files.csv'] #Used labels in this study
path_selection = [  '../Autoencoder/Ethiopia/selection.csv',
                    '../Autoencoder/Uganda/selection.csv'] #Selection files
#-------------------------#
#--- Do the processing ---#
#-------------------------#
for i in range(0,2):
    model_name = path_bestM[i].split("/")[-1].split(".")[1] #Get population name
    print("Process cAE for %s"%model_name)
    #--- Load stuff ---#
    label     = np.loadtxt(path_labels[i],dtype=str) #Load the string ordering used
    selection = np.loadtxt(path_selection[i],dtype=int,delimiter=",") #Load the user defined selection
    bestM     = np.loadtxt(path_bestM[i],dtype=str) #Load the best model
    #--- Get best moel code ---#
    code_raw = np.loadtxt(basepath+str(bestM)+"/code.csv",delimiter=",")
    code = code_raw[:,selection] #Cut out useful dimensions
    labelAE = np.loadtxt(basepath+str(bestM)+"/files.csv",dtype=str,delimiter=",") #Load the files used in AE training
    #--- Get the right lines in the file ---#
    MATRIX = np.zeros((label.shape[0],len(selection))) #Get a matrix with zeros in right dimension
    for k in range(0,label.shape[0]): #Loop over all files used durign data creation
        name = label[k] #Get current label in training data
        ID_in_AE = [ID for ID in range(0,labelAE.shape[0]) if(labelAE[ID].find(model_name+"/"+name+".")==0)]# Loop over all elements in the AE labels and get the ID with the right name
        if( len(ID_in_AE) != 1):
            print("Error AE labels")
            sys.error(-1)
        ID_in_AE = ID_in_AE[0] #Get the *only* (hopefully) element
        print("Found ID at %d"%ID_in_AE)
        MATRIX[k,:]=code[ID_in_AE,:]
    #--- Store code file ---#
    np.savetxt(model_name+"_code.csv", MATRIX,delimiter=",")
