//
//  QuadrantConfigIntent.swift
//  Widgets
//
//  中号四象限组件配置 Intent
//

import AppIntents

struct QuadrantConfigIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "config.title"
    static var description: IntentDescription? = "config.description"

    @Parameter(title: "config.parameter.filterMode", default: TaskFilterMode.today)
    var filterMode: TaskFilterMode
}
