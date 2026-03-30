import CoreGraphics
import Foundation

extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

extension CGPoint {
    func distance(to other: CGPoint) -> Double {
        let dx = Double(x - other.x)
        let dy = Double(y - other.y)
        return sqrt(dx * dx + dy * dy)
    }
}

extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    var area: Double {
        guard !isNull, !isEmpty else { return 0 }
        return Double(width * height)
    }

    func intersectionOverUnion(with other: CGRect) -> Double {
        guard !isNull, !isEmpty, !other.isNull, !other.isEmpty else {
            return 0
        }

        let intersectionArea = intersection(other).area
        let unionArea = area + other.area - intersectionArea
        guard unionArea > 0 else { return 0 }
        return intersectionArea / unionArea
    }

    func insetBy(dxPercent: CGFloat, dyPercent: CGFloat) -> CGRect {
        insetBy(dx: width * dxPercent, dy: height * dyPercent)
    }

    func clampedToUnit() -> CGRect {
        let minX = self.minX.clamped(to: 0 ... 1)
        let minY = self.minY.clamped(to: 0 ... 1)
        let maxX = self.maxX.clamped(to: 0 ... 1)
        let maxY = self.maxY.clamped(to: 0 ... 1)
        return CGRect(x: minX, y: minY, width: max(0, maxX - minX), height: max(0, maxY - minY))
    }
}
