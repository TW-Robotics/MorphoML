# this script runs the feature selector for Uganda and EWthiopia.
#
# This code is available under a GPL v3.0 license and comes without
# any explicit or implicit warranty.
#
# (C) Wilfried Wöber 2021 <wilfried.woeber@technikum-wien.at>

#!/bin/bash
#----------------#
#--- Ethiopia ---#
#----------------#
../Python/VE/bin/python3 ../Python/visFeatureSelector.py Ethiopia/Heatmaps/
mv selection.csv Ethiopia/.
#--------------#
#--- Uganda ---#
#--------------#
../Python/VE/bin/python3 ../Python/visFeatureSelector.py Uganda/Heatmaps/
mv selection.csv Uganda/.
