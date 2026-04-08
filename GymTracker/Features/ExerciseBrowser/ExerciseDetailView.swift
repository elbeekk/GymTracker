import SwiftUI

struct ExerciseDetailView: View {
    let exercise: CatalogExercise
    let onStartTracking: () -> Void
    @State private var showPlayer = false

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    videoSection
                    titleSection
                    statsSection
                    muscleSection
                    descriptionSection
                    startButton
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)
            }
        }
        .sheet(isPresented: $showPlayer) {
            if let videoID = exercise.youtubeShortID {
                YouTubePlayerSheet(videoID: videoID)
            }
        }
    }

    // MARK: - Video thumbnail

    @ViewBuilder
    private var videoSection: some View {
        if let videoID = exercise.youtubeShortID {
            Button(action: { showPlayer = true }) {
                GeometryReader { geo in
                    ZStack {
                        YouTubeInlineView(videoID: videoID)
                            .frame(width: geo.size.width, height: geo.size.height)

                        // Tap to expand hint
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.7))
                                    .padding(8)
                                    .background(.black.opacity(0.45))
                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                    .padding(10)
                            }
                        }
                    }
                }
                // 9:16 portrait ratio for Shorts
                .aspectRatio(9/16, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Title

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            if exercise.isAITrackable {
                AIBadge().padding(.top, 20)
            } else {
                Color.clear.frame(height: 20)
            }
            Text(exercise.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(AppTheme.gymText)
            Text(exercise.category.displayName)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Stats cards (matches HomeView StatCard style)

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(Int(exercise.estimatedCaloriesPerMinute))", unit: "kcal/min", label: "Calories")
            StatCard(value: exercise.difficulty.displayName, unit: "", label: "Level")
            StatCard(value: "\(exercise.muscleGroups.count)", unit: "groups", label: "Muscles")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Muscles

    private var muscleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Muscles")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.gymSubtext)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

            VStack(spacing: 1) {
                ForEach(exercise.muscleGroups, id: \.self) { muscle in
                    HStack {
                        Text(muscle)
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.gymText)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    Divider().background(AppTheme.gymBorder).padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 24)
    }

    // MARK: - Description

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Form Tips")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AppTheme.gymSubtext)
                .textCase(.uppercase)
                .tracking(0.5)
                .padding(.horizontal, 20)

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
                Text(exercise.isAITrackable ? "Start AI Tracking" : "Start Workout")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.gymBg)
                Spacer()
                Image(systemName: "arrow.right")
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

// MARK: - Stat card (mirrors HomeView style)

private struct StatCard: View {
    let value: String
    let unit: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.gymText)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10))
                        .foregroundStyle(AppTheme.gymSubtext)
                }
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.gymSubtext)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Simple wrapping layout kept for any future reuse
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 { y += rowHeight + spacing; x = 0; rowHeight = 0 }
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
            if x + size.width > bounds.maxX && x > bounds.minX { y += rowHeight + spacing; x = bounds.minX; rowHeight = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
