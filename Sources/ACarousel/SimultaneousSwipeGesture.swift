//
//  SimultaneousSwipeGesture.swift
//  ACarousel
//
//  Created by Marián Trpkoš on 25.09.2025.
//

import SwiftUI


/// fix iOS 26 simultaneous system gesture issue: https://stackoverflow.com/a/79768461
@available(iOS 18.0, * )
struct SimultaneousSwipeGesture: UIGestureRecognizerRepresentable {
    
    let onBegan: (UILongPressGestureRecognizer) -> Void
    let onChanged: (UILongPressGestureRecognizer, CGSize) -> Void
    let onEnded: (UILongPressGestureRecognizer, CGSize) -> Void

    init(
        onBegan: @escaping (UILongPressGestureRecognizer) -> Void = { _ in },
        onChanged: @escaping (UILongPressGestureRecognizer, CGSize) -> Void = { _, _ in },
        onEnded: @escaping (UILongPressGestureRecognizer, CGSize) -> Void = { _, _ in }
    ) {
        self.onBegan = onBegan
        self.onChanged = onChanged
        self.onEnded = onEnded
    }
    
    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let gestureRecognizer = UILongPressGestureRecognizer()
        gestureRecognizer.minimumPressDuration = 0.0
        gestureRecognizer.allowableMovement = CGFloat.greatestFiniteMagnitude
        gestureRecognizer.delegate = context.coordinator
        return gestureRecognizer
    }
    
    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        switch recognizer.state {
        case .began:
            context.coordinator.startLocation = recognizer.location(in: recognizer.view)
            onBegan(recognizer)
        
        case .changed:
            let location = recognizer.location(in: recognizer.view)
            let translation = CGSize(
                width: location.x - context.coordinator.startLocation.x,
                height: location.y - context.coordinator.startLocation.y
            )
            onChanged(recognizer, translation)
        
        case .ended, .cancelled:
            let location = recognizer.location(in: recognizer.view)
            let translation = CGSize(
                width: location.x - context.coordinator.startLocation.x,
                height: location.y - context.coordinator.startLocation.y
            )
            context.coordinator.startLocation = .zero
            onEnded(recognizer, translation)
        
        default:
            break
        }
    }
    
    func updateUIGestureRecognizer(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var startLocation: CGPoint = .zero
        
        func gestureRecognizer(
            _ recognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}





