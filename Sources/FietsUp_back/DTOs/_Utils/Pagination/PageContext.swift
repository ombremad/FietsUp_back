//
//  PageContext.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

import Fluent

struct PageContext<T: Encodable & Sendable>: Encodable {
  let items: [T]
  let metadata: PageMetadata
  
  init(_ page: Page<T>) {
    self.items = page.items
    self.metadata = PageMetadata(
      page: page.metadata.page,
      per: page.metadata.per,
      total: page.metadata.total
    )
  }
}
