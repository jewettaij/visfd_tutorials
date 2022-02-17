#!/usr/bin/env bash



# THESE INSTRUCTIONS ARE GENERIC AND WORK FOR ALMOST ALL BACTERIA.
# MANY BACTERIA DO CONTAIN STORAGE GRANULES.
# IN THIS EXAMPLE, THERE WERE NO VISIBLE STORAGE GRANULES IN THE TOMOGRAM/IMAGE.
# BUT WE MUST CREATE A FILE NAMED "storage_granule_blobs.rec".
# OTHERWISE, LATER STEPS IN THE SEGMENTATION PROCESS WILL NOT WORK.
# SO I JUST CREATED A BLANK FILE AND NAMED IT "storage_granule_blobs.rec"
# (TO PREVENT LATER STEPS IN THE SEGMENTATION PROCESS FROM FAILING.)
#
# More specifically, I create a 3D image file the same size as "orig_crop.rec"
# named "storage_granule_blobs.rec", where all the voxels have brightness = 0.
#
# To do that, I run "filter_mrc" with the "-fill 0" option.

filter_mrc -in orig_crop.rec \
	   -out storage_granule_blobs.rec \
	   -fill 0












# ---------------------------------------------------------------
# IF THE CELL YOU ARE SEGMENTING DOES CONTAIN VISIBLE STORAGE GRANULES,
# THE REMAINDER OF THIS FILE DEMONSTRATES HOW TO SEGMENT THEM MANUALLY.
# I included these instructions for completeness. Not relevant to this tomogram.
# ---------------------------------------------------------------



# ----- Goal -----
# Find the locations and diameters of all of the storage granules in the cell.
#
# These objects are difficult to detect because they have similar brightness
# compared to to the nearby surrounding cytoplasm (and nearby nucleoid).
# Since they are difficult to detect, I segment them manually.  Assuming they
# are spherical, I use 3dmod (IMOD) to measure the center and size of
# each spherical storage granule.  Open the original image in 3dmod and click
# on the center of each spherical blob and press the F key.  (The coordinates
# in voxels are also displayed in the main controller window.)  To measure
# the diameters of these storage granules, click on the "Model" button in
# the control window.  Then middle-click on two locations in the image and
# select the "Edit"->"Point"->"Distance" menu option.  This will measure
# the distance between the two points you clicked, in voxels.  Then record
# these numbers in a text file (eg. "storage_granule_blobs.txt").
# (You can create the "storage_granule_blobs.txt" file with a text editor.
#  However, here I use the unix command "cat" together with "<<" and ">"
#  redirection to copy lines of text into the "links_membrane.txt" file.)
#
# Here is an example showing how you could do that:
#
#cat << EOF > storage_granule_blobs.txt
## X   Y  Z   diameter
#(153, 456, 119)  33.5
#(203, 465, 116)  52.4
#(221, 421, 114)  30.0
#(186, 420, 103)  39.3
#(398, 361, 82)  25.7
#(555, 133, 73)  30.4
#(212, 430, 77)  29.5
#EOF
#
# (Note: The x,y,z coords and diameters are in units of voxels, not Angstroms.)
#
# Now use the "filter_mrc" program to create a new image.  In this image
# these spheres will be filled with bright voxels, and the background is dark.
#
#filter_mrc -in orig_crop.rec -w 19.6 \
#  -out storage_granule_blobs.rec \
#  -draw-spheres storage_granule_blobs.txt \
#  -foreground 1 \
#  -background 0


