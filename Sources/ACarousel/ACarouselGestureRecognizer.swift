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
    
    func apply(to: some View, gesture: any Gesture) -> any View {
        switch self {
        case .simple:
            return to.gesture(gesture)
        case let .simultaneous(mask):
            return to.simultaneousGesture(gesture, including: mask)
        case let .highPriority(mask):
            return to.highPriorityGesture(gesture, including: mask)
        }
    }
}

struct ACarouselGestureRecognizerModifier: ViewModifier {
    var gestureRecognizer: ACarouselGestureRecognizer
    var gesture: any Gesture
    
    func body(content: Content) -> some View {
        AnyView(gestureRecognizer.apply(to: content, gesture: gesture))
    }
}
