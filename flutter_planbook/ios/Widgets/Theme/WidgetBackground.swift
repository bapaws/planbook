//
//  WidgetBackground.swift
//  Widgets
//
//  平铺背景管理
//

import SwiftUI

/// Widget 背景配置
struct WidgetBackgroundConfig {
    let assetName: String

    /// 从 UserDefaults 读取配置
    static func current() -> WidgetBackgroundConfig {
        WidgetBackgroundConfig(assetName: WidgetSettings.backgroundAsset)
    }
}

/// 平铺背景视图
struct WidgetTiledBackground: View {
    let config: WidgetBackgroundConfig
    @Environment(\.colorScheme) private var colorScheme

    /// 与任务文字使用同一套外观解析，避免系统暗黑时铺深色底、文字仍是浅色方案。
    private var imageName: String {
        let isDark = WidgetSettings.isDark(colorScheme: colorScheme)
        return "\(config.assetName)_tile_\(isDark ? "dark" : "light")"
    }
    
    var body: some View {
        GeometryReader { geometry in
            Image(imageName)
                .resizable(resizingMode: .tile)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .ignoresSafeArea()
        }
        .ignoresSafeArea()
    }
}
