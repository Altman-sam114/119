import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject private var viewModel: GameViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.10, blue: 0.08),
                    Color(red: 0.42, green: 0.11, blue: 0.07),
                    Color(red: 0.68, green: 0.50, blue: 0.32)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer(minLength: 16)

                VStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(red: 0.86, green: 0.81, blue: 0.68))
                        .frame(width: 132, height: 132)
                        .overlay {
                            VStack(spacing: 6) {
                                Rectangle()
                                    .fill(Color(red: 0.64, green: 0.08, blue: 0.06))
                                    .frame(width: 74, height: 30)
                                Rectangle()
                                    .fill(Color(red: 0.07, green: 0.07, blue: 0.07))
                                    .frame(width: 82, height: 52)
                                Rectangle()
                                    .fill(Color(red: 0.64, green: 0.08, blue: 0.06))
                                    .frame(width: 36, height: 50)
                            }
                            .rotationEffect(.degrees(-8))
                        }

                    Text("帝国军团罗马")
                        .font(.system(size: 36, weight: .black, design: .serif))
                    Text("大征服者原型")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.78))
                }

                HStack(spacing: 12) {
                    ForEach(GameMode.allCases) { mode in
                        Button {
                            viewModel.start(mode: mode)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(mode.displayName)
                                    .font(.title3.weight(.bold))
                                Text(mode.subtitle)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
                            .padding(14)
                            .background(.black.opacity(0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(.white.opacity(0.18), lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 22)

                VStack(alignment: .leading, spacing: 10) {
                    Label("元老院敕令：夺取西西里，压制迦太基。", systemImage: "checkmark.seal.fill")
                    Label("军团候命：步兵、骑兵、弓兵、舰队。", systemImage: "square.grid.3x3.fill")
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.82))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(.black.opacity(0.22))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 22)

                Spacer(minLength: 16)
            }
        }
    }
}
