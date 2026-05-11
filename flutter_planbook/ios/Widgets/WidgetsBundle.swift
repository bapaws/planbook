//
//  WidgetsBundle.swift
//  Widgets
//
//  Planbook 小组件 Bundle
//

import SwiftUI
import WidgetKit

@main
struct WidgetsBundle: WidgetBundle {
    var body: some Widget {
        QuadrantWidgetLarge()
        QuadrantWidgetSmall()
        QuickNoteWidget()
    }
}
