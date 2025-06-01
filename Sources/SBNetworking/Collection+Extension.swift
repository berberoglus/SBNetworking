//
//  Collection+Extension.swift
//  SBNetworking
//
//  Created by Samet Berberoglu on 2025-06-01.
//

extension Collection {
    var nilWhenEmpty: Self? {
        return isEmpty ? nil : self
    }
}
