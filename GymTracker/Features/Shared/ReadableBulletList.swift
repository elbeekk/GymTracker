import SwiftUI

struct ReadableBulletList: View {
    let items: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(AppTheme.secondaryText)
                        .frame(width: 8, height: 8)
                        .padding(.top, 8)

                    Text(item)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
