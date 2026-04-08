import Observation
import SwiftUI

// MARK: - Navigation destination tokens

enum NavDestination: Hashable {
    case exerciseDetail(CatalogExercise)
}

// MARK: - App tabs

enum AppTab: Hashable {
    case home, workout, history, profile
}

enum ActiveWorkoutCover: Identifiable, Hashable {
    case tutorial(CatalogExercise)
    case tracking(CatalogExercise)

    var id: String {
        switch self {
        case .tutorial(let exercise):
            return "tutorial-\(exercise.id.uuidString)"
        case .tracking(let exercise):
            return "tracking-\(exercise.id.uuidString)"
        }
    }
}

// MARK: - RootView

struct RootView: View {
    @State private var workoutStore = WorkoutStore()
    @State private var selectedTab: AppTab = .home
    @State private var activeWorkoutCover: ActiveWorkoutCover? = nil

    private let tabBarHeight: CGFloat = 82

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch selectedTab {
                case .home:
                    NavigationStack {
                        HomeView(workoutStore: workoutStore) {
                            selectedTab = .workout
                        }
                        .navigationDestination(for: NavDestination.self, destination: navDestination)
                    }
                case .workout:
                    NavigationStack {
                        ExerciseBrowserView()
                            .navigationDestination(for: NavDestination.self, destination: navDestination)
                    }
                case .history:
                    NavigationStack {
                        HistoryView(workoutStore: workoutStore)
                    }
                case .profile:
                    NavigationStack {
                        ProfileView()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, tabBarHeight)

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .fullScreenCover(item: $activeWorkoutCover) { cover in
            switch cover {
            case .tutorial(let exercise):
                ExerciseTutorialView(
                    exercise: exercise,
                    onClose: { activeWorkoutCover = nil },
                    onContinue: { activeWorkoutCover = .tracking(exercise) }
                )
            case .tracking(let exercise):
                TrackingWrapperView(
                    exercise: exercise,
                    workoutStore: workoutStore,
                    onFinish: { activeWorkoutCover = nil }
                )
            }
        }
    }

    // MARK: - Navigation destination handler

    @ViewBuilder
    private func navDestination(_ destination: NavDestination) -> some View {
        switch destination {
        case .exerciseDetail(let exercise):
            ExerciseDetailView(exercise: exercise) {
                activeWorkoutCover = .tracking(exercise)
            }
        }
    }

    // MARK: - Custom tab bar

    private var customTabBar: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill",    label: "Home",    isSelected: selectedTab == .home)    { selectedTab = .home }
            TabBarItem(icon: "dumbbell.fill", label: "Workout", isSelected: selectedTab == .workout) { selectedTab = .workout }
            TabBarItem(icon: "calendar",      label: "History", isSelected: selectedTab == .history) { selectedTab = .history }
            TabBarItem(icon: "person.fill",   label: "Profile", isSelected: selectedTab == .profile) { selectedTab = .profile }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            AppTheme.gymSurface
                .overlay(Rectangle().fill(AppTheme.gymBorder).frame(height: 1), alignment: .top)
        )
    }
}

// MARK: - Tab bar item

private struct TabBarItem: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? AppTheme.gymText : AppTheme.gymDim)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundStyle(isSelected ? AppTheme.gymText : AppTheme.gymDim)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootView()
}
