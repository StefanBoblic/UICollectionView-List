//
//  Item.swift
//  GetAPet
//
//  Created by Stefan Boblic on 04.01.2023.
//

import Foundation

struct Item: Hashable {
  let title: String
  let pet: Pet?
  private let id = UUID()

  init(pet: Pet? = nil, title: String) {
    self.pet = pet
    self.title = title
  }
}
