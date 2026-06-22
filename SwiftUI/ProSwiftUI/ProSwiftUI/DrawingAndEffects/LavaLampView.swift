//
//  LavaLampView2.swift
//  ProSwiftUI
//
//  Created by yjc on 3/10/26.
//

import SwiftUI
internal import Combine

class LavaLampParticle: Identifiable {
    let id = UUID()
    var size = Double.random(in: 100...250)
    var x = Double.random(in: -0.1...1.1)
    var y = Double.random(in: -0.25...1.25)
    var isMovingDown = Bool.random()
    var speed = Double.random(in: 0.01...0.1)
}

class LavaLampParticleSystem {
    let particles: [LavaLampParticle]
    var lastUpdate = Date.now.timeIntervalSinceReferenceDate
    
    init(count: Int) {
        particles = (0..<count).map { _ in LavaLampParticle() }
    }

    func update(date: TimeInterval) {
        let delta = date - lastUpdate
        lastUpdate = date

        for particle in particles {
            if particle.isMovingDown {
                particle.y += particle.speed * delta

                if particle.y > 1.25 {
                    particle.isMovingDown = false
                }
            } else {
                particle.y -= particle.speed * delta

                if particle.y < -0.25 {
                    particle.isMovingDown = true
                }
            }
        }
    }
}

extension Array: @retroactive VectorArithmetic, @retroactive AdditiveArithmetic where Element == Double {
    public mutating func scale(by rhs: Double) {
        for (index, item) in self.enumerated() {
            guard index < self.count else { return }
            self[index] = item * rhs
        }
    }
    
    public static func +=(lhs: inout [Double], rhs: [Double]) {
        for (index, item) in rhs.enumerated() {
            guard index < lhs.count else { return }
            lhs[index] += item
        }
    }

    public static func -=(lhs: inout [Double], rhs: [Double]) {
        for (index, item) in rhs.enumerated() {
            guard index < lhs.count else { return }
            lhs[index] -= item
        }
    }
    
    public static func -(lhs: [Double], rhs: [Double]) -> [Double] { [] }
    
    public static var zero: Array<Element> {
        [0]
    }
    
    public var magnitudeSquared: Double { 0 }
}

struct AnimatablePolygonShape: Shape {
    var animatableData: [Double]

    init(points: [Double]) {
        animatableData = points
    }
    
    func path(in rect: CGRect) -> Path {
        Path { path in
            let center =  CGPoint(x: rect.width / 2, y: rect.height / 2)
            let radius = min(center.x, center.y)

            let lines = animatableData.enumerated().map { index, value in
                let fraction = Double(index) / Double(animatableData.count)
                let xPos = center.x + radius * cos(fraction * .pi * 2)
                let yPos = center.y + radius * sin(fraction * .pi * 2)
                return CGPoint(x: xPos * value, y: yPos * value)
            }

            path.addLines(lines)
        }
    }
}

struct AnimatingPolygon: View {
    @State private var points = Self.makePoints()
    @State private var timer = Timer.publish(every: 1, tolerance: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        AnimatablePolygonShape(points: points)
            .animation(.easeInOut(duration: 3), value: points)
            .onReceive(timer) { date in
                points = Self.makePoints()
            }
    }

    static func makePoints() -> [Double] {
        (0..<8).map { _ in .random(in: 0.8...1.2) }
    }
}

struct LavaLampView: View {
    @State private var particleSystem = LavaLampParticleSystem(count: 15)
    @State private var threshold = 0.5
    @State private var blur = 30.0
    @State private var usePolygon = false

    var body: some View {
        VStack {
            LinearGradient(colors: [.red, .orange], startPoint: .top, endPoint: .bottom).mask {
                TimelineView(.animation) { timeline in
                    Canvas { ctx, size in
                        particleSystem.update(date: timeline.date.timeIntervalSinceReferenceDate)
                        ctx.addFilter(.alphaThreshold(min: threshold))
                        ctx.addFilter(.blur(radius: blur))
                        
                        ctx.drawLayer { ctx in
                            for particle in particleSystem.particles {
                                guard let symbol = ctx.resolveSymbol(id: particle.id) else { continue }
                                let point = CGPoint(x: particle.x * size.width, y: particle.y * size.height)
                                ctx.draw(symbol, at: point)
                            }
                        }
                    } symbols: {
                        ForEach(particleSystem.particles) { particle in
                            symbol(particle: particle)
                                .frame(width: particle.size, height: particle.size)
                        }
                    }
                }
            }
            .ignoresSafeArea()
            .background(.indigo)
            
            LabeledContent("Use Polygon") {
                Toggle("", isOn: $usePolygon)
            }
            .padding(.horizontal)
            
            LabeledContent("Threshold") {
                Slider(value: $threshold, in: 0.01...0.99)
            }
            .padding(.horizontal)
            
            LabeledContent("Blur") {
                Slider(value: $blur, in: 0...40)
            }
            .padding(.horizontal)
        }
        .navigationTitle("Lava Lamp")
    }
    
    @ViewBuilder
    private func symbol(particle: LavaLampParticle) -> some View {
        if usePolygon {
            AnimatingPolygon()
        } else {
            Circle()
        }
    }
}

#Preview {
    LavaLampView()
}
