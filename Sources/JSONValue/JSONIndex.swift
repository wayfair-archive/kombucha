//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

public enum JSONIndex {
    case arrayIndex(Int)
    case objectIndex(String)
}

extension JSONIndex: Comparable {
    /// `Comparable` for `JSONIndex`es. Sort `arrayIndex`es ahead of `objectIndex`es (this is just arbitrary), and sort each index case against itself by sorting against the associated value of the index (eg. `.arrayIndex(1) < .arrayIndex(99) == true`
    ///
    /// - Parameters:
    ///   - lhs: a `JSONIndex`
    ///   - rhs: another `JSONIndex`
    /// - Returns: true if the `lhs` index should precede the `rhs` index
    public static func <(_ lhs: JSONIndex, _ rhs: JSONIndex) -> Bool {
        switch (lhs, rhs) {
        case (.arrayIndex(let lhsValue), .arrayIndex(let rhsValue)):
            return lhsValue < rhsValue
        case (.arrayIndex, .objectIndex):
            return true
        case (.objectIndex, .arrayIndex):
            return false
        case (.objectIndex(let lhsValue), .objectIndex(let rhsValue)):
            return lhsValue < rhsValue
        }
    }
}

extension JSONIndex: Hashable { }

public extension Array where Element == JSONIndex {
    /// “pretty print” a `JSONContext` so it kind of looks like JavaScript indexing syntax
    var prettyPrinted: String {
        return map { index in
            switch index {
            case .arrayIndex(let intValue):
                return "[\(intValue)]"
            case .objectIndex(let stringValue):
                return "['\(stringValue)']"
            }
        }.joined()
    }

    func appending(_ newElement: JSONIndex) -> Array {
        var copy = self
        copy.append(newElement)
        return copy
    }
}

/// An array of `JSONIndex` values, specifying how to traverse into a nested `JSONValue`. By convention, this array grows from the tail, so `JSONContext.removeFirst()` corresponds to the first (outermost) traversal
public typealias JSONContext = [JSONIndex]

public extension JSONContext {
    static let root: JSONContext = []
}

extension JSONContext: Comparable {
    /// `Comparable` for `JSONContext`s (an array of `JSONIndex`es). Sort by the `first` element of the list and if there’s a tie, move one level inward. eg. `['foo'] < ['foo'][0] < ['foo'][99] < ['zzz']`
    ///
    /// - Parameters:
    ///   - lhs: a `JSONContext`
    ///   - rhs: another `JSONContext`
    /// - Returns: true if the `lhs` context should precede the `rhs` context
    public static func <(_ lhs: JSONContext, rhs: JSONContext) -> Bool {
        switch (lhs.first, rhs.first) {
        case (.some(let lhsValue), .some(let rhsValue)):
            if lhsValue == rhsValue {
                return Array(lhs.dropFirst()) < Array(rhs.dropFirst())
            }
            return lhsValue < rhsValue
        case (.some, .none):
            return false
        case (.none, .some):
            return true
        case (.none, .none):
            return false
        }
    }
}

public extension JSONValue {
    subscript(index: JSONIndex) -> JSONValue? {
        get {
            switch (self, index) {
            case (.array(let arrayValue), .arrayIndex(let arrayIndex)):
                return arrayIndex < arrayValue.endIndex ? arrayValue[arrayIndex] : nil
            case (.object(let objectValue), .objectIndex(let objectIndex)):
                return objectValue[objectIndex]
            default:
                return nil
            }
        }
    }

    subscript(context jsonContext: JSONContext) -> JSONValue? {
        get {
            var result = self
            var context = jsonContext
            while !context.isEmpty {
                let index = context.removeFirst()
                guard let nextResult = result[index] else {
                    return nil
                }
                result = nextResult
            }
            return result
        }
    }
}
