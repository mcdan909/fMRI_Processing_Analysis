#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

# Aligns the anatomical and functional data in volume and surface space. Also pulls along default freesurfer parcellation

# Subs 3-5 completed 6 runs
# Subs 6,8-19 completed 8 runs

# TRY CENSORING SPIKY TIMEPOINTS INSTEAD OF EXCLUDING RUNS
# Sub3 has big spikes runs 5 & 6 (EXCLUDE)
# Sub4 has big spikes runs 1 & 2 (EXCLUDE)
# Sub5 has big spikes in runs 1, 3-6 (EXCLUDE)
# Sub8 has a lot of head motion in run 2 (EXCLUDE)
# Sub12 has a lot of head motion in run 8 (EXCLUDE)
# Sub19 has a lot of head motion in run 6 (EXCLUDE)

# Subject List
# Sub3 Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21

echo "== $0 starting"

# for quick commenting
if ( 0 ) then
endif

# set up variables for preprocessing
# the subj should be the same as used for the surfaces directory
#set subj = (Sub3 Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub17 Sub18 Sub19 Sub20 Sub21)
set subj = (Sub3 Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21)

# set master EPI run
set masterEPI = run1

# define the MR data folder
set dataDir = <YOUR_DATA_DIR> # e.g., ~/DataMRI

# assign input directory name
set inputDir = EPI

# assign output directory name
set outputDir = GLM

# change if the tcat option was used in preprocessFunctStep5
set funcFix = .warp.volreg

# do the loop for each subject
foreach subj ($subj)

    # verify that the results directory does not yet exist
    # break the loop if it does
    if ( -d $dataDir/$subj/$outputDir ) then
	   echo; echo output dir "$subj/$outputDir" already exists
	   exit
	endif

    # set current directory for output files
    set curDir = $dataDir/$subj/$inputDir

    # set directory for plots
    set resultsDir = $dataDir/$subj/$outputDir

    # create results and plot directories and go to results folder
    mkdir $resultsDir
    cd $curDir

    # "" at begining of preprocessing (start of this script)
    # easily changes the prefix if steps aren't included
    set curFix = ""

    # ================================== tcat ==================================
    # pull out reference EPI TR for alignment (same as used for motion correction)
    # AFNI gurus advise against the mean EPI approach due to loss of structure from averaging
    # If you used the tcat option to remove the 1st 2 TRs in preprocessFunctStep5, change the 
    # index from 4 to 2
    echo; echo "== extracting reference EPI volume"
    3dTcat \
        -prefix $subj.refEPIvol+orig \
        $subj.$masterEPI$funcFix+orig'[4]'

    # ================================= unifize ================================
    # also create a "normalized" version of the alignment EPI for easier EPI-ANAT alignment visualization
    # N.B. 3dUnifize is really designed for T1 images.  I adjust -Urad to account for the lower
    #      resolution EPI voxels.  But there is no garuntee that this will work "well".  However,
    #      I really just want a more uniform EPI image to judge the alignment of the EPI and ANAT,
    #      so if it works for that, then the details don't really matter.
    echo; echo "== unifizing EPI volume"
    3dUnifize \
        -prefix $subj.refEPIvol.uniform+orig \
        -Urad 6.1 \
        -GM \
        $subj.refEPIvol+orig

    # make a copy of the NoSkull_SurfVol+orig file from the SUMA folder
    3dcopy $SUBJECTS_DIR/$subj/SUMA/${subj}_NoSkull_SurfVol+orig $subj.surfvol+orig
    set curFix = $curFix.surfvol

    # ================================ allineate ===============================
    # surfvol to epi alignment
    # implementing a double-alignment: first pass is "coarse" (and potentially manual), second-pass is "fine"
    #
    # N.B. all alignments should be rigid-body, 6-parameter, linear alignment
    # N.B. If the following fails at the align_epi_anat.py stage, consider...
    #      - for failure at the 3dSkullStrip stage for the EPI, try -epi_strip 3dAutomask (e.g., helps with very smaller coverage of brain)
    #      - try -partial_coverage for smaller coverage
    #      - see -AddEdge for some additional information to compare alignment (see align_epi_anat.py -help)

    echo; echo "== starting coarse alignment (first-pass)"

    # if the default automatic coarse alignment is not working well (and you don't want to spend time tweaking the default parameters)
    # you can implement a manual coarse alignment using the NudgeDataset plugin of AFNI.  This code will create the file you want to
    # manually nudge (_nudged), open AFNI, wait until you nudge the dataset and close AFNI, and then continue along with the fine
    # pass alignment.

    # make a copy of the surfvol that you will manually nudge
    # 3dcopy $subj.surfvol+orig $subj.surfvol.nudged+orig.

    # setenv AFNI_DETACH NO; # don't let AFNI detach from terminal so we can nudge dataset before proceeding
    # echo; echo "*** manually nudge surfvol_nudged dataset in AFNI to be close to the $curfunc of one run.  close AFNI to continue ***"
    # afni
    # setenv AFNI_DETACH YES; # back to default

    # the following is the default "coarse" alignment.  It uses 3dAllineate to get the surfvol close enough to the mean epi
    # for the fine alignment to work.
    # N.B. Previously, the coarse alignement was implemented using -giant_move of align_epi_anat.py.  But, because -giant_move
    #      resets -Allineate_opts, using -giant_move utilizes a non-linear (12 parameter) warping of the anatomical, even with 
    #      -Allineate_opts "-warp shift_rotate"
    #      Here, we are implementing something similar to -giant_move more directly, but not as elegantly and perhaps not over such
    #      a large search space.
    # N.B. equivilent -giant_move arguments in align_epi_anat.ph for 3dAllineate are:
    #           -twobest 11 -twopass -VERB -maxrot 45 -maxshf 40 -fineblur 1 -source_automask+2
    #      but using these caused poor alignment on some test datasets for reasons that I do not fully understand.
    # N.B. you can emulate -giant_move and still get a rigid body transform with these options for align_epi_anat.py:
    #           -Allineate_opts "-weight_frac 1.0 -maxrot 45 -maxshf 40 -VERB -warp shift_rotate" -big_move -cmass cmass 
    # N.B. If you ever do use -giant_move, make sure to include -master_anat SOURCE so that the anatomical is not cropped to the size
    #      of the EPI, which will lead to subsequent failure of the alignment between the _al_al and SurfVol.

    # sometimes deobliquing the anatomical helps.  it usually gets it closer aligned with the EPI, if the EPIs were
    # collected at an oblique angle.  but this isn't always the case and usually we can deal with it without deobliquing
    # the anatomy.  set deoblique_anat = 1 (above) if automatic alignment fails and surfvol and the epi are rotated far
    # apart to begin with.

    # ================================== warp ==================================
    3dWarp \
        -verb \
        -card2oblique $subj.$masterEPI+orig \
        -prefix $subj$curFix.warp+orig \
        $subj$curFix+orig
    set curFix = $curFix.warp

    # the "coarse" alignment command
    3dAllineate \
        -prefix $subj$curFix.coarse+orig \
        -base $subj.refEPIvol+orig \
        -master $subj$curFix+orig \
        -warp shift_rotate \
        $subj$curFix+orig
    set curFix = $curFix.coarse

    # =============================== volAlign =================================
    # "fine" alignment
    # now that the surfvol is "close" to the EPI, do another pass using the default align_epi_anat.py parameters
    # N.B. Sometimes, for reasons unknown to me, this will fail miserably, and take a pretty-close alignment
    #      between the EPI and the coarse-SurfVol and output something that is way off.  In that case, you can
    #      try the following (but keep in mind that I haven't really had much success with the first two anyway):
    #      1. If you know that the input EPI and ANAT to this fine-pass are very close (as they
    #         should be - you can visually check in AFNI), then limit the range of startings points for the alignment
    #         search by updating the -Allineate_opts as follows (but note that you may want/need to play with the exact
    #         values for -maxrot and -maxshf):
    #            -Allineate_opts "-weight_frac 1.0 -maxrot 4 -maxshf 8 -VERB -warp shift_rotate"
    #      2. If you think that the alignment is failing because of a particular region (e.g., bad distortions in the
    #         frontal cortex, perhaps due to a retainer or glasses), then you can try to provide an exclusion mask
    #         to 3dAllineate with:
    #            -Allineate_opts "-weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp shift_rotate -emask KK_surfvol_obl_coarse_exclude_frontal_mask+orig"
    #         You can create such a mask using the DrawDataset plugin in the AFNI gui. Should be the same size as the
    #         source (-anat) dataset in the command below.  If you draw it on the EPI, try using 3dresample to convert
    #         to the appropriate grid/resolution.
    #      3. Rely on a purely manual alignment using NudgeDataset in the AFNI gui.  You can set manual_nudge=1 (above)
    #         and comment out the "fine" pass code.  In that case, the manual nudging will be the "final" alignmen
    #         between EPI and ANAT
    #
    # N.B. the default -Allineate_opts to implement a rigid body transformation (and keep other align_epi_anat.py defaults) is:
    #           -Allineate_opts "-weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp shift_rotate"

    echo; echo "== starting fine alignment (second-pass)"
    align_epi_anat.py \
        -anat $subj$curFix+orig \
        -epi $subj.refEPIvol+orig \
        -epi_base 0 \
        -volreg off \
        -tshift off \
        -deoblique off \
        -anat_has_skull no \
        -Allineate_opts "-weight_frac 1.0 -maxrot 6 -maxshf 10 -VERB -warp shift_rotate"

    # rename files to keep naming convention
    mv $subj${curFix}_al+orig.BRIK $subj$curFix.al+orig.BRIK
    mv $subj${curFix}_al+orig.HEAD $subj$curFix.al+orig.HEAD
    mv $subj${curFix}_al_mat.aff12.1D $subj$curFix.al.mat.aff12.1D
    set curFix = $curFix.al

    # =============================== surfAlign ================================
    # align high-res surface anatomical to epi-aligned anatomical
    # N.B. align_epi_anat.py skull-strips the anatomical, so use NoSkull hi-res for surface alignment
    # output is ${SUBJ}_[NoSkull_]SurfVol_Alnd_Exp+orig

    echo; echo "== aligning surface volume"
    @SUMA_AlignToExperiment \
        -align_centers \
        -strip_skull neither \
        -surf_anat $SUBJECTS_DIR/$subj/SUMA/${subj}_NoSkull_SurfVol+orig \
        -exp_anat $subj$curFix+orig \
        -atlas_followers


    # rename files to keep naming convention
    mv ${subj}_NoSkull_SurfVol_Alnd_Exp+orig.BRIK $subj.NoSkull.SurfVol.Alnd.Exp+orig.BRIK
    mv ${subj}_NoSkull_SurfVol_Alnd_Exp+orig.HEAD $subj.NoSkull.SurfVol.Alnd.Exp+orig.HEAD
    mv aseg_rank_Alnd_Exp+orig.BRIK $resultsDir/aseg.rank.Alnd.Exp+orig.BRIK
    mv aseg_rank_Alnd_Exp+orig.HEAD $resultsDir/aseg.rank.Alnd.Exp+orig.HEAD
    mv aparc+aseg_rank_Alnd_Exp+orig.BRIK $resultsDir/aparc+aseg.rank.Alnd.Exp+orig.BRIK
    mv aparc+aseg_rank_Alnd_Exp+orig.HEAD $resultsDir/aparc+aseg.rank.Alnd.Exp+orig.HEAD
    mv aparc.a2009s+aseg_rank_Alnd_Exp+orig.BRIK $resultsDir/aparc.a2009s+aseg.rank.Alnd.Exp+orig.BRIK
    mv aparc.a2009s+aseg_rank_Alnd_Exp+orig.HEAD $resultsDir/aparc.a2009s+aseg.rank.Alnd.Exp+orig.HEAD

    # copy experiment-aligned surface volume to the GLM folder
    cp -f $subj.NoSkull.SurfVol.Alnd.Exp+orig.* $resultsDir
    
    # =============================== automask ================================
    # create automask - just after motion correction/undistortion AND anatomical alignment,
    # BUT before smoothing/filtering/normalization etc.
    # this can be used to speed up 3dDeconvolve by ignoring the out-of-brain voxels
    # create binary mask from  EPI brik

    echo; echo "== creating automask"
    3dAutomask \
        -prefix $subj.automask \
        -dilate 1 \
        $subj.refEPIvol+orig

    # copy automask and EPI_for_align for checking alignment (now that we've used it for the automask)
    cp -f $subj.automask+orig.* $resultsDir
    cp -f $subj.refEPIvol+orig.* $resultsDir
    cp -f $subj.refEPIvol.uniform+orig.* $resultsDir
    
    # remove unnecessary files
    rm SessionAtlases*
    rm *shft*
    rm *A2E*
    rm *aff12*

end

echo; echo "== $0 complete"
exit 0
