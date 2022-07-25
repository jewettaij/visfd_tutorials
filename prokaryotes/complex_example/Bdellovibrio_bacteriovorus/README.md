Multiple concentric membranes containing Bdelloplasts
==========

### WARNING

This is a complex example demonstrating how to segment tomograms
of Bdellovibrio bacteriovorus cells invading a host cell.

***I recommend starting with the Hylemonella gracilis example instead.***

As of 2022-7-25, the protocol used here is not yet robust enough
to work automatically without some input from the user.
*(See below.)*


### Overview

The segmenting procedure described here was used to segment some of the
tomograms from
[this study](https://www.biorxiv.org/content/10.1101/2022.06.13.496000v1).

***The tomograms for this study have not yet been released to the public.
When they are, I will update these instructions. -A 2022-7-24***

In this study, B.bacteriovorus cells were imaged throughout their
life cycle.  In this here the B.bacteriovorus cells:

-  Attack and enter a host cell (E.coli),
-  Divide inside the host cell
-  Devour the contents of the host cell
-  Burst out of the host cell and hunt for new host cells to infectr

The protocol described here was used to segment tomograms right
before the final stage.
At this point the B.bacteriovorus cells are surrounded by a thin
wrinkled membrane from the host cell and are poised to burst out of the cell.
Consequently the tomograms here have (at least) 3 concentric membranes:

-  B.bacteriovorus inner membrane (one or more cells)
-  B.bacteriovorus outer membrane (one or more cells)
-  E.coli host cell membrane (single cell)


### Manual intervention is sometimes needed

Sometimes in step 2 and step 5, it was necessary to manually correct some
of the mistakes by the VISFD segmentation software.
The procedures for doing that is included in these notes,
however the exact procedure will depend on the tomogram you are working with.
This example demonstrates how difficult this software can be to use
as of 2022-7-24.
