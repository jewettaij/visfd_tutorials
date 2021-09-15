#!/usr/bin/env bash



# ------------- Goal --------------
#
# In STEPS 1 through 6, we created individual 3-D image
# files for each type of object in the cell:
#
#   membrane_outer.rec           <-- voxels inside the outer membrane
#   membrane_inner.rec           <-- voxels inside the inner membrane
#   ppb_blobs.rec                <-- voxels inside the polyphostate bodies
#   storage_granule_blobs.rec    <-- voxels inside the polyphostate bodies
#   ribosome_blobs.rec           <-- voxels inside ribosome-sized blobs
#   nucleoid.rec                 <-- voxels inside the nucleoid.
#
# You can load all of these files in ChimeraX and display them simultaneously.
#
# However, it is more convenient to work with a single file.
# In this file, I explain how to combine these files into one 3-D image file
# ("segmented_image.rec").  The brightness of each voxel indicates which object
# that voxel belongs to:
#
#   0  outside the cell
#   1  periplasm
#   2  cytoplasm
#   3  polyphosphate bodies
#   4  storage granules
#   5  ribosomes
#   6  the nucleoid


# ----- Start with the nucleoid. -----
# The voxels in the "nucleoid.rec" file have brightness 1 if they
# are in the nucleoid, and 0 otherwise.  We want 
# We want to set the brightness of voxels in the nucleoid to 6.
# We can do that using "filter_mrc" with the "-rescale m b" argument:
# new_brightness = m*old_brightness + b.
# (We'll worry about the other voxels later.)
           
filter_mrc -in nucleoid.rec \
           -w 18.08 \
           -out segmented_image.rec \
           -rescale 6 0

# Keep track of which voxels have already been chosen, and which are available.
# We want an image whose voxels are 1 if they have not been "used" yet
# (ie. assigned to anything yet), and 0 otherwise.  Since we have "used"
# the voxels in the nucleoid, we want to invert the brightnesses of the
# voxels in the "nucleoid.rec" file (swapping 1s with 0s).

filter_mrc -in nucleoid.rec \
           -w 18.08 \
           -out unused_voxels.rec \
           -rescale -1 1   # new voxel brightness = -1*old_brightness + 1


# ----- Now include the ribosomes in the segmentation. -----
# Set the brightness of voxels in the ribosomes to 5.

# Use the "unused_voxels.rec" image as a mask to make sure we don't re-use them.

filter_mrc -in ribosome_blobs.rec \
           -w 18.08 \
           -mask unused_voxels.rec \
           -rescale 5 0 \
           -out temporary_file.rec

# Add the voxels in "ribosome_blobs.rec" to the voxels in "segmented_image.rec".
combine_mrc segmented_image.rec "+" temporary_file.rec segmented_image.rec

# As we add more different kinds of objects to the "segmented_image.rec" file,
# keep track of the voxels we have not used yet.
# Those voxels are stored in the "unused_voxels.rec" file.
# So we remove the voxels in "ribosome_blobs.rec" by subtracting their
# brightnesses from the voxel brightnesses in "unused_voxels.rec".  (We clip
# the resulting brightnesses between 0 and 1 to avoid negative brightnesses.)
combine_mrc unused_voxels.rec "-" ribosome_blobs.rec unused_voxels.rec,0,1



# ----- Now include the storage granules in the segmentation. -----
# Set the brightness of voxels in the storage granules to 4.

filter_mrc -in storage_granule_blobs.rec \
           -w 18.08 \
           -mask unused_voxels.rec \
           -rescale 4 0 \
           -out temporary_file.rec
combine_mrc segmented_image.rec "+" temporary_file.rec segmented_image.rec
combine_mrc unused_voxels.rec "-" storage_granule_blobs.rec unused_voxels.rec,0,1


# ----- Now include the polyphosphate bodies in the segmentation. -----
# Set the brightness of voxels in the polyphosphate bodies to 3.

filter_mrc -in ppb_blobs.rec \
           -w 18.08 \
           -mask unused_voxels.rec \
           -rescale 3 0 \
           -out temporary_file.rec
combine_mrc segmented_image.rec "+" temporary_file.rec segmented_image.rec
combine_mrc unused_voxels.rec "-" ppb_blobs.rec unused_voxels.rec,0,1


# ----- Now include the remaining voxels in the cytoplasm in the segmentation.
# Set the brightness of the remaining voxels in the cytoplasm to 2.

filter_mrc -in membrane_inner.rec \
           -w 18.08 \
           -mask unused_voxels.rec \
           -rescale 2 0 \
           -out temporary_file.rec
combine_mrc segmented_image.rec "+" temporary_file.rec segmented_image.rec
combine_mrc unused_voxels.rec "-" membrane_inner.rec unused_voxels.rec,0,1


# ----- Now include voxels in the periplasm in the segmentation -----
# Set the brightness of the voxels in the periplasm to 1.

filter_mrc -in membrane_outer.rec \
           -w 18.08 \
           -mask unused_voxels.rec \
           -rescale 1 0 \
           -out temporary_file.rec
combine_mrc segmented_image.rec "+" temporary_file.rec segmented_image.rec
combine_mrc unused_voxels.rec "-" membrane_outer.rec unused_voxels.rec,0,1


# ----- The remaining voxels (outside the cell) should have brightness 0


# Now delete the temporary files:

rm -f unused_voxels.rec temporary_file.rec

