# File Annotator

If given a file path, will create an associated metadata file to take notes in.

For example, if pointed to the file `/home/user/project/image.png`, it will create the file `/home/user/project/.metadata.image.png.txt` and open it for you to edit. Works with any file type, and directories.

The path doesn't actually need to exist, the software never checks if there is a file at the given path.

Currently with a crude GUI whipped in minutes.

Works in debug mode, but curiously not once exported. TODO: check why