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
           -w 19.6 \
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
           -w 19.6 \
           -mask mask_interior.rec \
           -out nucleoid_soft.rec \
           -thresh2 0.125 0.114

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
# Does it look reasonable?  Yes.  (In my opinion.)
# Okay to proceed...

# In the "nucleoid_soft.rec" image, the brightness varies gradually from 0 to 1.
# (0 = outside the nucleoid, 1 = the center of the nucleoid).  When visualizing
# the nucleoid, it will appear to have a soft, smooth boundary.  However you
# might prefer to work with binary images, whose brightness is either 0 or 1.
# To do that, use a narrow range of "-thresh2" arguments:

filter_mrc -in orig_crop_fluct200.rec \
           -w 19.6 \
           -mask mask_interior.rec \
           -out nucleoid.rec \
           -thresh2 0.11700 0.11699 #<--voxels with fluctuation below 0.12
                                    #   will end up with brightness 1. others 0



# --------- method to remove disconnected islands -----------
#
# Some of the white clouds are islands which are not connected to the nucleoid.
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
