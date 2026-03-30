import SwiftUI

struct ExerciseDetailView: View {
    let exercise: CatalogExercise
    let onStartTracking: () -> Void

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    heroSection
                    Divider().background(AppTheme.gymBorder).padding(.horizontal, 20)
                    infoSection
                    muscleSection
                    descriptionSection
                    startButton
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: exercise.category.systemImage)
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(AppTheme.gymSubtext)
                .padding(.bottom, 8)

            if exercise.isAITrackable {
                AIBadge()
            }
            Text(exercise.name)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.gymText)
            Text(exercise.category.displayName)
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 24)
    }

    // MARK: - Info row

    private var infoSection: some View {
        HStack(spacing: 24) {
            InfoItem(label: "Calories", value: "\(Int(exercise.estimatedCaloriesPerMinute)) /min")
            InfoItem(label: "Level", value: exercise.difficulty.displayName)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: - Muscles

    private var muscleSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Muscles")
            FlowLayout(spacing: 8) {
                ForEach(exercise.muscleGroups, id: \.self) { muscle in
                    Text(muscle)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.gymSubtext)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.gymSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel("Description")
            Text(exercise.description)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.gymSubtext)
                .lineSpacing(5)
                .padding(.horizontal, 20)
        }
        .padding(.bottom, 32)
    }

    // MARK: - Start button

    private var startButton: some View {
        Button(action: onStartTracking) {
            HStack {
                Text(exercise.isAITrackable ? "Watch Demo & Start AI" : "Watch Demo & Start")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymBg)
                Spacer()
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.gymBg)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(AppTheme.gymText)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Helpers

private struct SectionLabel: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.gymSubtext)
            .textCase(.uppercase)
            .tracking(0.6)
            .padding(.horizontal, 20)
    }
}

private struct InfoItem: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.gymSubtext)
                .textCase(.uppercase)
                .tracking(0.4)
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.gymText)
        }
    }
}

// Simple wrapping layout for muscle tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                y += rowHeight + spacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowHeight + spacing
                x = bounds.minX
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
