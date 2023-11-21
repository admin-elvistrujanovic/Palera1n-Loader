//
//  Install+apt.swift
//  palera1nLoader
//
//  Created by samara on 11/17/23.
//

import Foundation
import Extras

public class Bootstrapper {
    
    static func installation() -> installStatus {
        #if targetEnvironment(simulator)
        return .simulated
        #else
        if envInfo.isRootful {
            if fm.fileExists(atPath: "/.procursus_strapped") {
                return .rootful_installed
            } else {
                return .rootful
            }
        }
        
        let dir = "/private/preboot/\(envInfo.bmHash)"
        var jbFolders = [String]()
        
        do {
            let contents = try fm.contentsOfDirectory(atPath: dir)
            jbFolders = contents.filter { $0.hasPrefix("jb-") }
            let jbFolderExists = !jbFolders.isEmpty
            let jbSymlinkPath = "/var/jb"
            let jbSymlinkExists = fm.fileExists(atPath: jbSymlinkPath)
            
            if jbFolderExists && jbSymlinkExists {
                return .rootless_installed
            } else {
                return .rootless
            }
        } catch {
            log(type: .fatal, msg: "Failed to get contents of directory: \(error.localizedDescription)")
            return .rootless
        }
        #endif
    }
    
    static func locateExistingFakeRoot() -> String? {
        guard let bootManifestHash = VersionSeeker.bootmanifestHash() else {
            return nil
        }
        let ppURL = URL(fileURLWithPath: "/private/preboot/" + bootManifestHash)
        guard let candidateURLs = try? FileManager.default.contentsOfDirectory(at: ppURL , includingPropertiesForKeys: nil, options: []) else { return nil }
        for candidateURL in candidateURLs {
            if candidateURL.lastPathComponent.hasPrefix("jb-") {
                return candidateURL.path
            }
        }
        return nil
    }
    // creating this back after hiding jb is done in jbinit
    static func removeExistingSymlink(reboot: Bool) {
        if fileExists("/var/jb") {
            binpack.rm("/var/jb")
            if reboot { spawn(command: "/cores/binpack/bin/launchctl", args: ["reboot"]) }
        }
    }
    
    static func remountPreboot(writable: Bool) {
        if writable {
            spawn(command: "/sbin/mount", args: ["-u", "-w","/private/preboot"])
        } else {
            spawn(command: "/sbin/mount", args: ["-u","/private/preboot"])
        }
    }
    
    static func obliterator() {
        let rootlessAppDir = "/var/jb/Applications/"
        
        if !envInfo.isRootful {
            do {
                let appContents = try fm.contentsOfDirectory(atPath: rootlessAppDir)
                
                for app in appContents {
                    let appPath = rootlessAppDir + app
                    spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-u", appPath])
                }
                print("Apps now unregistered\n")
                removeExistingSymlink(reboot: false)
            } catch {
                print("Error listing contents of /var/jb/Applications/: \(error)")
            }
            
            let leftovers = [
                "/var/LIB",
                "/var/Liy",
                "/var/ulb",
                "/var/bin",
                "/var/sbin",
                "/var/ubi",
                "/var/local",
                "/var/mobile/Application Support/xyz.willy.Zebra" ]
            
            spawn(command: "/cores/binpack/bin/rm", args: ["-rf"] + leftovers)
            let fakeRootPath = locateExistingFakeRoot()
            if fakeRootPath != nil {
                do {
                    binpack.rm(fakeRootPath!)
                }
            }
            remountPreboot(writable: false)
        }
        
        spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-a"])
        print("Jailbreak obliterated!!")
        
    }
    
    static func generateFakeRootPath() -> String {
        
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let randomCharacters = (0..<8).compactMap { _ in
            let randomIndex = Int(arc4random_uniform(UInt32(letters.count)))
            return letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
        }
        let randomString = String(randomCharacters)
        return "jb-\(randomString)"
    }
}

enum installStatus {
    case simulated
    case rootful
    case rootful_installed
    case rootless
    case rootless_installed
}

