import Foundation

// MARK: - Difficulty

enum Difficulty: String, CaseIterable, Codable, Hashable {
    case beginner, intermediate, advanced

    var displayName: String { rawValue.capitalized }

    var color: String {
        switch self {
        case .beginner:     return "gymGreen"
        case .intermediate: return "gymAccent"
        case .advanced:     return "danger"
        }
    }
}

// MARK: - ExerciseCategory

enum ExerciseCategory: String, CaseIterable, Identifiable, Hashable, Codable {
    case chest, back, legs, arms, shoulders, core, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest:     return "Chest"
        case .back:      return "Back"
        case .legs:      return "Legs"
        case .arms:      return "Arms"
        case .shoulders: return "Shoulders"
        case .core:      return "Core"
        case .fullBody:  return "Full Body"
        }
    }

    var systemImage: String {
        switch self {
        case .chest:     return "figure.strengthtraining.traditional"
        case .back:      return "figure.rowing"
        case .legs:      return "figure.run"
        case .arms:      return "dumbbell.fill"
        case .shoulders: return "figure.arms.open"
        case .core:      return "figure.core.training"
        case .fullBody:  return "figure.mixed.cardio"
        }
    }
}

// MARK: - CatalogExercise

struct CatalogExercise: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let category: ExerciseCategory
    let exerciseType: ExerciseType?
    let muscleGroups: [String]
    let difficulty: Difficulty
    let estimatedCaloriesPerMinute: Double
    let description: String

    var isAITrackable: Bool { exerciseType != nil && exerciseType != .unknown }

    static func == (lhs: CatalogExercise, rhs: CatalogExercise) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    init(
        name: String,
        category: ExerciseCategory,
        exerciseType: ExerciseType? = nil,
        muscleGroups: [String],
        difficulty: Difficulty = .intermediate,
        caloriesPerMinute: Double = 5.0,
        description: String
    ) {
        self.id = UUID()
        self.name = name
        self.category = category
        self.exerciseType = exerciseType
        self.muscleGroups = muscleGroups
        self.difficulty = difficulty
        self.estimatedCaloriesPerMinute = caloriesPerMinute
        self.description = description
    }
}

// MARK: - Static exercise catalog

extension ExerciseCategory {
    var exercises: [CatalogExercise] {
        switch self {
        case .chest:
            return [
                CatalogExercise(name: "Push-Up", category: .chest, exerciseType: .pushUp,
                    muscleGroups: ["Pectorals", "Triceps", "Shoulders"],
                    difficulty: .beginner, caloriesPerMinute: 7.0,
                    description: "Classic bodyweight exercise targeting the chest, triceps, and anterior deltoids. Keep your body in a straight line throughout the movement."),
                CatalogExercise(name: "Bench Press", category: .chest,
                    muscleGroups: ["Pectorals", "Triceps", "Anterior Deltoids"],
                    difficulty: .intermediate, caloriesPerMinute: 8.0,
                    description: "Fundamental compound barbell exercise for chest mass and strength. Control the descent and drive explosively on the press."),
                CatalogExercise(name: "Incline Push-Up", category: .chest,
                    muscleGroups: ["Upper Pectorals", "Triceps"],
                    difficulty: .beginner, caloriesPerMinute: 5.0,
                    description: "Modified push-up targeting the upper chest with hands elevated. Great for beginners building foundational strength."),
                CatalogExercise(name: "Dumbbell Fly", category: .chest,
                    muscleGroups: ["Pectorals", "Biceps"],
                    difficulty: .intermediate, caloriesPerMinute: 6.0,
                    description: "Isolation exercise for chest width and stretch. Maintain a slight bend in the elbows throughout."),
                CatalogExercise(name: "Cable Crossover", category: .chest,
                    muscleGroups: ["Pectorals", "Anterior Deltoids"],
                    difficulty: .intermediate, caloriesPerMinute: 6.0,
                    description: "Cable variation providing constant tension through the full range of motion."),
            ]
        case .back:
            return [
                CatalogExercise(name: "Pull-Up", category: .back,
                    muscleGroups: ["Latissimus Dorsi", "Biceps", "Rear Deltoids"],
                    difficulty: .intermediate, caloriesPerMinute: 8.0,
                    description: "Compound pulling exercise for back width and bicep strength. Drive elbows down to engage lats fully."),
                CatalogExercise(name: "Bent-Over Row", category: .back,
                    muscleGroups: ["Rhomboids", "Lats", "Biceps"],
                    difficulty: .intermediate, caloriesPerMinute: 7.0,
                    description: "Barbell or dumbbell row for back thickness and posture. Keep a neutral spine and row to your lower chest."),
                CatalogExercise(name: "Lat Pulldown", category: .back,
                    muscleGroups: ["Latissimus Dorsi", "Biceps"],
                    difficulty: .beginner, caloriesPerMinute: 6.0,
                    description: "Cable exercise mimicking pull-up motion. Ideal for developing lat width before mastering bodyweight pull-ups."),
                CatalogExercise(name: "Deadlift", category: .back,
                    muscleGroups: ["Erector Spinae", "Hamstrings", "Glutes", "Traps"],
                    difficulty: .advanced, caloriesPerMinute: 10.0,
                    description: "King of compound lifts. Full posterior chain engagement. Maintain a neutral spine and drive through the heels."),
                CatalogExercise(name: "Seated Cable Row", category: .back,
                    muscleGroups: ["Rhomboids", "Lats", "Biceps"],
                    difficulty: .beginner, caloriesPerMinute: 6.0,
                    description: "Horizontal pulling movement for mid-back development. Squeeze shoulder blades together at peak contraction."),
            ]
        case .legs:
            return [
                CatalogExercise(name: "Squat", category: .legs, exerciseType: .squat,
                    muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
                    difficulty: .beginner, caloriesPerMinute: 8.0,
                    description: "Foundational lower body compound movement. Keep your chest up, knees tracking over toes, and descend to parallel."),
                CatalogExercise(name: "Lunge", category: .legs, exerciseType: .lunge,
                    muscleGroups: ["Quadriceps", "Glutes", "Hamstrings"],
                    difficulty: .beginner, caloriesPerMinute: 7.0,
                    description: "Unilateral exercise improving leg strength and balance. Step forward and lower your back knee toward the floor."),
                CatalogExercise(name: "Leg Press", category: .legs,
                    muscleGroups: ["Quadriceps", "Glutes"],
                    difficulty: .beginner, caloriesPerMinute: 7.0,
                    description: "Machine-based quad and glute developer. Keep feet hip-width and don't lock out knees at the top."),
                CatalogExercise(name: "Romanian Deadlift", category: .legs,
                    muscleGroups: ["Hamstrings", "Glutes", "Lower Back"],
                    difficulty: .intermediate, caloriesPerMinute: 8.0,
                    description: "Hip hinge movement targeting posterior chain. Push hips back and feel the hamstring stretch before driving through."),
                CatalogExercise(name: "Calf Raise", category: .legs,
                    muscleGroups: ["Gastrocnemius", "Soleus"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Isolation exercise for calf muscle development. Pause at the top and bottom for maximum range of motion."),
            ]
        case .arms:
            return [
                CatalogExercise(name: "Bicep Curl", category: .arms, exerciseType: .bicepCurl,
                    muscleGroups: ["Biceps Brachii", "Brachialis"],
                    difficulty: .beginner, caloriesPerMinute: 5.0,
                    description: "Classic curl for bicep peak and strength. Keep elbows pinned to sides and avoid swinging torso."),
                CatalogExercise(name: "Tricep Dip", category: .arms,
                    muscleGroups: ["Triceps", "Anterior Deltoids"],
                    difficulty: .intermediate, caloriesPerMinute: 6.0,
                    description: "Bodyweight tricep isolation using parallel bars or bench. Lean forward slightly for more chest emphasis."),
                CatalogExercise(name: "Hammer Curl", category: .arms,
                    muscleGroups: ["Biceps", "Brachioradialis"],
                    difficulty: .beginner, caloriesPerMinute: 5.0,
                    description: "Neutral grip curl targeting the brachialis and outer bicep head. Great for overall arm thickness."),
                CatalogExercise(name: "Skull Crusher", category: .arms,
                    muscleGroups: ["Triceps Long Head"],
                    difficulty: .intermediate, caloriesPerMinute: 5.0,
                    description: "Lying tricep extension for full development. Lower the weight slowly toward your forehead, keeping elbows stable."),
                CatalogExercise(name: "Preacher Curl", category: .arms,
                    muscleGroups: ["Biceps Brachii"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Strict curl on a preacher bench, eliminating momentum for peak bicep isolation."),
            ]
        case .shoulders:
            return [
                CatalogExercise(name: "Shoulder Press", category: .shoulders, exerciseType: .shoulderPress,
                    muscleGroups: ["Anterior Deltoids", "Medial Deltoids", "Triceps"],
                    difficulty: .intermediate, caloriesPerMinute: 7.0,
                    description: "Overhead pressing for shoulder size and strength. Press straight up and fully extend at the top."),
                CatalogExercise(name: "Lateral Raise", category: .shoulders,
                    muscleGroups: ["Medial Deltoids"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Isolation for shoulder width via medial delt development. Lead with your elbows, not your hands."),
                CatalogExercise(name: "Front Raise", category: .shoulders,
                    muscleGroups: ["Anterior Deltoids"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Frontal raise targeting the anterior deltoid. Raise to shoulder height and control the descent."),
                CatalogExercise(name: "Face Pull", category: .shoulders,
                    muscleGroups: ["Rear Deltoids", "Rotator Cuff", "Rhomboids"],
                    difficulty: .beginner, caloriesPerMinute: 5.0,
                    description: "Cable exercise for rear delts and rotator cuff health. Essential for shoulder longevity and posture."),
                CatalogExercise(name: "Arnold Press", category: .shoulders,
                    muscleGroups: ["All Three Deltoid Heads", "Triceps"],
                    difficulty: .intermediate, caloriesPerMinute: 7.0,
                    description: "Rotating dumbbell press hitting all three deltoid heads through the rotational motion."),
            ]
        case .core:
            return [
                CatalogExercise(name: "Plank", category: .core,
                    muscleGroups: ["Rectus Abdominis", "Transverse Abdominis", "Obliques"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Isometric hold for core stability and endurance. Maintain a straight line from head to heels."),
                CatalogExercise(name: "Crunch", category: .core,
                    muscleGroups: ["Rectus Abdominis"],
                    difficulty: .beginner, caloriesPerMinute: 4.0,
                    description: "Basic abdominal flexion. Focus on curling the ribcage toward the pelvis, not pulling the neck."),
                CatalogExercise(name: "Russian Twist", category: .core,
                    muscleGroups: ["Obliques", "Rectus Abdominis"],
                    difficulty: .beginner, caloriesPerMinute: 5.0,
                    description: "Rotational core exercise targeting the obliques. Pause and squeeze at each end of the rotation."),
                CatalogExercise(name: "Leg Raise", category: .core,
                    muscleGroups: ["Lower Abs", "Hip Flexors"],
                    difficulty: .intermediate, caloriesPerMinute: 5.0,
                    description: "Lower abdominal focus. Keep lower back pressed to the floor and lower legs with control."),
                CatalogExercise(name: "Mountain Climber", category: .core,
                    muscleGroups: ["Core", "Hip Flexors", "Shoulders"],
                    difficulty: .intermediate, caloriesPerMinute: 8.0,
                    description: "Dynamic plank variation for core and cardiovascular conditioning. Drive knees to chest in a running motion."),
                CatalogExercise(name: "Ab Wheel Rollout", category: .core,
                    muscleGroups: ["Rectus Abdominis", "Transverse Abdominis"],
                    difficulty: .advanced, caloriesPerMinute: 6.0,
                    description: "Advanced anti-extension exercise. Roll out slowly and pull back with your abs, not your hips."),
            ]
        case .fullBody:
            return [
                CatalogExercise(name: "Burpee", category: .fullBody,
                    muscleGroups: ["Full Body", "Cardiovascular"],
                    difficulty: .intermediate, caloriesPerMinute: 12.0,
                    description: "High-intensity full-body conditioning exercise. Combines squat, plank, and jump for maximum calorie burn."),
                CatalogExercise(name: "Kettlebell Swing", category: .fullBody,
                    muscleGroups: ["Glutes", "Hamstrings", "Core", "Shoulders"],
                    difficulty: .intermediate, caloriesPerMinute: 10.0,
                    description: "Explosive hip hinge movement for power and conditioning. Drive hips forward aggressively at the top."),
                CatalogExercise(name: "Box Jump", category: .fullBody,
                    muscleGroups: ["Quads", "Glutes", "Calves"],
                    difficulty: .intermediate, caloriesPerMinute: 10.0,
                    description: "Plyometric jump for power development. Land softly and step down to protect joints."),
                CatalogExercise(name: "Clean & Press", category: .fullBody,
                    muscleGroups: ["Full Body"],
                    difficulty: .advanced, caloriesPerMinute: 11.0,
                    description: "Olympic-style movement combining power clean and overhead press. Demands full-body coordination and power."),
                CatalogExercise(name: "Thruster", category: .fullBody,
                    muscleGroups: ["Quads", "Glutes", "Shoulders", "Triceps"],
                    difficulty: .advanced, caloriesPerMinute: 12.0,
                    description: "Front squat into overhead press in one fluid motion. A CrossFit staple for total conditioning."),
            ]
        }
    }
}

// MARK: - All exercises flat list

extension CatalogExercise {
    static var all: [CatalogExercise] {
        ExerciseCategory.allCases.flatMap { $0.exercises }
    }
}
