//
//  MenuResult.swift
//  HotkeyManager
//
//  Created by Laurens Karpf on 13.12.24.
//

import Foundation

enum MenuResult {
    case item(MenuItem)
    case section(MenuSection)
}

extension MenuResult: Identifiable {
    var id: String {
        switch self {
        case .item(let item):
            return item.id
        case .section(let section):
            return section.id
        }
    }
}

extension MenuResult: Hashable {
    static func ==(lhs: MenuResult, rhs: MenuResult) -> Bool {
        switch (lhs, rhs) {
        case (.item(let lhsItem), .item(let rhsItem)):
            return lhsItem.id == rhsItem.id
        case (.section(let lhsSection), .section(let rhsSection)):
            return lhsSection.id == rhsSection.id
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .item(let item):
            hasher.combine(item.id)
        case .section(let section):
            hasher.combine(section.id)
        }
    }
}
