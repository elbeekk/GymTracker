import CoreGraphics
import Foundation

enum AngleCalculator {
    static func angle(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> Double {
        let ab = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let cb = CGVector(dx: c.x - b.x, dy: c.y - b.y)

        let dot = Double(ab.dx * cb.dx + ab.dy * cb.dy)
        let magnitudeAB = sqrt(Double(ab.dx * ab.dx + ab.dy * ab.dy))
        let magnitudeCB = sqrt(Double(cb.dx * cb.dx + cb.dy * cb.dy))
        guard magnitudeAB > 0, magnitudeCB > 0 else { return 0 }

        let cosine = (dot / (magnitudeAB * magnitudeCB)).clamped(to: -1 ... 1)
        return acos(cosine) * 180 / .pi
    }

    static func average(_ values: [Double?]) -> Double? {
        let compact = values.compactMap { $0 }
        guard !compact.isEmpty else { return nil }
        return compact.reduce(0, +) / Double(compact.count)
    }

    static func leanFromVertical(upper: CGPoint, lower: CGPoint) -> Double {
        let dx = Double(upper.x - lower.x)
        let dy = Double(lower.y - upper.y)
        guard dy != 0 || dx != 0 else { return 0 }
        return abs(atan2(dx, dy)) * 180 / .pi
    }

    static func pointLineDistance(point: CGPoint, lineStart: CGPoint, lineEnd: CGPoint) -> Double {
        let numerator = abs(
            Double(lineEnd.y - lineStart.y) * Double(point.x) -
                Double(lineEnd.x - lineStart.x) * Double(point.y) +
                Double(lineEnd.x * lineStart.y - lineEnd.y * lineStart.x)
        )
        let denominator = sqrt(
            pow(Double(lineEnd.y - lineStart.y), 2) +
                pow(Double(lineEnd.x - lineStart.x), 2)
        )
        guard denominator > 0 else { return 0 }
        return numerator / denominator
    }
}
