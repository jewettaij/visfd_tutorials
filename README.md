VISFD tutorials
=================================================
This repository contains a collection of examples
demonstrating how to segment cells, membrane-bound compartments,
and other features inside cells using
[VISFD](https://github.com/jewettaij/visfd)
and other open-source tools.

***(As of 2021-9-13, only one example has been added so far. -Andrew)***


## STATUS: Rough draft

Currently, these tutorials are just a collection of .SH files
containing a long list of instructions (and crufty comments).
I intended users to open these files with a text editor and
paste the commands into the terminal one by one.
If there is sufficient interest in this software, I hope to eventually
replace these tutorials with something more professional.

As of 2021-9-13, I have not yet even added any images or videos.
I realize that without pictures, these tutorials are difficult to understand.
When I have permission to post them, I will update these tutorials
with graphics.



### Overview

Segmenting an image of a cell or a virus is a multi-step process.
Typically you begin by segmenting the most obvious features
(such as the gold fiducial beads or the cell boundary).
Then you proceed to segment other objects which are more difficult to detect.
The instructions are typically split into multiple files, named
"STEP_1_...sh", "STEP_2_...sh", "STEP_3_...sh", etc...
detecting fiducial beads, then membranes, then nucleoids, then ribosomes, etc...
The commands in STEP_1 must be entered before proceeding to STEP_2.
You cannot skip any steps.


### Mask files

Each time a new object of feature is detected, we often create a new
"mask" file.  The "mask" file is an image file (REC file) which keeps
track of all of the voxels that that we have already segmented.
*(Since we know what is located at these locations, we can ignore
those voxels later when searching for the next feature.)*


### Voxel Width

This kind of quantitative image is sensitive to the object size.
So it is important that you run these calculations with the correct voxel width.
This software will attempt to infer the voxel width (typically in Angstroms)
from the header meta-data stored in the 3-D image file (REC file).
But if the voxel-width is not correctly stored in the REC file
(as is the case in many of the Jensen lab tomograms),
then you must specify it manually using the "-w" argument.


### Disclaimer / Warning

Here are the pros and cons of using this software.

The open-source software tools explaind here are not trivial to use.
If you just want to segment the boundary of a cell quickly, use AMIRA instead.
This software is useful if you want to generate a segmentation of
a membrane surface which is as accurate as possible.
It also provides some general tools for analyzing and
manipulating 3D image (MRC/REC) files.


#### Why this software is hard to use

The procedure described here using these tools is mostly automatic,
however a significant amount of manual input is often required from the user.
Each time you segment a new cell, you will have to choose different thresholds
for each type of object you want to detect (membranes, nucleoids), etc,
and these are often chosen by trial-and-error.
You may also have to click on the membrane a couple times
(to help join disconnected surface fragments together).
Depending on the resolution and size of the image, this software can be slow.
(In some cases, membrane and blob detection can take several hours.)

In addition, a significant amount of effort is often needed to
"clean up" a 3-D image (tomogram) beforehand.  One often has to remove
portions of the 3-D image that contain features which confuse the automated
detectors, especially near the edge of the detectable portion of a membrane
(where the signal-to-noise ratio is poor), and when objects are touching
each other. (Several examples of this are given in these instructions.)
Hence, in practice, a lot of manual effort is often needed to get results.
And because (as of 2021-9-10), the VISFD software lacks a graphical user
interface.  So the process of making these manual edits is often laborious.
The entire process can easily take more than a day to finish.  And if you
encounter a bug in the software, then it can take even longer to resolve.
However once you have figured out the protocol and parameters needed to
segment one cell, segmenting other similar cells will probably be much faster
because you can re-use many of the parameters and strategies you used in the
past.  For other species or samples (with thicker membranes, or fainter
nucleoids, for example), completely different strategies may be necessary.

By comparison, software like AMIRA is not free and is mostly used for manual
segmentation.  Segmenting one cell is relatively quick and straightforward
and can easily be done in a few hours or less.  However these manual results
are arguably more subjective and potentially less accurate.

