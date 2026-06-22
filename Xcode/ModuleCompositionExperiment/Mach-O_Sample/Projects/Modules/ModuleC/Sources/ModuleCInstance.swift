//
//  ModuleC.swift
//  ModuleC
//
//  Created by yjc on 11/17/24.
//
import ModuleCommon

public class ModuleCInstance {
    public init() {}
    
    public func callMyName() {
        print("I am ModuleC")
    }
    
    public func callModuleCommon() {
        ModuleCommonInstance().callMyName(caller: "ModuleC")
    }
    
    public var moduleCommonSharedInstance: ModuleCommonInstance { ModuleCommonInstance.shared }
}
