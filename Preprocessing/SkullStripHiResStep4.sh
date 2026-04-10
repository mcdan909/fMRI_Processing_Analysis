#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

#  SkullStripHiRes.sh
#  
#
#  Created by Dan on 8/12/15.
#
# Removes the skull from the anatomical volume 

set subj = (Sub5 Sub8)

foreach subj ($subj)

    cd $SUBJECTS_DIR/$subj/SUMA

    echo; echo "==stripping skull for $subj"
	
	#Remove the skull
    3dSkullStrip \
    	-input ${subj}_SurfVol+orig 
    	-prefix ${subj}_NoSkull_SurfVol+orig

	# Extra options for Ubuntu for similar mac performance
	# 3dSkullStrip \
	# 	-prefix ${subj}_NoSkull_SurfVol+orig \
	# 	-input ${subj}_SurfVol+orig \
 #    	-ld 30 \
 #    	-shrink_fac_bot_lim .7 \
 #    	-no_use_edge \
 #    	-touchup \
 #    	-touchup \
 #    	-orig_vol

end
