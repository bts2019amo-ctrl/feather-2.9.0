import SwiftUI

struct ParticleBackgroundView: View {
	private struct Particle {
		let x: CGFloat
		let y: CGFloat
		let radius: CGFloat
		let speed: CGFloat
		let phase: CGFloat
		let hue: CGFloat
	}

	private let particles: [Particle] = (0..<56).map { index in
		let value = CGFloat(index)
		return Particle(
			x: (sin(value * 12.9898) * 43758.5453).truncatingRemainder(dividingBy: 1).magnitude,
			y: (sin(value * 78.233) * 12741.371).truncatingRemainder(dividingBy: 1).magnitude,
			radius: 1.2 + (value.truncatingRemainder(dividingBy: 4.0) * 0.65),
			speed: 0.012 + (value.truncatingRemainder(dividingBy: 5.0) * 0.003),
			phase: value * 0.47,
			hue: value.truncatingRemainder(dividingBy: 3.0)
		)
	}

	var body: some View {
		GeometryReader { geometry in
			TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
				Canvas { context, size in
					let time = timeline.date.timeIntervalSinceReferenceDate
					let background = Gradient(colors: [
						Color(red: 0.015, green: 0.012, blue: 0.055),
						Color(red: 0.075, green: 0.025, blue: 0.14),
						Color(red: 0.012, green: 0.018, blue: 0.07)
					])
					context.fill(Path(CGRect(origin: .zero, size: size)), with: .linearGradient(
						background,
						startPoint: CGPoint(x: 0, y: 0),
						endPoint: CGPoint(x: size.width, y: size.height)
					))

					let glowCenter = CGPoint(
						x: size.width * (0.5 + 0.16 * CGFloat(sin(time * 0.12))),
						y: size.height * (0.42 + 0.14 * CGFloat(cos(time * 0.1)))
					)
					let glowRect = CGRect(x: glowCenter.x - size.width * 0.62, y: glowCenter.y - size.height * 0.5, width: size.width * 1.24, height: size.height)
					context.fill(Path(ellipseIn: glowRect), with: .radialGradient(
						Gradient(colors: [Color.purple.opacity(0.18), Color.blue.opacity(0.04), .clear]),
						center: glowCenter,
						startRadius: 0,
						endRadius: max(size.width, size.height) * 0.72
					))

					for particle in particles {
						let drift = CGFloat(time) * particle.speed + particle.phase
						let px = (particle.x * size.width + CGFloat(sin(drift * 1.7)) * 34).truncatingRemainder(dividingBy: size.width)
						let py = (particle.y * size.height - CGFloat(time) * particle.speed * 18 + CGFloat(cos(drift)) * 22).truncatingRemainder(dividingBy: size.height)
						let point = CGPoint(x: px < 0 ? px + size.width : px, y: py < 0 ? py + size.height : py)
						let pulse = 0.55 + 0.45 * CGFloat(sin(time * 1.2 + particle.phase))
						let color = particle.hue == 0 ? Color.white : (particle.hue == 1 ? Color.purple : Color.blue)
						let radius = particle.radius * (0.8 + pulse * 0.35)
						let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
						context.fill(Path(ellipseIn: rect), with: .color(color.opacity(0.3 + pulse * 0.55)))
						let halo = CGRect(x: point.x - radius * 4, y: point.y - radius * 4, width: radius * 8, height: radius * 8)
						context.fill(Path(ellipseIn: halo), with: .radialGradient(
							Gradient(colors: [color.opacity(0.16 * pulse), .clear]),
							center: point,
							startRadius: 0,
							endRadius: radius * 4
						))
					}
				}
			}
		}
		.ignoresSafeArea()
	}
}
