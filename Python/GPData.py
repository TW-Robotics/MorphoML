import GPy      			                #The GPy project
import datetime                                         #For printing sytem time
from sklearn import preprocessing                       #Data preprocessing
import numpy as np			                #You should know that...
from sklearn.model_selection import train_test_split    #Split functionality
#-------------------------------#
#--- Class for data handling ---#
#-------------------------------#
class GPData:
    #---------------------------------------------------#
    # Name: Constructor                                 #
    # Descr: Inits datastructures and gives sampling    #
    #       ability.                                    #
    # Param: pathData       Path to the design data     #
    # Return: -                                         #
    #---------------------------------------------------#
    def __init__(self, path_Data, path_inv_Selection="", path_faulty="", name="myDataHandler", scale=True):
        self.instanceName = name
        self.prefix = "GPData ["+self.instanceName+"]: "
        self.Print("Init GPData instance...")
        #--- Set variables ---#
        self.path_Data = path_Data                  #Path to training data
        self.path_invSelec = path_inv_Selection     #Inverse selection *.csv file = dimensions to ignore
        self.path_faulty = path_faulty              #Faulty elements 
        #-----------------#
        #--- Load data ---#
        #-----------------#
        self.design_Raw	= np.loadtxt(  open(self.path_Data),delimiter=",")      #Load data from file
        if(scale):
            self.Print("Train scaler...")
            self.scaler 	= preprocessing.StandardScaler().fit(self.design_Raw)   #Train scaler
            self.design 	= self.scaler.transform(self.design_Raw)                #Transform data
        else:
            self.Print("No scaler...")
            self.scaler 	= 0                 #No scaler
            self.design 	= self.design_Raw   #Use Raw data
        #-------------------------------#
        #--- Load feature exclustion ---#
        #-------------------------------#
        if(self.path_invSelec == ""):
            self.index_selection_inv=np.array(())
        else:
            self.index_selection_inv=np.genfromtxt(self.path_invSelec, delimiter=" ", dtype=np.int32) #Get feature to exclude
            self.index_selection_inv=self.index_selection_inv #Get feature to exclude
            if(self.index_selection_inv.shape == () ):      #Check if single feature to exclude
                self.index_selection_inv=self.index_selection_inv.reshape((1,1))
        #----------------------------#
        #--- Load faulty elements ---#
        #----------------------------#
        if(self.path_faulty == ""):
            self.index_faulty = np.array(())        #Init with empty array
        else:
            self.index_faulty = np.genfromtxt(self.path_faulty, delimiter=" ", dtype=np.int32)
            self.index_faulty = self.index_faulty
        #-------------------------#
        #--- Print system info ---#
        #-------------------------#
        self.Print("Loaded raw data ["+str(self.design_Raw.shape[0])+"x"+str(self.design_Raw.shape[1])+"]")
        self.Print("Found "+str(len(self.index_faulty))+ " faulty elements")
        self.Print(str(self.index_selection_inv))
        self.Print("Ignore "+str(len(self.index_selection_inv)) + " dimensions")
    #---------------------------------------------------#
    # Name: Print(x)                                    #
    # Descr: Prints x including metatdata               #
    # Param: x              A string                    #
    # Return: -                                         #
    #---------------------------------------------------#
    def Print(self,x):
        now = datetime.datetime.now()
        TIME=now.strftime("(%Y-%m-%d %H:%M:%S) ")
        print(TIME+self.prefix + x)
#    #---------------------------------------------------#
#    # Name: sample(x)                                   #
#    # Descr: Samples from data using x % for testing    #
#    #       (yeah I know,... but its Python conform...  #
#    # Param: x              Test percentage             #
#    # Return: -                                         #
#    #---------------------------------------------------#
#    def sample(self,split_Ratio, Y, normalize = False):
#        #-------------------------------#
#        #--- Exclude faulty elements ---#
#        #-------------------------------#
#        if(len(self.index_faulty) != 0):
#            self.Print("Exclude faulty elements")
#            self.X_train = np.delete(self.design, self.index_faulty, axis=0)
#            #--- Check if we have to remove faulty elements ---#
#            if( Y.shape[0] != self.X_train.shape[0]):
#                self.Print("Remove faulty elements from Y")
#                Y = np.delete(Y, self.index_faulty, axis=0)
#        else:
#            self.Print("No faulty elements")
#            self.X_train = self.design
#        #---------------------#
#        #--- Normalization ---#
#        #---------------------#
#        if(normalize):
#            self.Print("Do normalization")
#            X_min = np.min(self.X_train)
#            X_max = np.max(self.X_train)
#            self.X_train = (self.X_train-X_min)/(X_max-X_min)
#        self.X_train_Full = self.X_train
#        #--- We need the indices later, so I have to include it ---#
#        design_w_index = np.hstack((np.array((range(0,self.X_train.shape[0]))).reshape(self.X_train.shape[0],1),self.X_train))
#        self.Print("New design dimension : ["+str(design_w_index.shape[0])+"x"+str(design_w_index.shape[1])+"]")
#        self.Print("New Y dimension : ["+str(Y.shape[0])+"]")
#        #--------------------------#
#        #--- Sample using split ---#
#        #--------------------------#
#        self.X_train_w_indices, self.X_test_w_indices, self.y_train, self.y_test = train_test_split(design_w_index, Y,stratify=Y,test_size=split_Ratio)
#        #-----------------------------------#
#        #--- Prepare several sample sets ---#
#        #-----------------------------------#
#        self.index_Train= self.X_train_w_indices[:,0]
#        self.index_Test = self.X_test_w_indices[:,0]
#        self.X_train    = self.X_train_w_indices[:,1:self.X_train_w_indices.shape[1]]
#        self.X_test     = self.X_test_w_indices[:,1:self.X_test_w_indices.shape[1]]
#        if(len(self.index_selection_inv) != 0):
#            self.X_train_selection      = np.delete(self.X_train        , self.index_selection_inv, axis=1)
#            self.X_test_selection       = np.delete(self.X_test         , self.index_selection_inv, axis=1)
#            self.X_train_Full_selection = np.delete(self.X_train_Full   , self.index_selection_inv, axis=1)
#        else: 
#            self.X_train_selection    = self.X_train
#            self.X_test_selection     = self.X_test
#            self.X_train_Full_selection = self.X_train_Full
#        #-----------------------------#
#        #--- Print sampling result ---#
#        #-----------------------------#
#        self.Print("Dimension X_train: ["   +str(self.X_train.shape[0])     +"x"+str(self.X_train.shape[1])+"]")
#        self.Print("Dimension X_test: ["    +str(self.X_test.shape[0])      +"x"+str(self.X_test.shape[1])+"]")
#        self.Print("Dimension X_train_selection: [" +str(self.X_train_selection.shape[0])     +"x"+str(self.X_train_selection.shape[1])+"]")
#        self.Print("Dimension X_test_Selection: ["  +str(self.X_test_selection.shape[0])      +"x"+str(self.X_test_selection.shape[1])+"]")
