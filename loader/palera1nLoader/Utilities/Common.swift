//
//  Common.swift
//  palera1nLoader
//
//  Created by Staturnz on 4/10/23.
//

import Foundation
import Extras
import UIKit

let isIpad = UIDevice.current.userInterfaceIdiom
let fm = FileManager.default

struct envInfo {
    static var isRootful: Bool = false
    static var installPrefix: String = ""
    static var rebootAfter: Bool = true
    static var w_button: Bool = false
    static var jsonURI: String {
        get { UserDefaults.standard.string(forKey: "JsonURI") ?? "https://palera.in/loader.json" }
        set { UserDefaults.standard.set(newValue, forKey: "JsonURI") }
    }
    static var hasForceReverted: Bool = false
    static var hasChecked: Bool = false
    static var kinfoFlags: String = ""
    static var pinfoFlags: String = ""
    static var kinfoFlagsStr: String = ""
    static var pinfoFlagsStr: String = ""
    static var CF = Int(floor(kCFCoreFoundationVersionNumber / 100) * 100)
    static var bmHash: String = ""
    static var nav: UINavigationController = UINavigationController()
    static var jsonInfo: loaderJSON?
}

class LocalizationManager {
    static let shared = LocalizationManager()

    private var localizedStrings: [String: String] = [:]

    private init() {
        if let path = Bundle.main.path(forResource: "Localizable", ofType: "strings"),
            let dictionary = NSDictionary(contentsOfFile: path) as? [String: String] {
            localizedStrings = dictionary
        }
    }

    func local(_ key: String) -> String {
        return localizedStrings[key] ?? key
    }
}

public func fileExists(_ path: String) -> Bool {
    return fm.fileExists(atPath: path)
}

func getDeviceCode() -> String? {
    var systemInfo = utsname()
    uname(&systemInfo)
    let modelCode = withUnsafePointer(to: &systemInfo.machine) {
        $0.withMemoryRebound(to: CChar.self, capacity: 1) {
            ptr in String.init(validatingUTF8: ptr)
        }
    }
    if modelCode!.contains("arm64") || modelCode!.contains("x86_64") {
        return "Simulated"
    }
    return modelCode
}

func bootargsObviouslyProbably() -> String {
    var size: size_t = 0
    sysctlbyname("kern.bootargs", nil, &size, nil, 0)
    var machine = [CChar](repeating: 0, count: size)
    sysctlbyname("kern.bootargs", &machine, &size, nil, 0)
    let bootArgs = String(cString: machine)
    return bootArgs
}

func kernelVersion() -> String {
    var utsnameInfo = utsname()
    uname(&utsnameInfo)

    let releaseCopy = withUnsafeBytes(of: &utsnameInfo.release) { bytes in
        Array(bytes)
    }

    let version = String(cString: releaseCopy)
    return version
}

extension UIApplication {
  public func openSpringBoard() {
    let workspace = LSApplicationWorkspace.default() as! LSApplicationWorkspace
  workspace.openApplication(withBundleID: "com.apple.springboard")
  }
}
