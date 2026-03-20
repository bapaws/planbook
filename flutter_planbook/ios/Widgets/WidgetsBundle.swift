//
//  WidgetsBundle.swift
//  Widgets
//
//  Created by 张敏超 on 2026/3/18.
//

import WidgetKit
import SwiftUI

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        Widgets()
        WidgetsControl()
        WidgetsLiveActivity()
    }
}
