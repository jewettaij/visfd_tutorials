#!/usr/bin/env bash



# WARNING: In these instructions, it is assumed that the voxel width
#          is 19.6 Angstroms.  If not, replace this number everywhere.
#
# Terminology: I use the phrase "3-D image" and "tomogram" interchangeably.





# ---- Goal: Remove excessively bright or dark objects from the image ----
#
# If the tomogram contains extremely dark objects, such as gold fiducial
# beads or ice contamination, then the first step is to remove this debris
# from the tomogram.  To do that, create a mask file (eg. "mask_blobs.rec").
# This file has brightness 0 in regions from the image containing these
# objects that we want to exclude from consideration later on.
#
# IF YOUR TOMOGRAM DOES NOT CONTAIN GOLD FIDUCIAL BEADS, THEN YOU CAN
# SKIP ALL OF THE INSTRUCTIONS CONTAINED IN THIS FILE AND DO THIS INSTEAD:
#
#
#   filter_mrc -in orig_crop.rec -out fiducial_blobs.rec -fill 0
#
#
# (This will create an "fiducial_blobs.rec" file with voxels of brightness=0.
# This file must be present or the steps in "STEP_4..." and later will fail.)
# After doing this you can skip the remaining instructions in this file.
# 
#
# ------------------------------------------
#
# PREREQUISITES
#
# A 3-D image file (tomogram) containing the cell you want to segment.
# It is a -VERY- good idea to crop this tomogram beforehand so that it
# only includes the cell you want to segment.  (You can do this using
# "3dmod", "trimvol", or the "crop_mrc" program distributed with VISFD.)
# Otherwise the software will be extremely slow and your computer is also
# likely to run out of memory (freezing up and becomming unresponsive).
#
# The tomogram in this example has been cropped and is named "orig_crop.rec".



# ------- Detect gold fiducial beads (markers) --------

# Let's detect all dark blobs ("minima") between 120 and 170 Angstroms in width.
# This corresponds (approximately) to the size of gold-bead fiducial markers
# located in this image.  These objects are so dark that they confuse the
# code that detects other objects we do care about like membranes and ribosomes.
# We detect them now so that we can exclude them from consideration later.

filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -blob minima fiducial_blob_candidates.txt 120.0 170.0 1.01

# (Note: The "-w 19.6" argument specifies the voxel width in Angstroms.)
#
# (Note: The "1.01" parameter should probably be left alone.
#  Using larger values, like 1.02, will make detection faster, but doing that
#  will likely cause some of the blobs we do care about to be missed,
#  even if they are dark and clearly visible.  If that happens, feel free to
#  reduce this parameter even further.  The parameter must be > 1.0.)

# Now discard the faint, noisy, or overlapping blobs.  The remaining list of
# blobs (that we want to ignore later) will be saved in "fiducial_blobs.txt".

filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -discard-blobs fiducial_blob_candidates.txt fiducial_blobs.txt \
           -radial-separation 0.3 \
           -minima-threshold -1000    # <-- blobs with low "score" are omitted

# The critical parameter here is the "-minima-threshold".  We should choose
# this threshold so that we detect the fiducial markers that we want to ignore
# later, without also including other features we do care about.
#
# To obtain this parameter, open the "fiducial_blob_candidates.txt" file that
# we created in the previous step with a text editor.  This is a huge file
# containing one line per detected blob.  The "score" of each blob is in the
# final column on the far right.  This file is sorted according to blob score.
# (The scores are negative because the blobs are darker than their surroundings)
# The most significant blobs (with large scores) occur at the beginning of the
# file.  Scroll downward through the file.  After about a hundred lines or
# so (the number of gold beads in your image), you will notice a sudden
# drop-off in the score numbers in the 5th column.  Below that point,
# all of the remaining blobs (which make up the majority of the file),
# have low scores and probably do not correspond to gold beads.
# The score where this drop occurs makes a reasonable first guess to use as a
# parameter for the "-minima-threshold" argument.
#
# Now create an image with the location of each blob "marked" with a
# hollow spherical shell:

filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -out fiducials_blobs_annotated.rec \
           -draw-hollow-spheres fiducial_blobs.txt \
           -background-auto -background-scale 0.2 \
           -spheres-scale 2.2  # make the spheres 120% larger so we can
                               # see them more easily

# Verify that the threshold was chosen correctly by viewing the file using
#
#   3dmod -S fiducial_blobs_anotated.rec
#
# If we used a reasonable guess for the "-minima-threshold", then thin hollow
# shells should surround all of the fiducial markers.
# If not, then we have to go back and adjust this "-minima-threshold" parameter.
# (Useful trick: Clicking on one of the voxels in the thin shells and
# pressing the "F" key will print out the "score" for that blob.)
#
# It's okay if we also detect other dark objects in the image which are not
# fiducial markers (such as ice contamination or carbon films), as long as they
# are outside the cell and you don't mind excluding them from consideration
# later.  If everything looks good, then create another 3-D image
# ("fiducial_blobs.rec") file that displays the blobs as white on a black
# background.  (We will eventually use that version of the file to help
# us build an image "mask" later.)


filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -out fiducial_blobs.rec \
           -draw-spheres fiducial_blobs.txt \
           -foreground 1 \
           -background 0 \
           -spheres-scale 3.5  # make the spheres 3.5 times as large as the
                               # gold beads.  I want the spheres to completely
                               # cover up these beads (as well as the bright
                               # halos that tend to surround them).  I want
                               # to remove all traces of these beads later
                               # when we try to detect features in the cell.

