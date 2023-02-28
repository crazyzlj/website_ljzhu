echo "Deploying the entire site to Github pages..."

# delete build folder
rm -rf build

# Build the project.
./rebuild.sh

# Go To Public folder
cd ../crazyzlj.github.io
git checkout .
git pull origin master

# clean working dir
rm -f .git/index
git clean -df

# copy build folder
cp -av ../website_ljzhu/build/* .
cp -av ../website_ljzhu/build/.gitattributes .

# Add changes to git.
git add -A

# Commit changes.
msg="rebuilding site `date`"
if [ $# -eq 1 ]
	  then msg="$1"
fi
git commit -m "$msg"

# Push source and build repos.
git push origin master

# Come Back
cd ../website_ljzhu
