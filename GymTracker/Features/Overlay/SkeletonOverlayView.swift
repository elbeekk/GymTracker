import SwiftUI

struct SkeletonOverlayView: View {
    let overlay: SkeletonOverlayState
    let isMirrored: Bool

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for person in overlay.people {
                    let style = style(for: person.role)

                    if !person.boundingBox.isEmpty {
                        let minX = isMirrored
                            ? (1 - person.boundingBox.maxX)
                            : person.boundingBox.minX
                        let rect = CGRect(
                            x: minX * size.width,
                            y: person.boundingBox.minY * size.height,
                            width: person.boundingBox.width * size.width,
                            height: person.boundingBox.height * size.height
                        )

                        context.stroke(
                            Path(roundedRect: rect, cornerRadius: 16),
                            with: .color(style.color.opacity(style.opacity)),
                            style: StrokeStyle(lineWidth: style.lineWidth, dash: style.dashPattern)
                        )
                    }

                    for connection in PosePerson.skeletonConnections {
                        guard
                            let start = person.points.first(where: { $0.name == connection.0 && $0.confidence > 0.22 }),
                            let end = person.points.first(where: { $0.name == connection.1 && $0.confidence > 0.22 })
                        else {
                            continue
                        }

                        var path = Path()
                        path.move(to: point(start.location, in: size))
                        path.addLine(to: point(end.location, in: size))

                        context.stroke(
                            path,
                            with: .color(style.color.opacity(style.opacity)),
                            style: StrokeStyle(lineWidth: style.lineWidth, lineCap: .round, lineJoin: .round)
                        )
                    }

                    for keypoint in person.points where keypoint.confidence > 0.22 {
                        let point = point(keypoint.location, in: size)
                        let dotRect = CGRect(x: point.x - 4, y: point.y - 4, width: 8, height: 8)
                        context.fill(
                            Path(ellipseIn: dotRect),
                            with: .color(style.color.opacity(style.opacity))
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func point(_ normalized: CGPoint, in size: CGSize) -> CGPoint {
        CGPoint(
            x: (isMirrored ? 1 - normalized.x : normalized.x) * size.width,
            y: normalized.y * size.height
        )
    }

    private func style(for role: OverlayPersonRole) -> (color: Color, opacity: Double, lineWidth: CGFloat, dashPattern: [CGFloat]) {
        switch role {
        case .locked:
            (Color.green, 0.95, 3, [])
        case .calibrationCandidate:
            (Color.cyan, 0.90, 3, [10, 6])
        case .lost:
            (Color.red, 0.85, 3, [8, 6])
        case .other:
            (Color.white, 0.28, 2, [])
        }
    }
}
