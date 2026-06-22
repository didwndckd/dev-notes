//
//  ModuleCommonBridgeInstance.swift
//  ModuleA
//
//  Created by yjc on 6/14/25.
//

import Foundation

public class ModuleCommonBridgeInstance {
    public static let shared = ModuleCommonBridgeInstance()
    
    public init() {}
    
    public func callMyName(caller: String) {
        print("I am ModuleCommon in \(caller)")
    }
}
