
# ---- Creating the mask file we will need ----
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



# ----- Detecting the nucleoid -----

# The nucleoid does not contain any ribosomes or any large proteins
# that would appear as dark spots in the tomogram.  Since there are no large
# dark objects in the nucleoid visible at this resolution, the brightness
# inside the nucleoid is relatively constant throughout (compared to the rest
# of the cytoplasm).  This suggests a simple strategy to segment the nucleoid.
#
# Here we use a filter that will detect regions in the 3-D image whose
# brightness does not fluctuate very much compared to the nearby voxels
# (ie. within local neighborhood of approximately 200.0 Angstroms).
# See the "filter_mrc" documentation for the "-fluct" argument for details.

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask mask_interior.rec \
  -out nucleoid.rec \
  -fluct 200.0 \
  -thresh2 0.115 0.095 #<--optional: invert brightness to make nucleoid bright

# Then view the newly created 3D image ("nucleoid.rec") using 3dmod or chimerax.
# Does it look reasonable?
#
# RESULT:  No.  (Not in this example.)
#
# Why?  In the original 3-D image file ("orig_crop.rec"), there is sort of a
# faint diffuse gray cloud above and below the nucleoid (high and low Z).
# The crude filter I am using is misinterpreting these hazy clouds as the
# nucleoid.  Rather than try to come up with a more sophisticated way to
# ignore these clouds, I will just remove them manually.  To do that,
# I will alter the mask so that it also ignores several rectangular
# regions where these gray clouds are located.  I do this using the
# "-mask-rect-subtract" argument.  (See the "filter_mrc" documentation.)
# Then I run "filter_mrc" again using this updated mask.
#
# (Note: This is unfortunately pretty common.
#  I often end up relying on using custom masks to ignore portions of the
#  image that are being erroneously detected as interesting features.)

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask mask_interior.rec \
  -mask-rect-subtract   0 10000    0   10000    155 10000 \
  -mask-rect-subtract   0 598      310 10000    0   58 \
  -mask-rect-subtract   0 10000    0   10000    0   45 \
  -out nucleoid.rec \
  -fluct 200 \
  -thresh2 0.115 0.095 #<--optional: invert brightness to make nucleoid bright

# View the resulting image file "nucleoid.rec" to see if the process worked




# --------- method to remove disconnected islands -----------
#
# Fortunately, these dark clouds are not connected to the nucleoid.
# So more sophisticated way to get rid of these clouds is to blur it using
# the "-gauss" argument, and then run "filter_mrc" using the "-watershed",
# and "-watershed-threshold" arguments.  This will find all of the disconnected
# dark "islands" in the image, and keep only the largest one (the nucleoid).
# It might be a good idea to get rid of all of these tiny little islands
# anyway.  If I have time, perhaps I'll add some more detailed instructions
# explaining how to do this.
#
# (Even if some of the unwanted blobs are connected to the nucleoid, you can
#  still probably discard them by running "filter_mrc" with the "-gauss" and
#  then the "-openning" argument.  The "-openning" argument will erode any
#  tiny connections between big blobs.  Then you can apply "-watershed" and
#  "-watershed-threshold" to locate the biggest blobs.
#  See "filter_mrc" docs for details.)
#
# ----------------------------------------
