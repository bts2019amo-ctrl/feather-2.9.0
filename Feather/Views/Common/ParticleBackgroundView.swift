import SwiftUI

struct ParticleBackgroundView: View {
    private struct Particle {
        let x: CGFloat
        let y: CGFloat
        let length: CGFloat
        let width: CGFloat
        let speed: CGFloat
        let phase: CGFloat
        let colorIndex: Int
    }

    private let particles: [Particle] = (0..<92).map { index in
        let value = CGFloat(index)
        let pseudoX = abs((sin(value * 17.123) * 43758.5453).truncatingRemainder(dividingBy: 1))
        let pseudoY = abs((sin(value * 41.731) * 12741.371).truncatingRemainder(dividingBy: 1))
        return Particle(
            x: pseudoX,
            y: pseudoY,
            length: 3.0 + (value.truncatingRemainder(dividingBy: 7.0) * 2.8),
            width: 0.7 + (value.truncatingRemainder(dividingBy: 3.0) * 0.35),
            speed: 18.0 + (value.truncatingRemainder(dividingBy: 9.0) * 4.2),
            phase: value * 0.71,
            colorIndex: Int(value.truncatingRemainder(dividingBy: 4.0))
        )
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let rect = CGRect(origin: .zero, size: size)

                // Deep dark background with a restrained blue-violet atmospheric glow.
                context.fill(Path(rect), with: .color(Color(red: 0.004, green: 0.006, blue: 0.018).opacity(0.035)))
                let center = CGPoint(
                    x: size.width * (0.50 + 0.12 * CGFloat(sin(time * 0.08))),
                    y: size.height * (0.42 + 0.16 * CGFloat(cos(time * 0.07)))
                )
                let glowRect = CGRect(
                    x: center.x - size.width * 0.72,
                    y: center.y - size.height * 0.58,
                    width: size.width * 1.44,
                    height: size.height * 1.16
                )
                context.fill(Path(ellipseIn: glowRect), with: .radialGradient(
                    Gradient(colors: [
                        Color.indigo.opacity(0.11),
                        Color.blue.opacity(0.035),
                        .clear
                    ]),
                    center: center,
                    startRadius: 0,
                    endRadius: max(size.width, size.height) * 0.78
                ))

                for particle in particles {
                    let cycle = CGFloat(time) * particle.speed + particle.phase * size.height
                    let y = (particle.y * size.height + cycle).truncatingRemainder(dividingBy: size.height + 80) - 40
                    let sway = CGFloat(sin(time * 0.32 + particle.phase)) * 7.0
                    let x = particle.x * size.width + sway
                    let pulse = 0.55 + 0.45 * CGFloat(sin(time * 1.4 + particle.phase))
                    let color: Color = switch particle.colorIndex {
                    case 0: .white
                    case 1: .cyan
                    case 2: .blue
                    default: .purple
                    }

                    let lineRect = CGRect(
                        x: x - particle.width / 2,
                        y: y - particle.length / 2,
                        width: particle.width,
                        height: particle.length
                    )
                    context.fill(
                        Path(roundedRect: lineRect, cornerRadius: particle.width),
                        with: .color(color.opacity(0.34 + pulse * 0.46))
                    )

                    let haloRect = CGRect(
                        x: x - particle.length * 1.8,
                        y: y - particle.length * 1.8,
                        width: particle.length * 3.6,
                        height: particle.length * 3.6
                    )
                    context.fill(
                        Path(ellipseIn: haloRect),
                        with: .radialGradient(
                            Gradient(colors: [color.opacity(0.12 * pulse), .clear]),
                            center: CGPoint(x: x, y: y),
                            startRadius: 0,
                            endRadius: particle.length * 1.8
                        )
                    )
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}
