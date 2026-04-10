#!/bin/tcsh - xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

#  FreesurferRecon.sh
#  
#
#  Created by Dan on 4/29/15.
# 
# Does surface reconstruction to create surfaces for freesurfer (TAKES ~6 HRS ON MOST MACHINES)

set subj = Sub16

set dataDir = <YOUR_DATA_DIR> # e.g., ~/DataMRI

# N.B. the -openmp option allocates the number of cores to use for processing  

foreach subj in ($subj)
    cd $dataDir/$subj/NIFTI/
    recon-all \
        -i $subj.MPRAGE.nii \
        -s $subj \
        -all \
		-openmp 24
end
