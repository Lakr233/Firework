//
//  DockCanvasView.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import ColorfulX
import Pow
import SwiftUI

struct DockCanvasView: View {
    @StateObject var vm = ViewModel.shared

    @State var color: [Color] = [.red]
    @State var speed: Double = 1.0

    var body: some View {
        ZStack {
            Color.white
            content
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 8)
        .padding(12)
        .preferredColorScheme(.dark)
    }

    var content: some View {
        ZStack {
            Color.black

            ColorfulView(
                color: $color,
                speed: $speed,
                frameLimit: 30
            )
            .ignoresSafeArea()
            .onAppear { DispatchQueue.main.async {
                color = ColorfulPreset.sunset.colors
            } }
            .changeEffect(.shine, value: vm.fireCount)

            Image(.daPao)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .rotationEffect(.degrees(-45))
                .offset(y: 10)
                .conditionalEffect(
                    .repeat(
                        .glow(color: .orange, radius: 50),
                        every: 1
                    ),
                    condition: true
                )
                .changeEffect(
                    .rise(origin: UnitPoint(x: 0.75, y: 0.5)) {
                        Text("+1").font(.largeTitle)
                    }, value: vm.fireCount
                )
                .changeEffect(
                    .spray(origin: UnitPoint(x: 0.5, y: 0.5)) {
                        Image(systemName: "rays")
                            .tint(.white)
                    },
                    value: vm.fireCount
                )
                .conditionalEffect(.smoke, condition: vm.smoke)
                .conditionalEffect(.repeat(.wiggle(rate: .fast), every: .seconds(0.5)), condition: vm.wiggle)
                .foregroundStyle(.white)
                .padding()
        }
    }
}
