//
//  ACarouselGesture.swift
//  ACarousel
//
//  Created by Marián Trpkoš on 25.09.2025.
//

import SwiftUI

struct ACarouselGesture {
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: (CGSize) -> Void
}
