//
//  ViewModel.swift
//  FireBox
//
//  Created by 秋星桥 on 2024/2/9.
//

import Combine

class ViewModel: ObservableObject {
    static let shared = ViewModel()

    @Published var smoke = false
    @Published var wiggle = false
    @Published var fireCount = 0
}
