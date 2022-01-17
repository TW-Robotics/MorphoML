# getGPLVM.py is a script, that implements the GP-LVM optimization.
# This script calls the function defined in the bGPLVMOptimizer
# python script. The three step procedure is described in the paper.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2020 <wilfried.woeber@technikum-wien.at>
import numpy as np  #Numpy :-)
import sys
sys.path.append("../Python/")                  #Get own GPC stuff (GPC_nfCV.py)
from bGPLVMOptimizer import step1_PCA
from bGPLVMOptimizer import step2_bGPLVM_IDP
from bGPLVMOptimizer import step3_bGPLVM_latentDim
from bGPLVMOptimizer import model_BGPLVM
import GPy
from sklearn import preprocessing       #Data preprocessing
#--------------------#
#--- Define paths ---#
#--------------------#
path_data   = sys.argv[1]
data_raw    = np.loadtxt(path_data,delimiter=",")           #Load data from file
#---------------------#
#--- Do processing ---#
#---------------------#
mxSteps=25
PCADim  =   step1_PCA(data_raw,explanationTH=0.75)  #Get initial latent Dimension from PCA
#Check dimension
if(PCADim < 1): #If >75% are in dimension 0...
    PCADim = 1  #We still use one dimension
from timeit import default_timer as timer #For debugging reasons
IDP     =   step2_bGPLVM_IDP(  design_raw = data_raw,
                            PCAdim = PCADim, 
                            IDPRange = [10,20,50,75,100, 125, 150,200],  #np.array((range(2,31,2))),#[5,10,20,30,40,50], 
                            IDP_LL_TH = 0.95,
                            steps=mxSteps, #Mx steps
                            doPlot = True)
lDim    =   step3_bGPLVM_latentDim( design_raw=data_raw, 
                            IDP=IDP, 
                            lDimRange = [2,5,10,20,30,40,50,75,100,125,150,175,200], 
                            steps=mxSteps, #Mx steps
                            doPlot=True)
#-----------------------------#
#--- Train optimized model ---#
#-----------------------------#
iterations=10000                                            #Number of maximum iteration for modelling
print("Train optimized model")
print("Standartize data...")
scaler = preprocessing.StandardScaler().fit(data_raw)     #Create and train scaler
design = scaler.transform(data_raw)                       #Scale data
model_LVM = model_BGPLVM(design=design,
                        dim=lDim,
                        idp=IDP,
                        iterations=iterations,
                        steps=mxSteps,
                        stepsize=10,
                        min_step_inc=1e-3,
                        doPlot=True)
print("Start modelling")
#--- We now have finalized model ---#
pre_str = "optModel_"
projection_test, projection_var = model_LVM.infer_newX(design) #Do prediction for dataset
projection = projection_test.mean                                   #Get mean value of dataset
#---------------------#
#--- Store results ---#
#---------------------#
np.savetxt(pre_str+"bgp_features_train.csv", projection, delimiter=',')
np.savetxt(pre_str+"bgp_ARDValues.csv", model_LVM['rbf.lengthscale'], delimiter=',')
np.savetxt(pre_str+"bgp_loglik.csv", model_LVM.log_likelihood()[0,:], delimiter=',')
np.save(pre_str+'bgp_model.npy', model_LVM.param_array)
