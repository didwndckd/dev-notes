//
//  ModuleB.swift
//  ModuleB
//
//  Created by yjc on 11/17/24.
//

import ModuleCommon

public class ModuleBInstance {
    public init() {}
    
    public func callMyName() {
        print("I am ModuleB")
    }
    
    public func callModuleCommon() {
        ModuleCommonInstance().callMyName(caller: "ModuleB")
    }
    
    public var moduleCommonSharedInstance: ModuleCommonInstance { ModuleCommonInstance.shared }
}
