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
    let isDarkMode: Bool
    
    /// 根据当前主题获取实际的图片名称
    var imageName: String {
        "\(assetName)_tile_\(isDarkMode ? "dark" : "light")"
    }
    
    /// 从 UserDefaults 读取配置
    static func current() -> WidgetBackgroundConfig {
        WidgetBackgroundConfig(
            assetName: WidgetSettings.backgroundAsset,
            isDarkMode: WidgetSettings.isDarkMode
        )
    }
}

/// 平铺背景视图
struct WidgetTiledBackground: View {
    let config: WidgetBackgroundConfig
    @Environment(\.colorScheme) private var colorScheme
    
    private var imageName: String {
        "\(config.assetName)_tile_\(colorScheme == .dark ? "dark" : "light")"
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
