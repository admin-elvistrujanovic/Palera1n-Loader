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
            } else if jbFolderExists {
                return .rootless_install_path(path: jbSymlinkPath)
            } else {
                return .rootless
            }
        } catch {
            log(type: .fatal, msg: "Failed to get contents of directory: \(error.localizedDescription)")
            return .rootless
        }
        #endif
    }
    
    static func removeExistingSymlink() async {
        try! fm.removeItem(atPath: "/var/jb")
    }
    
    static func remountPreboot() {
        spawn(command: "/sbin/mount", args: ["-u", "-w","/private/preboot"])
    }
    
    static func obliterator() async {
        let strapValue = Bootstrapper.installation()
        let rootlessAppDir = "/var/jb/Applications/"
        
        if !envInfo.isRootful {
            do {
                let appContents = try fm.contentsOfDirectory(atPath: rootlessAppDir)
                
                for app in appContents {
                    let appPath = rootlessAppDir + app
                    spawn(command: "/cores/binpack/usr/bin/uicache", args: ["-u", appPath])
                }
                print("Apps now unregistered\n")
                await removeExistingSymlink()
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
            
            if case let .rootless_install_path(path) = strapValue {
                let spawnCommand = "/cores/binpack/bin/rm"
                let spawnArgs = ["-rf", "/private/preboot/" + "\(VersionSeeker.bootmanifestHash()!)" + path]
                spawn(command: spawnCommand, args: spawnArgs)
            }
        } else {
            let leftovers = [
                "/var/lib",
                "/var/mobile/Application Support/xyz.willy.Zebra",
                "/var/cache"]
            spawn(command: "/cores/binpack/bin/rm", args: ["-rf"] + leftovers)
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
        return "/private/preboot/\(VersionSeeker.bootmanifestHash()!)/jb-\(randomString)"
    }
}

enum installStatus {
    case simulated
    case rootful
    case rootful_installed
    case rootless
    case rootless_installed
    case rootless_install_path(path: String)
}

