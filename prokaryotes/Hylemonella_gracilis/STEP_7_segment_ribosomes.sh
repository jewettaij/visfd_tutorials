#!/usr/bin/env bash




# ---- Goal ----
#
# In this file, we will use a standard "scale-free blob detection" algorithm to
# search for dark blobs in the image which are the size of ribosomes.  This will
# create a file with a list of the positions of all the dark spots in the image
# which are approximately the size of ribosomes.
# We will also segment the image, creating a new image ("ribosome_blobs.rec")
# that highights all the voxels which belong to ribosomes.
#
#   (For details on blob-detection, see:
#    https://en.wikipedia.org/wiki/Blob_detection)
#
# THIS IS NOT AN OPTIMAL WAY TO DETECT RIBOSOMES.
#
# Suggestion: Preprocess the image using a machine-learning based program(EMAN2)
#
# The blob-detection strategy we use here is fairly generic and crude.
# It won't be able to distinguish the ribosomes in the cell from other dark
# objects of similar size.  But if you choose the "-minima-threshold" parameter
# carefully), it is usually possible to correctly identify ribosomes
# at least 70% of the time (in high-quality tomograms such as this one.)
#
# Any kind of processing you can do the image beforehand to enhance the features
# you want to detect (such as ribosomes), will improve the detection accuracy
# and make the following steps much easier.
# Programs like "EMAN2" do a much better job of highlighting
# the voxels in the image where the ribosomes are located.
# In this tutorial, I did not use EMAN2.  Instead I ran blob-detection on
# the original image.  To compensate, I attempted to clean up the image as
# as much as possible beforehand (such as using a DoG, Gauss, and Dilation
# filter before running the blob-detection; see below).
# These steps would not be necessary if I used a program like EMAN2 first.




# Strategy:
#
# 1) Create a mask image file ("mask_interior.rec") which excludes all
#    all voxels in the which are either outside of the cytoplasm, OR
#    in polyphosphate bodies or storage granules.
# 2) Clean up the image and process it beforehand to make the blobs you are
#    trying to detect stand out as much as possible.  (This usually involves
#    making the gap between dark blobs in the image wider, so that they
#    are easier to distinguish from each other.  See below.)
#
# 3) Then use a blob-detction algorithm to find the dark blobs in the image.




# ---- Part 1) Creating the mask file we will need ----
#
# It is difficult to devise a detection method (for nucleoids or any
# other features) which can directly detect the feature you are looking for.
# More often, you can figure out where the target object is (eg "nucleoid")
# in the context of what's around it.  One typically detects the most
# obvious features first (such as the gold fiducial beads and the membranes).
# As more and more of the voxels in the image are classified, you can
# often see where the target is simply by ruling out everything else out.
# In this example, we will use a fairly crude and sloppy method for detecting
# the nucleoid.  Unfortunately, that method will accidentally also detect many
# other voxels inside and outside the cell which are not part of th nucleoid.
# We need to find a way to ignore those voxels, so I create a "mask" image.
# We will use this "mask" image file to tell "filter_mrc" which voxels
# to consider, and which voxels to ignore.
#
# Below, I construct a 3-D "mask" image that designates where the remaining
# unsegmented interior of the cell is located.  Voxels in this 3-D image
# will have brightness of 0 in location that are either outside the cell,
# or they belong to regions in the cell we have already segmented
# (such as polyphosphate bodies or storage granules).  We don't want to
# consider those voxels in the future when we attempt to segment the nucleoid.
#
# I create this image using the "combine_mrc" program (distributed with VISFD).
# The "combine_mrc" program only accepts two images at a time, so I will apply
# this program twice to generate an image (named "mask_interior.rec")
# whose voxels are bright (brightness=1) if they do NOT belong to either
# polyphosphate bodies, or storage granules.
#
# The combine_mrc program can be used with the "+" argument to add voxel
# brightnesses together.  After they are added, the ",0,1" suffix in the
# final argument clips the resulting brightnesses between 0 and 1.
# Hence, voxels in the resulting image file "organelles.rec" are bright (=1)
# if they belong to "storage_granule_blobs.rec" OR "ppb_blobs.rec", or both.
# (In other words, the "+" operator behaves like an OR gate.)

combine_mrc storage_granule_blobs.rec "+" ppb_blobs.rec organelles.rec,0,1

# The combine_mrc program can also be used with the "*" argument to multiply
# the voxel brightnesses of two different images together.  In this case
# the two images have voxel brightnesses which are either 0 or 1.

combine_mrc cytoplasm.rec "*" organelles.rec,1,0 mask_interior.rec

# The ",1,0" suffix inverts the voxel brightnesses of the second input image
# (swapping the 0 and 1 brightness values).
# Hence, the voxels in the final image ("mask_interior.rec") are only bright
# if they are bright in the first image AND if they are NOT bright in the
# second image.  In other words, those voxels are only bright if they lie
# within the cytoplasm, AND if they are NOT in storage granules or
# polyphosphate bodies.


# In the future, we will ignore voxels which lie outside the region of space
# defined by the "mask_interior.rec" file.






# ------------- Part 2) Clean up the image -----------

# OPTIONAL:  First, remove low-frequencies from the image using
# DoG (difference-of-gaussians) filter.  The goal here is to remove any
# slowly-varying gradual changes in brightness gradients from the image.
# We do this because we want a dark blob (eg. ribosome) in one portion of the
# image to have the same average brightness as a similar dark blob somewhere
# else in the image.  Then we can use the same threshold to detect them both.
# Again, this step is optional. In practice, this does not seem to significantly
# improve the quality of blob detection.  (But it doesn't seem to hurt either.)
# For details, see:
# 1) https://en.wikipedia.org/wiki/Difference_of_Gaussians
# 2) the "filter_mrc" documentation concerning the "-dog" argument.


filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -out orig_crop_dog700.rec \
           -dog 0 700.0

# OPTIONAL: Remove extremely dark or extremely bright voxels from the image.
# In practice, this usually does not significantly improve the quality of blob
# detection.  But it doesn't hurt either.
# (See "filter_mrc" documentation concerning the "-cl" argument for details.)

filter_mrc -in orig_crop_dog700.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl3.rec \
           -cl -3 3

# Then apply a Gaussian blur to the image (sigma=35.0 Angstroms).
# For details, see:
# 1) https://en.wikipedia.org/wiki/Gaussian_blur
# 2) the "filter_mrc" documentation concerning the "-gauss" argument

filter_mrc -in orig_crop_dog700_cl3.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl3_gauss35.rec \
           -gauss 35.0

# We will use a standard blob-detection algorithm to hunt for ribosomes.
# But the ribosomes in this image are too close together for automatic blob 
# detection to work effectively.  Blob detection algorithms are bad at
# detecting objects which are very close to each other.  We can get around
# this problem somewhat by making each dark blob smaller (while preserving
# its position and its dark intensity).  To do that we "erode" the dark
# portions of the image, making the smaller.  The left over space in the
# image is filled with light voxels.  Consequently, eroding the dark portions
# of an image is effectively the same thing as increasing the size of the
# bright portions of that image.  Consequently what we are doing is actually
# called image "dilation" (instead of "erosion"). The make the dark blobs in
# an image appear smaller, we should use the "dilation" operation.
# For details, see:
#
#  https://en.wikipedia.org/wiki/Dilation_(morphology)
#  https://en.wikipedia.org/wiki/Erosion_(morphology)
#
# In the command below, we will reduce the thickness of the dark blobs
# in the filtered image by approximately 50.0 Angstroms.  For details, see
# the "filter_mrc" documentation concerning the "-dilate" argument.

filter_mrc -in orig_crop_dog700_cl3_gauss35.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl3_gauss35_dilate40.rec \
           -dilate 50.0   # make the dark regions smaller by ~50.0 Angstroms





# ------------- Part 3) Blob detection -----------




filter_mrc -in orig_crop_dog700_cl3_gauss35_dilate40.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -blob minima ribosome_blob_candidates.txt 120.0 210.0 1.004 \
           -blob-aspect-ratio 1 1 1.2



# (Note: The "-mask" argument tells "filter_mrc" to ignore all voxels that
#  aren't in the "mask_interior.rec" file we created in the previous step.)


# Now discard the faint, noisy, or overlapping blobs.  The remaining list of
# blobs (that we want to ignore later) will be saved in "ribosome_blobs.txt".

filter_mrc -in orig_crop_dog700_cl3_gauss35_dilate40.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -discard-blobs ribosome_blob_candidates.txt ribosome_blobs.txt \
           -radial-separation 0.8 \
           -minima-threshold -39   # (threshold chosen by trial and error.
                                     #  See "NOTE" below for a graphical
                                     #  way to choose these thresholds.)

# The file we just created, "ribosome_blobs.txt", contains the positions
# of all the ribosome-sized blobs in the image.  The X,Y,Z coordinates
# are stored in the first 3 columns of that file, in units of Angstroms.
# (The 4th and 5th columns can be ignored.  If you are curious, those columns
# store the blob diameter (which cannot be trusted), and the "score" of the
# blob, which roughly correlates with how dark the blob is relative to its
# surroundings.)

# Now check to see if we used the correct threshold
# by creating a new image where each ribisome object we detected
# is enclosed in a thin hollow sphere.

# First, create a version of the original image ("orig_crop.rec") which has been
# blurred in the Z direction.  This will make the ribosomes, membranes
# and other features stand out more when viewing with IMOD.

filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -out orig_crop_gauss_20_20_90.rec \
           -gauss-aniso 20 20 90

# Then superimpose the hollow spheres on top of this image:

filter_mrc -in orig_crop_gauss_20_20_90.rec \
           -w 19.6 \
           -out ribosome_blobs_annotated.rec \
           -draw-hollow-spheres ribosome_blobs.txt \
           -background-auto -background-scale 0.4 -spheres-scale 2.2


# NOTE: If you view this image ("ribosome_blobs_annotated.rec") using IMOD/3dmod
#       and if you click on one of the voxels right on the edge of a spherical
#       surface and press "F", IMOD it will report the score for that blob.
#       (But you have to click on the sphere's edge, not inside the sphere.)
#       Some of the spheres will be enclosing ribosomes.
#       Some of them will be enclosing something else (possibly noise).
#
# Choosing the "-minima-threshold" parameter (that we used above).
#
#       By knowing the scores of the blobs that were misidentified as
#       ribosomes, this is a convenient graphical way for you to choose the
#       "-minima-threshold" parameter that we used in the previous step.


# If the results look okay, then create a new image file ("ribosome_blobs.rec")
# whose voxels have brightness 1 inside the ribosomes and 0 everywhere else.

filter_mrc -in orig_crop.rec \
           -w 19.6 \
           -out ribosome_blobs.rec \
           -draw-spheres ribosome_blobs.txt \
           -spheres-scale 1.5 \
           -foreground 1 \
           -background 0


# The image we just created "ribosome_blobs.rec" displays where the
# ribosomes are in the cell, and can be used for visualization.




# Once you are done, delete the temporary files we created earlier:

rm -f orig_crop_dog*.rec
