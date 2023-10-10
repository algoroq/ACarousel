//
//  ContentView.swift
//  ACarouselDemo iOS
//
//  Created by Autumn on 2020/11/16.
//

import SwiftUI
import ACarousel
import SDWebImageSwiftUI

struct Item: Hashable {
    var id: Int
}

let items = [Item(id: 200), Item(id: 202), Item(id: 203), Item(id: 204), Item(id: 206)]

struct ListRow: View {
    let id: Int
    var url: String { "https://picsum.photos/id/\(id)/1800/2300" }
    
    init(id: Int) {
        //        print("Init ListRow \(id)")
        self.id = id
    }
    var body: some View {
        VStack {
            WebImage(url: URL(string: url))
                .onSuccess {_,_,_ in
                    print("Load photo \(id)")
                }
                .onFailure {error in
                    print(error)
                }
                .placeholder(content: {
                    ProgressView()
                })
                .resizable()
                .scaledToFill()
                .transition(.fade(duration: 0.5))
        }
    }
}

struct ContentView: View {
    
    @State var spacing: CGFloat = 0
    @State var headspace: CGFloat = 0
    @State var sidesScaling: CGFloat = 0.8
    @State var isWrap: Bool = false
    @State var autoScroll: Bool = false
    @State var time: TimeInterval = 1
    @State var currentIndex: Int = 0
    @State var dragThresholdCoef: CGFloat = 1/3
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                //                VStack {
                //                    ScrollView(.horizontal) {
                //                        LazyHStack {
                //                            ForEach(items, id:\.id){ item in
                //                                ListRow(id: item.id)
                //                            }
                //                        }
                //                        .frame(height: 200, alignment: .center)
                //                    }
                //                }
                
                Text("\(currentIndex + 1)/\(items.count)")
                
                Spacer().frame(height: 40)
                ACarousel(items,
                          id: \.id,
                          index: $currentIndex,
                          spacing: spacing,
                          headspace: headspace,
                          sidesScaling: sidesScaling,
                          isWrap: isWrap,
                          autoScroll: autoScroll ? .active(time) : .inactive,
                          dragThresholdCoef: dragThresholdCoef,
                          lazyLoadDistance: 2,
                          content: { item in
                            ListRow(id: item.id)
                        },
                          suspending: { item in
                            Rectangle()
                        }
                )
                .padding(.all, 0)
                .frame(height: 200)
                
                Spacer()
                
                ControlPanel(spacing: $spacing,
                             headspace: $headspace,
                             sidesScaling: $sidesScaling,
                             isWrap: $isWrap,
                             autoScroll: $autoScroll,
                             duration: $time,
                             dragThresholdCoef: $dragThresholdCoef)
                Spacer()
            }
        }
    }
}

struct ControlPanel: View {
    
    @Binding var spacing: CGFloat
    @Binding var headspace: CGFloat
    @Binding var sidesScaling: CGFloat
    @Binding var isWrap: Bool
    @Binding var autoScroll: Bool
    @Binding var duration: TimeInterval
    @Binding var dragThresholdCoef: CGFloat
    
    var body: some View {
        VStack {
            Group {
                HStack {
                    Text("spacing: ").frame(width: 120)
                    Slider(value: $spacing, in: 0...30, minimumValueLabel: Text("0"), maximumValueLabel: Text("30")) { EmptyView() }
                }
                HStack {
                    Text("headspace: ").frame(width: 120)
                    Slider(value: $headspace, in: 0...30, minimumValueLabel: Text("0"), maximumValueLabel: Text("30")) { EmptyView() }
                }
                HStack {
                    Text("sidesScaling: ").frame(width: 120)
                    Slider(value: $sidesScaling, in: 0...1, minimumValueLabel: Text("0"), maximumValueLabel: Text("1")) { EmptyView() }
                }
                HStack {
                    Toggle(isOn: $isWrap, label: {
                        Text("wrap: ").frame(width: 120)
                    })
                }
                HStack {
                    Text("dragThreshold: ").frame(width: 120)
                    Slider(value: $dragThresholdCoef, in: 0...1, minimumValueLabel: Text("0"), maximumValueLabel: Text("1")) { EmptyView() }
                }
                VStack {
                    HStack {
                        Toggle(isOn: $autoScroll, label: {
                            Text("autoScroll: ").frame(width: 120)
                        })
                    }
                    if autoScroll {
                        HStack {
                            Text("duration: ").frame(width: 120)
                            Slider(value: $duration, in: 1...10, minimumValueLabel: Text("1"), maximumValueLabel: Text("10")) { EmptyView() }
                        }
                    }
                }
            }
        }
        .padding([.horizontal, .bottom])
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}




