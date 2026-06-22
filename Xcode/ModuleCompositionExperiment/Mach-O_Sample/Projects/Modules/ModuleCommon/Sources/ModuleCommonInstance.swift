//
//  ModuleCommon.swift
//  ModuleCommon
//
//  Created by yjc on 11/17/24.
//

import Foundation

@objc
public class ModuleCommonInstance: NSObject {
    public static let shared = ModuleCommonInstance()
    
    public override init() {
        super.init()
    }
    
    @objc
    public func callMyName(caller: String) {
        print("I am ModuleCommon in \(caller)")
    }
}
