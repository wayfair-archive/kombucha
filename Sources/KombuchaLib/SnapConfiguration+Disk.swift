//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

public extension FileURL {
    init(baseURL: FileURL, fileName: String) throws {
        let lastPathComponent = sanitizePathComponent(fileName)
        
        self = try FileURL(
            baseURL
                .value
                .appendingPathComponent(lastPathComponent)
                .appendingPathExtension("json")
                .resolvingSymlinksInPath()
        )
    }
}
