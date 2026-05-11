//
//  CreateNoteIntent.swift
//  Widgets
//
//  打开 App 创建笔记 Intent
//

import AppIntents
import WidgetKit
#if canImport(planbook_widget)
import planbook_widget
#endif

/// 打开 App 创建笔记（iOS 18+）
/// iOS 17 使用 widgetURL 或 Link 实现
@available(iOS 18.0, *)
struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "intent.createNote.title"
    static var description: IntentDescription? = "intent.createNote.description"

    static var isDiscoverable: Bool { false }

    func perform() async throws -> some IntentResult {
        return .result(opensIntent: OpenURLIntent(
            URL(string: "planbook.bapaws://note/new")!
        ))
    }
}
