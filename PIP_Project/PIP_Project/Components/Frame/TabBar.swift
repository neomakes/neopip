// Location: Components/TabBar.swift
import SwiftUI

struct TabBar: View {
    @Binding var selectedTab: Int
    var onCenterButtonTapped: (() -> Void)? = nil
    private let tabs = ["home", "insight", "write", "goal", "status"]
    
    var body: some View {
        VStack(spacing: 0) {
            // TabBar Content Area (44pt icon + 5pt padding)
            ZStack(alignment: .center) {
                // Background with rounded top corners
                Color.black
                    .clipShape(CustomCornerShape(radius: 40, corners: [.topLeft, .topRight]))
                
                // Border stroke
                CustomCornerShape(radius: 40, corners: [.topLeft, .topRight])
                    .stroke(Color.pip.lineTabbar, lineWidth: 0.5)
                
                // Tabs VStack with bottom alignment
                VStack(spacing: 0) {
                    Spacer()
                    
                    HStack(alignment: .top, spacing: 0) {
                        // Section 1: Home Icon
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 0
                                }
                            }) {
                                let isSelected = selectedTab == 0
                                Image(isSelected ? "icon_home" : "icon_home_deactivated")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .opacity(isSelected ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(height: 44)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Section 2: Insight Icon
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 1
                                }
                            }) {
                                let isSelected = selectedTab == 1
                                Image(isSelected ? "icon_insight" : "icon_insight_deactivated")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .opacity(isSelected ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(height: 44)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)

                        // Section 4: Goal Icon
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 3
                                }
                            }) {
                                let isSelected = selectedTab == 3
                                Image(isSelected ? "icon_goal" : "icon_goal_deactivated")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .opacity(isSelected ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(height: 44)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Section 5: Status Icon
                        VStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = 4
                                }
                            }) {
                                let isSelected = selectedTab == 4
                                Image(isSelected ? "icon_status" : "icon_status_deactivated")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 44, height: 44)
                                    .opacity(isSelected ? 1.0 : 0.6)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .frame(height: 44)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, CGFloat.PIPLayout.tabbarHorizontalPadding)
                    .frame(height: 44)
                }
            }
            .frame(height: 49)  // 44pt icons + 5pt padding
            
            // Safe Area / Home Indicator area
            Color.black
                .frame(height: 34)
        }
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
