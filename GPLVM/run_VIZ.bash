# This script runs the visualization and p value calculation
# for GPLVM features.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>
#!/bin/bash
#--- For Ethiopia ---#
folder="./Ethiopia"
../Python/VE/bin/python3 ./FeatureVariance.py $folder ../preProc/Ethiopia_img.csv 96 224
mv Heatmaps $folder/.
ln -s ./Ethiopia/Heatmaps .
../Python/VE/bin/python3 ./GPLVM_pval.py 96 224
rm ./Heatmaps
#--- For Uganda ---#
folder="./Uganda"
../Python/VE/bin/python3 ./FeatureVariance.py $folder ../preProc/Uganda_fin_img.csv 96 224
mv Heatmaps $folder/.
ln -s ./Uganda/Heatmaps .
../Python/VE/bin/python3 ./GPLVM_pval.py 96 224
rm ./Heatmaps
