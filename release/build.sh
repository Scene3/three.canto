#
#  Script to combine all three.fun source files into a single file
#  called three.fun
#

echo Rebuilding three.fun...

rm -f three.fun
cat ../src/*.fun >> three.fun

echo Done.
