//
//  CustomSwipeAction.swift
//  CustomSwipeAction
//
//  Created by cano on 2025/03/20.
//

import SwiftUI

/// Swipe Action Model
struct Action: Identifiable {
    var id = UUID().uuidString
    var symbolImage: String
    var tint: Color
    var background: Color
    /// Properties
    var font: Font = .title3
    var size: CGSize = .init(width: 45, height: 45)
    var shape: some Shape = .circle
    var action: (inout Bool) -> ()
}

/// Swipe Action Builder
/// Accepts a set of actions without any ‘return’ or ‘commas’ and returns it in an array format
@resultBuilder
struct ActionBuilder {
    static func buildBlock(_ components: Action...) -> [Action] {
        return components
    }
}

/// Customization Properties
struct ActionConfig {
    var leadingPadding: CGFloat = 0
    var trailingPadding: CGFloat = 10
    var spacing: CGFloat = 10
    var occupiesFullWidth: Bool = true
}

extension View {
    /// Custom View Modifier
    @ViewBuilder
    func swipeActions(config: ActionConfig = .init(), @ActionBuilder actions: () -> [Action]) -> some View {
        self
            .modifier(CustomSwipeActionModifier(config: config, actions: actions()))
    }
}

@MainActor
@Observable
class SwipeActionSharedData {
    static let shared = SwipeActionSharedData()
    
    var activeSwipeAction: String?
}

/// Helper View Modifier
fileprivate struct CustomSwipeActionModifier: ViewModifier {
    
    var config: ActionConfig
    var actions: [Action]
    
    /// View Properties
    @State private var resetPositionTrigger: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var lastStoredOffsetX: CGFloat = 0
    @State private var bounceOffset: CGFloat = 0
    @State private var progress: CGFloat = 0
    
    /// Scroll Properties
    @State private var currentScrollOffset: CGFloat = 0
    @State private var storedScrollOffset: CGFloat?
    var sharedData = SwipeActionSharedData.shared
    @State private var currentID: String = UUID().uuidString
    
    /// iOS 17 Properties
    @GestureState private var isActive: Bool = false
    
    func body(content: Content) -> some View {
        Group {
            if #available(iOS 18, *) {
                content
                    .overlay {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                            .overlay(alignment: .trailing) {
                                ActionsView()
                            }
                    }
                    .compositingGroup()
                    .offset(x: offsetX)
                    .offset(x: bounceOffset)
                    .mask {
                        Rectangle()
                            .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                    }
                    .gesture(
                        PanGesture(onBegan: {
                            gestureDidBegan()
                        }, onChange: { value in
                            gestureDidChange(translation: value.translation)
                        }, onEnded: { value in
                            gestureDidEnded(translation: value.translation, velocity: value.velocity)
                        })
                    )
            } else {
                content
                    .overlay {
                        Rectangle()
                            .foregroundStyle(.clear)
                            .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                            .overlay(alignment: .trailing) {
                                ActionsView()
                            }
                    }
                    .compositingGroup()
                    .offset(x: offsetX)
                    .offset(x: bounceOffset)
                    .mask {
                        Rectangle()
                            .containerRelativeFrame(config.occupiesFullWidth ? .horizontal : .init())
                    }
                    .gesture(
                        DragGesture()
                            .updating($isActive, body: { _, out, _ in
                                out = true
                            }).onChanged { value in
                                gestureDidChange(translation: value.translation)
                            }.onEnded { value in
                                gestureDidEnded(translation: value.translation, velocity: value.velocity)
                            }
                    )
                    .onChange(of: isActive) { oldValue, newValue in
                        if newValue {
                            gestureDidBegan()
                        }
                    }
            }
        }
        .onChange(of: resetPositionTrigger) { oldValue, newValue in
            reset()
        }
        .onGeometryChange(for: CGFloat.self) {
            $0.frame(in: .scrollView).minY
        } action: { newValue in
            if let storedScrollOffset, storedScrollOffset != newValue {
                reset()
            }
        }
        .onChange(of: sharedData.activeSwipeAction) { oldValue, newValue in
            if newValue != currentID && offsetX != 0 {
                reset()
            }
        }
    }
    
    /// Actions View
    @ViewBuilder
    func ActionsView() -> some View {
        ZStack {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                
                GeometryReader { proxy in
                    let size = proxy.size
                    let spacing = config.spacing * CGFloat(index)
                    let offset = (CGFloat(index) * size.width) + spacing
                    
                    Button(action: { action.action(&resetPositionTrigger) }) {
                        Image(systemName: action.symbolImage)
                            .font(action.font)
                            .foregroundStyle(action.tint)
                            .frame(width: size.width, height: size.height)
                            .background(action.background, in: action.shape)
                    }
                    .offset(x: offset * progress)
                }
                .frame(width: action.size.width, height: action.size.height)
            }
        }
        .visualEffect { content, proxy in
            content
                .offset(x: proxy.size.width)
        }
        .offset(x: config.leadingPadding)
    }
    
    private func gestureDidBegan() {
        storedScrollOffset = lastStoredOffsetX
        sharedData.activeSwipeAction = currentID
    }
    
    private func gestureDidChange(translation: CGSize) {
        offsetX = min(max(translation.width + lastStoredOffsetX, -maxOffsetWidth), 0)
        progress = -offsetX / maxOffsetWidth
        
        bounceOffset = min(translation.width - (offsetX - lastStoredOffsetX), 0) / 10
    }
    
    private func gestureDidEnded(translation: CGSize, velocity: CGSize) {
        let endTarget = velocity.width + offsetX
        
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            if -endTarget > (maxOffsetWidth * 0.6) {
                offsetX = -maxOffsetWidth
                bounceOffset = 0
                progress = 1
            } else {
                /// Reset to intial position
                reset()
            }
        }
        
        lastStoredOffsetX = offsetX
    }
    
    private func reset() {
        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
            offsetX = 0
            lastStoredOffsetX = 0
            progress = 0
            bounceOffset = 0
        }
        
        storedScrollOffset = nil
    }
    
    var maxOffsetWidth: CGFloat {
        let totalActionSize: CGFloat = actions.reduce(.zero) { partialResult, action in
            partialResult + action.size.width
        }
        
        let spacing = config.spacing * CGFloat(actions.count - 1)
        
        return totalActionSize + spacing + config.leadingPadding + config.trailingPadding
    }
}
