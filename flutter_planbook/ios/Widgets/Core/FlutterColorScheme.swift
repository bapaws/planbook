//
//  FlutterColorScheme.swift
//  Runner
//
//  Created by 张敏超 on 2025/3/10.
//

import SwiftUI
import UIKit

struct FlutterColorScheme: Codable {
    let primary: Int
    let onPrimary: Int
    let primaryContainer: Int
    let onPrimaryContainer: Int
    let secondary: Int
    let onSecondary: Int
    let secondaryContainer: Int
    let onSecondaryContainer: Int
    let tertiary: Int
    let onTertiary: Int
    let tertiaryContainer: Int
    let onTertiaryContainer: Int
    let error: Int
    let onError: Int
    let errorContainer: Int
    let onErrorContainer: Int
    let background: Int
    let onBackground: Int
    let surface: Int
    let onSurface: Int
    let surfaceVariant: Int
    let onSurfaceVariant: Int
    let surfaceContainerLowest: Int
    let surfaceContainerLow: Int
    let surfaceContainer: Int
    let surfaceContainerHigh: Int
    let surfaceContainerHighest: Int
    let outline: Int
    let outlineVariant: Int
    let shadow: Int
    let scrim: Int
    let inverseSurface: Int
    let onInverseSurface: Int
    let inversePrimary: Int
    let surfaceTint: Int
}

extension FlutterColorScheme {
    private func uiColorFromARGB(_ argb: Int) -> UIColor {
        let (a, r, g, b) = (argb >> 24, argb >> 16 & 0xFF, argb >> 8 & 0xFF, argb & 0xFF)
        return UIColor(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }

    var uiPrimaryColor: UIColor { uiColorFromARGB(primary) }
    var uiOnPrimaryColor: UIColor { uiColorFromARGB(onPrimary) }
    var uiPrimaryContainerColor: UIColor { uiColorFromARGB(primaryContainer) }
    var uiOnPrimaryContainerColor: UIColor { uiColorFromARGB(onPrimaryContainer) }
    var uiSecondaryColor: UIColor { uiColorFromARGB(secondary) }
    var uiOnSecondaryColor: UIColor { uiColorFromARGB(onSecondary) }
    var uiSecondaryContainerColor: UIColor { uiColorFromARGB(secondaryContainer) }
    var uiOnSecondaryContainerColor: UIColor { uiColorFromARGB(onSecondaryContainer) }
    var uiTertiaryColor: UIColor { uiColorFromARGB(tertiary) }
    var uiOnTertiaryColor: UIColor { uiColorFromARGB(onTertiary) }
    var uiTertiaryContainerColor: UIColor { uiColorFromARGB(tertiaryContainer) }
    var uiOnTertiaryContainerColor: UIColor { uiColorFromARGB(onTertiaryContainer) }
    var uiErrorColor: UIColor { uiColorFromARGB(error) }
    var uiOnErrorColor: UIColor { uiColorFromARGB(onError) }
    var uiErrorContainerColor: UIColor { uiColorFromARGB(errorContainer) }
    var uiOnErrorContainerColor: UIColor { uiColorFromARGB(onErrorContainer) }
    var uiBackgroundColor: UIColor { uiColorFromARGB(background) }
    var uiOnBackgroundColor: UIColor { uiColorFromARGB(onBackground) }
    var uiSurfaceColor: UIColor { uiColorFromARGB(surface) }
    var uiOnSurfaceColor: UIColor { uiColorFromARGB(onSurface) }
    var uiSurfaceVariantColor: UIColor { uiColorFromARGB(surfaceVariant) }
    var uiOnSurfaceVariantColor: UIColor { uiColorFromARGB(onSurfaceVariant) }
    var uiSurfaceContainerLowestColor: UIColor { uiColorFromARGB(surfaceContainerLowest) }
    var uiSurfaceContainerLowColor: UIColor { uiColorFromARGB(surfaceContainerLow) }
    var uiSurfaceContainerColor: UIColor { uiColorFromARGB(surfaceContainer) }
    var uiSurfaceContainerHighColor: UIColor { uiColorFromARGB(surfaceContainerHigh) }
    var uiSurfaceContainerHighestColor: UIColor { uiColorFromARGB(surfaceContainerHighest) }
    var uiOutlineColor: UIColor { uiColorFromARGB(outline) }
    var uiOutlineVariantColor: UIColor { uiColorFromARGB(outlineVariant) }
    var uiShadowColor: UIColor { uiColorFromARGB(shadow) }
    var uiScrimColor: UIColor { uiColorFromARGB(scrim) }
    var uiInverseSurfaceColor: UIColor { uiColorFromARGB(inverseSurface) }
    var uiOnInverseSurfaceColor: UIColor { uiColorFromARGB(onInverseSurface) }
    var uiInversePrimaryColor: UIColor { uiColorFromARGB(inversePrimary) }
    var uiSurfaceTintColor: UIColor { uiColorFromARGB(surfaceTint) }

    var primaryColor: Color { .init(argb: primary) }
    var onPrimaryColor: Color { .init(argb: onPrimary) }
    var primaryContainerColor: Color { .init(argb: primaryContainer) }
    var onPrimaryContainerColor: Color { .init(argb: onPrimaryContainer) }
    var secondaryColor: Color { .init(argb: secondary) }
    var onSecondaryColor: Color { .init(argb: onSecondary) }
    var secondaryContainerColor: Color { .init(argb: secondaryContainer) }
    var onSecondaryContainerColor: Color { .init(argb: onSecondaryContainer) }
    var tertiaryColor: Color { .init(argb: tertiary) }
    var onTertiaryColor: Color { .init(argb: onTertiary) }
    var tertiaryContainerColor: Color { .init(argb: tertiaryContainer) }
    var onTertiaryContainerColor: Color { .init(argb: onTertiaryContainer) }
    var errorColor: Color { .init(argb: error) }
    var onErrorColor: Color { .init(argb: onError) }
    var errorContainerColor: Color { .init(argb: errorContainer) }
    var onErrorContainerColor: Color { .init(argb: onErrorContainer) }
    var backgroundColor: Color { .init(argb: background) }
    var onBackgroundColor: Color { .init(argb: onBackground) }
    var surfaceColor: Color { .init(argb: surface) }
    var onSurfaceColor: Color { .init(argb: onSurface) }
    var surfaceVariantColor: Color { .init(argb: surfaceVariant) }
    var onSurfaceVariantColor: Color { .init(argb: onSurfaceVariant) }
    var surfaceContainerLowestColor: Color { .init(argb: surfaceContainerLowest) }
    var surfaceContainerLowColor: Color { .init(argb: surfaceContainerLow) }
    var surfaceContainerColor: Color { .init(argb: surfaceContainer) }
    var surfaceContainerHighColor: Color { .init(argb: surfaceContainerHigh) }
    var surfaceContainerHighestColor: Color { .init(argb: surfaceContainerHighest) }
    var outlineColor: Color { .init(argb: outline) }
    var outlineVariantColor: Color { .init(argb: outlineVariant) }
    var shadowColor: Color { .init(argb: shadow) }
    var scrimColor: Color { .init(argb: scrim) }
    var inverseSurfaceColor: Color { .init(argb: inverseSurface) }
    var onInverseSurfaceColor: Color { .init(argb: onInverseSurface) }
    var inversePrimaryColor: Color { .init(argb: inversePrimary) }
    var surfaceTintColor: Color { .init(argb: surfaceTint) }
}

