#!/bin/bash

cd $(dirname "$0")

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
echo "1.Compile app directly without zip compressed"
echo "2.Compile app with zip compressed"
echo "Q.Exit"
echo " "
echo " "
echo "Press the corresponding key to continue..."
read -n 1 option
}

function cmpwithzip
{
    head
    xcodebuild -exportArchive -archivePath product.xcarchive -exportFormat app -exportPath ./LazyHackintoshGenerator
    zip -r LazyHackintoshGenerator.app.zip LazyHackintoshGenerator.app
    rm -rf LazyHackintoshGenerator.app
    zip -d LazyHackintoshGenerator.app.zip __MACOSX/\*
    zip -d LazyHackintoshGenerator.app.zip \*/.DS_Store
    echo " "
    echo " "
    echo "Done."
    exit 0
}

function cmpwithoutzip
{
    head
    xcodebuild -exportArchive -archivePath product.xcarchive -exportPath ./LazyHackintoshGenerator
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

1)
echo
cmpwithoutzip ;;

2)
echo
cmpwithzip ;;

q|Q)
echo
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
