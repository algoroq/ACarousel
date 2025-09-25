//
//  File.swift
//
//
//  Created by Marián Trpkoš on 07.03.2024.
//

import Foundation
import SwiftUI


public enum ACarouselGestureRecognizer {
    case simple
    case simultaneous(mask: GestureMask = .all)
    case highPriority(mask: GestureMask = .all)
    
    /// applies `ACarouselGesture` onto view content
    func applyACarouselGesture<Content: View>(to content: Content, gesture: ACarouselGesture) -> any View {
        
        // MARK: - system gesture handlers
        
        func handleSwipeChanged(_ recognizer: UILongPressGestureRecognizer, _ translation: CGSize) {
            //dragChanged(translation: translation)
            gesture.onDragChanged(translation)
        }
        
        func handleSwipeEnded(_ recognizer: UILongPressGestureRecognizer, _ translation: CGSize) {
            //dragEnded(translation: translation)
            gesture.onDragEnded(translation)
        }
        
        func handleDragChanged(_ dragGesture: DragGesture.Value) {
            //dragChanged(translation: gesture.translation)
            gesture.onDragChanged(dragGesture.translation)
        }
        
        func handleDragEnded(_ dragGesture: DragGesture.Value) {
            //dragEnded(translation: gesture.translation)
            gesture.onDragEnded(dragGesture.translation)
        }
        
        
        // MARK: - ACarouselGesture view hook
        
        switch self {
        case .simple:
            return content.gesture(DragGesture().onChanged(handleDragChanged).onEnded(handleDragEnded))
        case let .simultaneous(mask):
            /// ensure iOS 18 and iOS 26`simultaneous` gesture compatability, for more info see `SimultaneousSwipeGesture.swift` file
            if #available(iOS 18, *) {
                return content.gesture(SimultaneousSwipeGesture(
                    onChanged: handleSwipeChanged,
                    onEnded: handleSwipeEnded
                ))
            } else {
                return content.simultaneousGesture(DragGesture().onChanged(handleDragChanged).onEnded(handleDragEnded), including: mask)
            }
        case let .highPriority(mask):
            return content.highPriorityGesture(DragGesture().onChanged(handleDragChanged).onEnded(handleDragEnded), including: mask)
        }
    }
}

@available(iOS 14.0, OSX 11.0, *)
struct ACarouselGestureRecognizerModifier<Data, ID>: ViewModifier where Data : RandomAccessCollection, ID : Hashable  {
    
    var gestureRecognizer: ACarouselGestureRecognizer
    var gesture: ACarouselGesture
    
    func body(content: Content) -> some View {
        AnyView(gestureRecognizer.applyACarouselGesture(to: content, gesture: gesture))
    }
}
