import SwiftUI

struct FeedbackBannerView: View {
    let banner: FeedbackBanner
    var action: (() -> Void)?

    private var tint: Color {
        switch banner.style {
        case .success:
            AppTheme.success
        case .warning:
            AppTheme.warning
        case .critical:
            AppTheme.danger
        case .neutral:
            AppTheme.accent
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(tint)
                .frame(width: 4)

            Text(banner.text)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .lineLimit(2)
                .minimumScaleFactor(0.75)

            if banner.showsLessonAction, let action {
                Button("Lesson", action: action)
                    .buttonStyle(.bordered)
                    .tint(tint)
                    .controlSize(.large)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.elevatedSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }
}
