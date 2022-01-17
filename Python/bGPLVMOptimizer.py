# The bGPLVMOptimizer.py script includes python fucntions to 
# optimize a Bayesian GP-LVM based on given data. As mentioned in the 
# paper, this is a three step procedure.
# Step 1:   Get an initial guess of the latent dimension using the PCA
#           and the elbow of the explained variance.
# Step 2:   Using the estimated latent dimension estimation from the
#           PCA to optimize the number of inducing points. The number
#           of inducing points above a given threshold is taken
# Step 3:   Optimize the final GP-LVM, where the maximum marginal log 
#           likelihood is used.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2020 <wilfried.woeber@technikum-wien.at>
import numpy as np                      #You should know that
from sklearn.decomposition import PCA   #PCA decomposition module
from sklearn import preprocessing       #Data preprocessing
import matplotlib.pyplot as plt         #Plot function
import GPy                              #GPy python library
import matplotlib
matplotlib.use('Agg')
#=======================================#
#=== The B-GP-LVM Modelling function ===#
#=======================================#
def model_BGPLVM(design,dim,idp,iterations,steps,stepsize,min_step_inc,doPlot):
    #--------------------#
    #--- Train bGPLVM ---#
    #--------------------#
    while(True):
        model_LVM = GPy.models.BayesianGPLVM(Y              = design,           #Dataset - the original dimension
                                            input_dim       = dim,           #Latent dimension
                                            num_inducing    = idp)              #Number of induction points
        #--- Analyse optimization strategy ---#
        #We optimize with default settings
        if(steps == None):
            model_return = model_LVM.optimize(messages=False, max_iters   = iterations)  #Do modelling 
            #--- We now have a valid model ---#
            if(model_return.status!="Errorb'ABNORMAL_TERMINATION_IN_LNSRCH'"):
                break
        #We optimize in iterations 
        else:
            mem_loss = np.zeros((steps+1,2)) #Memory for loss in steps
            mem_loss[0,0]=model_LVM.log_likelihood()[0,:] #Store default elbo
            nr_steps=0 #a counter
            for i in range(0,steps+1): #A for loop over steps to do
                mem_loss[i,0]=- (model_LVM.optimize(messages=False, max_iters = stepsize).f_opt) #Take a step
                nr_steps+=stepsize #Go a step
                mem_loss[i,1]=nr_steps #Store it
                increase=np.sqrt((mem_loss[i,0]-mem_loss[i-1,0])**2)/abs(mem_loss[i,0]) #Get increase
                if(increase <= min_step_inc): #Analyse increase
                    mem_loss = mem_loss[0:(i+1),:]
                    break
            #End step loop
            if(i==steps):
                print("WARNING: may not converged")
            if(doPlot):
                plt.close()
                plt.plot(mem_loss[:,0])
                plt.savefig("./IDP_"+str(idp)+"_IDP_"+str(dim)+"_DIM_loss.pdf")
                plt.close()
            np.asarray(mem_loss).tofile("./IDP_"+str(idp)+"_IDP_"+str(dim)+"_DIM_loss.csv",sep=',',format='%d')
            break #No need to repeat
        #End model optimization
    #End while model-not-converged loop
    return(model_LVM)
#-------------------------#
#--- Step 1: PCA elbow ---#
#-------------------------#
#-------------------------------------------------------#
# Function: step1_PCA(...)                              #
# Desct:    This function uses the PCA to find initially#
#           a latent dimension.                         #
# Param:    design_raw      Raw design matrix           #
#           plotResults     Flag for plot creation      #
# Return:   nr_latent dimesions                         #
#-------------------------------------------------------#
def step1_PCA(design_raw, explanationTH=0.9, doPlot=True):
    #-------------------------#
    #--- Plot system infos ---#
    #-------------------------#
    print("- Step 1: PCA based latent dimension definition")
    print("          design: [%d x %d]" % (design_raw.shape[0],design_raw.shape[1]))
    print("          Explanation threshold: %f" % (explanationTH*100))
    print("          Plot results: %d" % doPlot)
    #------------------------#
    #--- Standartize data ---#
    #------------------------#
    print("          Standartize data...")
    scaler = preprocessing.StandardScaler().fit(design_raw)     #Create and train scaler
    design = scaler.transform(design_raw)                       #Scale data
    #--------------#
    #--- Do PCA ---#
    #--------------#
    print("          Do PCA...")
    pca_model = PCA()       #Create PCA instance
    pca_model.fit(design)   #Do PCA
    explainedVariance = pca_model.explained_variance_ratio_ #Percent of variance explained per component
    latentDim = np.where(np.cumsum(pca_model.explained_variance_ratio_)>explanationTH)[0][0] #Get first element above expl. TH
    np.savetxt( "./step1_PCA_latentDim.csv", 
                np.array((explanationTH,latentDim)).reshape((1,2)),
                header="varTH,latentDim",
                delimiter=',')
    #-------------------#
    #--- Do plotting ---#
    #-------------------#
    if(doPlot):
        plt.figure()
        plt.plot(pca_model.explained_variance_ratio_, 
                    linewidth=2.0, 
                    label="Explained Variance")   #Plot explained ratio
        plt.plot([latentDim,latentDim],[0,np.max(explainedVariance)], 
                    linewidth=2.0, c='r',
                    label="Chosed Latent Dimension")
        plt.title("PCA Latent Dimension Identification (" + str(explanationTH*100) + " % explained)")
        plt.xlabel('Latent Dimension')
        plt.ylabel('Explained Variance')
        plt.legend(fontsize = 'x-small')
        plt.savefig("./step1_PCA.pdf")
        plt.close()
    #-------------------------------#
    #--- Return latent dimension ---#
    #-------------------------------#
    return int(latentDim)       #Retuirn estimated latent dimension
#----------------------------#
#--- Step 2: IDP analysis ---#
#----------------------------#
def step2_bGPLVM_IDP(   design_raw,    
                        PCAdim, 
                        IDPRange, 
                        steps = None,
                        stepsize=10,
                        min_step_inc=1e-3,
                        IDP_LL_TH=0.9, iterations= 10000, doPlot=True):
    print("- Step 2: Bayes GP-LVM IDP analysis")
    print("          Use PCA dim %d" % PCAdim)
    print("          IDP values to try: %d " % len(IDPRange))
    print("          IDP normalization TH: %f " % IDP_LL_TH)
    print("          Plot results: %d" % doPlot)
    if(steps != None):
        print("          Activated step-wise optimization with %d steps" % steps)
        print("          Abort if step increment is below: %f percent" % min_step_inc)
    #------------------------#
    #--- Standartize data ---#
    #------------------------#
    print("          Standartize data...")
    scaler = preprocessing.StandardScaler().fit(design_raw)     #Create and train scaler
    design = scaler.transform(design_raw)                       #Scale data
    #---------------------------#
    #--- Do GP-LVM modelling ---#
    #---------------------------#
    logLikMemory = np.zeros(len(IDPRange))  #Memory for estimated marginal log likelihood values
    looper=0    #Looping variable
    for idp in IDPRange:
        print("          Do bgplvm with %d IDP" % idp)
        model_LVM = model_BGPLVM(design,PCAdim,idp,iterations,steps,stepsize,min_step_inc,doPlot)
        #--- Store results ---#
        logLikMemory[looper]=model_LVM.log_likelihood()[0,:]    #Get log likelihood
        looper = looper +1
    #-----------------------------#
    #--- Calculate optimal IDP ---#
    #-----------------------------#
    normalized_LL = (logLikMemory - np.min(logLikMemory))/(np.max(logLikMemory)-np.min(logLikMemory)) #Normalize log L memory
    IDP_index = np.where(normalized_LL > IDP_LL_TH)[0][0]
    IDP_chosen=IDPRange[IDP_index]
    print("Chosen IDP %d " % IDP_chosen)
    #---------------------#
    #--- Store results ---#
    #---------------------#
    array_IDPRange = np.array(IDPRange).reshape(1,len(IDPRange))
    memory_store = np.concatenate(  (array_IDPRange,
                                    logLikMemory.reshape(1,len(IDPRange)),
                                    normalized_LL.reshape(1,len(IDPRange)))
                                )
    np.savetxt( "./step2_bGPLVM_mLL_memory.csv",    #Store marginal log likelihood memory
                memory_store,
                delimiter=',')
    #------------------#
    #--- Plot stuff ---#
    #------------------#
    if(doPlot):
        plt.figure()
        plt.plot(   IDPRange,normalized_LL, 
                    linewidth=2.0,
                    label="Normalized Marginal log. Likelihood")
        plt.plot([IDP_chosen,IDP_chosen],[0,1], 
                    linewidth=2.0, c='r',
                    label="Chosen Inducing Points")
        plt.title("bGPLVM IDP Identification (" + str(PCAdim) + " PCA dim)")
        plt.xlabel('Inducing Points')
        plt.ylabel('Normalized Marginal log. Likelihood')
        plt.legend(fontsize = 'x-small')
        plt.savefig("./step2_bGPLVM_IDP.pdf")
        plt.close()
    #--------------------#
    #--- Return stuff ---#
    #--------------------#
    np.asarray(IDP_chosen).tofile("./optModel_bgp_nrInd.csv",sep=',',format='%d')
    #np.savetxt( "./optModel_bgp_nrInd.csv",np.atleast_1d(np.array(IDP_chosen)), delimiter=',')
    return IDP_chosen
#---------------------------------------#
#--- Step 3: latent Dim optimization ---#
#---------------------------------------#
def step3_bGPLVM_latentDim( design_raw, 
                            IDP, 
                            lDimRange,  
                            steps = None,
                            stepsize=10,
                            min_step_inc=1e-3,
                            iterations= 10000, doPlot=True):
    print("- Step 3: Bayes GP-LVM latent dimension analysis")
    print("          Use IDP: %d" % IDP)
    print("          Latent Dim values to try: %d " % len(lDimRange))
    print("          Plot results: %d" % doPlot)
    if(steps != None):
        print("          Activated step-wise optimization with %d steps" % steps)
        print("          Abort if step increment is below: %f percent" % min_step_inc)
    #------------------------#
    #--- Standartize data ---#
    #------------------------#
    print("          Standartize data...")
    scaler = preprocessing.StandardScaler().fit(design_raw)     #Create and train scaler
    design = scaler.transform(design_raw)                       #Scale dat 
    #---------------------------#
    #--- Do GP-LVM modelling ---#
    #---------------------------#
    logLikMemory = np.zeros(len(lDimRange))  #Memory for estimated marginal log likelihood values
    looper=0    #Looping variable
    for latentDim in lDimRange:
        print("          Do bgplvm with %d latent Dimesions" % latentDim)
        model_LVM = model_BGPLVM(design,latentDim,IDP,iterations,steps,stepsize,min_step_inc,doPlot)
        logLikMemory[looper]=model_LVM.log_likelihood()[0,:]    #Get log likelihood
        looper = looper +1
    #-------------------------#
    #--- Get optimal model ---#
    #-------------------------#
    index_optimal_model = np.argmax(logLikMemory)
    optimal_model_dimension = int(lDimRange[index_optimal_model])
    print("Maximum model marginal log. likelihood found at %d" % optimal_model_dimension)
    #---------------------#
    #--- Store results ---#
    #---------------------##
    array_lDimRange = np.array(lDimRange).reshape(1,len(lDimRange))
    memory_store = np.concatenate(( array_lDimRange,
                                    logLikMemory.reshape(1,len(lDimRange)))
                                )
    np.savetxt( "./step3_bGPLVM_mLL_memory.csv",    #Store marginal log likelihood memory
                memory_store,
                delimiter=',')
    #------------------#
    #--- Plot stuff ---#
    #------------------#
    if(doPlot):
        plt.figure()
        plt.plot(   lDimRange,logLikMemory, 
                    linewidth=2.0,
                    label="Marginal log. Likelihood")
        plt.plot([optimal_model_dimension,optimal_model_dimension],[np.min(logLikMemory),np.max(logLikMemory)], 
                    linewidth=2.0, c='r',
                    label="Chosen Latent Dimension")
        plt.title("bGPLVM Latebnt Dimension Identification")
        plt.xlabel('Latent Dimension')
        plt.ylabel('Marginal log. Likelihood')
        plt.legend(fontsize = 'x-small')
        plt.savefig("./step3_bGPLVM_lDim.pdf")
        plt.close()
    #----------------------------------#
    #--- Return estimated dimension ---#
    #----------------------------------#
    np.asarray(optimal_model_dimension).tofile("./optModel_bgp_lDim.csv",sep=',',format='%d')
    #np.savetxt( "./optModel_bgp_lDim.csv",np.atleast_1d(np.array(optimal_model_dimension)), delimiter=',')
    return optimal_model_dimension
