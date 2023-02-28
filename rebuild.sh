echo "ReBuild sites by jemdoc.py -- Runing on shell environment..."
# Remove existed build folder and make a new one
rm -rf build
mkdir build
# Copy folders and files to the build folder
cp -r review_history build/review_history
cp -r images build/images
cp -r styles build/styles
cp -r cv build/cv
cp -r ppts build/ppts
cp CNAME build/CNAME
cp .gitattributes build/.gitattributes

function realpath { echo $(cd $(dirname $1); pwd)/$(basename $1); }

for i in `find . -name "*.jemdoc"`;
do
  filename=$(basename "$i" .jemdoc)
  fullname=$(realpath "$i")
  echo "Building $filename..."
  python jemdoc.py -c mysite.conf -o build/$filename.html $fullname
done

echo "Finished!"
