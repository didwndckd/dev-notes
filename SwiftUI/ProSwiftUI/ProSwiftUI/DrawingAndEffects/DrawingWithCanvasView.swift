//
//  DrawingWithCanvas.swift
//  ProSwiftUI
//
//  Created by yjc on 3/9/26.
//

import SwiftUI

extension DrawingWithCanvasView {
    class ParticleSystem {
        var particles = [Particle]()
        var position = CGPoint.zero

        func update(date: TimeInterval) {
            particles = particles.filter { $0.deathDate > date }
            particles.append(Particle(position: position))
        }
    }

    struct Particle {
        let position: CGPoint
        let deathDate = Date.now.timeIntervalSinceReferenceDate + 1
    }
}

struct DrawingWithCanvasView: View {
    @State private var particleSystem = ParticleSystem()
    
    var body: some View {
        // 시간의 흐름에 따라 뷰를 주기적으로 다시 그림 (.animation: 애니메이션에 최적화된 빈도)
        TimelineView(.animation) { timeline in
//            print(timeline.date)
            Canvas { ctx, size in
                // ctx: GraphicsContext - 실제 드로잉 작업을 수행
                // size: CGSize - Canvas의 현재 크기
                
                let timelineDate = timeline.date.timeIntervalSinceReferenceDate
                particleSystem.update(date: timelineDate)
                ctx.blendMode = .plusLighter
                ctx.addFilter(.blur(radius: 10))

                for particle in particleSystem.particles {
                    let frame = CGRect(
                        x: particle.position.x - 16,
                        y: particle.position.y - 16,
                        width: 32,
                        height: 32
                    )
                    
                    ctx.opacity = particle.deathDate - timelineDate
                    ctx.fill(
                        Circle().path(in: frame),
                        with: .color(.cyan)
                    )
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { drag in
                    particleSystem.position = drag.location
                }
        )
        .ignoresSafeArea()
        .background(.black)
    }
}

#Preview {
    NavigationStack {
        DrawingWithCanvasView()
    }
}
