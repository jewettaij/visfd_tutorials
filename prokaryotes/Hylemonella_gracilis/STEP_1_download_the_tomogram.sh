
# This tomogram can be found online at
# https://etdb.caltech.edu/tomogram/749afe
# You can either visit that URL with a web browser and click on the download
# link, or use "wget" or "curl" to download the .rec file.  Here, I use wget:

wget https://etdb.caltech.edu/ipfs/QmWNWgvY7uTMvk3qTytkT2APFkcroKXww9W6r9J8BuSsjz/3dimage_20944/20120923_Hylemonella_30010_full.rec

# I will rename it to something simpler "orig.rec"

mv 20120923_Hylemonella_30010_full.rec orig.rec


# The original tomogram from https://etdb.caltech.org
# is too large to run the "voxelize_mesh.py" program using a normal desktop
# computer.  (Unfortunately that program is not yet very efficient.)
#
# So I use the "crop_mrc" program (included with VISFD) to extract a small
# region from the original image.  We will segment that small image instead.
# This will make the example, much much faster and hopefully it will
# give you an idea how you can use this software.

crop_mrc orig.rec orig_crop.rec 263 659 329 646 151 304

# The syntax of this program is:
#   crop_mrc OLD_FILE NEW_CROPPED_FILE xmin xmax ymin ymax zmin zmax
# Alternatively you can use the "trimvol" or "3dmod" programs included with IMOD

