# GPLVM_pval.py estiamtes the p-val images for GP-LVM. 
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2020 <wilfried.woeber@technikum-wien.at>
import matplotlib
matplotlib.use('Agg')
import sys                  #System stuff
import numpy as np          #You should know that
import matplotlib.pyplot as plt #We aim to plot something...
import os                   #For bash stuff
import cv2
import sys
kernel_width = 5 	#Width and height of Gaussian kernel
kernel_sigma = 0 	#Default, estimated from width
#-----------------#
#--- functions ---#
#-----------------#
def mySmoother(img):
    img = img.copy()    #Get a deep copy of the image
    img = cv2.GaussianBlur(img,(kernel_width,kernel_width),kernel_sigma)#Smooth image
    return(img)
def randomizeImage(img):
    img = img.copy()
    img_vector = img.reshape((img.shape[0]*img.shape[1]),1)
    index = np.random.choice(range(0,np.prod(img.shape)),np.prod(img.shape),replace=False)
    random_image = np.zeros((np.prod(img.shape),1))
    random_image[index]=img_vector
    random_image=random_image.reshape(img.shape)
    return(random_image)
def normalize(img):
    img=(img-np.min(img))/(np.max(img)-np.min(img))
    return(img)
def getPimage(img,k):
    img_dim = img.shape
    memory = np.zeros((img_dim[0],img_dim[1],k))
    for looper in range(0,k):
        memory[:,:,looper]=mySmoother(randomizeImage(img))
    print("Check random images")
    counter = np.zeros(img_dim)
    smoothed_LRP = mySmoother(img)
    for R in range(0,img_dim[0]):
        for C in range(0,img_dim[1]):
            random_vector = memory[R,C,:]
            counter[R,C] = np.sum(
                                    random_vector > smoothed_LRP[R,C]
                                    )
    #--- normalize image ---#
    counter_norm = counter/float(k)
    return(counter_norm)
def addBorder(img):
    #--- add black border ---#
    for i in range(0,int(kernel_width/2)):
        cv2.rectangle(  img,   #Destination=source
                    (0+i,0+i),          #Top left
                    (img.shape[1]-1-i,img.shape[0]-1-i),#Bottom right
                    (0),            #Color
                    1) #Thickness of lines
    return(img)
if __name__ == "__main__":
    sys.path.append('../Python/')  #Add path to project library
    from bGPLVM import bGPLVM   #GPy wrapper
    #--- global infos ---#
    img_dim = (int(sys.argv[1]), int(sys.argv[2])) #(91,224)
    k=1000			#Number of iterations
    alpha = 0.001		#Alpha threshold value
    #-------------------------------#
    #--- Create summarized plots ---#
    #-------------------------------#
    top_border=20
    font_size=18
    font_border=15
    img_rows=3*2
    img_cols=4
    plot_top_n=(img_rows,img_cols)
    #--- We get the number of features ---#
    #selection = range(0,49) #We ignore possible selection and take top 50
    nfiles=int(len([f for f in os.listdir("./Heatmaps")      if f.endswith('.csv') and os.path.isfile(os.path.join("./Heatmaps", f))])/2)
    selection = range(0,nfiles)
    print("Process %d files"%nfiles)
    #--- Do processing ---#    
    for i in range(0,len(selection)):
        img=np.loadtxt('./Heatmaps/'+str(selection[i])+'.csv',delimiter=',')
        #arr[x_looper].imshow(np.transpose(img),cmap='jet')
        #arr[x_looper].text(5,30, "F"+str(selection[i]),fontsize=20,color='red')
        #arr[x_looper].axis('off')
        plt.close()
        #if(img.shape[0] != img.shape[1]):
        img = cv2.copyMakeBorder(np.transpose(img), top_border, 0, 0, 0, cv2.BORDER_CONSTANT, None, 0)
        plt.imshow(img,cmap='jet')
        plt.text(5,font_border, "F"+str(selection[i]),fontsize=font_size,color='red')
        plt.axis('off')
        plt.savefig("./Heatmaps/HM_"+str(i)+".pdf",bbox_inches = 'tight',pad_inches = 0)
        plt.savefig("./Heatmaps/HM_"+str(i)+".png",bbox_inches = 'tight',pad_inches = 0)
        #x_looper=x_looper+1
        #if(x_looper >= plot_top_n[1]):
        #    x_looper=0
        #    y_looper=y_looper+1
        #    plt.subplots_adjust(wspace=0, hspace=0, left=0, right=1, bottom=0, top=1)
        #    plt.savefig("./Heatmaps/row_"+str(y_looper)+".pdf",bbox_inches = 'tight',pad_inches = 0)
        #    os.system("pdfcrop --margins '0 0 0 0' --clip ./Heatmaps/row_"+str(y_looper)+".pdf ./Heatmaps/row_"+str(y_looper)+".pdf")
        #    f, arr = plt.subplots(1,img_cols)  #Create 'grid' for plot
    #x_looper=0
    #y_looper=0
    for i in range(0,len(selection)):
        img=np.transpose(np.loadtxt('./Heatmaps/'+str(selection[i])+'.csv',delimiter=','))
        pImg = getPimage(img,k)   #Get the p value image
        mask = (pImg<alpha).astype(np.int8)
        res = cv2.bitwise_and(img,img,mask = mask)
        res_raw = res.copy()
        #res_raw = np.transpose(res_raw)
        #arr[x_looper].imshow(addBorder(res),cmap='jet')
        #arr[x_looper].text(5,30, "F"+str(selection[i])+" MSK",fontsize=20,color='red')
        #arr[x_looper].axis('off')
        plt.close()
        res = cv2.copyMakeBorder(addBorder(res), top_border, 0, 0, 0, cv2.BORDER_CONSTANT, None, 0)
        plt.imshow(res,cmap='jet')
        plt.text(5,font_border, "F"+str(selection[i])+" MSK",fontsize=font_size,color='red')
        plt.axis('off')
        plt.savefig("./Heatmaps/HM_"+str(i)+"_p.pdf",bbox_inches = 'tight',pad_inches = 0)
        plt.savefig("./Heatmaps/HM_"+str(i)+"_p.png",bbox_inches = 'tight',pad_inches = 0)
        np.savetxt( "./Heatmaps/HM_"+str(i)+"_p.csv", res_raw) #Store raw data
