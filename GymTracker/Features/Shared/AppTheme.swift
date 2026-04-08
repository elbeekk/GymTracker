import SwiftUI
import UIKit

enum AppTheme {
    // Legacy adaptive colors (used by existing tracking views)
    static let accent = Color(uiColor: .systemBlue)
    static let success = Color(uiColor: .systemGreen)
    static let warning = Color(uiColor: .systemOrange)
    static let danger = Color(uiColor: .systemRed)
    static let info = Color(uiColor: .systemTeal)

    static let pageBackground   = Color(uiColor: .systemGroupedBackground)
    static let surface          = Color(uiColor: .secondarySystemGroupedBackground)
    static let elevatedSurface  = Color(uiColor: .systemBackground)
    static let border           = Color(uiColor: .separator).opacity(0.18)
    static let secondaryText    = Color(uiColor: .secondaryLabel)
    static let tertiaryText     = Color(uiColor: .tertiaryLabel)

    // MARK: - Gym adaptive colors (dark + light)

    static let gymBg = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1)   // #0A0A12
            : UIColor.systemGroupedBackground
    })

    static let gymSurface = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.09, blue: 0.13, alpha: 1)   // #171721
            : UIColor.secondarySystemGroupedBackground
    })

    static let gymCard = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.13, blue: 0.19, alpha: 1)   // #212130
            : UIColor.tertiarySystemGroupedBackground
    })

    static let gymBorder = Color(UIColor { t in
        t.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.08)
            : UIColor.black.withAlphaComponent(0.08)
    })

    // Text — use system labels so they flip automatically
    static let gymText    = Color(UIColor.label)
    static let gymSubtext = Color(UIColor.secondaryLabel)
    static let gymDim     = Color(UIColor.tertiaryLabel)

    // Accent colors — same in both modes
    static let gymAccent     = Color(red: 1.00, green: 0.42, blue: 0.21)   // #FF6B35
    static let gymAccentGlow = Color(red: 1.00, green: 0.42, blue: 0.21).opacity(0.15)
    static let gymGreen      = Color(red: 0.20, green: 0.78, blue: 0.50)   // slightly richer
    static let gymBlue       = Color(red: 0.36, green: 0.65, blue: 1.00)   // #5CA6FF
}

// MARK: - Category gradient helpers
extension Color {
    static func categoryGradientStart(_ category: ExerciseCategory) -> Color {
        switch category {
        case .chest:     return Color(red: 1.00, green: 0.42, blue: 0.21)
        case .back:      return Color(red: 0.30, green: 0.80, blue: 0.75)
        case .legs:      return Color(red: 0.48, green: 0.52, blue: 1.00)
        case .arms:      return Color(red: 1.00, green: 0.42, blue: 0.42)
        case .shoulders: return Color(red: 1.00, green: 0.85, blue: 0.24)
        case .core:      return Color(red: 0.58, green: 0.88, blue: 0.83)
        case .fullBody:  return Color(red: 0.97, green: 0.47, blue: 0.49)
        }
    }
    static func categoryGradientEnd(_ category: ExerciseCategory) -> Color {
        switch category {
        case .chest:     return Color(red: 1.00, green: 0.55, blue: 0.10)
        case .back:      return Color(red: 0.27, green: 0.72, blue: 0.63)
        case .legs:      return Color(red: 0.59, green: 0.73, blue: 1.00)
        case .arms:      return Color(red: 1.00, green: 0.56, blue: 0.56)
        case .shoulders: return Color(red: 1.00, green: 0.92, blue: 0.52)
        case .core:      return Color(red: 0.30, green: 0.80, blue: 0.75)
        case .fullBody:  return Color(red: 0.78, green: 0.26, blue: 0.43)
        }
    }
}
