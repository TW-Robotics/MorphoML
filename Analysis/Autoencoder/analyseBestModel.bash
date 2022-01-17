# Thius script controls the cAE best model analysis. It is based on the 
# result of the cAEAnalysis.R script result (these fancy csv file).
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at
#!/bin/bash
set -e #Abort if 
#--- Basic infos ---#
path_cAE="../../Autoencoder" #Path to cAE data
#img_size='96 224' #Size of the training images
#-------------------------------------#
#--- Check if analysis file exists ---#
#-------------------------------------#
if [ -f "./bestModel.Ethiopia.csv" ]
then
    echo "Found best model file - can proceed"
else
    echo "Please run cAEAnalysis.R before running the visualization"
fi
cat bestModel.Ethiopia.csv > best.models.csv
cat bestModel.Uganda.csv >> best.models.csv
#--------------------------------------------#
#--- Create symbolic link magic for Keras ---#
#--------------------------------------------#
rm -rf data
mkdir data
cd data
mkdir Ethiopia
mkdir Uganda
cd Ethiopia
ln -s ../../../../preProc/Ethiopia
cd ../Uganda
ln -s ../../../../preProc/Uganda_fin Uganda
cd ../../
#-------------------------#
#--- Sample from model ---#
#-------------------------#
cat best.models.csv | while read line
do
	echo "Process $line"
	POP=$(echo $line | awk -F"/" '{print $2}') #Get population
	CODE_SIZE=$(echo $line | awk -F"/" '{print $3}') #Get code size
	../../Python/VE_DL/bin/python samples_cAE.py ./data/$POP "$path_cAE"/"$line" 96 224 &> sample.log #Get heatmaps
	../../Python/VE_DL/bin/python Heatmap_pval.py ./ &> pval.log #Get Sykacek's p val map
	../../Python/VE/bin/python ../../Python/visFeatureSelector.py ./Heatmaps/
	#--- Move folder ---#
	mv *.log Heatmaps/.
	mv Heatmaps "$POP"
	mv selection.csv "$POP"/.
done
