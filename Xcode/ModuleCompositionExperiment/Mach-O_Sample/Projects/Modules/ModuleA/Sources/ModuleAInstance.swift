//
//  ModuleA.swift
//  ModuleA
//
//  Created by yjc on 11/17/24.
//
import ModuleCommon

public class ModuleAInstance {
    public init() {}
    
    public func callMyName() {
        print("I am ModuleA")
    }
    
    public func callModuleCommon() {
        ModuleCommonInstance().callMyName(caller: "ModuleA")
    }
    
    public var moduleCommonSharedInstance: ModuleCommonInstance { ModuleCommonInstance.shared }
}
