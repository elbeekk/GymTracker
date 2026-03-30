import Foundation

enum ExerciseAnimationStyle: Sendable {
    case squat
    case lunge
    case legPress
    case calfRaise
    case pushUp
    case benchPress
    case fly
    case pullUp
    case row
    case hinge
    case curl
    case dip
    case overheadPress
    case raise
    case plank
    case crunch
    case twist
    case legRaise
    case rollout
    case conditioning
}

struct ExerciseTutorial: Sendable {
    let animation: ExerciseAnimationStyle
    let summary: String
    let steps: [String]
}

extension CatalogExercise {
    var tutorial: ExerciseTutorial {
        switch name {
        case "Push-Up":
            tutorial(
                .pushUp,
                summary: "Move as one line from head to heels and finish every rep with a strong press.",
                "Set hands under shoulders and brace your core",
                "Lower your chest with hips level",
                "Press straight back up without sagging"
            )
        case "Bench Press":
            tutorial(
                .benchPress,
                summary: "Stable shoulders and stacked wrists make the press cleaner and safer.",
                "Pin shoulders down and keep feet planted",
                "Lower the bar or dumbbells to mid chest",
                "Press up with wrists over elbows"
            )
        case "Incline Push-Up":
            tutorial(
                .pushUp,
                summary: "Use the same push-up line, just with hands elevated so the rep stays controlled.",
                "Set hands on a stable bench or box",
                "Lower chest while keeping hips level",
                "Press away without shrugging shoulders"
            )
        case "Dumbbell Fly":
            tutorial(
                .fly,
                summary: "Open the chest under control and keep a soft bend in the elbows the whole time.",
                "Start above the chest with soft elbows",
                "Open wide until the chest stretches",
                "Squeeze the arms back together slowly"
            )
        case "Cable Crossover":
            tutorial(
                .fly,
                summary: "Pull through the chest, not the hands, and finish with control at the center.",
                "Stand tall with a small staggered stance",
                "Sweep hands inward on a smooth arc",
                "Pause at the center and return slowly"
            )
        case "Pull-Up":
            tutorial(
                .pullUp,
                summary: "Start from the shoulders, then drive the elbows down until the chest rises.",
                "Hang long and set shoulders down first",
                "Pull elbows toward your ribs",
                "Lower back down under control"
            )
        case "Bent-Over Row":
            tutorial(
                .row,
                summary: "Keep the hinge stable and row with the elbows instead of yanking with the hands.",
                "Hinge back and brace your torso",
                "Row elbows past your ribs",
                "Lower the weight without rounding"
            )
        case "Lat Pulldown":
            tutorial(
                .pullUp,
                summary: "Think chest up and elbows down so the lats do the work instead of the neck.",
                "Sit tall and lock your legs in",
                "Pull the bar to upper chest height",
                "Let the elbows rise back slowly"
            )
        case "Deadlift":
            tutorial(
                .hinge,
                summary: "This is a hip hinge first: keep the weight close and stand up by driving the floor away.",
                "Set ribs down and hinge hips back",
                "Keep the weight close to your legs",
                "Stand tall by driving hips through"
            )
        case "Seated Cable Row":
            tutorial(
                .row,
                summary: "Stay tall through the spine and finish each pull by squeezing the elbows behind you.",
                "Sit tall with shoulders packed down",
                "Row handle toward lower ribs",
                "Reach forward without collapsing"
            )
        case "Squat":
            tutorial(
                .squat,
                summary: "Sit the hips down and back while the chest stays proud and the knees stay active.",
                "Set feet just outside hip width",
                "Lower hips while knees track out",
                "Drive through heels to stand tall"
            )
        case "Lunge":
            tutorial(
                .lunge,
                summary: "Keep the torso tall and drop straight down so the front leg controls the rep.",
                "Step long enough to keep balance",
                "Drop the back knee straight down",
                "Push through the front foot to rise"
            )
        case "Leg Press":
            tutorial(
                .legPress,
                summary: "Press through the whole foot and stop before the knees snap out at the top.",
                "Set feet mid platform and brace",
                "Lower until knees stay controlled",
                "Press up without locking knees hard"
            )
        case "Romanian Deadlift":
            tutorial(
                .hinge,
                summary: "Keep the shins almost vertical and push the hips back until the hamstrings load.",
                "Unlock the knees and hinge back",
                "Slide the weight down close to legs",
                "Stand by squeezing glutes through"
            )
        case "Calf Raise":
            tutorial(
                .calfRaise,
                summary: "Move through the ankle slowly and finish every rep with a deliberate pause on the toes.",
                "Stand tall with weight over big toe",
                "Lift heels as high as possible",
                "Lower slowly to a full stretch"
            )
        case "Bicep Curl":
            tutorial(
                .curl,
                summary: "Pin the elbows and let the biceps move the weight instead of the torso.",
                "Stand tall with elbows glued in",
                "Curl hands toward your shoulders",
                "Lower slowly without swinging"
            )
        case "Tricep Dip":
            tutorial(
                .dip,
                summary: "Stay long through the chest and bend the elbows straight back instead of dumping forward.",
                "Set shoulders down and chest open",
                "Lower until elbows bend cleanly",
                "Press straight back to lockout"
            )
        case "Hammer Curl":
            tutorial(
                .curl,
                summary: "Keep the neutral grip fixed and drive the dumbbells up without letting the elbows drift.",
                "Hold thumbs up and brace the torso",
                "Curl while elbows stay near your ribs",
                "Lower under control without rocking"
            )
        case "Skull Crusher":
            tutorial(
                .benchPress,
                summary: "Keep the upper arm quiet and let the elbows bend and extend without flaring.",
                "Lie back and point elbows to ceiling",
                "Lower weight toward forehead slowly",
                "Extend elbows without moving shoulders"
            )
        case "Preacher Curl":
            tutorial(
                .curl,
                summary: "Stay strict on the pad and finish the curl without letting the shoulder take over.",
                "Set upper arm fully on the pad",
                "Curl up with your wrist neutral",
                "Lower all the way with control"
            )
        case "Shoulder Press":
            tutorial(
                .overheadPress,
                summary: "Stack wrists over shoulders and press in a straight line without flaring the ribs.",
                "Brace core with elbows under wrists",
                "Press straight overhead to full reach",
                "Lower back to shoulder level slowly"
            )
        case "Lateral Raise":
            tutorial(
                .raise,
                summary: "Lead with the elbows and stop at shoulder height so the delts, not momentum, drive the rep.",
                "Stand tall with a soft elbow bend",
                "Raise arms out to shoulder height",
                "Lower slowly without shrugging"
            )
        case "Front Raise":
            tutorial(
                .raise,
                summary: "Lift with control in front of the body and keep the ribs quiet the whole time.",
                "Brace core and set shoulders down",
                "Raise hands to shoulder height",
                "Lower with the same control"
            )
        case "Face Pull":
            tutorial(
                .row,
                summary: "Pull high with elbows wide and finish by opening the chest, not leaning back.",
                "Set rope at face height and brace",
                "Pull elbows wide toward your ears",
                "Return forward without shrugging"
            )
        case "Arnold Press":
            tutorial(
                .overheadPress,
                summary: "Rotate smoothly from the front rack to overhead without rushing the turn.",
                "Start palms facing you at shoulder level",
                "Rotate and press straight overhead",
                "Reverse the motion under control"
            )
        case "Plank":
            tutorial(
                .plank,
                summary: "A good plank is a straight line with active glutes, abs, and shoulders.",
                "Set hands or elbows under shoulders",
                "Brace abs and squeeze glutes hard",
                "Hold a straight line without sagging"
            )
        case "Crunch":
            tutorial(
                .crunch,
                summary: "Curl the ribcage toward the pelvis instead of yanking the neck forward.",
                "Set lower back down and chin tucked",
                "Curl ribs up off the floor",
                "Lower slowly without dropping"
            )
        case "Russian Twist":
            tutorial(
                .twist,
                summary: "Rotate through the ribcage with the core tight so the twist stays controlled.",
                "Lean back tall and brace your abs",
                "Rotate side to side with control",
                "Keep feet and hips as still as possible"
            )
        case "Leg Raise":
            tutorial(
                .legRaise,
                summary: "Keep the low back pinned and move the legs only as far as you can control.",
                "Flatten lower back into the floor",
                "Lift legs with knees controlled",
                "Lower slowly before your back arches"
            )
        case "Mountain Climber":
            tutorial(
                .conditioning,
                summary: "Think fast feet under a strong plank, not a bouncing run with loose hips.",
                "Start in a strong plank position",
                "Drive one knee under the chest",
                "Switch quickly while hips stay level"
            )
        case "Ab Wheel Rollout":
            tutorial(
                .rollout,
                summary: "Brace first, then reach long without letting the hips or low back collapse.",
                "Start kneeling with ribs locked down",
                "Roll forward as one long line",
                "Pull back using abs, not momentum"
            )
        case "Burpee":
            tutorial(
                .conditioning,
                summary: "Keep the movement sharp and organized: down to the floor, back to the feet, then jump.",
                "Drop hands down under the shoulders",
                "Kick back to plank and return fast",
                "Stand and jump tall to finish"
            )
        case "Kettlebell Swing":
            tutorial(
                .hinge,
                summary: "The bell floats from hip power, not from lifting with the arms.",
                "Hike the bell back between the legs",
                "Snap hips forward hard to float it",
                "Let it return and hinge again"
            )
        case "Box Jump":
            tutorial(
                .conditioning,
                summary: "Load the hips, jump softly, and own the landing before you stand all the way up.",
                "Dip hips back with arms ready",
                "Jump up and land softly on the box",
                "Stand tall, then step down carefully"
            )
        case "Clean & Press":
            tutorial(
                .overheadPress,
                summary: "Keep the bar or dumbbells close, catch at the shoulders, then finish with a clean overhead press.",
                "Hinge and pull the weight close",
                "Catch at the shoulders with balance",
                "Press straight overhead to finish"
            )
        case "Thruster":
            tutorial(
                .overheadPress,
                summary: "Use the legs out of the squat to drive the weight overhead in one smooth rhythm.",
                "Front squat with chest tall and elbows up",
                "Drive through the floor out of the bottom",
                "Use that leg power to press overhead"
            )
        default:
            tutorial(
                .conditioning,
                summary: "Move through a controlled full range and keep the body tension clean from start to finish.",
                "Set your stance and brace first",
                "Move through the full range with control",
                "Finish tall and reset before the next rep"
            )
        }
    }

    private func tutorial(
        _ animation: ExerciseAnimationStyle,
        summary: String,
        _ step1: String,
        _ step2: String,
        _ step3: String
    ) -> ExerciseTutorial {
        ExerciseTutorial(
            animation: animation,
            summary: summary,
            steps: [step1, step2, step3]
        )
    }
}
