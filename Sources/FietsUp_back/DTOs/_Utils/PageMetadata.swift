//
//  PageMetadata.swift
//  FietsUp_back
//
//  Created by Anne Ferret on 20/07/2026.
//

struct PageMetadata: Encodable {
  let page: Int
  let per: Int
  let total: Int
  let pageCount: Int
  let previousPage: Int?
  let nextPage: Int?
  
  init(page: Int, per: Int, total: Int) {
    self.page = page
    self.per = per
    self.total = total
    self.pageCount = Int((Double(total) / Double(per)).rounded(.up))
    self.previousPage = page > 1 ? page - 1 : nil
    self.nextPage = page < self.pageCount ? page + 1 : nil
  }
}
