# Lazy Hackintosh Image Generator
[![Swift 2.2](https://img.shields.io/badge/Swift-2.2-orange.svg?style=flat)](https://swift.org)
##What is this?
This is an simple app that automaticly modifies the OS X Installation app/disk image so that it could be used as a Hackintosh image and install OS X on non-apple computers.
##Why do I need this?
* If you are on a computer that does not support UEFI.
* If you have hardwares on you computer that causes original installation image kernel panic.
* If you have less than 2GB RAM.
* If you are just too lazy to read the tutorial and install the original.

you'll need this app to alter the original installation image.
##How does this work
Just drag the Install app, or Install app image, or Install ESD image onto the top, hit start and enjoy.
>If you use custom kernel, you can drop your kernel onto the big black Kernel lable right there.
>>If you use Chameleon Bootloader, you can drop your Chameleon Extra folder onto the /Extra lable to make this an Chameleon bootabale image.

##Shut up and gimmi the app
the precompiled binary could be downloaded at the [realease page](https://github.com/arslan2012/Lazy-Hackintosh-Image-Generator/releases).

# Support needed
As you can see, beacase I used Swift to code this, app authorization is really a pain in the ass. sometimes you need to type in your password twice to make this work.

I'm using STprivilagedTask to do the authrization for me, if you know how to fix the issue, I would be very appriciated.

And if you have any issue report or suggestions, it would be great.

### Good at Shell Script?
If you are good at shell scripting and have spare time to kill, why dont you try translating my app into shell script, my app core is in ViewController.swift func startGenerating(), and I'm pretty confident it's convertable.

What I'm expecting is that turning this into a shell script would fix the authoriation problem. and make this more usable(currently this app only works on 10.10+,because i wrote it in Swift)