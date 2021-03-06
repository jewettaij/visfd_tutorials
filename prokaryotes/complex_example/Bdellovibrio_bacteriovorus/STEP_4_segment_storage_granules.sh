#!/usr/bin/env bash



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

cat << EOF > storage_granule_blobs.txt
# X   Y  Z   diameter
153 456 119  33.5
203 465 116  52.4
221 421 114  30.0
186 420 103  39.3
398 361 82  25.7
555 133 73  30.4
212 430 77  29.5
EOF

filter_mrc -in orig_crop.rec -w 1 \
  -out storage_granule_blobs.rec \
  -draw-spheres storage_granule_blobs.txt \
  -foreground 1 \
  -background 0 \
  -spheres-scale 1.01 #optional: make spheres 1% larger (to be on the safe side)

# (Note: The "-w 1" argument was necessary in this case because the coordinates
#        in the text file are in units of voxels, not of Angstroms.)



