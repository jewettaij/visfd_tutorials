#!/usr/bin/env bash



# ---- Goal: Improve the contrast in the source image ----

# 
# This step is optional but highly recommended if you are
# starting with a tomogram which was reconstructed with a
# low-contrast method such as weighted back projection (WKB).
#
# But if you are starting from a tomogram which was reconstructed using
# an an algorithm like SIRT which generates high-contrast at low frequencies,
# or if the data was collected using a phase-plate, then this step
# (NAD filtering) might not be necessary and may cause unnecessary blurring.
# If you want to skip this step, ignore the remainder of this file
# and jump to the instructions inthe "STEP_1...sh" file.
# Alternatively, you can try it and see if it helps.
#
# The command below will attempt to improve the contrast of the membranes in the
# 3D image by applying nonlinear-anisotropic-diffusion (NAD) filter to the image
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

# Now open the new tomogram ("orig_crop_nad.rec") using IMOD/3dmod.
# If the membranes (and ribosomes or other features you wish to segment)
# are more clearly visible than before, then rename this file
# from "orig_crop_nad.rec" to "orig_crop.rec" (after backing up the old file).

mv orig_crop.rec orig_crop_BACKUP.rec
mv orig_crop_nad.rec orig_crop.rec

# If not, then adjust the numeric arguments above.
# Again, if your original data was collected using a phase plate,
# or if the tomogram was reconstructed using SIRT, then NAD-filtering might not
# help.  In that case, leave the original "orig_crop.rec" file alone.

# Note: In this example, the voxel width in the tomogram was 18.08 Angstroms
# If the voxel width in your tomogram deviates significantly from this,
# (ie. by a factor of 2), you will have to adjust the nad_eed_3d
# arguments to get reasonable results.

