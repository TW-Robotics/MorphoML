# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Woeber 2021 <wilfried.woeber@technikum-wien.at>
#!/bin/bash
set -e
populations=(./data/Ethiopia ./data/Uganda) #Possible populations
img_res=('96 224' '96 224') #Image resolutions
codeSize=(2 5 10 25 50 75 100 125 150 200)	#Same as GPLVM
epochs=1000 #Number of epochs used for cAE training
#--------------------------#
#--- Create data folder ---#
#--------------------------#
for ((ITERATION = 1 ; ITERATION <= 5 ; ITERATION++))
do
	mkdir data
	cd data
	mkdir Ethiopia
	mkdir Uganda
	cd Ethiopia
	ln -s ../../../preProc/Ethiopia .
	cd ../Uganda
	ln -s ../../../preProc/Uganda_fin Uganda
	cd ../../
	#--------------------------#
	#--- Do main processing ---#
	#--------------------------#
	looper=0
	for p in "${populations[@]}"
	do
	    #--- Train the cAE set ---#
	    for i in "${codeSize[@]}"	#Loop over code sizes
	    do
	    	../Python/VE_DL/bin/python cAE.py $p $epochs $i ${img_res[$looper]} &> logfile_$i.log
	    	#--- Move data ---#
	    	mkdir $i
	    	mv  ./my_model $i/.
	    	mv  ./reconstruction $i/.
	    	mv *.csv $i/.
	    	mv *.png $i/.
	    	sleep 10
	    done
	    #--- move all files ---#
	    FOLDER_NAME=$(basename $p) #Get population name
	    #mv Heatmaps ./data/$FOLDER_NAME/.
	    #mv bestModel.csv ./data/$FOLDER_NAME/.
	    mv *.log ./data/$FOLDER_NAME/.
	    for i in "${codeSize[@]}"	#Loop over code sizes
	    do
	        mv $i ./data/$FOLDER_NAME/.	#Move trained cAE model and results
	    done
	    #--- Update system ---#
	    looper=$(($looper + 1))
	done
	mv data IT_$ITERATION
done
