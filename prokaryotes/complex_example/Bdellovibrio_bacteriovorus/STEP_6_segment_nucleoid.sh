#!/usr/bin/env bash



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
# Save the result in the "orig_crop_fluct200.rec" file.
# (See the "filter_mrc" documentation for the "-fluct" argument for details.)

filter_mrc -in orig_crop.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -out orig_crop_fluct200.rec \
           -fluct 200.0

# Then view the newly created 3D image ("orig_crop_fluct200.rec", using
# IMOD/3dmod or something similar).
# Then adjust the contrast thresholds until you can see the nucleoid clearly.

# In the "orig_crop_fluct200.rec" file we just created regions with large
# fluctuations in brightness appear bright.  Regions with lower fluctuations
# in brightness (where the nucleoid is located) appear darker.  We want
# to create an image where the nucleoid is brighter than its surroundings.
# So I use the "-thresh2" argument to invert the brightness from that image.
# (See the "filter_mrc" documentation for the "-thresh2" argument for details.)


filter_mrc -in orig_crop_fluct200.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -out nucleoid_soft.rec \
           -thresh2 0.115 0.097

# What "-thresh2" parameters should we use?  To find out, view the
# "orig_crop_fluct200.rec" image file in IMOD/3dmod.  Click on
# somewhere in the image near where you think the edge of the nucleoid
# should be.  Then press the "F" key to print out the magnitude of the
# fluctuations at that location.  Do this a few times.  This should give you
# a range of numbers.  Use this range of numbers with the "-thresh2" argument
# (larger number first).
#
#
# Now view this newly created 3D image ("nucleoid.rec") using chimerax.
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

filter_mrc -in orig_crop_fluct200.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -mask-rect-subtract   0 10000    0   10000    155 10000 \
           -mask-rect-subtract   0 598      310 10000    0   58 \
           -mask-rect-subtract   0 10000    0   10000    0   45 \
           -out nucleoid_soft.rec \
           -thresh2 0.115 0.097


# View the resulting image file ("nucleoid_soft.rec")
# to see if the process worked.


# In the "nucleoid_soft.rec" image, the brightness varies gradually from 0 to 1.
# (0 = outside the nucleoid, 1 = the center of the nucleoid).  When visualizing
# the nucleoid, it will appear to have a soft, smooth boundary.  However you
# might prefer to work with binary images, whose brightness is either 0 or 1.
# To do that, use a narrow range of "-thresh2" arguments:

filter_mrc -in orig_crop_fluct200.rec \
           -w 18.08 \
           -mask mask_interior.rec \
           -mask-rect-subtract   0 10000    0   10000    155 10000 \
           -mask-rect-subtract   0 598      310 10000    0   58 \
           -mask-rect-subtract   0 10000    0   10000    0   45 \
           -out nucleoid.rec \
           -thresh2 0.1095001 0.1095 #<--voxels with fluctuation below 0.1095
                                     #   will end up with brightness 1. others 0



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
