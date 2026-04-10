#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

# Does functional preprocessing and aligns all functional data to the 5th TR (AFNI default).
# Performs the following steps:
# 1. Remove the first 2 TRs (optional; can be done easily in 3dDeconvolve later)
# 2. Deobliques the volume (output will warn if collected data is oblique)
# 3. Calculates outlier timepoints (may use to censor in the GLM)
# 4. De-spikes the dataset (OPTIONAL; only necessary if data is spiky, censoring outlier TRs probably better)
# 5. Performs time-slice correction
# 6. Performs volume registration (motion correction) and generates motion regressor files for the GLM

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
set subj = (Sub3 Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21)

# set master EPI run
# CHANGE IF FIRST RUN WAS BAD
set masterEPI = run1

# number of TRs in each run
set runTRs = 154

# define the MR data folder
set dataDir = <YOUR_DATA_DIR> # e.g., ~/DataMRI

# assign output directory name
set outputDir = EPI

# do the loop for each subject
foreach subj ($subj)

    # verify that the results directory does not yet exist
    # break the loop if it does
    if ( -d $dataDir/$subj/$outputDir ) then
    	echo; echo output dir "$subj/$outputDir" already exists
    	exit
    endif

    echo; echo "== Starting processing for $subj"

    # set current directory for output files
    set curDir = $dataDir/$subj/$outputDir

    # set directory for plots
    set plotDir = $dataDir/$subj/Plots

    # "" at begining of preprocessing (for each subject)
    # easily changes the prefix if steps aren't included
    set curFix = ""; 

    # create results and plot directories and go to results folder
    mkdir $curDir
    mkdir $plotDir
    cd $curDir

    # define number of runs
    if ($subj == Sub3 || $subj == Sub4 || $subj == Sub5 || $subj == Sub20) then
        set runs = (run1 run2 run3 run4 run5 run6)
        set nRuns = 6
        set totalTRs = 924
    else
        set runs = (run1 run2 run3 run4 run5 run6 run7 run8)
        set nRuns = 8
        set totalTRs = 1232
    endif

    # ================================== copy ==================================
    # convert NIFTI to AFNI for each run
    # done for each run separately in case of scanner restart, incompleteion, etc.
    # CHANGE IF NECESSARY
    echo; echo "== Converting NIFTI to AFNI Runwise"

    3dcopy $dataDir/$subj/NIFTI/$subj.run1.EPI.nii $subj.run1+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run2.EPI.nii $subj.run2+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run3.EPI.nii $subj.run3+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run4.EPI.nii $subj.run4+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run5.EPI.nii $subj.run5+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run6.EPI.nii $subj.run6+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run7.EPI.nii $subj.run7+orig
    3dcopy $dataDir/$subj/NIFTI/$subj.run8.EPI.nii $subj.run8+orig

    # OPTIONAL: this can also be done by ensoring TRs in the GLM
    # # ================================== tcat ==================================
    # # apply 3dTcat to copy input dsets to results dir, while
    # # removing the first 2 TRs
    # foreach run ($runs)

    # 	echo; echo "== concatenating $subj.$run"
    # 	3dTcat -prefix $subj.$run.tcat $subj.$run$curFix+orig'[2..$]'

    # end
    # set curFix = $curFix.tcat

	# ================================== warp ==================================
	# datasets from some scanners (Brown Included) are oblique (functional data 
	# collected at different angle from anatomical)
    # this performs a warping transform as a fix
    foreach run ($runs)
        
    	echo; echo "== warping dataset for $run"
    	3dWarp \
    		-verb \
    		-deoblique \
    		-prefix $subj.$run$curFix.warp \
    		$subj.$run$curFix+orig

    end
    set curFix = $curFix.warp

	# ================================ outcount ================================
	# data check: compute outlier fraction for each volume
	foreach run ($runs)
		
		echo; echo "== calculating outcount for $run"
		3dToutcount \
			-automask \
			-fraction \
			-polort 3 \
			-legendre \
			$subj.$run$curFix+orig > $subj.$run.outcount.1D

    	# outliers at TR 2 might suggest pre-steady state TRs
    	# output text file to indicate if this was true for any run
    	if ( `1deval -a $subj.$run.outcount.1D"{2}" -expr "step(a-0.4)"` ) then
    		echo; echo "** TR #2 outliers: possible pre-steady state TRs in $run" \
    		>> $subj.preSteadyStateOutlierWarning.txt
    		endif

    	# Generate outcount plots for each run with line for 5% chance level
    	1dplot -xlabel 'TR' -ylabel 'PctOutlierVoxels' -png $plotDir/$subj.$run.outcountplot.png -one $subj.$run.outcount.1D '1D: 154@0.05' 

        # determine if the run had any outlier TRs and save text file for each run
        # N.B. the index of TRs in this file start at 1, BRIKs start at 0, adjust accordingly if censoring
        echo $run >> $subj.allruns.outlierTRs.txt
        # determine if chance threshold was exceeded and save runwise
        1deval -a $subj.$run.outcount.1D -expr "t * step(a-0.05)" | awk '$0' >> $subj.allruns.outlierTRs.txt

    end

    # catenate outlier counts into a single time series
    cat $subj.run*.outcount.1D > $subj.allruns.outcount.1D

	# plot global outcount
	1dplot -xlabel 'TR' -ylabel 'PctOutlierVoxels' -png $plotDir/$subj.$run.outcountplot.png -one $subj.allruns.outcount.1D '1D: 1232@0.05'

	mkdir $plotDir/Outcount
	mv $plotDir/*outcountplot* $plotDir/Outcount

    # ================================= despike =================================
    # OPTIONAL, only necessary if there are actually spikes in your dataset.
    # N.B. AFNI default is to despike first.  "Most likely due to quick movement that would not 
    # be fixed by volume registration.  Despike first to minimize corruption of TRs that are 
    # adjacent to spike during time slice correction. -Rick Reynolds (10-08-08)
    # N.B. A better option may be to censor bad timepoints from subsequent analyses (e.g., GLM)
    # foreach run ($runs)
    #     echo; echo "== despiking $run"
    #     3dDespike \
    #         -ssave $subj.$run.spikiness \
    #         -nomask \
    #         -ignore 4 \
    #         -prefix $subj.$run$curFix.dspk \
    #         $subj.$run$curFix+orig
    # end
    # set curFix = $curFix.dspk

	# ================================= tshift =================================
	# time shift data so all slice timing is the same 
	# N.B., Brown scanner data is already time slice corrected
	# foreach run ($runs)
	# 	echo; echo "== time slice correction for $run"
	# 	3dTshift \
	# 		-tzero 0 \
	# 		-quintic \
	# 		-prefix $subj.$run$curFix.tshift \
    #       $subj.$run$curFix+orig
	# end
    # set curFix = $curFix.tshift

	# ================================= volreg =================================
	# align each dset to base volume
	# N.B. do motion correction before fieldmap undistortion (and anatomical alignment)
    #      so that the reference run/volume will match all other EPI volumes.
    # 2012.02.06 - changed from -Fourier (default) to -cubic upon advice from AFNI gurus at Princeton AFNI bootcamp
	foreach run ($runs)
	
    	# register each volume to the base
    	echo; echo "== motion correction for $run"
    	3dvolreg \
    		-verbose \
            -zpad 3 \
    		-base $subj.$masterEPI$curFix+orig'[2]' \
            -1Dfile $subj.$run.mcparams.1D \
            -prefix $subj.$run$curFix.volreg \
            -cubic \
            $subj.$run$curFix+orig 

        # plot motion parameters for each run
    	1dplot -volreg -xlabel 'TR' -one -png $plotDir/$subj.$run.mcparamsplot.png $subj.$run.mcparams.1D

        # compute motion magnitude time series: the Euclidean norm
        # (sqrt(sum squares)) of the motion parameter derivatives
        1d_tool.py \
            -infile $subj.$run.mcparams.1D \
            -derivative \
            -collapse_cols euclidean_norm \
            -write $subj.$run.mcparams.enorm.1D

        # determine if any TRs exceeded the framewise displacement threshold and print out for each run
        # this can be used to "scrub" out sharp motion peaks in the GLM
        # Usually is highly correlated, but less sensitive, than 3dOutcount
        echo $run >> $subj.allruns.scrubHiThresh.txt
        1deval -a $subj.$run.mcparams.enorm.1D -expr "t * step(a-1)" | awk '$0' >> $subj.allruns.scrubHiThresh.txt

        echo $run >> $subj.allruns.scrubLoThresh.txt
        1deval -a $subj.$run.mcparams.enorm.1D -expr "t * step(a-0.5)" | awk '$0' >> $subj.allruns.scrubLoThresh.txt

        # plot motion enorm for each runs
        1dplot -xlabel 'TR' -ylabel 'Motion Euclidean Norm' -one -png $plotDir/$subj.$run.mcparamsplot.enorm.png $subj.$run.mcparams.enorm.1D '1D: 154@1' '1D: 154@0.5'

	end
    set curFix = $curFix.volreg

	# make a single file of registration params
	cat $subj.run*.mcparams.1D > $subj.allruns.mcparams.1D

    # plot motion parameters for all runs
    1dplot -volreg -xlabel 'TR' -png $plotDir/$subj.allruns.mcparamsplot.png -one $subj.allruns.mcparams.1D

    # move plot 
	mkdir $plotDir/Motion
	mv $plotDir/*mcparamsplot* $plotDir/Motion

    # compute motion magnitude time series: the Euclidean norm
    # (sqrt(sum squares)) of the motion parameter derivatives
    1d_tool.py \
        -infile $subj.allruns.mcparams.1D \
        -derivative \
        -collapse_cols euclidean_norm \
        -write $subj.allruns.mcparams.enorm.1D
  
    # plot motion enorm for all runs
    1dplot -xlabel 'TR' -ylabel 'Motion Euclidean Norm' -one -png $plotDir/$subj.allruns.mcparamsplot.enorm.png $subj.allruns.mcparams.enorm.1D '1D: 1232@1' '1D: 1232@0.5'

    # compute de-meaned motion parameters (for use in regression)
    1d_tool.py \
        -infile $subj.allruns.mcparams.1D \
        -set_nruns $nRuns \
        -demean \
        -write $subj.allruns.mcparams.demean.1D
 
    # plot demeaned motion parameters for all runs
    1dplot -xlabel 'TR' -ylabel 'Motion Demeaned' -png $plotDir/$subj.allruns.mcparamsplot.demean.png $subj.allruns.mcparams.demean.1D

    # compute motion parameter derivatives (can also be used in regression if desired)
    1d_tool.py \
        -infile $subj.allruns.mcparams.1D \
        -set_nruns $nRuns \
        -derivative \
        -demean \
        -write $subj.allruns.mcparams.deriv.1D

    # plot motion derivative for all runs       
    1dplot -xlabel 'TR' -ylabel 'Motion Deritative' -png $plotDir/$subj.allruns.mcparamsplot.deriv.png $subj.allruns.mcparams.deriv.1D

    # move plots to appropriate folder
    mv $plotDir/*enorm* $plotDir/Motion
    mv $plotDir/*demean* $plotDir/Motion
    mv $plotDir/*deriv* $plotDir/Motion
end

echo; echo "== $0 complete"
exit 0
