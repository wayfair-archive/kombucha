//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import JSONValue
import Prelude

/// a dictionary from JSON locations to diagnostic messages from the tool, for those locations
public typealias CheckResult = [JSONContext: [String]]

public extension JSONContext {
    /// convenience method for producing a new `CheckResult` from this `JSONContext` (`self`)
    /// - Parameter message: the string message to attach to this location
    func attaching(message: String) -> CheckResult {
        return [self: [message]]
    }
}

/// diagnostic messages from the tool for a particular JSON location, sorted into errors, infos, and warnings
public struct CheckRecord { public let errors, infos, warnings: [String] }

extension CheckRecord: Monoid {
    public static var empty: CheckRecord {
        return .init(errors: .empty, infos: .empty, warnings: .empty)
    }

    /// give `CheckRecord` a trivial `Monoid` implementation — a `CheckRecord` is just a bundle of arrays, so combine the arrays element-wise to implement `<>`
    /// - Parameter lhs: a `CheckRecord`
    /// - Parameter rhs: another `CheckRecord`
    public static func <>(_ lhs: CheckRecord, _ rhs: CheckRecord) -> CheckRecord {
        return .init(
            errors: lhs.errors <> rhs.errors,
            infos: lhs.infos <> rhs.infos,
            warnings: lhs.warnings <> rhs.warnings
        )
    }
}

/// a dictionary from JSON locations to diagnostic messages from the tool, for those locations, sorted into errors, infos, and warnings
public typealias CheckResults = [JSONContext: CheckRecord]

/// given a dictionary from JSON locations to string messages, map all the messages to errors
/// - Parameter result: a `CheckResults` dictionary
public func mapToErrors(_ result: CheckResult) -> CheckResults {
    result.mapValues { .init(errors: $0, infos: .empty, warnings: .empty) }
}

/// given a dictionary from JSON locations to string messages, map all the messages to infos
/// - Parameter result: a `CheckResults` dictionary
public func mapToInfos(_ result: CheckResult) -> CheckResults {
    result.mapValues { .init(errors: .empty, infos: $0, warnings: .empty) }
}

/// given a dictionary from JSON locations to string messages, map all the messages to warnings
/// - Parameter result: a `CheckResults` dictionary
public func mapToWarnings(_ result: CheckResult) -> CheckResults {
    result.mapValues { .init(errors: .empty, infos: .empty, warnings: $0) }
}

public extension CheckResults {
    /// given a dictionary of results (`self`), return a dictionary of results containing only those key-value pairs that contain errors, and only the errors
    var errors: CheckResult {
        compactMapValues { rec in
            rec.errors.isEmpty ? nil : rec.errors
        }
    }

    /// given a dictionary of results (`self`), return a dictionary of results containing only those key-value pairs that contain infos, and only the infos
    var infos: CheckResult {
        compactMapValues { rec in
            rec.infos.isEmpty ? nil : rec.infos
        }
    }

    /// given a dictionary of results (`self`), return a dictionary of results containing only those key-value pairs that contain warnings, and only the warnings
    var warnings: CheckResult {
        compactMapValues { rec in
            rec.warnings.isEmpty ? nil : rec.warnings
        }
    }
}
