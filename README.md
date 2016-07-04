# Lazy Hackintosh Image Generator
[![Swift 2.2](https://img.shields.io/badge/Swift-2.2-orange.svg?style=flat)](https://swift.org)
##What is this?
This is an simple app that automatically modifies the OS X Installer app/disk image so that it could be used as a Hackintosh installer and install OS X on non-apple computers.
##Why do I need this?
* If you are on a computer that does not support UEFI.
* If you have hardwares on you computer that causes original installation image kernel panic.
* If you have less than 2GB RAM.
* If you are just too lazy to read the tutorial and install the original.

you'll need this app to alter the original installation image.
##How does this work
Just drag the Install app, or Install app image, or Install ESD image onto the top, click start and enjoy.
>If you use Chameleon Bootloader, you can drop your Chameleon Extra folder onto the /Extra lable to make this a Chameleon bootable image.

##Shut up and gimmi the app
Just download the [LazyHackintoshGenerator.app.zip](https://raw.githubusercontent.com/arslan2012/Lazy-Hackintosh-Image-Generator/master/LazyHackintoshGenerator.app.zip). It will keep updating to the latest version.

# Support needed
As you can see, since I used Swift to code this, app authorization is really a pain in the ass. Sometimes you need to type in your password twice to make this work.

I'm using STprivilagedTask to do the authrization for me, if you know how to fix the issue, I would be very appriciated.

And if you have any issue to report or ideas, feel free to open up an issue and tell me about it.