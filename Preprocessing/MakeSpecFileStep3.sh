#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

#  MakeSpecFile.sh
#  
#
#  Created by Dan on 8/12/15.
#
# Makes a spec file that SUMA can read
# Generates SUMA folder in the freesurfer subject directory ($SUBJECTS_DIR)

set subj = (Sub5 Sub8)

foreach subj ($subj)

    cd $SUBJECTS_DIR/$subj
    @SUMA_Make_Spec_FS -sid $subj

end
