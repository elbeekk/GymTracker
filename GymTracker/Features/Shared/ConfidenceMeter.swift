import SwiftUI

struct ConfidenceMeter: View {
    let value: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.primary.opacity(0.08))

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(tint)
                        .frame(width: geometry.size.width * value.clamped(to: 0 ... 1))
                }
            }
            .frame(height: 8)

            Text("\(Int((value.clamped(to: 0 ... 1)) * 100))% confidence")
                .font(.caption.weight(.medium))
                .foregroundStyle(AppTheme.secondaryText)
        }
    }
}
