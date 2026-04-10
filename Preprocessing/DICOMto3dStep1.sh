#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

#  DICOMto3d.sh
#  
#
#  Created by Dan on 8/12/15.
#
# Converts DICOM files to NIFTI format (readable by AFNI)

# set up variables for preprocessing
# the subj should be the same as used for the surfaces directory
#set subj = (Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub17 Sub18 Sub19 Sub20 Sub21)
set subj = (Sub5 Sub8)

# define the MR data folder
set dataDir = <YOUR_DATA_DIR> # e.g., ~/DataMRI

# assign input directory name
#set inputDir = DICOM

# assign output directory name
set outputDir = NIFTI

foreach subj ($subj)

	mkdir $dataDir/${subj}/$outputDir

	cd $dataDir/$subj/$inputDir

	# convert DICOM to NIFTI format
    mcverter -o $dataDir/${subj}/$outputDir -f nifti -v -d -n ./

	cd $dataDir/${subj}/$outputDir
    
	#rm *.txt
	#rm *localizer
	# this must be changed according to run numbers
	# renames the files to be in consistent format
	# VERIFY THESE ARE THE CORRECT INDEXES FOR EACH SUBJECT
    mv *t1* ${subj}.MPRAGE.nii
    mv *003* ${subj}.run1.EPI.nii     
    mv *004* ${subj}.run2.EPI.nii
    mv *005* ${subj}.run3.EPI.nii
	mv *006* ${subj}.run4.EPI.nii
	mv *007* ${subj}.run5.EPI.nii
	mv *008* ${subj}.run6.EPI.nii
	mv *009* ${subj}.run7.EPI.nii
	mv *010* ${subj}.run8.EPI.nii

end

