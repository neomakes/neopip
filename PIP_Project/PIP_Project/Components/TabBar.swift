// Location: Components/TabBar.swift
import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    private let tabs = ["home", "insight", "goal", "status"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    let isSelected = selectedTab == index
                    let assetName = isSelected ? "icon_\(tabs[index])" : "icon_\(tabs[index])_deactivated"
                    Image(assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 44, height: 44)
                        .opacity(isSelected ? 1.0 : 0.6)
                }
                .buttonStyle(PlainButtonStyle())
                
                if index < tabs.count - 1 { Spacer() }
            }
        }
        .padding(.horizontal, CGFloat.PIPLayout.tabbarHorizontalPadding)
        // Positioning icons exactly 2pt above the Home Indicator area
        .padding(.bottom, CGFloat.PIPLayout.safeAreaBottomHeight + 2)
        .padding(.top, 5)
        .frame(width: CGFloat.PIPLayout.fullScreenWidth, height: CGFloat.PIPLayout.tabbarHeight)
        .background(
            CustomCornerShape(radius: CGFloat.PIPLayout.tabbarCornerRadius, corners: [.topLeft, .topRight])
                .fill(Color.black)
                .overlay(
                    CustomCornerShape(radius: CGFloat.PIPLayout.tabbarCornerRadius, corners: [.topLeft, .topRight])
                        .strokeBorder(Color.pip.lineTabbar, lineWidth: 1.0)
                        .padding(.bottom, -50)
                )
        )
    }
}

struct CustomCornerShape: Shape, InsettableShape {
    var radius: CGFloat
    var corners: UIRectCorner
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        let path = UIBezierPath(
            roundedRect: insetRect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: max(0, radius - insetAmount), height: max(0, radius - insetAmount))
        )
        return Path(path.cgPath)
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var shape = self
        shape.insetAmount += amount
        return shape
    }
}
