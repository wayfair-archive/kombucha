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

/// wrapper struct for a `check` function: when run, it compares two `JSONValue`s and returns a value of type `A`
public struct JSONCheck<A> {
    /// run a `JSONCheck` given a `JSONContext`, reference `JSONValue`, and test value
    public let run: (JSONContext, JSONValue, JSONValue) -> A
}

public extension JSONCheck {
    /// given a JSON comparison that produces a value of type `A` (`self`), and a transform function from `(A) -> B`, produce a JSON comparison that produces a value of type `B`
    ///
    /// - Parameter transform: a function from `(A) -> B`
    /// - Returns: a `JSONCheck` that returns a `B` as a result of its comparison
    func map<B>(_ transform: @escaping (A) -> B) -> JSONCheck<B> {
        return .init { context, reference, test in
            return transform(self.run(context, reference, test))
        }
    }
}

extension JSONCheck: Semigroup where A: Semigroup {
    /// combine two `JSONCheck`s: run the `lhs` check, then run the `rhs` check, then combine the results
    ///
    /// - Parameters:
    ///   - lhs: a `JSONCheck` to run first
    ///   - rhs: a `JSONCheck` to run second
    /// - Returns: a `JSONCheck` that runs both checks
    public static func <>(_ lhs: JSONCheck, _ rhs: JSONCheck) -> JSONCheck {
        return .init { context, reference, test in
            lhs.run(context, reference, test) <> rhs.run(context, reference, test)
        }
    }
}

extension JSONCheck: Monoid where A: Monoid {
    /// the empty `JSONCheck`: given two `JSONValue`s, do nothing with them and return `.empty`
    public static var empty: JSONCheck {
        return .init { _, _, _ in .empty }
    }
}

/// compare two `JSONValue` objects (`Dictionary`s) and return an array of `CheckResult`s flagging any keys present in the `reference` that are not in the `test`, as well as any values in the `test` with a different dynamic type (string, number, etc.) than the corresponding value in the `reference`
///
/// - Parameters:
///   - context: a `JSONContext` describing the location in a larger JSON structure where this check is taking place
///   - reference: a reference `JSONValue.object` (the snapshot)
///   - test: a `JSONValue.object` to be tested
/// - Returns: an array of `CheckResult` diagnostics
private func checkMaps(context: JSONContext, _ reference: [String: JSONValue], _ test: [String: JSONValue]) -> [CheckResult] {
    return reference.reduce(.empty) { acc, rec in
        let (key, referenceValue) = rec
        guard let testValue = test[key] else {
            let check = CheckResult(
                context: context,
                message: "The key \(key) does not exist"
            )
            return acc <> [check]
        }
        let nextContext = context.appending(.objectIndex(key))
        return acc <> checkStructure(context: nextContext, referenceValue, testValue)
    }
}

/// compare two `JSONValue`s and return an array of `CheckResult`s flagging any keys present in the `reference` that are not in the `test`, as well as any values in the `test` with a different dynamic type (string, number, etc.) than the corresponding value in the `reference`
///
/// - Parameters:
///   - context: a `JSONContext` describing the location in a larger JSON structure where this check is taking place
///   - reference: a reference `JSONValue` (the snapshot)
///   - test: a `JSONValue` to be tested
/// - Returns: an array of `CheckResult` diagnostics
private func checkStructure(context: JSONContext, _ reference: JSONValue, _ test: JSONValue) -> [CheckResult] {
    switch (reference, test) {
    case (.array(let referenceArray), .array(let testArray)):
        guard let reference = referenceArray.first, let test = testArray.first else {
            return .empty
        }
        let nextContext = context.appending(.arrayIndex(0))
        return checkStructure(context: nextContext, reference, test)
    case (.bool, .bool),
         (.double, .double),
         (.null, _),
         (_, .null):
        return .empty
    case (.object(let referenceObject), .object(let testObject)):
        return checkMaps(context: context, referenceObject, testObject)
    case (.string, .string):
        return .empty
    default:
        return [
            .init(
                context: context,
                message: "Types didn’t match. Reference: \(reference), test: \(test)"
            )
        ]
    }
}

private func checkFlagNewKeys(context: JSONContext, _ reference: JSONValue, _ test: JSONValue) -> [CheckResult] {
    switch (reference, test) {
    case (.array(let referenceArray), .array(let testArray)):
        guard let reference = referenceArray.first, let test = testArray.first else {
            return .empty
        }
        let nextContext = context.appending(.arrayIndex(0))
        return checkFlagNewKeys(context: nextContext, reference, test)
    case (.object(let referenceObject), .object(let testObject)):
        return testObject.reduce(.empty) { acc, rec in
            let (key, testValue) = rec
            guard let referenceValue = referenceObject[key] else {
                let check = CheckResult(
                    context: context,
                    message: "The key \(key) exists in the value being tested, but not in the snapshot. Perhaps you need to update your snapshot?"
                )
                return acc <> [check]
            }
            let nextContext = context.appending(.objectIndex(key))
            return acc <> checkFlagNewKeys(context: nextContext, referenceValue, testValue)
        }
    default:
        return .empty
    }
}

/// given an array of `JSONValue`s, determine if the array is heterogeneous by comparing the structure of the first element to the structures of the rest of the elements one by one
///
/// - Parameters:
///   - context: a `JSONContext` describing the location in a larger JSON structure where this check is taking place
///   - testArray: an array of `JSONValue`s to check
/// - Returns: an array of `CheckResult` diagnostics
private func checkTestArrayTypes(context: JSONContext, _ testArray: [JSONValue]) -> [CheckResult] {
    guard let firstValue = testArray.first else {
        return .empty
    }
    return testArray.dropFirst().enumerated().reduce(.empty) { acc, tuple in
        let (index, element) = tuple
        let nextContext = context.appending(.arrayIndex(index + 1))
        return acc <> checkStructure(context: nextContext, firstValue, element).map {
            CheckResult(context: $0.context, message: "Mixed types in array: \($0.message)")
        }
    }
}

/// compare two `JSONValue`s and return an array of `CheckResult`s flagging all differences between the `test` and `reference` value that would make the statement `reference == test` false based on the conformance of `JSONValue` to `Equatable`.
///
/// - Parameters:
///   - context: a `JSONContext` describing the location in a larger JSON structure where this check is taking place
///   - reference: a reference `JSONValue` (the snapshot)
///   - test: a `JSONValue` to be tested
/// - Returns: an array of `CheckResult` diagnostics
private func checkForStrictEquality(context: JSONContext, _ reference: JSONValue, _ test: JSONValue) -> [CheckResult] {
    
    switch (reference, test) {
    case (.bool(let refBool), .bool(let testBool)):
        guard refBool != testBool else { return .empty }
        return [ .init(context: context, message: "Not a strict equality between the boolean \(refBool) and \(testBool)") ]
        
    case (.double(let refDouble), .double(let testDouble)):
        guard refDouble != testDouble else { return .empty }
        return [ .init(context: context, message: "Not a strict equality between the number \(refDouble) and \(testDouble)") ]
        
    case (.null, .null):
        return .empty
        
    case (.string(let refString), .string(let testString)):
        guard refString != testString else { return .empty }
        return [ .init(context: context, message: "Not a strict equality between the string \"\(refString)\" and \"\(testString)\"") ]
        
    case (.object(let referenceObject), .object(let testObject)):
        return checkForStrictEqualityOfObjects(context: context, referenceObject, testObject)
        
    case (.array(let referenceArray), .array(let testArray)):
        guard referenceArray.count == testArray.count else {
            return  [ .init(context: context, message: "Not a strict equality since arrays of different sizes: \(referenceArray.count) vs \(testArray.count)") ]
        }
        
        return zip(referenceArray, testArray).enumerated().reduce(.empty) { previousChecks, el in
            let (index, (reference, test)) = el
            return previousChecks <> checkForStrictEquality(context: context.appending(.arrayIndex(index)), reference, test)
        }
        
    default:
        return  [ .init(context: context, message: "Not a strict equality since the types are diffrent. Reference: \(reference), test: \(test)") ]
    }
}

/// compare two `JSONValue` objects (`Dictionary`s) and return an array of `CheckResult`s flagging all differences between the `test` and `reference` objects based on the `checkForStrictEquality` test.
///
/// - Parameters:
///   - context: a `JSONContext` describing the location in a larger JSON structure where this check is taking place
///   - reference: a reference `JSONValue.object` (the snapshot)
///   - test: a `JSONValue.object` to be tested
private func checkForStrictEqualityOfObjects(context: JSONContext, _ referenceObject: [String : JSONValue], _ testObject: [String : JSONValue]) -> [CheckResult] {
    
    let newKeyInTestObjectChecks: [CheckResult] = testObject
        .keys
        .compactMap { key in referenceObject[key] == nil ? CheckResult(context: context, message: "Not a strict equality since there is a new key \(key)") : nil }
    
    let missingKeysInTestObjectAndStrictEqualityAtSharedKeys: [CheckResult] = referenceObject.reduce(.empty) { acc, rec in
        let (key, referenceValue) = rec
        guard let testValue = testObject[key] else {
            let check = CheckResult(context: context, message: "Not a strict equality since the key \(key) does not exist")
            return acc <> [check]
        }
        let nextContext = context.appending(.objectIndex(key))
        return acc <> checkForStrictEquality(context: nextContext, referenceValue, testValue)
    }
    
    return newKeyInTestObjectChecks <> missingKeysInTestObjectAndStrictEqualityAtSharedKeys
}

public extension JSONCheck where A == [CheckResult] {
    static let structure = JSONCheck(run: checkStructure)

    static let arrayConsistency = JSONCheck { context, _, test in
        test.fold(
            context: context,
            arrayCase: { context, array in checkTestArrayTypes(context: context, array) }
        )
    }

    /// flag empty arrays in the `test` `JSONValue`
    static let emptyArrays = JSONCheck { context, _, test in
        test.fold(
            context: context,
            arrayCase: { $1.isEmpty ? [.init(context: $0, message: "We found an empty array")] : .empty }
        )
    }

    /// flag empty objects in the `test` `JSONValue`
    static let emptyObjects = JSONCheck { context, _, test in
        test.fold(
            context: context,
            objectCase: { $1.isEmpty ? [.init(context: $0, message: "Empty object")] : .empty }
        )
    }

    static let flagNewKeys = JSONCheck(run: checkFlagNewKeys)

    /// flag the strings “true” or “false” (as opposed to real `true`s and `false`s) in the `test` `JSONValue`
    static let stringBools = JSONCheck { context, _, test in
        test.fold(
            context: context,
            stringCase: { $1.lowercased() == "true" || $1.lowercased() == "false" ? [.init(context: $0, message: "string bool: “\($0)”")] : .empty }
        )
    }

    /// flag strings that can be converted to `Double`s (as opposed to true JSON numbers) in the `test` `JSONValue`. This test may ultimately not be very useful: ID-like values as well as information such as zip codes are probably best represented as strings despite technically being convertible to `Double`s
    static let stringNumbers = JSONCheck { context, _, test in
        test.fold(
            context: context,
            stringCase: { Double($1) != nil ? [.init(context: $0, message: "string number: “\($1)”")] : .empty }
        )
    }
    
    static let strictEquality = JSONCheck(run: checkForStrictEquality)
}
