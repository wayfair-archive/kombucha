//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

extension GraphQLQueryContent {
    func getQueryText() throws -> String {
        switch query {
        case .file(let fileURL):
            return try String(contentsOf: fileURL.value)
        case .text(let stringValue):
            return stringValue
        }
    }
}
