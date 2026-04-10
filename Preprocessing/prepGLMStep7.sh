#!/bin/tcsh -xef
#
# Author: Dan McCarthy
# Part of the EyeHandPrimingMRI pipeline (JoCN 2024)
#

# N.B. There are many options when preprocessing fMRI data.  This script
#      is not meant to be general enough to capture all possible combinations
#      of volume and/or surface based preprocessing steps (e.g., detrending,
#      smoothing, signal scaling or normalization).  Be sure to consider the
#      inclusion / exclusion of each preprocessing step for your data.
#
#      This script implements:
#      1. Volume Smoothing (optional, can be set to zero and/or any other value)
#      2. Volume Signal Scaling (i.e., normalization)	
#      3. Projection to surface (lh and rh)
#      4. Copy final surface files to ../GLM/ (will be input to GLM)

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
# Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21

echo "== $0 starting"

# for quick commenting
if ( 0 ) then
	endif

# set up variables for preprocessing
# the subj should be the same as used for the surfaces directory
set subj = (Sub3 Sub4 Sub6 Sub9 Sub10 Sub11 Sub12 Sub13 Sub14 Sub15 Sub16 Sub17 Sub18 Sub19 Sub20 Sub21)

# define the MR data folder
set dataDir = <YOUR_DATA_DIR> # e.g., ~/DataMRI

# assign input directory name
set inputDir = EPI

# assign output directory name
set outputDir = GLM

# normalize runwise or scanwise? 1 = runwise (AFNI default)
set runBase = 0

# icoFix is optional.  Leave as '' to run surface analysis on the subject's native space.  if, rather, you are planning on
#    doing a group-level analysis in standard surface space (i.e., icosahedron space), then set icoprefix to be either
#    'std.141.' or 'std.60.'.  This will determines which icosahedron (resolution) surface to use.  use 141 unless you specifically
#    want a lower resolution space
set icoFix = std.141; # '', 'std.141.'. or 'std.60.' (see comment above)

foreach subj ($subj)

	# "" at begining of preprocessing (reset for each run)
	# easily changes the prefix if steps aren't included
	set curFix = warp.volreg

	set curDir = $dataDir/$subj/$inputDir

	set resultsDir = $dataDir/$subj/$outputDir

	cd $curDir

	# define number of runs
    if ($subj == Sub3 || $subj == Sub4 || $subj == Sub20) then
        set runs = (run1 run2 run3 run4 run5 run6)
        if (! $runBase) then
			3dTcat \
				-prefix $subj.allruns.$curFix+orig \
				$subj.run1.$curFix+orig $subj.run2.$curFix+orig $subj.run3.$curFix+orig $subj.run4.$curFix+orig $subj.run5.$curFix+orig $subj.run6.$curFix+orig
		endif
    else
        set runs = (run1 run2 run3 run4 run5 run6 run7 run8)
        if (! $runBase) then
			3dTcat \
				-prefix $subj.allruns.$curFix+orig \
				$subj.run1.$curFix+orig $subj.run2.$curFix+orig $subj.run3.$curFix+orig $subj.run4.$curFix+orig $subj.run5.$curFix+orig $subj.run6.$curFix+orig $subj.run7.$curFix+orig $subj.run8.$curFix+orig
		endif
    endif

	foreach run ($runs)

		# define smoothing levels
		set blur = (0 6 8)

    	# ================================== blur ==================================
		# blur each volume of each run at different smoothing levels
		foreach blur ($blur)

			# # "" at begining of preprocessing (reset for each run)
			# # easily changes the prefix if steps aren't included
			# # change if the tcat option was used in preprocessFunctStep5
			set curFix = warp.volreg

			echo; echo "== smoothing $run with $blur mm kernel"

			if ($blur == 0) then
				# for zero smoothing, we still want a file with "sm0" appended, just to be explicit.
		 		# so although this is really of a waste of disc space, we'll make a copy of the curfunc.
		 		3dcopy $subj.$run.$curFix+orig $subj.$run.$curFix.blur$blur+orig
		 		if ($run == run1) then
		 			if (! $runBase) then
		 				3dcopy $subj.allruns.$curFix+orig $subj.allruns.$curFix.blur$blur+orig
		 			endif
		 		endif
		 	else
				3dmerge \
			 		-1blur_fwhm $blur \
			 		-doall \
			 		-prefix $subj.$run.$curFix.blur$blur \
			 		$subj.$run.$curFix+orig
			 	if ($run == run1) then
			 		if (! $runBase) then
			 			3dmerge \
			 				-1blur_fwhm $blur \
			 				-doall \
			 				-prefix $subj.allruns.$curFix.blur$blur \
			 				$subj.allruns.$curFix+orig
			 		endif
			 	endif
			endif
			set curFix = $curFix.blur$blur

			# # ================================= scale ==================================
			# # signal scaling - normalization to percent signal change
			# # calculate voxel-wise mean (i.e., mean over time points)

			echo; echo "== signal scaling (normalization) for $run ($blur mm blur)"
			if ($runBase) then
				# get runwise means
				3dTstat \
					-prefix $subj.$run.$curFix.runMean \
			 		$subj.$run.$curFix+orig
			else
				# get the mean across all runs
				if ($run == run1) then
				3dTstat \
					-prefix $subj.allruns.$curFix.scanMean \
			 		$subj.allruns.$curFix+orig
			 		endif
			endif

			# Signal Scaling (i.e., Signal Normalization)
			# there are multiple options for percent signal normalization:
			#    -expr '100*a/b'                   					; basic percent of mean (mean = 100)
			#    -expr '100*(a-b)/b'               					; basic percent of mean (mean = 0)
			#    -expr '100*a/b*ispositive(b-200)' 					; masked. voxels must have mean of at least 200 across a run
			#    -expr 'min(200, 100*a/b)'         					; cap normalized signal change at 200 (twice the mean)
			#                                        				avoids very large, and presumably non-physiological, signal changes.
			#                                        				also keeps range symmetrical since scanner values are always positive
			#														and thus, will never go below 0%.
			#    -expr 'fift_t2z(t,a,b)'                            ; converts t-values to z-values (see the cdf command for multiple options)
			# Adding a 'c' option allows you apply a mask
			# this option must also be added to the -expr option E.g., 'c * min(200, 100*a/b)'
			# For a GLM analysis, normalization shouldn't appreciably affect significance (although there may be minor effects from masking/capping)
			# and it is meant to make the outputted beta-weights in interpretable units (percent signal change, z-scores, etc)
			
			if ($runBase) then
				3dcalc \
					-a $subj.$run.$curFix+orig \
					-b $subj.$run.$curFix.runMean+orig \
					-prefix $subj.$run.$curFix.runNorm \
					-expr 'min(200, 100*a/b)'
					set curFix = $curFix.runNorm
			else
				3dcalc \
					-a $subj.$run.$curFix+orig \
					-b $subj.allruns.$curFix.scanMean+orig \
					-prefix $subj.$run.$curFix.scanNorm \
					-expr 'min(200, 100*a/b)' 
					set curFix = $curFix.scanNorm
			endif

			# define the two hemispheres
			set hemi = (lh rh)

		    # =============================== Vol2Surf =================================
		    # project normalized data to surface (separately for lh and rh)
		    foreach hemi ($hemi)

		    		if ($blur == 0) then
						# project to native surface for ROI analysis
			            echo; echo "projecting $hemi data to native surface for $run ($blur mm blur)"
			            3dVol2Surf \
				            -spec $SUBJECTS_DIR/$subj/SUMA/${subj}_${hemi}.spec \
				            -surf_A ${hemi}.pial.asc \
				            -surf_B ${hemi}.smoothwm.asc \
				            -sv $resultsDir/$subj.NoSkull.SurfVol.Alnd.Exp+orig \
				            -grid_parent $subj.$run.$curFix+orig \
				            -map_func ave \
				            -oob_value -0 \
				            -f_steps 10 \
				            -f_index voxels \
				            -out_niml $subj.$run.$curFix.$hemi.niml.dset
				    else
			            # project to icosahedron surface (std141) for whole-brain surface GLM
			            echo; echo "projecting $hemi data to std141 surface for $run ($blur mm blur)"
			            3dVol2Surf \
				            -spec $SUBJECTS_DIR/$subj/SUMA/${icoFix}.${subj}_${hemi}.spec \
				            -surf_A ${icoFix}.${hemi}.pial.asc \
				            -surf_B ${icoFix}.${hemi}.smoothwm.asc \
				            -sv $resultsDir/$subj.NoSkull.SurfVol.Alnd.Exp+orig \
				            -grid_parent $subj.$run.$curFix+orig \
				            -map_func ave \
				            -oob_value -0 \
				            -f_steps 10 \
				            -f_index voxels \
				            -out_niml $icoFix.$subj.$run.$curFix.$hemi.niml.dset
				    endif
	    	end
	    end
	end

	mv -f $subj.run*.scale* $resultsDir
	mv -f *dset $resultsDir

end

echo; echo "== $0 complete"
exit 0
