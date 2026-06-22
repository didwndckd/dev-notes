//
//  FallingSnowView1.swift
//  ProSwiftUI
//
//  Created by yjc on 3/9/26.
//

import SwiftUI

class FallingSnowParticle {
    var x: Double
    var y: Double
    let xSpeed: Double
    let ySpeed: Double
    let deathDate = Date.now.timeIntervalSinceReferenceDate + 2

    init(x: Double, y: Double, xSpeed: Double, ySpeed: Double) {
        self.x = x
        self.y = y
        self.xSpeed = xSpeed
        self.ySpeed = ySpeed
    }
}

class FallingSnowParticleSystem {
    var particles = [FallingSnowParticle]()
    var lastUpdate = Date.now.timeIntervalSinceReferenceDate
    
    func update(date: TimeInterval, size: CGSize) {
        let delta = date - lastUpdate
        lastUpdate = date

        for (index, particle) in particles.enumerated() {
            if particle.deathDate < date {
                // 기존 Particle 제거
                particles.remove(at: index)
            } else {
                // 기존 Particle 이동
                particle.x += particle.xSpeed * delta
                particle.y += particle.ySpeed * delta
            }
        }

        let newParticle = FallingSnowParticle(
            x: .random(in: -32...size.width),
            y: -32,
            xSpeed: .random(in: -50...50),
            ySpeed: .random(in: 100...500)
        )
        particles.append(newParticle)
    }
}

struct FallingSnowView1: View {
    @State private var particleSystem = FallingSnowParticleSystem()
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                particleSystem.update(date: timelineDate, size: size)
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
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    FallingSnowView1()
}
