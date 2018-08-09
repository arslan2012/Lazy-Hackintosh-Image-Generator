//
// Created by Arslan Ablikim on 30/06/2017.
// Copyright (c) 2017 PCBeta. All rights reserved.
//

import Foundation

func Drop_Kernel() {//progress:2%
    Command(Bundle.main.path(forResource: "lzvn", ofType: nil)!, ["-d", "\(lazyImageMountPath)/System/Library/PrelinkedKernels/prelinkedkernel", "kernel"], "#COPYKERNELF#", 0, "/tmp/tech.arslan2012.lazy/")
    Command("/bin/cp", ["/tmp/tech.arslan2012.lazy/kernel", "\(lazyImageMountPath)/System/Library/Kernels"], "#COPYKERNELF#", 2)
    if !SystemVersion.SysVerBiggerThan("10.11") {
        /////// 10.10.x
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
    } else if SystemVersion.SysVerBiggerThan("10.11.99") {
        if SystemBuildVersion == "16A201w" {
            /////// 10.12.DB1.116A201w
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
        } else if SystemBuildVersion == "16A238m" || SystemBuildVersion == "16A239j" {
            /////// 10.12.PB1.16A238m, 10.12.DB2.16A239j
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x71\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
            Command("/bin/sh", ["-c", "perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
        }
    } else {
        //////// 10.11.x
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xC3\\x48\\x85\\xDB\\x74\\x70\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|\\xC3\\x48\\x85\\xDB\\xEB\\x12\\x48\\x8B\\x03\\x48\\x89\\xDF\\xFF\\x50\\x28\\x48|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
        Command("/bin/sh", ["-c", "perl -pi -e 's|\\xE8\\x25\\x00\\x00\\x00\\xEB\\x05\\xE8|\\xE8\\x25\\x00\\x00\\x00\\x90\\x90\\xE8|g' \(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
    }
    Command("/bin/chmod", ["+x", "\(lazyImageMountPath)/System/Library/Kernels/kernel"], "#COPYKERNELF#", 0)
}