import SwiftUI

struct ExerciseTutorialView: View {
    let exercise: CatalogExercise
    let onClose: () -> Void
    let onContinue: () -> Void

    @State private var canContinue = false

    private var tutorial: ExerciseTutorial { exercise.tutorial }

    var body: some View {
        ZStack {
            AppTheme.gymBg.ignoresSafeArea()

            tutorialBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    animationCard
                    summaryCard
                    musclesCard
                    techniqueCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 140)
            }
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .task(id: exercise.id) {
            canContinue = false
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            canContinue = true
        }
    }

    private var tutorialBackground: some View {
        ZStack {
            Circle()
                .fill(AppTheme.gymAccentGlow)
                .frame(width: 280, height: 280)
                .blur(radius: 40)
                .offset(x: 110, y: -170)

            Circle()
                .fill(AppTheme.gymBlue.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 48)
                .offset(x: -130, y: -40)
        }
        .allowsHitTesting(false)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(AppTheme.gymText)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.gymSurface, in: Circle())
                        .overlay(Circle().stroke(AppTheme.gymBorder, lineWidth: 1))
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Technique Demo")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(AppTheme.gymSubtext)
                    .textCase(.uppercase)
                    .tracking(1.1)

                if exercise.isAITrackable {
                    AIBadge()
                }
            }

            Text(exercise.name)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.gymText)

            Text("Watch one clean rep pattern before the camera starts.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.gymSubtext)

            HStack(spacing: 10) {
                TutorialChip(text: exercise.category.displayName, tint: AppTheme.gymAccent)
                TutorialChip(text: exercise.difficulty.displayName, tint: AppTheme.gymBlue)
                TutorialChip(
                    text: exercise.isAITrackable ? "AI form ready" : "Camera tracker",
                    tint: exercise.isAITrackable ? AppTheme.gymGreen : AppTheme.gymSubtext
                )
            }
        }
    }

    private var animationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Movement Loop")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.gymText)

                Spacer()

                Text("Autoplay")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.gymSubtext)
            }

            ExerciseAnimationStage(style: tutorial.animation)
                .frame(height: 310)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.gymCard, AppTheme.gymSurface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(AppTheme.gymBorder, lineWidth: 1)
                )
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            cardTitle("What To Copy")

            Text(tutorial.summary)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(AppTheme.gymText)
                .lineSpacing(4)
        }
        .padding(18)
        .background(AppTheme.gymSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.gymBorder, lineWidth: 1)
        )
    }

    private var musclesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Main Muscles")

            MuscleChipGrid(items: Array(exercise.muscleGroups.prefix(4)))
        }
        .padding(18)
        .background(AppTheme.gymSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.gymBorder, lineWidth: 1)
        )
    }

    private var techniqueCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("3 Step Setup")

            ForEach(Array(tutorial.steps.enumerated()), id: \.offset) { index, step in
                TechniqueStepRow(index: index + 1, text: step)
            }
        }
        .padding(18)
        .background(AppTheme.gymSurface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(AppTheme.gymBorder, lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        VStack(spacing: 12) {
            Text(exercise.isAITrackable ? "The AI form tracker opens next." : "The camera tracker opens next.")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppTheme.gymSubtext)

            Button(action: onContinue) {
                HStack {
                    Text(canContinue ? trackerButtonTitle : "Watch the demo first")
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(canContinue ? AppTheme.gymBg : AppTheme.gymDim)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(canContinue ? AppTheme.gymText : AppTheme.gymCard, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canContinue)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 20)
        .background(
            AppTheme.gymBg
                .overlay(Rectangle().fill(AppTheme.gymBorder).frame(height: 1), alignment: .top)
        )
    }

    private var trackerButtonTitle: String {
        exercise.isAITrackable ? "Open AI Tracker" : "Open Exercise Tracker"
    }

    private func cardTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppTheme.gymSubtext)
            .textCase(.uppercase)
            .tracking(0.9)
    }
}

private struct TutorialChip: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.10), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
    }
}

private struct TechniqueStepRow: View {
    let index: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(index)")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(AppTheme.gymBg)
                .frame(width: 26, height: 26)
                .background(AppTheme.gymAccent, in: Circle())

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AppTheme.gymText)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
    }
}

private struct MuscleChipGrid: View {
    let items: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(AppTheme.gymText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppTheme.gymCard, in: Capsule())
                    .overlay(Capsule().stroke(AppTheme.gymBorder, lineWidth: 1))
            }
        }
    }
}

private struct ExerciseAnimationStage: View {
    let style: ExerciseAnimationStyle

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            Canvas { context, size in
                drawBackdrop(context: &context, size: size)

                let progress = animationProgress(for: style, date: timeline.date)

                switch style {
                case .squat:
                    drawSquat(context: &context, size: size, progress: progress)
                case .lunge:
                    drawLunge(context: &context, size: size, progress: progress)
                case .legPress:
                    drawLegPress(context: &context, size: size, progress: progress)
                case .calfRaise:
                    drawCalfRaise(context: &context, size: size, progress: progress)
                case .pushUp:
                    drawPushUp(context: &context, size: size, progress: progress)
                case .benchPress:
                    drawBenchPress(context: &context, size: size, progress: progress, armsWide: false)
                case .fly:
                    drawBenchPress(context: &context, size: size, progress: progress, armsWide: true)
                case .pullUp:
                    drawPullUp(context: &context, size: size, progress: progress)
                case .row:
                    drawRow(context: &context, size: size, progress: progress)
                case .hinge:
                    drawHinge(context: &context, size: size, progress: progress)
                case .curl:
                    drawCurl(context: &context, size: size, progress: progress)
                case .dip:
                    drawDip(context: &context, size: size, progress: progress)
                case .overheadPress:
                    drawOverheadPress(context: &context, size: size, progress: progress)
                case .raise:
                    drawRaise(context: &context, size: size, progress: progress)
                case .plank:
                    drawPlank(context: &context, size: size, progress: progress)
                case .crunch:
                    drawCrunch(context: &context, size: size, progress: progress)
                case .twist:
                    drawTwist(context: &context, size: size, progress: progress)
                case .legRaise:
                    drawLegRaise(context: &context, size: size, progress: progress)
                case .rollout:
                    drawRollout(context: &context, size: size, progress: progress)
                case .conditioning:
                    drawConditioning(context: &context, size: size, progress: progress)
                }
            }
        }
    }

    private func animationProgress(for style: ExerciseAnimationStyle, date: Date) -> CGFloat {
        let speed: Double
        switch style {
        case .conditioning: speed = 0.85
        case .pushUp, .curl, .raise, .calfRaise: speed = 0.65
        default: speed = 0.52
        }

        let time = date.timeIntervalSinceReferenceDate * speed
        return CGFloat((sin(time * .pi * 2) + 1) * 0.5)
    }

    private func drawBackdrop(context: inout GraphicsContext, size: CGSize) {
        let stage = Path(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 6, dy: 6), cornerRadius: 18)
        context.fill(stage, with: .linearGradient(
            Gradient(colors: [AppTheme.gymCard.opacity(0.65), AppTheme.gymSurface.opacity(0.85)]),
            startPoint: CGPoint(x: 0, y: 0),
            endPoint: CGPoint(x: size.width, y: size.height)
        ))

        let floorY = size.height * 0.84
        var floor = Path()
        floor.move(to: CGPoint(x: size.width * 0.12, y: floorY))
        floor.addLine(to: CGPoint(x: size.width * 0.88, y: floorY))
        context.stroke(floor, with: .color(AppTheme.gymBorder.opacity(0.75)), style: StrokeStyle(lineWidth: 2, lineCap: .round))
    }
}

private struct FigurePose {
    let head: CGPoint
    let leftShoulder: CGPoint
    let rightShoulder: CGPoint
    let leftElbow: CGPoint
    let rightElbow: CGPoint
    let leftHand: CGPoint
    let rightHand: CGPoint
    let leftHip: CGPoint
    let rightHip: CGPoint
    let leftKnee: CGPoint
    let rightKnee: CGPoint
    let leftFoot: CGPoint
    let rightFoot: CGPoint
}

private func drawFigure(context: inout GraphicsContext, size: CGSize, pose: FigurePose) {
    let minSide = min(size.width, size.height)
    let bodyColor = AppTheme.gymText
    let accentColor = AppTheme.gymAccent
    let limbWidth = minSide * 0.030
    let torsoWidth = minSide * 0.040

    drawSegment(context: &context, from: pose.leftShoulder, to: pose.rightShoulder, in: size, color: bodyColor, width: torsoWidth)
    drawSegment(context: &context, from: pose.leftShoulder, to: pose.leftElbow, in: size, color: bodyColor, width: limbWidth)
    drawSegment(context: &context, from: pose.leftElbow, to: pose.leftHand, in: size, color: accentColor, width: limbWidth)
    drawSegment(context: &context, from: pose.rightShoulder, to: pose.rightElbow, in: size, color: bodyColor, width: limbWidth)
    drawSegment(context: &context, from: pose.rightElbow, to: pose.rightHand, in: size, color: accentColor, width: limbWidth)
    drawSegment(context: &context, from: pose.leftShoulder, to: pose.leftHip, in: size, color: bodyColor, width: torsoWidth)
    drawSegment(context: &context, from: pose.rightShoulder, to: pose.rightHip, in: size, color: bodyColor, width: torsoWidth)
    drawSegment(context: &context, from: pose.leftHip, to: pose.rightHip, in: size, color: bodyColor, width: torsoWidth)
    drawSegment(context: &context, from: pose.leftHip, to: pose.leftKnee, in: size, color: bodyColor, width: limbWidth)
    drawSegment(context: &context, from: pose.leftKnee, to: pose.leftFoot, in: size, color: accentColor, width: limbWidth)
    drawSegment(context: &context, from: pose.rightHip, to: pose.rightKnee, in: size, color: bodyColor, width: limbWidth)
    drawSegment(context: &context, from: pose.rightKnee, to: pose.rightFoot, in: size, color: accentColor, width: limbWidth)

    let headCenter = scaledPoint(pose.head, in: size)
    context.fill(
        Path(ellipseIn: CGRect(
            x: headCenter.x - minSide * 0.055,
            y: headCenter.y - minSide * 0.055,
            width: minSide * 0.11,
            height: minSide * 0.11
        )),
        with: .color(AppTheme.gymText)
    )
}

private func drawSquat(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: mix(0.16, 0.26, progress)),
        leftShoulder: CGPoint(x: 0.44, y: mix(0.28, 0.38, progress)),
        rightShoulder: CGPoint(x: 0.56, y: mix(0.28, 0.38, progress)),
        leftElbow: CGPoint(x: mix(0.40, 0.35, progress), y: mix(0.40, 0.47, progress)),
        rightElbow: CGPoint(x: mix(0.60, 0.65, progress), y: mix(0.40, 0.47, progress)),
        leftHand: CGPoint(x: mix(0.37, 0.31, progress), y: mix(0.50, 0.48, progress)),
        rightHand: CGPoint(x: mix(0.63, 0.69, progress), y: mix(0.50, 0.48, progress)),
        leftHip: CGPoint(x: 0.47, y: mix(0.47, 0.59, progress)),
        rightHip: CGPoint(x: 0.53, y: mix(0.47, 0.59, progress)),
        leftKnee: CGPoint(x: mix(0.46, 0.39, progress), y: mix(0.65, 0.69, progress)),
        rightKnee: CGPoint(x: mix(0.54, 0.61, progress), y: mix(0.65, 0.69, progress)),
        leftFoot: CGPoint(x: 0.42, y: 0.84),
        rightFoot: CGPoint(x: 0.58, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawLunge(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let pose = FigurePose(
        head: CGPoint(x: 0.48, y: mix(0.16, 0.23, progress)),
        leftShoulder: CGPoint(x: 0.42, y: mix(0.28, 0.35, progress)),
        rightShoulder: CGPoint(x: 0.54, y: mix(0.29, 0.36, progress)),
        leftElbow: CGPoint(x: 0.38, y: mix(0.40, 0.46, progress)),
        rightElbow: CGPoint(x: 0.58, y: mix(0.40, 0.46, progress)),
        leftHand: CGPoint(x: 0.35, y: mix(0.53, 0.56, progress)),
        rightHand: CGPoint(x: 0.61, y: mix(0.53, 0.56, progress)),
        leftHip: CGPoint(x: 0.45, y: mix(0.47, 0.56, progress)),
        rightHip: CGPoint(x: 0.51, y: mix(0.48, 0.57, progress)),
        leftKnee: CGPoint(x: 0.38, y: mix(0.66, 0.72, progress)),
        rightKnee: CGPoint(x: 0.60, y: mix(0.63, 0.70, progress)),
        leftFoot: CGPoint(x: 0.33, y: 0.84),
        rightFoot: CGPoint(x: 0.67, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawLegPress(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    drawMachinePlate(context: &context, size: size, rect: CGRect(x: size.width * 0.72, y: size.height * 0.20, width: size.width * 0.10, height: size.height * 0.46))
    let pose = FigurePose(
        head: CGPoint(x: 0.30, y: 0.42),
        leftShoulder: CGPoint(x: 0.33, y: 0.49),
        rightShoulder: CGPoint(x: 0.39, y: 0.47),
        leftElbow: CGPoint(x: 0.39, y: mix(0.58, 0.55, progress)),
        rightElbow: CGPoint(x: 0.44, y: mix(0.56, 0.53, progress)),
        leftHand: CGPoint(x: 0.46, y: mix(0.62, 0.58, progress)),
        rightHand: CGPoint(x: 0.50, y: mix(0.60, 0.56, progress)),
        leftHip: CGPoint(x: 0.40, y: 0.60),
        rightHip: CGPoint(x: 0.46, y: 0.58),
        leftKnee: CGPoint(x: mix(0.58, 0.65, progress), y: mix(0.58, 0.49, progress)),
        rightKnee: CGPoint(x: mix(0.60, 0.68, progress), y: mix(0.54, 0.45, progress)),
        leftFoot: CGPoint(x: 0.74, y: 0.45),
        rightFoot: CGPoint(x: 0.74, y: 0.57)
    )
    drawBenchLine(context: &context, size: size, from: CGPoint(x: 0.20, y: 0.70), to: CGPoint(x: 0.48, y: 0.56))
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawCalfRaise(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let lift = mix(0.0, -0.05, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.15 + lift),
        leftShoulder: CGPoint(x: 0.44, y: 0.27 + lift),
        rightShoulder: CGPoint(x: 0.56, y: 0.27 + lift),
        leftElbow: CGPoint(x: 0.41, y: 0.40 + lift),
        rightElbow: CGPoint(x: 0.59, y: 0.40 + lift),
        leftHand: CGPoint(x: 0.40, y: 0.54 + lift),
        rightHand: CGPoint(x: 0.60, y: 0.54 + lift),
        leftHip: CGPoint(x: 0.47, y: 0.47 + lift),
        rightHip: CGPoint(x: 0.53, y: 0.47 + lift),
        leftKnee: CGPoint(x: 0.47, y: 0.66 + lift),
        rightKnee: CGPoint(x: 0.53, y: 0.66 + lift),
        leftFoot: CGPoint(x: 0.45, y: 0.84),
        rightFoot: CGPoint(x: 0.55, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawPushUp(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let drop = mix(0.0, 0.07, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.26, y: 0.44 + drop),
        leftShoulder: CGPoint(x: 0.31, y: 0.48 + drop),
        rightShoulder: CGPoint(x: 0.38, y: 0.49 + drop),
        leftElbow: CGPoint(x: mix(0.33, 0.39, progress), y: mix(0.61, 0.55, progress)),
        rightElbow: CGPoint(x: mix(0.39, 0.45, progress), y: mix(0.62, 0.56, progress)),
        leftHand: CGPoint(x: 0.34, y: 0.84),
        rightHand: CGPoint(x: 0.42, y: 0.84),
        leftHip: CGPoint(x: 0.56, y: 0.52 + drop * 0.4),
        rightHip: CGPoint(x: 0.63, y: 0.53 + drop * 0.4),
        leftKnee: CGPoint(x: 0.70, y: 0.63 + drop * 0.2),
        rightKnee: CGPoint(x: 0.76, y: 0.64 + drop * 0.2),
        leftFoot: CGPoint(x: 0.82, y: 0.84),
        rightFoot: CGPoint(x: 0.88, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawBenchPress(context: inout GraphicsContext, size: CGSize, progress: CGFloat, armsWide: Bool) {
    drawBenchLine(context: &context, size: size, from: CGPoint(x: 0.20, y: 0.70), to: CGPoint(x: 0.68, y: 0.70))

    let leftHandX = armsWide ? mix(0.41, 0.28, progress) : 0.43
    let rightHandX = armsWide ? mix(0.59, 0.72, progress) : 0.57
    let handY = armsWide ? mix(0.30, 0.46, progress) : mix(0.32, 0.48, progress)

    let pose = FigurePose(
        head: CGPoint(x: 0.26, y: 0.53),
        leftShoulder: CGPoint(x: 0.34, y: 0.58),
        rightShoulder: CGPoint(x: 0.42, y: 0.58),
        leftElbow: CGPoint(x: mix(0.38, 0.35, progress), y: mix(0.45, 0.56, progress)),
        rightElbow: CGPoint(x: mix(0.54, 0.41, progress), y: mix(0.45, 0.56, progress)),
        leftHand: CGPoint(x: leftHandX, y: handY),
        rightHand: CGPoint(x: rightHandX, y: handY),
        leftHip: CGPoint(x: 0.52, y: 0.60),
        rightHip: CGPoint(x: 0.59, y: 0.60),
        leftKnee: CGPoint(x: 0.66, y: 0.72),
        rightKnee: CGPoint(x: 0.75, y: 0.72),
        leftFoot: CGPoint(x: 0.66, y: 0.84),
        rightFoot: CGPoint(x: 0.75, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawPullUp(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    drawBar(context: &context, size: size, y: 0.16)
    let shoulderY = mix(0.38, 0.26, progress)
    let hipY = mix(0.56, 0.44, progress)
    let kneeY = mix(0.72, 0.63, progress)
    let elbowX = mix(0.38, 0.43, progress)
    let rightElbowX = mix(0.62, 0.57, progress)

    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: shoulderY - 0.12),
        leftShoulder: CGPoint(x: 0.45, y: shoulderY),
        rightShoulder: CGPoint(x: 0.55, y: shoulderY),
        leftElbow: CGPoint(x: elbowX, y: mix(0.31, 0.23, progress)),
        rightElbow: CGPoint(x: rightElbowX, y: mix(0.31, 0.23, progress)),
        leftHand: CGPoint(x: 0.40, y: 0.16),
        rightHand: CGPoint(x: 0.60, y: 0.16),
        leftHip: CGPoint(x: 0.47, y: hipY),
        rightHip: CGPoint(x: 0.53, y: hipY),
        leftKnee: CGPoint(x: 0.47, y: kneeY),
        rightKnee: CGPoint(x: 0.53, y: kneeY),
        leftFoot: CGPoint(x: 0.45, y: 0.82),
        rightFoot: CGPoint(x: 0.55, y: 0.82)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawRow(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let torsoLift = mix(0.0, -0.03, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.40, y: 0.22 + torsoLift),
        leftShoulder: CGPoint(x: 0.36, y: 0.34 + torsoLift),
        rightShoulder: CGPoint(x: 0.46, y: 0.32 + torsoLift),
        leftElbow: CGPoint(x: mix(0.48, 0.40, progress), y: mix(0.47, 0.39, progress) + torsoLift),
        rightElbow: CGPoint(x: mix(0.57, 0.49, progress), y: mix(0.45, 0.37, progress) + torsoLift),
        leftHand: CGPoint(x: mix(0.60, 0.50, progress), y: mix(0.54, 0.40, progress) + torsoLift),
        rightHand: CGPoint(x: mix(0.67, 0.57, progress), y: mix(0.52, 0.38, progress) + torsoLift),
        leftHip: CGPoint(x: 0.49, y: 0.49),
        rightHip: CGPoint(x: 0.57, y: 0.48),
        leftKnee: CGPoint(x: 0.52, y: 0.67),
        rightKnee: CGPoint(x: 0.61, y: 0.67),
        leftFoot: CGPoint(x: 0.50, y: 0.84),
        rightFoot: CGPoint(x: 0.64, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawHinge(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let pose = FigurePose(
        head: CGPoint(x: mix(0.50, 0.42, progress), y: mix(0.16, 0.23, progress)),
        leftShoulder: CGPoint(x: mix(0.44, 0.38, progress), y: mix(0.28, 0.35, progress)),
        rightShoulder: CGPoint(x: mix(0.56, 0.48, progress), y: mix(0.28, 0.33, progress)),
        leftElbow: CGPoint(x: mix(0.43, 0.41, progress), y: mix(0.42, 0.49, progress)),
        rightElbow: CGPoint(x: mix(0.57, 0.52, progress), y: mix(0.42, 0.49, progress)),
        leftHand: CGPoint(x: mix(0.42, 0.43, progress), y: mix(0.56, 0.67, progress)),
        rightHand: CGPoint(x: mix(0.58, 0.55, progress), y: mix(0.56, 0.67, progress)),
        leftHip: CGPoint(x: 0.47, y: mix(0.46, 0.55, progress)),
        rightHip: CGPoint(x: 0.53, y: mix(0.46, 0.55, progress)),
        leftKnee: CGPoint(x: 0.46, y: mix(0.67, 0.70, progress)),
        rightKnee: CGPoint(x: 0.54, y: mix(0.67, 0.70, progress)),
        leftFoot: CGPoint(x: 0.44, y: 0.84),
        rightFoot: CGPoint(x: 0.56, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawCurl(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.16),
        leftShoulder: CGPoint(x: 0.44, y: 0.28),
        rightShoulder: CGPoint(x: 0.56, y: 0.28),
        leftElbow: CGPoint(x: 0.43, y: 0.43),
        rightElbow: CGPoint(x: 0.57, y: 0.43),
        leftHand: CGPoint(x: mix(0.42, 0.39, progress), y: mix(0.60, 0.47, progress)),
        rightHand: CGPoint(x: mix(0.58, 0.61, progress), y: mix(0.60, 0.47, progress)),
        leftHip: CGPoint(x: 0.47, y: 0.47),
        rightHip: CGPoint(x: 0.53, y: 0.47),
        leftKnee: CGPoint(x: 0.47, y: 0.66),
        rightKnee: CGPoint(x: 0.53, y: 0.66),
        leftFoot: CGPoint(x: 0.45, y: 0.84),
        rightFoot: CGPoint(x: 0.55, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawDip(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    drawBarPair(context: &context, size: size, x1: 0.37, x2: 0.63, y1: 0.30, y2: 0.72)
    let drop = mix(0.0, 0.08, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.18 + drop),
        leftShoulder: CGPoint(x: 0.44, y: 0.30 + drop),
        rightShoulder: CGPoint(x: 0.56, y: 0.30 + drop),
        leftElbow: CGPoint(x: mix(0.40, 0.39, progress), y: mix(0.43, 0.52, progress)),
        rightElbow: CGPoint(x: mix(0.60, 0.61, progress), y: mix(0.43, 0.52, progress)),
        leftHand: CGPoint(x: 0.37, y: 0.52),
        rightHand: CGPoint(x: 0.63, y: 0.52),
        leftHip: CGPoint(x: 0.47, y: 0.49 + drop),
        rightHip: CGPoint(x: 0.53, y: 0.49 + drop),
        leftKnee: CGPoint(x: 0.47, y: 0.67 + drop),
        rightKnee: CGPoint(x: 0.53, y: 0.67 + drop),
        leftFoot: CGPoint(x: 0.44, y: 0.84),
        rightFoot: CGPoint(x: 0.56, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawOverheadPress(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.16),
        leftShoulder: CGPoint(x: 0.44, y: 0.28),
        rightShoulder: CGPoint(x: 0.56, y: 0.28),
        leftElbow: CGPoint(x: mix(0.40, 0.45, progress), y: mix(0.41, 0.18, progress)),
        rightElbow: CGPoint(x: mix(0.60, 0.55, progress), y: mix(0.41, 0.18, progress)),
        leftHand: CGPoint(x: mix(0.39, 0.45, progress), y: mix(0.55, 0.06, progress)),
        rightHand: CGPoint(x: mix(0.61, 0.55, progress), y: mix(0.55, 0.06, progress)),
        leftHip: CGPoint(x: 0.47, y: 0.47),
        rightHip: CGPoint(x: 0.53, y: 0.47),
        leftKnee: CGPoint(x: 0.47, y: 0.66),
        rightKnee: CGPoint(x: 0.53, y: 0.66),
        leftFoot: CGPoint(x: 0.45, y: 0.84),
        rightFoot: CGPoint(x: 0.55, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawRaise(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let handY = mix(0.60, 0.32, progress)
    let elbowY = mix(0.46, 0.34, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.16),
        leftShoulder: CGPoint(x: 0.44, y: 0.28),
        rightShoulder: CGPoint(x: 0.56, y: 0.28),
        leftElbow: CGPoint(x: mix(0.41, 0.32, progress), y: elbowY),
        rightElbow: CGPoint(x: mix(0.59, 0.68, progress), y: elbowY),
        leftHand: CGPoint(x: mix(0.40, 0.22, progress), y: handY),
        rightHand: CGPoint(x: mix(0.60, 0.78, progress), y: handY),
        leftHip: CGPoint(x: 0.47, y: 0.47),
        rightHip: CGPoint(x: 0.53, y: 0.47),
        leftKnee: CGPoint(x: 0.47, y: 0.66),
        rightKnee: CGPoint(x: 0.53, y: 0.66),
        leftFoot: CGPoint(x: 0.45, y: 0.84),
        rightFoot: CGPoint(x: 0.55, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawPlank(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let breathe = mix(-0.01, 0.01, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.27, y: 0.44 + breathe),
        leftShoulder: CGPoint(x: 0.32, y: 0.48 + breathe),
        rightShoulder: CGPoint(x: 0.39, y: 0.49 + breathe),
        leftElbow: CGPoint(x: 0.34, y: 0.62 + breathe),
        rightElbow: CGPoint(x: 0.41, y: 0.63 + breathe),
        leftHand: CGPoint(x: 0.34, y: 0.84),
        rightHand: CGPoint(x: 0.41, y: 0.84),
        leftHip: CGPoint(x: 0.57, y: 0.52 + breathe),
        rightHip: CGPoint(x: 0.64, y: 0.53 + breathe),
        leftKnee: CGPoint(x: 0.72, y: 0.63 + breathe),
        rightKnee: CGPoint(x: 0.79, y: 0.64 + breathe),
        leftFoot: CGPoint(x: 0.85, y: 0.84),
        rightFoot: CGPoint(x: 0.90, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawCrunch(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    drawBenchLine(context: &context, size: size, from: CGPoint(x: 0.18, y: 0.78), to: CGPoint(x: 0.82, y: 0.78))
    let curl = mix(0.0, 0.10, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.32 + curl, y: 0.57 - curl),
        leftShoulder: CGPoint(x: 0.38 + curl, y: 0.62 - curl),
        rightShoulder: CGPoint(x: 0.45 + curl, y: 0.62 - curl),
        leftElbow: CGPoint(x: 0.33 + curl * 0.4, y: 0.49 - curl * 0.8),
        rightElbow: CGPoint(x: 0.47 + curl * 0.4, y: 0.49 - curl * 0.8),
        leftHand: CGPoint(x: 0.29, y: 0.44 - curl),
        rightHand: CGPoint(x: 0.51, y: 0.44 - curl),
        leftHip: CGPoint(x: 0.58, y: 0.69),
        rightHip: CGPoint(x: 0.65, y: 0.69),
        leftKnee: CGPoint(x: 0.72, y: 0.64),
        rightKnee: CGPoint(x: 0.79, y: 0.64),
        leftFoot: CGPoint(x: 0.74, y: 0.79),
        rightFoot: CGPoint(x: 0.81, y: 0.79)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawTwist(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let rotation = mix(-0.05, 0.05, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.50 + rotation, y: 0.24),
        leftShoulder: CGPoint(x: 0.43 + rotation, y: 0.35),
        rightShoulder: CGPoint(x: 0.55 + rotation, y: 0.35),
        leftElbow: CGPoint(x: 0.37 + rotation, y: 0.46),
        rightElbow: CGPoint(x: 0.61 + rotation, y: 0.46),
        leftHand: CGPoint(x: 0.30 + rotation * 1.4, y: 0.56),
        rightHand: CGPoint(x: 0.68 + rotation * 1.4, y: 0.56),
        leftHip: CGPoint(x: 0.45, y: 0.53),
        rightHip: CGPoint(x: 0.55, y: 0.53),
        leftKnee: CGPoint(x: 0.41, y: 0.68),
        rightKnee: CGPoint(x: 0.59, y: 0.68),
        leftFoot: CGPoint(x: 0.37, y: 0.84),
        rightFoot: CGPoint(x: 0.63, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawLegRaise(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    drawBenchLine(context: &context, size: size, from: CGPoint(x: 0.18, y: 0.78), to: CGPoint(x: 0.82, y: 0.78))
    let legLift = mix(0.0, 0.24, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.26, y: 0.60),
        leftShoulder: CGPoint(x: 0.32, y: 0.64),
        rightShoulder: CGPoint(x: 0.39, y: 0.64),
        leftElbow: CGPoint(x: 0.24, y: 0.56),
        rightElbow: CGPoint(x: 0.42, y: 0.56),
        leftHand: CGPoint(x: 0.20, y: 0.72),
        rightHand: CGPoint(x: 0.46, y: 0.72),
        leftHip: CGPoint(x: 0.54, y: 0.69),
        rightHip: CGPoint(x: 0.61, y: 0.69),
        leftKnee: CGPoint(x: 0.70, y: 0.68 - legLift),
        rightKnee: CGPoint(x: 0.76, y: 0.66 - legLift),
        leftFoot: CGPoint(x: 0.80, y: 0.70 - legLift * 1.6),
        rightFoot: CGPoint(x: 0.86, y: 0.68 - legLift * 1.6)
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawRollout(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let reach = mix(0.0, 0.16, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.36 + reach, y: 0.28),
        leftShoulder: CGPoint(x: 0.40 + reach, y: 0.39),
        rightShoulder: CGPoint(x: 0.47 + reach, y: 0.39),
        leftElbow: CGPoint(x: 0.52 + reach, y: 0.46),
        rightElbow: CGPoint(x: 0.58 + reach, y: 0.46),
        leftHand: CGPoint(x: 0.62 + reach, y: 0.56),
        rightHand: CGPoint(x: 0.68 + reach, y: 0.56),
        leftHip: CGPoint(x: 0.33, y: 0.56),
        rightHip: CGPoint(x: 0.40, y: 0.56),
        leftKnee: CGPoint(x: 0.28, y: 0.73),
        rightKnee: CGPoint(x: 0.36, y: 0.73),
        leftFoot: CGPoint(x: 0.24, y: 0.84),
        rightFoot: CGPoint(x: 0.32, y: 0.84)
    )
    drawFigure(context: &context, size: size, pose: pose)
    drawWheel(context: &context, size: size, center: CGPoint(x: 0.72 + reach, y: 0.60))
}

private func drawConditioning(context: inout GraphicsContext, size: CGSize, progress: CGFloat) {
    let jump = mix(0.0, -0.12, progress)
    let armSwing = mix(0.0, 0.16, progress)
    let pose = FigurePose(
        head: CGPoint(x: 0.50, y: 0.17 + jump),
        leftShoulder: CGPoint(x: 0.44, y: 0.29 + jump),
        rightShoulder: CGPoint(x: 0.56, y: 0.29 + jump),
        leftElbow: CGPoint(x: mix(0.41, 0.33, progress), y: mix(0.42, 0.32, progress) + jump),
        rightElbow: CGPoint(x: mix(0.59, 0.67, progress), y: mix(0.42, 0.32, progress) + jump),
        leftHand: CGPoint(x: mix(0.40, 0.26, progress), y: mix(0.58, 0.18, progress) + jump),
        rightHand: CGPoint(x: mix(0.60, 0.74, progress), y: mix(0.58, 0.18, progress) + jump),
        leftHip: CGPoint(x: 0.47, y: mix(0.48, 0.45, progress) + jump * 0.4),
        rightHip: CGPoint(x: 0.53, y: mix(0.48, 0.45, progress) + jump * 0.4),
        leftKnee: CGPoint(x: mix(0.45, 0.41, armSwing), y: mix(0.68, 0.63, progress) + jump * 0.4),
        rightKnee: CGPoint(x: mix(0.55, 0.59, armSwing), y: mix(0.68, 0.63, progress) + jump * 0.4),
        leftFoot: CGPoint(x: 0.41, y: mix(0.84, 0.78, progress)),
        rightFoot: CGPoint(x: 0.59, y: mix(0.84, 0.78, progress))
    )
    drawFigure(context: &context, size: size, pose: pose)
}

private func drawSegment(
    context: inout GraphicsContext,
    from: CGPoint,
    to: CGPoint,
    in size: CGSize,
    color: Color,
    width: CGFloat
) {
    var path = Path()
    path.move(to: scaledPoint(from, in: size))
    path.addLine(to: scaledPoint(to, in: size))
    context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round, lineJoin: .round))
}

private func drawBar(context: inout GraphicsContext, size: CGSize, y: CGFloat) {
    var path = Path()
    path.move(to: CGPoint(x: size.width * 0.30, y: size.height * y))
    path.addLine(to: CGPoint(x: size.width * 0.70, y: size.height * y))
    context.stroke(path, with: .color(AppTheme.gymAccent.opacity(0.70)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
}

private func drawBarPair(context: inout GraphicsContext, size: CGSize, x1: CGFloat, x2: CGFloat, y1: CGFloat, y2: CGFloat) {
    var left = Path()
    left.move(to: CGPoint(x: size.width * x1, y: size.height * y1))
    left.addLine(to: CGPoint(x: size.width * x1, y: size.height * y2))
    var right = Path()
    right.move(to: CGPoint(x: size.width * x2, y: size.height * y1))
    right.addLine(to: CGPoint(x: size.width * x2, y: size.height * y2))
    context.stroke(left, with: .color(AppTheme.gymAccent.opacity(0.70)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
    context.stroke(right, with: .color(AppTheme.gymAccent.opacity(0.70)), style: StrokeStyle(lineWidth: 8, lineCap: .round))
}

private func drawBenchLine(context: inout GraphicsContext, size: CGSize, from: CGPoint, to: CGPoint) {
    var bench = Path()
    bench.move(to: scaledPoint(from, in: size))
    bench.addLine(to: scaledPoint(to, in: size))
    context.stroke(bench, with: .color(AppTheme.gymBlue.opacity(0.70)), style: StrokeStyle(lineWidth: 10, lineCap: .round))
}

private func drawMachinePlate(context: inout GraphicsContext, size: CGSize, rect: CGRect) {
    let scaledRect = CGRect(
        x: rect.origin.x,
        y: rect.origin.y,
        width: rect.width,
        height: rect.height
    )
    context.fill(Path(roundedRect: scaledRect, cornerRadius: 12), with: .color(AppTheme.gymAccent.opacity(0.18)))
    context.stroke(Path(roundedRect: scaledRect, cornerRadius: 12), with: .color(AppTheme.gymAccent.opacity(0.45)), style: StrokeStyle(lineWidth: 2))
}

private func drawWheel(context: inout GraphicsContext, size: CGSize, center: CGPoint) {
    let point = scaledPoint(center, in: size)
    let rect = CGRect(x: point.x - 16, y: point.y - 16, width: 32, height: 32)
    context.fill(Path(ellipseIn: rect), with: .color(AppTheme.gymAccent.opacity(0.20)))
    context.stroke(Path(ellipseIn: rect), with: .color(AppTheme.gymAccent), style: StrokeStyle(lineWidth: 3))
}

private func scaledPoint(_ point: CGPoint, in size: CGSize) -> CGPoint {
    CGPoint(x: point.x * size.width, y: point.y * size.height)
}

private func mix(_ start: CGFloat, _ end: CGFloat, _ progress: CGFloat) -> CGFloat {
    start + (end - start) * progress
}

#Preview {
    ExerciseTutorialView(
        exercise: ExerciseCategory.legs.exercises.first!,
        onClose: {},
        onContinue: {}
    )
}
