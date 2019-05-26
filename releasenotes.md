### 3.0.5
###### released March 31, 2019
fixed a bug where helper stucks on newer systems

### 3.0.1
###### released March 21, 2019
fixes install CLT button

### 2.0.83
###### released March 11, 2019
added support for 10.14.4
Rewrote code using RxSwift

### 2.0.79
###### released August 9, 2018
removed XCPM and LAPIC patch ability since chameleon has it already

### 2.0.77
###### released August 9, 2018
MBR patch is now mandatory

fix a bug where baseSystem.dmg copying fail thanks for @crazybirdy discovering it

### 2.0.75
###### released August 8, 2018
thanks to [@crazybirdy](https://www.insanelymac.com/forum/files/file/944-mojave-mbr-hfs-firmware-check-patch/) we now have mojave support
### Important
because I lost my private key, older version of the app could not update to 75

older version users need to download manually from [Github](https://github.com/arslan2012/Lazy-Hackintosh-Image-Generator) or [InsanelyMac](https://www.insanelymac.com/forum/files/file/567-hackintosh-custom-installer-generator/)

### 2.0.68
###### released March 30, 2017
Updated kernel patching commands

### 2.0.66
###### released March 29, 2017
Fixed bug that lvzn cannot be executed
because it doesnt have x property

### 2.0.61
###### released Nov 1, 2016
Fixed bugs that happens on Chinese systems

### 2.0.57
###### released Nov 1, 2016
Fix Bug

### 2.0.52
###### released Sep 30, 2016
Fix Bug

### 2.0.50
###### released Sep 27, 2016
Fixed a bug where app propmts asr timeout when successfully generated image

### 2.0.49
###### released Sep 16, 2016
Upgraded app to use Swift3.0!
fixed defective that app needs user to input password multiple times(still in testing)

### 2.0.48
###### released Sep 12, 2016
fixed bug that app tries to patch OSInstall.mpkg on 10.12GM
fixed bug that app continue workflow with waiting asr command to finish(which may cause an error in slow computers)

### 2.0.46
###### released Aug 20, 2016
changed MBR Patch function so that it will not try to patch OSInstall.mpkg for version later than 16A284a
added Copy custom OSInstaller feature for when you don't have CLT on your computer

### 2.0.44(Beta)
###### released Aug 7, 2016
added directly write to disk fuction
added designate output file fuction

### 2.0.43
###### released Aug 2, 2016
Bug fix

### 2.0.41
###### released Aug 1, 2016
code improvement
LAPIC now uses patching method provided by donovan6000 and sherlocks instead of using the rainbow chart and otool

### 2.0.38
###### released July 30, 2016
function update, now you can double click the icons to choose file

### 2.0.34
###### released July 27, 2016
major code style change.
no need to update if your not expierecing "ERROR: Couldn't write to the output image." issue
若未遇到"对不起，镜像写入失败。"错误则无需升级该版本。
### 2.0.33
###### released July 21, 2016
deleted build in Lapic patch string for Sierra PB2,DB2 and DB3 to avoid causing bug (PB2 and DB3 SystemBuildVersion is the same,might cause trouble)
added build in Lapic patch string for 10.11.6

### 2.0.32
added build in Lapic patch string for Sierra DB3, fixed Lapic patch string for Sierra PB1

### 2.0.28
###### released July 9, 2016
altered Lapic patch func so that it could get patch from kernel when otool is present in system

### 2.0.26
added command line tools detection

### 2.0.25
system version read fail now prompts error instead of crashing

### 2.0.14
###### released July 8, 2016
This release added auto update feature
