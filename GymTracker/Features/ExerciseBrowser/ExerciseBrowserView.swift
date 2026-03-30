import SwiftUI

struct ExerciseBrowserView: View {
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var searchText = ""

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()
            VStack(spacing: 0) {
                navBar
                searchBar
                if let cat = selectedCategory {
                    exerciseList(for: cat)
                } else {
                    categoryGrid
                }
            }
        }
        .navigationBarHidden(true)
    }

    // MARK: - Nav bar

    private var navBar: some View {
        HStack {
            if selectedCategory != nil {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedCategory = nil
                        searchText = ""
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 15))
                    }
                    .foregroundStyle(AppTheme.gymText)
                }
            }
            Spacer()
            Text(selectedCategory?.displayName ?? "Exercises")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.gymText)
            Spacer()
            if selectedCategory != nil {
                Color.clear.frame(width: 60, height: 20)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 56)
        .padding(.bottom, 12)
    }

    // MARK: - Search bar

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.gymSubtext)
            TextField("Search", text: $searchText)
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.gymText)
                .tint(AppTheme.gymText)
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.gymSubtext)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppTheme.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Category grid

    private var categoryGrid: some View {
        ScrollView(showsIndicators: false) {
            let filtered = searchText.isEmpty
                ? ExerciseCategory.allCases
                : ExerciseCategory.allCases.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(filtered) { category in
                    CategoryCard(category: category)
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedCategory = category
                                searchText = ""
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Exercise list

    @ViewBuilder
    private func exerciseList(for category: ExerciseCategory) -> some View {
        let exercises = category.exercises.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.muscleGroups.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
        }
        ScrollView(showsIndicators: false) {
            VStack(spacing: 1) {
                ForEach(exercises) { exercise in
                    NavigationLink(value: NavDestination.exerciseDetail(exercise)) {
                        ExerciseRowCard(exercise: exercise)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - CategoryCard

struct CategoryCard: View {
    let category: ExerciseCategory

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.system(size: 22, weight: .light))
                .foregroundStyle(AppTheme.gymText)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)
                Text("\(category.exercises.count) exercises")
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gymSubtext)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.gymSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .contentShape(Rectangle())
    }
}

// MARK: - ExerciseRowCard

struct ExerciseRowCard: View {
    let exercise: CatalogExercise

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.gymText)
                    if exercise.isAITrackable {
                        AIBadge()
                    }
                }
                Text(exercise.muscleGroups.prefix(2).joined(separator: ", "))
                    .font(.system(size: 12))
                    .foregroundStyle(AppTheme.gymSubtext)
            }
            Spacer()
            Text(exercise.difficulty.displayName)
                .font(.system(size: 11))
                .foregroundStyle(AppTheme.gymSubtext)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(AppTheme.gymDim)
        }
        .padding(.vertical, 14)
        Divider()
            .background(AppTheme.gymBorder)
    }
}

// MARK: - Shared small components

struct AIBadge: View {
    var body: some View {
        Text("AI")
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(AppTheme.gymAccent)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .overlay(Capsule().stroke(AppTheme.gymAccent.opacity(0.5), lineWidth: 1))
            .clipShape(Capsule())
    }
}

struct DifficultyDot: View {
    let difficulty: Difficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(AppTheme.gymSubtext)
    }
}
