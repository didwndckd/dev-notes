//
//  ContentView.swift
//  Mach-O_Sample
//
//  Created by yjc on 11/17/24.
//

import SwiftUI
import ModuleA
import ModuleB
import ModuleC

struct ContentView: View {
    private let moduleA = ModuleAInstance()
    private let moduleB = ModuleBInstance()
    private let moduleC = ModuleCInstance()
    
    var body: some View {
        List {
            Button("Path Bundle") {
                print(Bundle.main.bundlePath)
            }
            
            Button("Call ModuleA") {
                moduleA.callMyName()
            }
            
            Button("Call ModuleA-Common") {
                moduleA.callModuleCommon()
            }
            
            Button("Call ModuleB") {
                moduleB.callMyName()
            }
            
            Button("Call ModuleB-Common") {
                moduleB.callModuleCommon()
            }
            
            Button("Call ModuleC") {
                moduleC.callMyName()
            }
            
            Button("Call ModuleC-Common") {
                moduleC.callModuleCommon()
            }
            
            Section("Common Shared Instance Check") {
                Button("ModuleA-Common == ModuleB-Common") {
                    print(moduleA.moduleCommonSharedInstance === moduleB.moduleCommonSharedInstance)
                }
                
                Button("ModuleA-Common == ModuleC-Common") {
                    print(moduleA.moduleCommonSharedInstance === moduleC.moduleCommonSharedInstance)
                }
                
                Button("ModuleB-Common == ModuleC-Common") {
                    print(moduleB.moduleCommonSharedInstance === moduleC.moduleCommonSharedInstance)
                }
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
