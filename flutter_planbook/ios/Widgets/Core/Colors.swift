import SwiftUI

class Colors {
    static let shared = Colors()

    lazy var lightColorScheme = AppFlutterColorSchemes.light
    lazy var darkColorScheme = AppFlutterColorSchemes.dark
}

/// UIColor
extension Colors {
    static var uiPrimaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiPrimaryColor :
                Colors.shared.lightColorScheme.uiPrimaryColor
        }
    }

    static var uiOnPrimaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnPrimaryColor :
                Colors.shared.lightColorScheme.uiOnPrimaryColor
        }
    }

    static var uiPrimaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiPrimaryContainerColor :
                Colors.shared.lightColorScheme.uiPrimaryContainerColor
        }
    }

    static var uiOnPrimaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnPrimaryContainerColor :
                Colors.shared.lightColorScheme.uiOnPrimaryContainerColor
        }
    }

    static var uiSecondaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSecondaryColor :
                Colors.shared.lightColorScheme.uiSecondaryColor
        }
    }

    static var uiOnSecondaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnSecondaryColor :
                Colors.shared.lightColorScheme.uiOnSecondaryColor
        }
    }

    static var uiSecondaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSecondaryContainerColor :
                Colors.shared.lightColorScheme.uiSecondaryContainerColor
        }
    }

    static var uiOnSecondaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnSecondaryContainerColor :
                Colors.shared.lightColorScheme.uiOnSecondaryContainerColor
        }
    }

    static var uiTertiaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiTertiaryColor :
                Colors.shared.lightColorScheme.uiTertiaryColor
        }
    }

    static var uiOnTertiaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnTertiaryColor :
                Colors.shared.lightColorScheme.uiOnTertiaryColor
        }
    }

    static var uiTertiaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiTertiaryContainerColor :
                Colors.shared.lightColorScheme.uiTertiaryContainerColor
        }
    }

    static var uiOnTertiaryContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnTertiaryContainerColor :
                Colors.shared.lightColorScheme.uiOnTertiaryContainerColor
        }
    }

    static var uiErrorColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiErrorColor :
                Colors.shared.lightColorScheme.uiErrorColor
        }
    }

    static var uiOnErrorColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnErrorColor :
                Colors.shared.lightColorScheme.uiOnErrorColor
        }
    }

    static var uiErrorContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiErrorContainerColor :
                Colors.shared.lightColorScheme.uiErrorContainerColor
        }
    }

    static var uiOnErrorContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnErrorContainerColor :
                Colors.shared.lightColorScheme.uiOnErrorContainerColor
        }
    }

    static var uiSurfaceColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceColor :
                Colors.shared.lightColorScheme.uiSurfaceColor
        }
    }

    static var uiOnSurfaceColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnSurfaceColor :
                Colors.shared.lightColorScheme.uiOnSurfaceColor
        }
    }

    static var uiSurfaceVariantColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceVariantColor :
                Colors.shared.lightColorScheme.uiSurfaceVariantColor
        }
    }

    static var uiOnSurfaceVariantColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnSurfaceVariantColor :
                Colors.shared.lightColorScheme.uiOnSurfaceVariantColor
        }
    }

    static var uiSurfaceContainerLowestColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceContainerLowestColor :
                Colors.shared.lightColorScheme.uiSurfaceContainerLowestColor
        }
    }

    static var uiSurfaceContainerLowColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceContainerLowColor :
                Colors.shared.lightColorScheme.uiSurfaceContainerLowColor
        }
    }

    static var uiSurfaceContainerColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceContainerColor :
                Colors.shared.lightColorScheme.uiSurfaceContainerColor
        }
    }

    static var uiSurfaceContainerHighColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceContainerHighColor :
                Colors.shared.lightColorScheme.uiSurfaceContainerHighColor
        }
    }

    static var uiSurfaceContainerHighestColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceContainerHighestColor :
                Colors.shared.lightColorScheme.uiSurfaceContainerHighestColor
        }
    }

    static var uiOutlineColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOutlineColor :
                Colors.shared.lightColorScheme.uiOutlineColor
        }
    }

    static var uiOutlineVariantColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOutlineVariantColor :
                Colors.shared.lightColorScheme.uiOutlineVariantColor
        }
    }

    static var uiShadowColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiShadowColor :
                Colors.shared.lightColorScheme.uiShadowColor
        }
    }

    static var uiScrimColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiScrimColor :
                Colors.shared.lightColorScheme.uiScrimColor
        }
    }

    static var uiInverseSurfaceColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiInverseSurfaceColor :
                Colors.shared.lightColorScheme.uiInverseSurfaceColor
        }
    }

    static var uiOnInverseSurfaceColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiOnInverseSurfaceColor :
                Colors.shared.lightColorScheme.uiOnInverseSurfaceColor
        }
    }

    static var uiInversePrimaryColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiInversePrimaryColor :
                Colors.shared.lightColorScheme.uiInversePrimaryColor
        }
    }

    static var uiSurfaceTintColor: UIColor {
        UIColor {
            $0.userInterfaceStyle == .dark ?
                Colors.shared.darkColorScheme.uiSurfaceTintColor :
                Colors.shared.lightColorScheme.uiSurfaceTintColor
        }
    }
}

extension Colors {
    static var primaryColor: Color { Color(uiColor: uiPrimaryColor) }
    static var onPrimaryColor: Color { Color(uiColor: uiOnPrimaryColor) }
    static var primaryContainerColor: Color { Color(uiColor: uiPrimaryContainerColor) }
    static var onPrimaryContainerColor: Color { Color(uiColor: uiOnPrimaryContainerColor) }
    static var secondaryColor: Color { Color(uiColor: uiSecondaryColor) }
    static var onSecondaryColor: Color { Color(uiColor: uiOnSecondaryColor) }
    static var secondaryContainerColor: Color { Color(uiColor: uiSecondaryContainerColor) }
    static var onSecondaryContainerColor: Color { Color(uiColor: uiOnSecondaryContainerColor) }
    static var tertiaryColor: Color { Color(uiColor: uiTertiaryColor) }
    static var onTertiaryColor: Color { Color(uiColor: uiOnTertiaryColor) }
    static var tertiaryContainerColor: Color { Color(uiColor: uiTertiaryContainerColor) }
    static var onTertiaryContainerColor: Color { Color(uiColor: uiOnTertiaryContainerColor) }
    static var errorColor: Color { Color(uiColor: uiErrorColor) }
    static var onErrorColor: Color { Color(uiColor: uiOnErrorColor) }
    static var errorContainerColor: Color { Color(uiColor: uiErrorContainerColor) }
    static var onErrorContainerColor: Color { Color(uiColor: uiOnErrorContainerColor) }
    static var surfaceColor: Color { Color(uiColor: uiSurfaceColor) }
    static var onSurfaceColor: Color { Color(uiColor: uiOnSurfaceColor) }
    static var surfaceVariantColor: Color { Color(uiColor: uiSurfaceVariantColor) }
    static var onSurfaceVariantColor: Color { Color(uiColor: uiOnSurfaceVariantColor) }
    static var surfaceContainerLowestColor: Color { Color(uiColor: uiSurfaceContainerLowestColor) }
    static var surfaceContainerLowColor: Color { Color(uiColor: uiSurfaceContainerLowColor) }
    static var surfaceContainerColor: Color { Color(uiColor: uiSurfaceContainerColor) }
    static var surfaceContainerHighColor: Color { Color(uiColor: uiSurfaceContainerHighColor) }
    static var surfaceContainerHighestColor: Color { Color(uiColor: uiSurfaceContainerHighestColor) }
    static var outlineColor: Color { Color(uiColor: uiOutlineColor) }
    static var outlineVariantColor: Color { Color(uiColor: uiOutlineVariantColor) }
    static var shadowColor: Color { Color(uiColor: uiShadowColor) }
    static var scrimColor: Color { Color(uiColor: uiScrimColor) }
    static var inverseSurfaceColor: Color { Color(uiColor: uiInverseSurfaceColor) }
    static var onInverseSurfaceColor: Color { Color(uiColor: uiOnInverseSurfaceColor) }
    static var inversePrimaryColor: Color { Color(uiColor: uiInversePrimaryColor) }
    static var surfaceTintColor: Color { Color(uiColor: uiSurfaceTintColor) }
}
