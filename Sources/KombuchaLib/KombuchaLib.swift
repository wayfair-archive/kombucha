//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Basic
import JSONCheck
import Prelude

public extension JSONCheck where A == [CheckResult] {
    static let allChecks: [String: JSONCheck] = [
        "array-consistency": JSONCheck.arrayConsistency,
        "empty-arrays": JSONCheck.emptyArrays,
        "empty-objects": JSONCheck.emptyObjects,
        "flag-new-keys": JSONCheck.flagNewKeys,
        "string-bools": JSONCheck.stringBools,
        "string-numbers": JSONCheck.stringNumbers,
        "structure": JSONCheck.structure,
        "strict-equality": JSONCheck.strictEquality
    ]
}

public extension JSONCheck where A == CheckResults {
    static let `default` = defaultErrors
        <> defaultWarnings
        <> defaultInfos

    static let defaultErrors = JSONCheck<[CheckResult]>.structure.map(CheckResults.asErrors)

    static let defaultInfos = (
        JSONCheck<[CheckResult]>.emptyArrays
            <> JSONCheck<[CheckResult]>.emptyObjects
            <> JSONCheck<[CheckResult]>.stringBools
            <> JSONCheck<[CheckResult]>.flagNewKeys
        ).map(CheckResults.asInfos)

    static let defaultWarnings = JSONCheck<[CheckResult]>.arrayConsistency.map(CheckResults.asWarnings)
}

public extension SnapConfiguration {
    var jsonCheck: JSONCheck<CheckResults> {
        guard let preferences = preferences else {
            return .default
        }

        return
            preferences // given the user’s preferences for this test
                .errors // with all the errors they requested that we run
                .compactMap { JSONCheck<[CheckResult]>.allChecks[$0] } // look up the corresponding check function
                .reduce(.empty, <>) // combine all the checks we found into one big one
                .map(CheckResults.asErrors) // make sure they appear as `ERROR:`s
            <>
            preferences
                .infos
                .compactMap { JSONCheck<[CheckResult]>.allChecks[$0] }
                .reduce(.empty, <>)
                .map(CheckResults.asInfos)
            <>
            preferences
                .warnings
                .compactMap { JSONCheck<[CheckResult]>.allChecks[$0] }
                .reduce(.empty, <>)
                .map(CheckResults.asWarnings)
    }
}

func sanitizePathComponent(_ string: String) -> String {
    return string
        .replacingOccurrences(of: "\\W+", with: "-", options: .regularExpression)
        .replacingOccurrences(of: "^-|-$", with: "", options: .regularExpression)
}

func sha256(string: String) -> String {
    let sha = SHA256(string)
    return sha.digestString()
}
