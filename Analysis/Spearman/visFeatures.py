# This script uses the results from spearmans rank correlation and 
# creates a visualization for all extracted features.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>
import pandas as pd
import numpy as np
import os
import matplotlib.pyplot as plt
os.system("rm -rf plots;mkdir plots")
#---------------------------#
#--- Load optimal models ---#
#---------------------------#
best_cAE_Ethiopia = str(np.loadtxt("../Autoencoder/bestModel.Ethiopia.csv", dtype=str))
best_cAE_Uganda   = str(np.loadtxt("../Autoencoder/bestModel.Uganda.csv", dtype=str))
#-------------------------------------------#
#--- Global information to load the data ---#
#-------------------------------------------#
data={  'Name': ['Ethiopia','Uganda','Ethiopia','Uganda'],
        'Model':['GPLVM','GPLVM','AE','AE'],
        'pathFeatures': ['../../GPLVM/Ethiopia/optModel_bgp_features_train.csv',
                         '../../GPLVM/Uganda/optModel_bgp_features_train.csv',
                         '../../'+best_cAE_Ethiopia+"/code.csv",
                         '../../'+best_cAE_Uganda+"/code.csv"],
        'pathSelection':['../../GPLVM/Ethiopia/selection.csv',
                         '../../GPLVM/Uganda/selection.csv',
                         '../Autoencoder/Ethiopia/selection.csv',
                         '../Autoencoder/Uganda/selection.csv'],
        'pathHeatmap':['../../GPLVM/Ethiopia/Heatmaps/',
                       '../../GPLVM/Uganda/Heatmaps/',
                       '../Autoencoder/Ethiopia/',
                       '../Autoencoder/Uganda/'],
        'pathClasses':['../../preProc/Ethiopia_classes.csv',
                       '../../preProc/Uganda_fin_classes.csv',
                       '../../preProc/Ethiopia_classes.csv',
                       '../../preProc/Uganda_fin_classes.csv'],
        'alpha':[0.01,0.01, #GPLVM
                0.01,0.01     #cAE
                ]
            } #Define list for panda frame
basePath_pvals="./data/" #Basepath to estimated p values
#--------------------------------#
#--- Create data to loop over ---#
#--------------------------------#
DF=pd.DataFrame(data) #Get a data frame
#------------------------------------#
#--- Loop over all created models ---#
#------------------------------------#
for DF_iterator in range(0,DF.shape[0]):
    LST = DF.loc[DF_iterator]
    print("Process model %s from dataset %s"%(LST.Model,LST.Name))
    #-----------------------#
    #--- Load parameters ---#
    #-----------------------#
    #features_full=np.loadtxt(LST.pathFeatures,delimiter=',') #Load features
    selection=np.sort(np.loadtxt(LST.pathSelection,delimiter=',',dtype=int)) #Load selection
    #features=features_full[:,selection] #Get selected features
    p_vals=np.loadtxt(basePath_pvals+LST.Name+"_"+LST.Model+".csv") #Load spearmanns rank correlation test p values
    classes=np.genfromtxt(LST.pathClasses,dtype='str') #Get classes
    #---------------------#
    #--- Do processing ---#
    #---------------------#
    alpha = LST.alpha #Get custom alpha
    os.system("rm *.pdf")
    plt.close()
    pdf_counter=0
    for INDEX in range(0,len(selection)):
        #-------------------------#
        #--- Check alpha value ---#
        #-------------------------#
        #if(not any(p_vals[INDEX,] < alpha)): #If this is commented - we show all features
        #    continue #If all p vals are above alpha, we ignore it for plotting
        pdf_counter+=1
        print("Sum of p<alpha: %d"% np.sum(any(p_vals[INDEX,] < alpha)))
        print(p_vals[INDEX,])
        #--------------------#
        #--- Create plots ---#
        #--------------------#
        fig, (ax1, ax2) = plt.subplots(1, 2)
        fig.suptitle('p Value Analysis for Feature '+str(selection[INDEX]),fontsize=20)
        #Load the heatmap
        heatmap=np.transpose(np.loadtxt(LST.pathHeatmap+"HM_"+str(selection[INDEX])+"_p.csv"))
        #Heatmap handling
        ax1.imshow(heatmap,cmap='jet')
        ax1.axis('off')
        #plt.savefig("test.png",bbox_inches = 'tight',pad_inches = 0)
        #plt.close()
        #Barplot handling
        height = 1.-p_vals[INDEX,]
        bar_names = classes
        y_pos = np.arange(len(bar_names))
        ax2.barh(y_pos, height)
        ax2.set_yticks(y_pos)
        ax2.set_yticklabels(bar_names)
        ax2.set_xlabel("1-p value")
        ax2.set_xlim([0,1])
        #fig.savefig(str(INDEX)+".pdf",bbox_inches = 'tight',pad_inches = 0)
        fig.savefig(str(INDEX)+".pdf")
        plt.close()
        #--- Abort if we want just n samples ---#
        abortAt=15
        if( (abortAt>0) and (pdf_counter >= abortAt)):
            break
    #--- Build the summarized pdf ---#
    row_elements=5.
    col_elements=int(np.ceil(float(pdf_counter)/row_elements))
    os.system(  "pdfjam $(ls | grep pdf | sort -n | tr '\n' ' ') --nup "+
                str(int(row_elements))+
                "x"+
                str(col_elements)+
                " --outfile "+LST.Name+"_"+LST.Model+".pdf")
    os.system(  "pdfcrop --margins '0 0 0 0' --clip "+
                LST.Name+"_"+LST.Model+".pdf "+
                LST.Name+"_"+LST.Model+".pdf")
    os.system("mv "+LST.Name+"_"+LST.Model+".pdf plots/.")
    os.system("rm *.pdf")
