//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import Prelude

public enum IsFileURL: Refinement {
    public typealias BaseType = URL

    public static func isValid(_ value: URL) -> Bool {
        return value.isFileURL
    }
}

public typealias FileURL = Refined<URL, IsFileURL>

public extension FileURL {
    static func fileURLWithPath(_ path: String) -> FileURL {
        return try! .init(.init(fileURLWithPath: path))
    }
}

extension FileURL: CustomStringConvertible {
    public var description: String {
        return value.path
    }
}

public enum IsHTTPURL: Refinement {
    public typealias BaseType = URL

    public static func isValid(_ value: URL) -> Bool {
        return value.scheme?.uppercased() == "HTTP"
    }
}

public enum IsHTTPSURL: Refinement {
    public typealias BaseType = URL

    public static func isValid(_ value: URL) -> Bool {
        return value.scheme?.uppercased() == "HTTPS"
    }
}

public typealias IsWebURL = OneOf<IsHTTPURL, IsHTTPSURL>

public typealias WebURL = Refined<URL, IsWebURL>
