# This script runs the GPLVM optimization script.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>

#!/bin/bash
#----------------#
#--- Ethiopia ---#
#----------------#
mkdir Ethiopia
../Python/VE/bin/python3 getGPLVM.py ../preProc/Ethiopia_img.csv
mv *.csv Ethiopia/.
mv *.pdf Ethiopia/.
mv *.npy Ethiopia/.
#--------------#
#--- Uganda ---#
#--------------#
mkdir Uganda
../Python/VE/bin/python3 getGPLVM.py ../preProc/Uganda_fin_img.csv
mv *.csv Uganda/.
mv *.pdf Uganda/.
mv *.npy Uganda/.
#----------------------------------#
#--- Run the p-value generation ---#
#----------------------------------#
bash ./run_VIZ.bash
