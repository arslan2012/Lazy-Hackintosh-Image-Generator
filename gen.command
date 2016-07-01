#!/bin/bash

cd $(dirname "$0")
hash xcodebuild 2>/dev/null || { echo >&2 "Please install Xcode command line tools"; exit 1; }

function head
{
clear
echo " "
echo "      Welcome to use self compiling LazyHackintoshGenerator!"
echo " "
echo "                                 by arslan2012, optimized by Vanilla."
}

function menu
{
echo "1.Compile zip package(default)"
echo "2.Compile pkg package"
echo "Q.Exit"
echo " "
echo " "
echo "Press the corresponding key to continue,or press enter for default..."
read -n 1 option
}

function cmpZip
{
	xcodebuild archive -scheme LazyHackintoshGenerator -archivePath product
    xcodebuild -exportArchive -archivePath product.xcarchive -exportFormat app -exportPath ./LazyHackintoshGenerator
	rm -rf product.xcarchive
    zip -r LazyHackintoshGenerator.app.zip LazyHackintoshGenerator.app
    rm -rf LazyHackintoshGenerator.app
    zip -d LazyHackintoshGenerator.app.zip __MACOSX/\*
    zip -d LazyHackintoshGenerator.app.zip \*/.DS_Store
    echo " "
    echo " "
    echo "Done."
    exit 0
}

function cmpPkg
{
	xcodebuild archive -scheme LazyHackintoshGenerator -archivePath product
    xcodebuild -exportArchive -archivePath product.xcarchive -exportPath ./LazyHackintoshGenerator
	rm -rf product.xcarchive
    echo " "
    echo " "
    echo "Done."
    exit 0
}

function quit
{
    exit 0
}

while [ 1 ]
do
head
menu
case $option in

1|"")
echo
cmpZip ;;

2)
echo
cmpPkg ;;

q|Q)
echo
rm -rf product.xcarchive
quit ;;

*)
echo "Typo detected!"
esac
echo
echo "Press any key to return."
echo
read -n 1 line
clear
done

exit
