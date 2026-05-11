//
//  SwitchQuadrantIntent.swift
//  Widgets
//
//  中号组件切换象限 Intent
//

import AppIntents
import WidgetKit
#if canImport(planbook_widget)
import planbook_widget
#endif

/// 中号组件切换象限
struct SwitchQuadrantIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.switchQuadrant.title"
    static var description: IntentDescription? = "intent.switchQuadrant.description"

    static var isDiscoverable: Bool { false }

    @Parameter(title: "Priority")
    var priority: TaskPriority

    init() {}

    init(priority: TaskPriority) {
        self.priority = priority
    }

    func perform() async throws -> some IntentResult {
        WidgetSettings.selectedPriority = priority
        await WidgetCenter.shared.reloadTimelines(ofKind: QuadrantWidgetSmall.kind)
        return .result()
    }
}
