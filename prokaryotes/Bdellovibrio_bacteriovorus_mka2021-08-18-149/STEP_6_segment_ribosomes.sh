
# ---- Goal ----
#
# In this file, we will use a standard "scale-free blob detection" algorithm to
# search for dark blobs in the image which are the size of ribosomes.  This will
# create a file with a list of the positions of all the ribosomes in the cell.
# We will also segment the image, creating a new image ("ribosome_blobs.rec")
# that highights all the voxels which belong to ribosomes.
#
#   (For details on blob-detection, see:
#    https://en.wikipedia.org/wiki/Blob_detection)
#
# THIS IS NOT AN OPTIMAL WAY TO DETECT RIBOSOMES.
# Other template-based methods (such as the "MolMatch" software) probably
# work much better for detecting molecules with a well known shape.
# I RECOMMEND USING THAT STRATEGY INSTEAD.
#
# Unfortunately, the source code for that "MolMatch" has not been made public,
# (and some other tools require MatLab).
#
#
# -- Limitations / Disclaimer --
#
# Unfortunately, the blob-detection strategy we use here is fairly crude.
# It won't be able to distinguish the ribosomes in the cell from other
# dark blobs.  Depending on the threshold parameter we use, there will
# definitely be many false positives (and a few false negatives).
# But (with enough effort), it's usually possible to correctly identify
# ribosomes -at least- 70% of the time (in high-quality tomograms)
# using this strategy.  (If you tinker with the parameters enough,
# you can often do better.)  Again, if you can find other software desgined
# for detecting molecules in tomograms, I recommend using that instead.


# Strategy:
#
# 1) Clean up the image and process it beforehand to make the blobs you are
#    trying to detect stand out as much as possible.  (This usually involves
#    making the gap between dark blobs in the image wider, so that they
#    are easier to distinguish from each other.  See below.)
#
# 2) Then use a blob-detction algorithm to find the dark blobs in the image.





# ------------- Part 1) Clean up the image -----------

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
           -w 18.08 \
           -mask mask_interior.rec \
           -out orig_crop_dog700.rec \
           -dog 0 700.0

# OPTIONAL: Remove extremely dark or extremely bright voxels from the image.
# In practice, this usually does significantly improve the quality of blob
# detection.  But it doesn't hurt either.
# (See "filter_mrc" documentation concerning the "-cl" argument for details.)

filter_mrc -in orig_crop_dog700.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl2.rec \
           -cl -2 2

# Then apply a Gaussian blur to the image (sigma=35.0 Angstroms).
# For details, see:
# 1) https://en.wikipedia.org/wiki/Gaussian_blur
# 2) the "filter_mrc" documentation concerning the "-gauss" argument

filter_mrc -in orig_crop_dog700_cl2.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl2_gauss35.rec \
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

filter_mrc -in orig_crop_dog700_cl2_gauss35.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -out orig_crop_dog700_cl2_gauss35_dilate50.rec \
           -dilate 50.0   # make the dark regions smaller by ~50.0 Angstroms





# ------------- Part 2) Blob detection -----------




filter_mrc -in orig_crop_dog700_cl2_gauss35_dilate50.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -blob minima ribosome_blob_candidates.txt 120.0 180.0 1.004 \
           -blob-aspect-ratio 1 1 1.2



# (Note: The "-mask" argument tells "filter_mrc" to ignore all voxels that
#  aren't in the "mask_interior.rec" file we created in the previous step.)


# Now discard the faint, noisy, or overlapping blobs.  The remaining list of
# blobs (that we want to ignore later) will be saved in "ribosome_blobs.txt".

filter_mrc -in orig_crop_dog700_cl2_gauss35_dilate50.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -discard-blobs ribosome_blob_candidates.txt ribosome_blobs.txt \
           -radial-separation 0.8 \
           -minima-threshold -22.75  # (threshold chosen by trial and error)

# The file we just created, "ribosome_blobs.txt", contains the positions
# of all the ribosome-sized blobs in the image.  The X,Y,Z coordinates
# are stored in the first 3 columns of that file, in units of Angstroms.
# (The 4th and 5th columns can be ignored.  If you are curious, those columns
# store the blob diameter (which cannot be trusted), and the "score" of the
# blob, which roughly correlates with how dark the blob is relative to its
# surroundings.)

# Now check to see if we used the correct threshold
# by creating a new image where each ribisome object we detectec
# is enclosed in a thin hollow sphere.

filter_mrc -in orig_crop_dog700_cl2_gauss35.rec \
           -w 18.08 \
           -out ribosome_blobs.rec \
           -draw-hollow-spheres ribosome_blobs.txt \
           -background-auto -background-scale 0.3 -spheres-scale 1.7


# If the results look okay, then replace the "ribosome_blobs.rec" file
# with a new image whose voxels have brightness 1 inside the ribosomes,
# and 0 everywhere else.

filter_mrc -in orig_crop.rec \
           -w 18.08 \
           -out ribosome_blobs.rec \
           -draw-spheres ribosome_blobs.txt \
           -spheres-scale 1.5 \
           -foreground 1 \
           -background 0


# The image we just created "ribosome_blobs.rec" displays where the
# ribosomes are in the cell, and can be used for visualization.




# Once you are done, delete the temporary files we created earlier:

rm -f orig_crop_dog*.rec
