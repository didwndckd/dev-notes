//
//  FallingSnowView2.swift
//  ProSwiftUI
//
//  Created by yjc on 3/9/26.
//

import SwiftUI

struct FallingSnowView2: View {
    @State private var particleSystem = FallingSnowParticleSystem()
    
    var body: some View {
        LinearGradient(colors: [.red, .indigo], startPoint: .top, endPoint: .bottom).mask {
            TimelineView(.animation) { timeline in
                Canvas { ctx, size in
                    let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                    particleSystem.update(date: timelineDate, size: size)
                    
                    // FallingSnowView1과 차이
                    ctx.addFilter(.alphaThreshold(min: 0.5, color: .white))
                    
                    ctx.addFilter(.blur(radius: 10))
                    
                    // 내부 모든 파티클이 하나의 레이어에 먼저 합쳐진 후 캔버스에 그려짐
                    ctx.drawLayer { ctx in
                        for particle in particleSystem.particles {
                            ctx.opacity = particle.deathDate - timelineDate
                            
                            let frame = CGRect(x: particle.x, y: particle.y, width: 32, height: 32)
                            ctx.fill(
                                Circle().path(in:frame) ,
                                with: .color(.white)
                            )
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    FallingSnowView2()
}
