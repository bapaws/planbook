//
//  UserDefaults.swift
//  Runner
//
//  Created by 张敏超 on 2025/3/11.
//

import Foundation

extension UserDefaults {
    static var appGroup: UserDefaults { UserDefaults(suiteName: kAppGroupId)! }
}
