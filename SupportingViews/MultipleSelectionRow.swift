//
//  MultipleSelectionRow.swift
//  TempAqua
//

import SwiftUI

protocol SelectableRow {
    var name: String { get }
    var isSelected: Bool { get set }
}
