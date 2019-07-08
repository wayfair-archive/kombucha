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

/// a single diagnostic message from the tool
public struct CheckResult {
    public var context: JSONContext
    public var message: String
}

/// diagnostic messages from the tool sorted into errors, infos, and warnings
public struct CheckResults {
    public struct Record { public let errors, infos, warnings: [String] }

    public var results: [JSONContext: Record]
}

extension CheckResults.Record: Monoid {
    public static var empty: CheckResults.Record {
        return .init(errors: .empty, infos: .empty, warnings: .empty)
    }

    public static func <>(_ lhs: CheckResults.Record, _ rhs: CheckResults.Record) -> CheckResults.Record {
        return .init(
            errors: lhs.errors <> rhs.errors,
            infos: lhs.infos <> rhs.infos,
            warnings: lhs.warnings <> rhs.warnings)
    }
}

public extension CheckResults {
    var errors: [CheckResult] {
        // wanted to write this with `flatMap` but the compiler wouldn’t let me :(
        // check back again in 5.1 I guess
        return results.keys.reduce(into: []) { acc, key in
            if let errors = results[key]?.errors {
                acc.append(
                    contentsOf: errors.map { CheckResult(context: key, message: $0) }
                )
            }
        }
    }

    var infos: [CheckResult] {
        return results.keys.reduce(into: []) { acc, key in
            if let infos = results[key]?.infos {
                acc.append(
                    contentsOf: infos.map { CheckResult(context: key, message: $0) }
                )
            }
        }
    }

    var warnings: [CheckResult] {
        return results.keys.reduce(into: []) { acc, key in
            if let warnings = results[key]?.warnings {
                acc.append(
                    contentsOf: warnings.map { CheckResult(context: key, message: $0) }
                )
            }
        }
    }

    static func asErrors(_ results: [CheckResult]) -> CheckResults {
        let keysAndValues = results.map {
            (
                $0.context, Record(errors: [$0.message], infos: .empty, warnings: .empty)
            )
        }
        return .init(results: .init(keysAndValues, uniquingKeysWith: <>))
    }

    static func asWarnings(_ results: [CheckResult]) -> CheckResults {
        let keysAndValues = results.map {
            (
                $0.context, Record(errors: .empty, infos: .empty, warnings: [$0.message])
            )
        }
        return .init(results: .init(keysAndValues, uniquingKeysWith: <>))
    }

    static func asInfos(_ results: [CheckResult]) -> CheckResults {
        let keysAndValues = results.map {
            (
                $0.context, Record(errors: .empty, infos: [$0.message], warnings: .empty)
            )
        }
        return .init(results: .init(keysAndValues, uniquingKeysWith: <>))
    }
}

extension CheckResults: Monoid {
    public static var empty: CheckResults {
        return .init(results: [:])
    }

    public static func <>(_ lhs: CheckResults, _ rhs: CheckResults) -> CheckResults {
        return .init(results: lhs.results.merging(rhs.results, uniquingKeysWith: <>))
    }
}
