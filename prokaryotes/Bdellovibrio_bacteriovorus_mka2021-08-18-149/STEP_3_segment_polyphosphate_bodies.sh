#!/usr/bin/env bash

# ------- Goal: Detect polyphosphate bodies --------

# There are several ways one might segment polyphosphate bodies (PPBs).
# 1) Use a standard blob-detection algorithm to locate them and measure
#    their size.  Then use the "-draw-spheres" argument to create a
#    new 3-D image that highlights the voxels which lie within these PPBs.
# 2) Use a combination of low-frequency removal, blurring, thresholding,
#    and morphological closing and openning operations, to detect
#    dark objects larger than a certain size.  (See below.)
# 3) Use an edge detector to detect the surface of each dark region (PPB).
#    Then close each surface, and fill it.  This is similar to the (laborious)
#    method we used to segment the volume of the cell.
#
# In this file, we use method #1.  The other two methods are discussed
# in slightly more detail at the end of this file.
#
# 
# Using method #1 (standard spherical blob-detection).
#
# Again, polyphosphate bodies are substantially darker than their surroundings.
# They are also (approximately) spherical.  This makes it possible to use a
# standard blob detector to segment them automatically.
# As with the fiducial beads, we use the "-blob" detection argument
# to locate the polyphosphate bodies, and measure their size.
# These structures are much larger than the gold fiducial beads.
# In this image their diameters lie in the range from 760 to 1000 Angstroms.
# So when I use the "-blob" argument to detect them, I use a range which
# comfortably encloses this range of diameters (eg 600.0 to 1400.0 angstroms).

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask cytoplasm.rec \
  -blob minima ppb_blob_candidates.txt 600.0 1400.0 1.01

# Note: The "-mask cytoplasm.rec" argument tells the detector to ignore
#       blobs which are outside the cytplasmic volume.


# Now select the blobs we want using a score threshold ("-30")
# (This threshold was determined by trial and error. See below.)

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask cytoplasm.rec \
  -discard-blobs ppb_blob_candidates.txt ppb_blobs.txt \
  -minima-threshold -30 \
  -radial-separation 0.9

# Now generate an image superimposing spherical shells at
# the positions of the blobs we detected earlier.
# This effectively annotates the original image with markers.

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask cytoplasm.rec \
  -out ppb_blobs.rec \
  -draw-hollow-spheres ppb_blobs.txt \
  -background-auto

# Now verify that the threshold was chosen correctly using
#  3dmod -S ppb_blobs.rec
#
# Hopefully the polyphosphate bodies in this object were highlighted.
# It's okay if other objects are detected as long as they are outside
# of the cell, since we will use a mask to discard those objects later.
# If everything looks good, then replace the "ppb_blobs.rec" file with
# one where the blobs are white on a black background.

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask cytoplasm.rec \
  -out ppb_blobs.rec \
  -draw-spheres ppb_blobs.txt \
  -foreground 1 \
  -background 0 \
  -spheres-scale 1.01 #optional: make spheres 1% larger (to be on the safe side)





#     ------ alternative method details -------
#     ------ PLEASE IGNORE THIS SECTION -------
#
#  The method above only works if the objects you want to detect are spherical.
#  The methods below are useful for detecting non-spherical dark blobs.
#  THESE METHODS ARE MORE LABORIOUS.  For completeness, I sketch
#  these methods below.  FEEL FREE TO SKIP OVER THIS SECTION.
#
# 2) Polyphosphate bodies are darker than their surroudnings.
#    So you can use blurring ("-gauss") followed by thresholding ("-thresh")
#    to select the dark regions of the cell.  Unfortunately, there are many
#    other smaller dark objects in the cell as well (such as the ribosomes).
#    Those can be eliminated by invoking "filter_mrc" with the "-closing"
#    argument, to eliminate dark objects smaller than a certain size.
#
# 3) Invoke "filter_mrc" with the "-edge" argument to find the boundary
#    surfaces of all of the polyphosphate bodies (and other dark objects)
#    in the image.  Then construct closed surfaces using the "-connect"
#    argument followed by using the "SSDRecon" or "PoissonRecon" programs.
#    Then use "voxelize_mesh.py" to fill in each surface.
#    This is the same procedure used for detecting and segmenting the
#    cell boundary, except we use "-edge" instead of "-membrane.
#    The polphosphate bodies can be distinguished from other dark objects
#    in the cell due to their larger size.  This is a laborious process
#    because we need to repeat this for the N largest objects in the cell.
#    (Where N is the number of polyphosphate bodies.)
#
#     ------ end of alternative methods ------
