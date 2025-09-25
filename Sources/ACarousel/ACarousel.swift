/**
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import SwiftUI


@available(iOS 14.0, OSX 11.0, *)
public struct ACarousel<Data, ID, Content, Suspending> : View where Data : RandomAccessCollection, ID : Hashable, Content : View, Suspending : View {
    
    @ObservedObject
    private var viewModel: ACarouselViewModel<Data, ID>
    private let content: (Data.Element) -> Content
    private let suspending: (Data.Element) -> Suspending
    
    @State
    private var lazyLoadCache: [ID:Bool]
    
    public var body: some View {
        GeometryReader { proxy -> AnyView in
            viewModel.viewSize = proxy.size
            return AnyView(generateContent(proxy: proxy))
        }
        .clipped()
    }
    
    private func generateContent(proxy: GeometryProxy) -> some View {
        Group {
            HStack(spacing: viewModel.spacing) {
                self.mainContent
            }
        }
        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
        .offset(x: viewModel.offset)
        /*
        .modifier(ACarouselGestureRecognizerModifier(
            gestureRecognizer: viewModel.gestureRecognizer,
            gesture: viewModel.dragGesture))
         */
        .modifier(ACarouselGestureRecognizerModifier(
            gestureRecognizer: viewModel.gestureRecognizer,
            gesture: viewModel.gesture
        ))
        .animation(viewModel.offsetAnimation, value: viewModel.offset)
        .onReceive(timer: viewModel.timer, perform: viewModel.receiveTimer)
        .onReceiveAppLifeCycle(perform: viewModel.setTimerActive)
    }
    
    // returns true if should be rendered
    private func isLazyLoaded(data: Data.Element) -> Bool {
        if !viewModel.lazyLoadingEnabled { return true } // distance has to be >= 2 (lazy loading enabled)
        
        // check if element was ever lazy loaded (lazy load cache)
        let dataId = data[keyPath: viewModel.dataId]
        if self.dataIdLazyLoaded(dataId: dataId) { return true }
        
        // extract indices from RAC
        guard let index = viewModel.data.firstIndex(where: { $0[keyPath: viewModel.dataId] == dataId }) else { return false }
        let activeIndex = viewModel.data.index(viewModel.data.startIndex, offsetBy: viewModel.activeIndex)
        let distance = viewModel.data.distance(from: index, to: activeIndex)
        
        // check if data element falls into current lazy loading range
        if abs(distance) < viewModel.lazyLoadDistance {
            self.setDataIdLazyLoaded(dataId: dataId)
            return true
        }
        
        return false
    }
    
    private var mainContent: some View {
        ForEach(viewModel.data, id: viewModel.dataId) { item in
            Group {
                if isLazyLoaded(data: item) {
                    content(item)
                } else {
                    suspending(item)
                }
            }
            .frame(width: viewModel.itemWidth)
            .scaleEffect(x: 1, y: viewModel.itemScaling(item), anchor: .center)
            .clipped()
        }
    }
}

@available(iOS 14.0, OSX 11.0, *)
extension ACarousel {
    private func dataIdLazyLoaded(dataId: ID) -> Bool {
        self.lazyLoadCache[dataId] ?? false
    }
    
    private func setDataIdLazyLoaded(dataId: ID) {
        // needs to be called from main queue, because functions called by view are pure functions!
        DispatchQueue.main.async {
            self.lazyLoadCache[dataId] = true
        }
    }
}


// MARK: - Initializers


// without lazy loading
@available(iOS 14.0, OSX 11.0, *)
extension ACarousel where Suspending == Content {
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The data that the ``ACarousel`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - index: The index of currently active.
    ///   - spacing: The distance between adjacent subviews, default is 10.
    ///   - headspace: The width of the exposed side subviews, default is 10
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///     default is 0.8.
    ///   - isWrap: Define views to scroll through in a loop, default is false.
    ///   - autoScroll: A enum that define view to scroll automatically. See
    ///     ``ACarouselAutoScroll``. default is `inactive`.
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, index: Binding<Int> = .constant(0), spacing: CGFloat = 10, headspace: CGFloat = 10, sidesScaling: CGFloat = 0.8, isWrap: Bool = false, autoScroll: ACarouselAutoScroll = .inactive, canMove: Bool = true, dragThresholdCoef: CGFloat = 1/3, gestureRecognizer: ACarouselGestureRecognizer = .simple, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        
        self.viewModel = ACarouselViewModel(data, id: id, index: index, spacing: spacing, headspace: headspace, sidesScaling: sidesScaling, isWrap: isWrap, autoScroll: autoScroll, canMove: canMove, dragThresholdCoef: dragThresholdCoef, gestureRecognizer: gestureRecognizer, lazyLoadDistance: -1)
        
        // ignore lazy loading
        self.content = { item in content(item) }
        self.suspending = { item in content(item) }
        
        _lazyLoadCache = State(initialValue: [:])
    }
}


// with lazy loading
@available(iOS 14.0, OSX 11.0, *)
extension ACarousel {
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The data that the ``ACarousel`` instance uses to create views
    ///     dynamically.
    ///   - id: The key path to the provided data's identifier.
    ///   - index: The index of currently active.
    ///   - spacing: The distance between adjacent subviews, default is 10.
    ///   - headspace: The width of the exposed side subviews, default is 10
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///     default is 0.8.
    ///   - isWrap: Define views to scroll through in a loop, default is false.
    ///   - autoScroll: A enum that define view to scroll automatically. See
    ///     ``ACarouselAutoScroll``. default is `inactive`.
    ///   - lazyLoadDistance: distance to lazy load neighbour views, has to be >= 2 otherwise is ignored
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, id: KeyPath<Data.Element, ID>, index: Binding<Int> = .constant(0), spacing: CGFloat = 10, headspace: CGFloat = 10, sidesScaling: CGFloat = 0.8, isWrap: Bool = false, autoScroll: ACarouselAutoScroll = .inactive, canMove: Bool = true, dragThresholdCoef: CGFloat = 1/3, gestureRecognizer: ACarouselGestureRecognizer = .simple, lazyLoadDistance: Int = 2, @ViewBuilder content: @escaping (Data.Element) -> Content, @ViewBuilder suspending: @escaping (Data.Element) -> Suspending) {
        
        self.viewModel = ACarouselViewModel(data, id: id, index: index, spacing: spacing, headspace: headspace, sidesScaling: sidesScaling, isWrap: isWrap, autoScroll: autoScroll, canMove: canMove, dragThresholdCoef: dragThresholdCoef, gestureRecognizer: gestureRecognizer, lazyLoadDistance: lazyLoadDistance)
        
        self.content = content
        self.suspending = suspending
        
        _lazyLoadCache = State(initialValue: [:])
    }
}


// without lazy loading
@available(iOS 14.0, OSX 11.0, *)
extension ACarousel where ID == Data.Element.ID, Data.Element : Identifiable, Suspending == Content{
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``ACarousel`` instance uses to
    ///     create views dynamically.
    ///   - index: The index of currently active.
    ///   - spacing: The distance between adjacent subviews, default is 10.
    ///   - headspace: The width of the exposed side subviews, default is 10
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///      default is 0.8.
    ///   - isWrap: Define views to scroll through in a loop, default is false.
    ///   - autoScroll: A enum that define view to scroll automatically. See
    ///     ``ACarouselAutoScroll``. default is `inactive`.
    ///   - lazyLoadDistance: distance to lazy load neighbour views, has to be >= 2 otherwise is ignored
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, index: Binding<Int> = .constant(0), spacing: CGFloat = 10, headspace: CGFloat = 10, sidesScaling: CGFloat = 0.8, isWrap: Bool = false, autoScroll: ACarouselAutoScroll = .inactive, canMove: Bool = true, dragThresholdCoef: CGFloat = 1/3, gestureRecognizer: ACarouselGestureRecognizer = .simple, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        
        self.viewModel = ACarouselViewModel(data, id: \.id, index: index, spacing: spacing, headspace: headspace, sidesScaling: sidesScaling, isWrap: isWrap, autoScroll: autoScroll, canMove: canMove, dragThresholdCoef: dragThresholdCoef, gestureRecognizer: gestureRecognizer, lazyLoadDistance: -1)
        
        // ignore lazy loading
        self.content = { item in content(item) }
        self.suspending = { item in content(item) }
        
        _lazyLoadCache = State(initialValue: [:])
    }
}

// with lazy loading
@available(iOS 14.0, OSX 11.0, *)
extension ACarousel where ID == Data.Element.ID, Data.Element : Identifiable {
    
    /// Creates an instance that uniquely identifies and creates views across
    /// updates based on the identity of the underlying data.
    ///
    /// - Parameters:
    ///   - data: The identified data that the ``ACarousel`` instance uses to
    ///     create views dynamically.
    ///   - index: The index of currently active.
    ///   - spacing: The distance between adjacent subviews, default is 10.
    ///   - headspace: The width of the exposed side subviews, default is 10
    ///   - sidesScaling: The scale of the subviews on both sides, limits 0...1,
    ///      default is 0.8.
    ///   - isWrap: Define views to scroll through in a loop, default is false.
    ///   - autoScroll: A enum that define view to scroll automatically. See
    ///     ``ACarouselAutoScroll``. default is `inactive`.
    ///   - lazyLoadDistance: distance to lazy load neighbour views, has to be >= 2 otherwise is ignored
    ///   - content: The view builder that creates views dynamically.
    public init(_ data: Data, index: Binding<Int> = .constant(0), spacing: CGFloat = 10, headspace: CGFloat = 10, sidesScaling: CGFloat = 0.8, isWrap: Bool = false, autoScroll: ACarouselAutoScroll = .inactive, canMove: Bool = true, dragThresholdCoef: CGFloat = 1/3, gestureRecognizer: ACarouselGestureRecognizer = .simple, lazyLoadDistance: Int = 2, @ViewBuilder content: @escaping (Data.Element) -> Content, @ViewBuilder suspending: @escaping (Data.Element) -> Suspending) {
        
        self.viewModel = ACarouselViewModel(data, id: \.id, index: index, spacing: spacing, headspace: headspace, sidesScaling: sidesScaling, isWrap: isWrap, autoScroll: autoScroll, canMove: canMove, dragThresholdCoef: dragThresholdCoef, gestureRecognizer: gestureRecognizer, lazyLoadDistance: lazyLoadDistance)
        
        self.content = content
        self.suspending = suspending
        
        _lazyLoadCache = State(initialValue: [:])
    }
}


@available(iOS 14.0, OSX 11.0, *)
struct ACarousel_LibraryContent: LibraryContentProvider {
    let Datas = Array(repeating: _Item(color: .red), count: 3)
    @LibraryContentBuilder
    var views: [LibraryItem] {
        LibraryItem(ACarousel(Datas) { _  in }, title: "ACarousel", category: .control)
        LibraryItem(ACarousel(Datas, index: .constant(0), spacing: 10, headspace: 10, sidesScaling: 0.8, isWrap: false, autoScroll: .inactive) { _ in }, title: "ACarousel full parameters", category: .control)
    }
    
    struct _Item: Identifiable {
        let id = UUID()
        let color: Color
    }
}
