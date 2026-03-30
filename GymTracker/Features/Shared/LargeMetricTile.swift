import SwiftUI

struct LargeMetricTile: View {
    let title: String
    let value: String
    let detail: String?
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppTheme.secondaryText)

            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.primary)
                .lineLimit(2)
                .minimumScaleFactor(0.65)

            if let detail, !detail.isEmpty {
                Text(detail)
                    .font(.headline.weight(.medium))
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(3)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(tint)
                .frame(width: 32, height: 4)
                .padding(.top, 12)
                .padding(.leading, 18)
        }
    }
}
