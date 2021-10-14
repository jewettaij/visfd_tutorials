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


### Preprocessing recommendations

Segmentation is much easier (for you and for the software)
if the features you are trying to segment are easier to see.
So any processing steps which enhance those features
*(such as NAD filtering, machine-learning (EMAN2), or SIRT reconstruction)*
should be done in advance.
This may save you time in the long run, reducing the amount
of manual intervention needed to get clean, well-separated features.
(Instructions for NAD filtering are included in the examples.)





#### Avoid using weighted back projection

Weighted back projection
[WBP](https://doi.org/10.1007/978-0-387-69008-7_9)
is one of several techniques for creating 3-D images
from a series of TEM images at different angles.
Itis popular in the field of Cryo-EM tomography (ECT).
High-resolution structural details are often well preserved using this method,
however larger features such as membranes, ribosomes, and nucleoids
are often faint and difficult to see.
Such tomograms are more difficult to analyze using VISFD.

VISFD can be used to analyze and segment WBP tomograms.
But if some other reconstruction method is available, try that instead.
We have had better results with tomograms created using the
[SIRT](https://doi.org/10.1016/0022-5193(72)90180-4) and
[SART](https://doi.org/10.1016/0161-7346(84)90008-7) methods.
Both methods enhances the contrast for large objects in the image,
(including membranes) the cost of fine (sub-nanometer) details.
Other reconstruction methods which enhance low
spatial frequencies may also work well.  (For EM tomograms, the use of a
phase-plate during image collection will also help.)




#### Machine-learning methods (EMAN2)

Several machine-learning based methods have been developed to enhance the
detection sensitivity of
[membranes](https://doi.org/10.1038/nmeth.4405),
[polymers](https://doi.org/10.1038/nmeth.4405),
and
[molecular complexes](https://doi.org/10.1016/j.jsb.2018.09.002) in tomograms.
These sophisticated tools excel at distinguishing the objects you are
interested in (eg. membranes, polymers, ribosomes), from other features
in the image (or noise) that you want to ignore.
(VSFD can detect these objects too, but with a much higher rate of error.)
Many of these tools are available in EMAN2 (documented
[here](https://blake.bcm.edu/emanwiki/EMAN2/Programs/tomoseg) and
[here](https://doi.org/10.1038/protex.2017.095)).

***These methods complement the capabilities of VISFD.***

Once the feature you care about (such as membranes) is detected using these
tools, a new 3D image (tomogram) can be generated containing only that feature.
With other distracting objects emoved from the image, the VISFD software
("filter_mrc") can focus on measuring the locations of the features you
care about, and these locations can be used for further analysis and modeling.
For example, you could use EMAN2 to create a new 3-D volumetric image which
enhances the membranes membranes in the original image.  In this new image,
the only bright voxels are the ones that lie on the surface of the membranes.
However EMAN2 cannot yet identify the voxels which lie within a closed
(or semi-closed) membrane surface.  *This is where VISFD can help.*
The 3-D positions of these voxels in the membrane can be measured
using VISFD, and used to generate closed 3-D polyhedral mesh surface using
[poisson surface reconstruction](https://github.com/mkazhdan/PoissonRecon).
The voxels inside this closed polyhedron can be segmented using tools
(such as "voxelize_mesh.py").  In this way, EMAN2, VISFD, and other tools,
can be used together to identify the volumes inside membrane-bound
compartments like cells and organelles.

In another example, EMAN2 can be used to enhance the visible ribosomes in an
image. The resulting image can be processed using VISFD software ("filter_mrc")
to create a text file that specifies the X,Y,Z coordinates of all of the
risosomes.)  Since only the ribosomes are present in the image that VISFD sees,
it is much less likely to be distracted or confused by other features.




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
In addition, a significant amount of effort is often needed to "clean up"
a 3-D image (tomogram) beforehand.  One often has to remove portions of
the 3-D image that contain features which confuse the automated detectors,
especially near the edge of the detectable portion of a membrane (where the
signal-to-noise ratio is poor), and when objects are touching each other.
(Several examples of this are given in these instructions.)

Hence, in practice, a lot of manual effort is often needed to get results.
**This is especially true when the image
contrast is poor and the features in the tomogram are faint or difficult to
see.**  (This is why processing the image in advance using NAD-filtering,
EMAN2, or SIRT reconstruction, can save time and effort.)
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

