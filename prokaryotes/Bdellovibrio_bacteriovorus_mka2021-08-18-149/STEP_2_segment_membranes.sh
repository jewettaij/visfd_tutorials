#!/usr/bin/env bash



# WARNING: In these instructions, it is assumed that the voxel width
#          is 18.08 Angstroms.  If not, replace this number everywhere.




#   ---- Goal: Segment the inner membrane of the cell and its contents ----
#
# Terminology: I use the phrase "3-D image" and "tomogram" interchangeably.
#
# When detecting the features we care about inside a cell, it will makes our
# life much easier if we can ignore the region outside the cell.
# So the next step is to figure out which voxels lie inside the cytoplasm,
# and which voxels lie outside.
#
# To do that, we will attempt to segment the inner membrane of a cell,
# generating a PLY file (containing surface polyhedral mesh geometry),
# on the boundary of the cytoplasm, as well as a new 3-D image file (REC file)
# indicating which voxels lie inside the cytoplasm.
# We will use that REC file as a mask in later calculations.
#
# PREREQUISITES
#
# 1) A 3-D image file (tomogram) containing the cell you want to segment.
# It is a -VERY- good idea to crop this tomogram beforehand so that it
# only includes the cell you want to segment.  (You can do this using
# "3dmod", "trimvol", or the "crop_mrc" program distributed with visfd.)
# Otherwise the algorithm will be extremely slow, and your computer is also
# likely to run out of memory (freezing up and becomming unresponsive).
#
# The tomogram in this example is named "orig_crop.rec".
#
# 2) If the tomogram contains extremely dark objects, such as gold fiducial
# beads or ice contamination, then it is also a GOOD idea to remove this debris
# from the tomogram.  To do that create a mask file (eg. "mask_blobs.rec").
# This file has brightness 0 in regions from the image containing these
# objects that we want to exclude from consideration.
#
# To do that, follow the instructions in the "STEP_1" file.
# That will create a 3-D image file named "fiducial_blobs.rec".
# The bright regions in that image contain any gold fiducial beads
# which might be present outside the cell.  In the steps below, we
# a "mask" 3D image file whose voxel brightnesses are 1 everywhere we want to
# consder, and 0 everwhere we want to ignore (such as the gold beads).
# So, I invert the brightnesses of the voxels in the "fiducial_blobs.rec"
# file using this command:

filter_mrc -in fiducial_blobs.rec -out mask_membranes.rec -thresh2 1 0


# Later we will use this mask_membranes.rec file when detecting other objects.



# --------- Detect all membranes in the image (width ~= 80 Angstroms) --------

filter_mrc -in orig_crop.rec -w 18.08 \
  -mask mask_membranes.rec \
  -out orig_crop_mem80.rec \
  -membrane minima 80.0 \
  -tv 5 -tv-angle-exponent 4 -tv-best 0.1 \
  -save-progress temporary_file \
  -cl -0.5 0.5 #<--Limit the brightness of the output file to 0.5 x std-dev
               #  (For easier viewing in IMOD. This does not change the result.)


#     Details:  (Feel free to skip.)
#
# -The "-w 18.08" argument specifies the voxel width in Angstroms.
# -The "80.0" parameter indicates the approximate width parameter for
#  membrane detection (in Angstroms).  It should be approximately equal to the
#  membrane width but it can be a little bit larger.  Values of 60-85 Angstroms
#  seem to work well.
# -The "-cl -0.5 0.5" arguments make it easier to view the "orig_crop_mem80.rec"
#  we created above in visualizer programs like 3dmod, but has no other effect.
# -The "-save-progress" argument enables us to save time.  In the future, we
#   skip the calculation we just ran by using the "-load-progress" argument.
# -We use "-membrane" with the "minima" argument because we are
#  searching for a dark membrane-like surface on a brighter background.
# -The "-tv 5" and "-tv-angle-exponent" "-tv-best" parameters
#  can usually be left alone.  (They are used for tensor-voting, which is a
#  popular strategy to improve signal-to-noise when detecting membranes.)


# The command above detects all of the membrane-like surfaces in the 3-D image.
# However these membranes are incomplete.  They are often have large missing
# regions.  For example, in electron tomography:
# Membrane surfaces in the XZ plane are often faint (compared to the YZ plane).
# Membrane surfaces in the XY plane are invisble due to the missing wedge
# artifact.  These missing regions sometims break a smooth closed membrane
# into multiple disconnected fragments.
#
# The process of creating closed surfaces from one or more incomplete
# membrane fragments is called "surface reconstruction".
# We will use several tools to do that below.


# ----------------- segment the inner membrane ----------------------
#
# Now open the newly created tomogram "orig_crop_mem80.rec"
# with visualizer software (such as IMOD's "3dmod" program).
# Membranes in EM tomograms are often faint or invisible in certain directions.
# So the membrane detector can usually only detect small disconnected fragments
# in the membrane surface. You can see these when you view "orig_crop_mem80.rec"
#
# In the next step, we will try to fuse these fragments into a closed surface.
# This process is mostly automatic.  However it usually does require some
# manual intervention.  If the membranes we care about appear to be broken into
# disconnected fragments (as you can see in this example when viewing the
# "orig_crop_mem80.rec" file we just created),
# ...then we must manually let our software know which of these small fragments
# belong to the larger closed membrane surface that we want to segment.
#
# So view the original 3-D image file (eg. "orig_crop.rec") using 3dmod.
# (NOT the new "orig_crop_mem80.rec" file we just created).  Then click on
# places along the membrane you want to segment, selecting least one point from
# each likely fragment. (You can see where the fragments are by viewing the
# lower-resolution image we just created "orig_crop_mem80.rec".)
# After clicking, press the "F" key to print out the XYZ coordinates of
# that point to 3dmod's control window.  Copy these XYZ coordinates
# (in units of voxels) to a text file ("links_membrane.txt"), and surround
# them with parenthesis.  (See example below.)
# (You can create the "links_membrane.txt" file with a text editor.  However,
#  here I use the unix command "echo" together with ">" and ">>" redirection
#  to print those lines of text into the "links_membrane.txt" file.)

echo "(259 534 102)"  > links_membrane.txt  # inner membrane
echo "(152 534 102)" >> links_membrane.txt  # inner membrane
echo "(237 351 102)" >> links_membrane.txt  # inner membrane
echo "(629 47 102) " >> links_membrane.txt  # inner membrane
echo "(629 197 102)" >> links_membrane.txt  # inner membrane
echo "(440 442 107)" >> links_membrane.txt  # inner membrane
echo "  # blank line separates different connected surfaces">>links_membrane.txt
echo "(258 552 107)" >> links_membrane.txt  # outer membrane
echo "(153 551 107)" >> links_membrane.txt  # outer membrane
echo "(237 337 107)" >> links_membrane.txt  # outer membrane
echo "(618 22 88)"   >> links_membrane.txt  # outer membrane

# If you are unfamiliar with the "echo" command then open up the
# "links_membrane.txt" file with a text editor to see what it looks like.
#
# Comment: Alternatively, you could measure the position of membrane
# fragments from the "orig_crop_mem80.rec" file we just created (or the
# "membrane_clusters.rec" we will create in the next step).  But since those
# images are probably down-sampled, you will need to multiply the X,Y,Z
# coordinates by a factor of 2 or 3 to compensate if you do that.




# Now try to connect the surface fragments together into contiguous membranes.

filter_mrc -in orig_crop.rec \
           -w 18.08 \
           -load-progress temporary_file \
           -out membrane_clusters.rec \
           -connect 0.03 -connect-angle 15 \
           -must-link links_membrane.txt \
           -select-cluster 2 \
           -normals-file membrane_inner_pointcloud.ply

# In the previous calculation, we asked "filter_mrc" to generate a PLY
# file containing the surface geometry of the second-largest surface
# in the image.  Usually this will be the inner membrane.
# (The outer membrane is usually the largest surface in the tomogram.)
#
# All of these parameters make reasonably good defaults for membrane
# detection EXCEPT the "-connect" parameter ("0.01" in the example).
# It must be chosen carefully because it will vary from image to image.
# As of 2021-9-10, strategies for choosing this parameter are discussed here:
# https://github.com/jewettaij/visfd/blob/master/doc/doc_filter_mrc.md#determining-the--connect-threshold-parameter
#
# So repeat the step above with different parameters until the resulting
# "membranes_clusters.rec" shows that the various surface fragments
# that belong to the surface you care about have been merged and have
# the same ID-number.
# (Verify this by opening the file in 3dmod, clicking on different portions
# of the dark surface that you care about, pressing the "F" key each time,
# and checking if the resulting ID numbers match.)
# If they do, then it is time to view the PLY file we just created
# in 3-D to verify it has the shape we expect.
# You can use the "meshlab" program to do this:
#
#   meshlab membrane_inner_pointcloud.ply
#
# Does it look correct?
#
#  (Don't worry too much about the huge missing regions at the top
#   and bottom of the cell.  These are due to the missing wedge.
#   However if there is something undesirable and unexpected attached
#   the the membrane, or connecting two different membranes together,
#   then we should probably eliminate this problematic part of the image
#   and try again before proceeding. This is typically done using the
#   "-mask", "mask-rect-sutract", or "mask-sphere-sutract" arguments.
#   See "filter_mrc" documentation for details.)
#
# If everything is okay, then proceed with the next step (using "PoissonRecon").




# Now use "SSDRecon".  This program will attempt to create a closed
# surface which passes through these points in a reasonable way.
# "SSDRecon" is distributed along with "PoissonRecon", which is available at:
#
# https://github.com/mkazhdan/PoissonRecon
#
# (I first tried using "PoissonRecon", but it failed to produce a single 
#  closed connected surface.  The "SSDRecon" software performed better
#  for this example, so I am using that instead.  The two programs
#  use nearly identical arguments.)

SSDRecon --in membrane_inner_pointcloud.ply \
  --out membrane_inner_rough.ply --depth 12 --scale 2.0

# Now see if the reconstruction process worked.

meshlab membrane_inner_rough.ply

# If it doesn't look good, it could be for many reasons.
#
#
#     Possible catastrophic failures:
#
#
# If the surface is not a closed surface, try running
# "SSDRecon" again with a larger "--scale" parameter.
# (If the surface volume is missing large regions,
#  you might try using a smaller "--scale" parameter.)
#
# If the surface looks terrible (as if part of it is inside-out), then follow
# these instructions:
#
# https://github.com/jewettaij/visfd/blob/b9564ca3bb7b3d52ab2d38fbef15330012accdcd/doc/doc_filter_mrc.md#manual-specification-of-fragment-orientation
# 
# If that fails, try using "PoissonRecon" instead of "SSDRecon".
# (Both programs accept the same arguments and are distributed together.
#  Instructions for installing both programs should be in this directory.)
#
# The SSDRecon and PoissonRecon programs change all the time.
# If both "SSDRecon" and "PoinssonRecon" fail, then try downloading the
# version I used when preparing this tutorial.  To do that, enter:
# git clone https://github.com/jewettaij/PoissonRecon ~/PoissonRecon_jewettaij
# and follow the same installation instructions you used earlier to compile
# that version of the code.
#
#     Minor failures:
#
# If the surface becomes accidentally fused with something else
# (such as another membrane, or some other object), you can use one or more
# "-mask-sphere-subtract" and/or "-mask-rect-subtract" arguments
# to ignore the region or regions where these two objects touch each other.
# This will be demonstrated later.
#
# The surface will likely have some defects, typically located near
# the edge of the detectable portion of the original membrane surface
# where the signal is weak and noise dominates.  Depending upon
# how serious those defects are, you may want to re-run the membrane
# connection step again (combining the "-connect" argument with the
# "-mask-sphere-subtract" and/or "-mask-rect-subtract" arguments
# to omit problematic regions of the 3-D image from consideration.
#
# These kinds of problems can almost always be resolved this way.
# (See the documentation for "filter_mrc" for details.)
#
# Fortunately, for this membrane, these steps weren't really necessary.
#
# Finally, the interpolation process often has difficulty filling large holes
# on the surface, such as the top and bottom holes created by the missing wedge.
# The surface may appear be bulged out in these regions.  This is normal.
# This problem can be ameliorated by smoothing.  (See the instructions
# below for smoothing the membrane using meshlab.)



# Now we are ready to apply a smoothing filter to the closed surface
# we created in the previous step "membrane_inner_rough.ply".
#
# 1) Open the "membrane_inner_rough.ply" file in meshlab, and select the
# "Filters"->"Smoothing, Fairing and Decomposition"->"HC Laplacian Smooth"
# menu option.  Click the "Apply" button until the surface looks reasonable.
# (I ended up pressing the "Apply" button about 70 times for this example to
#  eliminate the obvious bulge in the Z direction.  Some tomograms may require
#  less smoothing.  After I eliminated the bulge, I kept going until the surface
#  resembled the kind of squished shape that one normally sees when cells are
#  pressed against a grid surface during sample preparation.
#  Cells on grids are rarely round.)
#
# 2) Optional: Reduce the number of polygons in the surface. (Warning: This step
#  sometimes causes tears in the surface which cause "voxelize_mesh.py" to fail.
#  If "voxelize_mesh.py" crashes later on, then skip this step.)  Select the
#    "Filters"->"Remeshing, Simplification and Reconstruction"->
#    ->"Simplification: Quadratic Edge Collapse Decimation" menu option.
# Reduce the number of polygons in the mesh down to about 20000 or less.
#
# 3) Then select the "File"->"Export Mesh" menu option and give the file a
# new name (eg "membrane_inner.ply").  (Optional: Uncheck the
# box named "binary encoding" box before clicking on the "Save" button.
# Not all mesh analysis software can read PLY files with a binary encoding.)

# Now find all of the voxels which lie inside the closed surface we
# just detected using the "voxelize_mesh.py" program.
# This program 

voxelize_mesh.py \
  -w 18.08 \
  -m membrane_inner.ply \
  -i orig_crop.rec \
  -o membrane_inner.rec

# This command used 12 Gb of (free) RAM, and required 13 minutes to complete.
# If your computer has less than 16 Gb of RAM, do not attempt this.
# (In that case, if you have access to a computer cluster running SLURM, I
#  included a slurm script in the directory "slurm_scripts_for_voxelization".)
#
# The newly created file "membrane_inner.rec" is a 3-D image file whose voxels
# have brightness 1 if they are inside the closed membrane surface, and 0
# outside.  Later on, we will use this image to decide what voxels to consider
# when trying to segment ribosomes and other contents within the cytoplasm.
# Unfortunately, since the membrane itself is usually several voxels in
# thickness, some of those membrane voxels will be located within this volume,
# since it lies right on the boundary.  The membrane is darker than its
# surroudings.
#
# We don't want the detection software to notice or get distracted
# by these little dark membrane fragments on the cytoplasm boundary
# when trying to detect objects that are supposed to be inside it.
# So I create a new 3-D image containing a slightly thinner, contracted
# version of the previous image we just created ("cytoplasm.rec").
# (For details, see the "filter_mrc" documentation for "-erode-gauss".)


# --- Initial attempt (commenting out) ---
# filter_mrc -in membrane_inner.rec -w 18.08 \
#  -out cytoplasm.rec \
#  -erode-gauss 40  # Contract the interior region by a distance of 40 Angstroms
#                   # (This is approximately half the membrane thickness.)
# Later, I decided 40 wasn't enough, and raised it to 160 Angstroms
# --------


filter_mrc -in membrane_inner.rec -w 18.08 \
  -out cytoplasm.rec \
  -erode-gauss 160 # Contract the interior region by a distance of 160 Angstroms


# This might throw away a few voxels near the edge of the cytoplasm
# which don't contain any membrane, but that's okay.  We just want to
# make sure the remaining voxels in the new image ("cytoplasm.rec")
# are entirely wthin the cytoplasmic volume of the cell.










# ----------------- segmenting the outer membrane ----------------------
#
# This membrane has a problem which we need to address beforehand:
#
# The cell appears to be pushing against the surface of another cell.
# You can see this if you open the "orig_crop.rec" file, and look at the
# right-hand tip of the cell.  (In Cryo-EM, cells are also frequenly
# seen touching holes in the thin carbon surfaces they are resting against.)
# Whenever two objects are touching, there is a danger that the membrane
# detection software will accidentally try to fuse them together.
# If you open the "orig_crop_mem80.rec" or "membrane_clusters.rec" image files
# that we created earlier, you can see that this has happened.
#
# Open the "orig_crop.rec" file using 3dmod and click near the place these
# two membranes are touching.  Make note of the XYZ coordiates of the point
# where you clicked.  In this case, I get:
#    697 169 52
# Then try to estimate the width of this contact point in voxels.
# (To do that, click on the "Model" button in the control window.
# Then middle-click on two locations in the image and select the
# "Edit"->"Point"->"Distance" menu option to measure the distance between them.)
#    26.0891 voxels
# We will use these numbers when we re-run "filter_mrc" with the "-connect"
# argument.  We will supply the following additional argument:
#
#  -mask-sphere-subtract  697 169 52  26.1
#
# This tells the "filter_mrc" program to ignore voxels lying in a sphere
# of diameter 26.1 voxels, centered at position 697 169 52.
# You can supply multiple "-mask-sphere-subtract" arguments to
# exclude multiple spherical regions.  You can also exclude rectangular
# regions using the "-mask-rect-subtract" argument.
# See the documentation for the "filter_mrc" program for details.
#
# Note: Alternatively, you can measure the XYZ coordinates and distances
# from the "membrane_clusters.rec" image file we created earlier.
# But you will probably have to multiply the XYZ coordinates and the
# diameters by 2 or 3, because that image has probably been downsampled.)


# Now try to connect the outer membrane surface fragments together again.
# using the "-mask-sphere-subtract" argument.
#
# We will use "-select-cluster 1" this time, because we want to segment
# the largest surface.  (Previously we used "-select-cluster 2".)

filter_mrc -in orig_crop.rec \
           -w 18.08 \
           -load-progress temporary_file \
           -mask-sphere-subtract  697 169 52  26.1 \
           -out membrane_clusters.rec \
           -connect 0.03 -connect-angle 15 \
           -must-link links_membrane.txt \
           -select-cluster 1 \
           -normals-file membrane_outer_pointcloud.ply

# Open the "membrane_clusters.rec" using 3dmod to see if the membranes are
# still fused.  If they are still fused, did you put the
# sphere(s) in the right place?  The sphere you ignored should be visible in
# the "membrane_clusters.rec" file (as a dark region with brightness=0).


# Then proceed as we did before, using meshlab, SSDRecon, and voxelize_mesh.py
# to segment the outer membrane and create a "membrane_outer.rec file.


SSDRecon --in membrane_outer_pointcloud.ply \
  --out membrane_outer_rough.ply --depth 12 --scale 2.0

# Now see if the reconstruction process worked.

meshlab membrane_outer_rough.ply

# If it worked, then, as we did earlier, smooth the mesh,
# and export a new mesh (named "membrane_outer.ply").

voxelize_mesh.py \
  -w 18.08 \
  -m membrane_outer.ply \
  -i orig_crop.rec \
  -o membrane_outer.rec


# If you want to segment the periplasm (the space between the inner and outer
# membranes, you can use the "combine_mrc" program to subtract the volume
# of the inner membrane from the volume of the outer membrane.  You can do this
# by multiplying the brightness of the two files this way:

combine_mrc membrane_inner.rec "*" membrane_outer.rec,1,0  periplasm.rec


# ------ Maintianing a fixed distance between concentric membranes ------
#
# A new potential may arise:
#
# A large portion of the inner and outer membranes are not visible in the
# original tomogram.  The "SSDRecon" program attempts to infer where
# they are.  But it does this separately and indepenently for each surface.
# As a result, there is no way to guarantee that the inner membrane will
# lie within the outer membrane.
#
# Alternate method:
#
# To insure that the inner membrane remains a fixed distance away from
# the outer membrane, it might be easier to segment only one of these
# membranes (say, the outer membrane, since it is often much easier to see).
# Then invoke "filter_mrc" with the "-erode 290.0" argument to
# create a new volume which has been contracted inward approximately 290.0
# Angstroms (for example):
#
#
# filter_mrc -in membrane_outer.rec -out membrane_inner.rec -erode 290.0
#
#
# Alternatively, if you prefer to start with the inner membrane and expand
# outward, do this instead:
#
#
# filter_mrc -in membrane_inner.rec -out membrane_outer.rec -dilate 290.0
#
#
# Either way, this will ensure that the inner and outer surfaces are separated
# by 290.0 Angstroms.  (Note: If "-erode 290.0" or "-dilate 290.0" does not
# work well, try using "-erode-gauss 290.0" or "-dilate-gauss 290.0" instead.
# The "-erode-gauss" and "-dilate-gauss" methods not as sensitive to
# bumps and imperfections on the surface.)


# Finally, after you are done detecting membranes, it is a good idea to delete
# all of the temporary files that we created earlier (which are quite large).

rm -f temporary_file*

