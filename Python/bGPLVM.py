import GPy      			                #The GPy project
import datetime                                         #For printing sytem time
from sklearn import preprocessing                       #Data preprocessing
import numpy as np			                #You should know that...
from sklearn.model_selection import train_test_split    #Split functionality
from GPData import GPData                               #Create GP data structures
import matplotlib.pyplot as plt                         #To plot stuff
#----------------------------#
#--- bGPLVM derived class ---#
#----------------------------#
class bGPLVM:
    #---------------------------------------------------#
    # Name: Constructor                                 #
    # Descr: The constructor loads the bGPLVM model and #
    #       trains the scaler.                          #
    # Param: see below                                  #
    # Return: -                                         #
    #---------------------------------------------------#
    def __init__(self, path_Data, path_latent, path_Model, path_faulty, path_inv_Selection, nrInd, nrLD, imgDim, name="mymodel"):
        self.modelName=name                         #Name of this model
        self.prefix = "bGPLVM ["+name+"]: "      #Used for printing
        self.Print("Init bGPLVM datastructures...")
        #----------------------------------#
        #--- Load data from constructor ---#
        #----------------------------------#
        self.path_Model = path_Model    #Path to *.npy model datastructure
        self.nr_inducingPTS = nrInd     #Number of inducing variables
        self.nr_LD = nrLD               #Number of used latent dimensions
        self.imageDimensions = imgDim   #Dimension for image reshaping
        #------------------------------#
        #--- Set data datastructure ---#
        #------------------------------#
        if(path_latent==""):
            self.Print("No latent data")
            self.Data_latent    = 0
        else:
            self.Data_latent    = GPData(path_latent,   path_inv_Selection, path_faulty, "Features")
        self.Data_full      = GPData(path_Data,     "",                 path_faulty, "Images")
        #------------------#
        #--- Load model ---#
        #------------------#
        self.Print("Load bGPLVM data")
        self.model = GPy.models.BayesianGPLVM(  Y = self.Data_full.design,          #Used for kernel matrix
                                                input_dim = self.nr_LD,             #Number of latent dimensions used
                                                num_inducing = self.nr_inducingPTS, #Number of used inducing pts.
                                                initialize = True)
        self.Print("Initialize bGPLVM parameters")
        self.model[:] = np.load(self.path_Model)        #Load trained model
        self.model.initialize_parameter()
        #---------------------#
        #--- Print summary ---#
        #---------------------#
        print("||=====================||")
        print("||=== Model Summary ===||")
        print("||=====================||")
        print("|| Name: "               + self.modelName)
        print("|| Data path: "          + self.Data_full.path_Data)
        print("|| Data latent: "        + self.Data_latent.path_Data)
        print("|| Model path: "         + self.path_Model)
        print("|| #ind Pts: "           + str(self.nr_inducingPTS))
        print("|| #latent Dim: "        + str(self.nr_LD))
        print("|| Rescaling factors "   +str(self.imageDimensions))
    #---------------------------------------------------#
    # Name: print(...)                                  #
    # Descr: The print function is used to print a given#
    #       statement including a prefic.               #
    # Param: x                  A string to be print    #
    # Return: -                                         #
    #---------------------------------------------------#
    def Print(self,x):
        now = datetime.datetime.now()
        TIME=now.strftime("(%Y-%m-%d %H:%M:%S) ")
        print(TIME+self.prefix + x)
    #---------------------------------------------------#
    # Name: plotVarHeatmaps()                           #
    # Descr: Plots image heatmaps by re-projecting the  #
    #       latent space into the image space.          #
    # Param: -                                          #
    # Return: -                                         #
    #---------------------------------------------------#
    def plotVarHeatmaps(self, prefix="",pltText="F", transpose=False):
        self.Print("Estimating variance based heatmaps")
        #--- Get latent space data ---#
        projection_test, projection_var = self.model.infer_newX(self.Data_full.design)
        #(We do not have to predict -> for clearity only)
        projection = projection_test.mean #Get expectation in latent space
        #-------------------------------------#
        #--- Start creating visualizations ---#
        #-------------------------------------#
        image_dim = self.imageDimensions                        #Get variable
        display_grid = np.zeros((projection.shape[0] * image_dim[0], image_dim[1]))            #Create Image for features
        looper_grid=0                                           #Looper variable
        VarMemory = np.zeros((self.nr_LD,np.prod(image_dim)))   #Memory for variance memory
        for i in range(0,projection.shape[1]):                  #For all dimensions
            feature = np.zeros((1,projection.shape[1]))         #Init memory
            for k in range(0,projection.shape[1]):              #For all dimensions, estimate mean value
                feature[0,k] = np.mean(projection[:,k])         #(get mean value)
            mx_val = np.max(projection[:,i])                    #Get maximum of chosen dimension
            mn_val = np.min(projection[:,i])                    #Get minimum of chosen dimension
            #--- reproject data ---#
            featureVar_memory = np.zeros((self.Data_full.design.shape[1], projection.shape[0]))   #Memory for variance
            looper=0                                                    #Looper variable
            #--- Now we use real sample data ---#
            for k in range(0,projection.shape[0]): #For all samples
                f_vector = feature                                      #Get mean feature
                f_vector[0,i]=projection[k,i]                           #Replace chosen dimension with value
                img_mean, img_var = self.model.predict(f_vector)        #Reprooject to image space
                featureVar_memory[:,looper]=img_mean                    #Store reprojected and added value
                looper=looper+1                                         #Increment looper
            #--- Store variance ---#
            VARImg = np.var(featureVar_memory, axis=1)                                  #Estimate variance for all pixels in image
            VarMemory[i,:]=VARImg
            I = np.reshape(VARImg, (image_dim[0],image_dim[1]))                         #Reshape variance image
            I = (I-np.min(I))/(np.max(I)-np.min(I))                                     #Normalize variance image
            display_grid[(looper_grid*image_dim[0]):((looper_grid+1)*image_dim[0]),:]=I #Plance variance image in grid
            #--- Store as an image ---#
            plt.figure()
            if(transpose):
                plt.imshow(np.transpose(I))               #Plot image
            else:
                plt.imshow(I)               #Plot image
            plt.axis('off')             #Remove axes
            plt.text(5,30, pltText+str(looper_grid),fontsize=40,color='red')
            plt.savefig(prefix+str(looper_grid)+".png")                       #Save variance image as png file
            plt.savefig(prefix+str(looper_grid)+"F.pdf")
            np.savetxt( prefix+str(looper_grid)+"_raw.csv", VARImg, delimiter=',') #Save variance vector as csv file
            np.savetxt( prefix+str(looper_grid)+".csv", I, delimiter=',') #Save variance vector as csv file
            looper_grid=looper_grid+1   #Increment looper
            plt.close()
