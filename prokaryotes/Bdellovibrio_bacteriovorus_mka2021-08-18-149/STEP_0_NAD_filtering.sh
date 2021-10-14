#!/usr/bin/env bash



# ---- Goal: Improve the contrast in the source image ----

# This step is optional but highly recommended.
#
# The command below will improve the contrast of the membranes in the image
# by applying nonlinear-anisotropic-diffusion (NAD) filter to the image.
# Improving the contrast will make it easier to detect the membranes and
# it will reduce the amount of manual effort needed later on to "clean up"
# the image (ie. remove noise or objects in the image that are not membranes).
# Cleaning up an image is often the most laborious part of the process, so
# anything you can do to enhance the image beforehand will save you time later.
#
# A NAD filter is a kind of directional blurring which enhances the
# membranes and filaments within the image.  (For documentation, see
# https://bio3d.colorado.edu/imod/doc/NADexample.html)
# "nad_eed_3d" is included with the IMOD software distributed here:
# https://bio3d.colorado.edu/imod/

nad_eed_3d -m 2 -k 7 -n 15 orig_crop.rec orig_crop_nad.rec

# Open the new image ("orig_crop_nad.rec") using IMOD/3dmod to
# verify that the membranes are now easier to see.
# If not, then adjust the numeric arguments above.
# Note: In this example, the voxel width in the tomogram was 18.08 Angstroms
# If the voxel width in your tomogram deviates significantly from this,
# (ie. by a factor of 2), you will have to adjust the nad_eed_3d
# arguments to get reasonable results.

# Now replace the "orig_crop.rec" file with "orig_crop_nad7_15.rec"
mv orig_crop.rec orig_crop_BACKUP.rec
mv orig_crop_nad.rec orig_crop.rec

# --------- avoid weighted back projection ---------
#
# Note: If the original 3-D image is a tomogram generated using the
#       weighted-back-projection method, then I suggest using SIRT, or some
#       other reconstruction method which improves the contrast of
#       large objects (like membranes) in the image.  (For EM tomograms,
#       the use of a phase-plate during image collection can also help.)
