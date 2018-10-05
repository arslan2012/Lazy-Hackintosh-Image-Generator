//
//  shellCommand.swift
//  LazyHackintoshGenerator
//
//  Created by ئ‍ارسلان ئابلىكىم on 7/27/16.
//  shouldInstallHelper, installHelper, helperConnection written by Erik Berglund on 2016-12-06.
//  https://github.com/erikberglund/SwiftPrivilegedHelper
//  Copyright © 2016 Arslan Ablikim. All rights reserved.
//

import Foundation
import ServiceManagement
import RxSwift

class ShellCommand: ProcessProtocol {
    var xpcHelperConnection: NSXPCConnection?
    var cachedHelperAuthData: NSData?
    static let shared = ShellCommand()

    private init() {
        shouldInstallHelper(callback: {
            installed in
            if !installed {
                self.installHelper()
                self.xpcHelperConnection = nil  //  Nulls the connection to force a reconnection
            }
        })
    }

    private func shouldInstallHelper(callback: @escaping (Bool) -> Void) {

        let helperURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LaunchServices/\(HelperConstants.machServiceName)")
        let helperBundleInfo = CFBundleCopyInfoDictionaryForURL(helperURL as CFURL!)
        if helperBundleInfo != nil {
            let helperInfo = helperBundleInfo as! NSDictionary
            let helperVersion = helperInfo["CFBundleVersion"] as! String

            print("Helper: Bundle Version => \(helperVersion)")

            let helper = self.helperConnection()?.remoteObjectProxyWithErrorHandler({
                _ in
                callback(false)
            }) as! HelperProtocol

            helper.getVersion(reply: {
                installedVersion in
                print("Helper: Installed Version => \(installedVersion)")
                callback(helperVersion == installedVersion)
            })
        } else {
            callback(false)
        }
    }

    private func installHelper() {
        var authRef: AuthorizationRef?
        var authItem = AuthorizationItem(name: kSMRightBlessPrivilegedHelper, valueLength: 0, value: UnsafeMutableRawPointer(bitPattern: 0), flags: 0)
        var authRights: AuthorizationRights = AuthorizationRights(count: 1, items: &authItem)
        let authFlags: AuthorizationFlags = [[], .extendRights, .interactionAllowed, .preAuthorize]

        let status = AuthorizationCreate(&authRights, nil, authFlags, &authRef)
        if (status != errAuthorizationSuccess) {
            let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            NSLog("Authorization error: \(error)")
        } else {
            var cfError: Unmanaged<CFError>? = nil
            if !SMJobBless(kSMDomainSystemLaunchd, HelperConstants.machServiceName as CFString, authRef, &cfError) {
                let blessError = cfError!.takeRetainedValue() as Error
                NSLog("Bless Error: \(blessError)")
            } else {
                NSLog("\(HelperConstants.machServiceName) installed successfully")
            }
        }
    }

    /*
        Connect Helper Functions
     */

    // This could be written as a lazy variable instead to reuse the same connection.
    // But I found an issue when first installing the helper, the connection is invalidated and the never recreated.
    // Therefore I changed that to a function that re-creates a connection if the stored one is invalidated.

    // There might be issues with this, It doesn't check if the conenction is suspended for example. That might need to be handled.
    private func helperConnection() -> NSXPCConnection? {
        if (self.xpcHelperConnection == nil) {
            self.xpcHelperConnection = NSXPCConnection(machServiceName: HelperConstants.machServiceName, options: NSXPCConnection.Options.privileged)
            self.xpcHelperConnection!.exportedObject = self
            self.xpcHelperConnection!.exportedInterface = NSXPCInterface(with: ProcessProtocol.self)
            self.xpcHelperConnection!.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            self.xpcHelperConnection!.invalidationHandler = {
                self.xpcHelperConnection?.invalidationHandler = nil
                OperationQueue.main.addOperation() {
                    self.xpcHelperConnection = nil
                    NSLog("XPC Connection Invalidated\n")
                }
            }
            self.xpcHelperConnection?.resume()
        }
        return self.xpcHelperConnection
    }

    func run(
            _ path: String,
            _ arg: [String],
            _ label: String,
            _ progress: Double,
            _ currentDirectoryPath: String = ""
    ) -> Observable<Int32> {
        return Observable.create { observer in
            viewController!.didReceiveProcessName(label)
            let xpcService = self.helperConnection()?.remoteObjectProxyWithErrorHandler() { error -> Void in
                print("XPCService error: %@", error)
            } as? HelperProtocol

            xpcService?.runTask(path, arg, currentDirectoryPath) { terminationStatus in
                viewController!.didReceiveProgress(progress)
                observer.onNext(terminationStatus)
                observer.onCompleted()
            }

            return Disposables.create()
        }.observeOn(MainScheduler.instance).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    }

    func sudo(_ path: String,
              _  arg: [String],
              _ label: String = "",
              _ progress: Double = 0
    ) -> Observable<Int32> {
        return Observable.create { observer in
            if self.cachedHelperAuthData == nil {
                self.cachedHelperAuthData = HelperAuthorization().authorizeHelper()
            }
            viewController!.didReceiveProcessName(label)
            let xpcService = self.helperConnection()?.remoteObjectProxyWithErrorHandler() { error -> Void in
                print("XPCService error: %@", error)
            } as? HelperProtocol

            xpcService?.runTask(path, arg, "", { terminationStatus in
                viewController!.didReceiveProgress(progress)
                observer.onNext(terminationStatus)
                observer.onCompleted()
            }, self.cachedHelperAuthData!)
            return Disposables.create()
        }.observeOn(MainScheduler.instance).subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    }

    func saveLog(_ path: String, _ arg: [String], _ output: String, _ error: String) {
        if viewController!.debugLog {
            let components = (Calendar.current as NSCalendar).components([.hour, .minute, .second], from: Date())
            Logger("[\(components.hour!):\(components.minute!):\(components.second!)]: \(path) \(arg.joined(separator: " "))")
            Logger(output)
            Logger(error)
        }
    }
}
