//
//  Define.swift
//  Config
//
//  Created by yjc on 11/18/24.
//

import Foundation
@preconcurrency import ProjectDescription

public enum Define {
    public static let appName = "Mach-O-Sample-App"
    public static let bundleIdentifier = "com.didwndckd"
    public static let projectPath = "Projects"
    public static let modulePath = "Projects/Modules"
    public static let defaultSettings: SettingsDictionary = [
        "OTHER_LDFLAGS": "-Objc",
//        "DEAD_CODE_STRIPPING": "NO",
    ]
}
