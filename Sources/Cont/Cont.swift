//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

/// wrapper for an asynchronous computation that eventually returns a value of type `A`; similar to a promise, but more lightweight. The argument to `next` represents the “continuation” of the computation, to be called once the asynchronous portion returns an `A`.
/// To extend an asynchronous computation with an additional synchronous computation, use `Cont.map(_:)`. To extend an asynchronous computation with an additional asynchronous computation, use `Cont.flatMap(_:)`.
public struct Cont<A> {
    public let next: (@escaping (A) -> Void) -> Void

    public init(_ next: @escaping (@escaping (A) -> Void) -> Void) {
        self.next = next
    }
}

public extension Cont {
    func flatMap<B>(_ transform: @escaping (A) -> Cont<B>) -> Cont<B> {
        return .init { callback in
            self.next { value in
                transform(value).next { innerValue in
                    callback(innerValue)
                }
            }
        }
    }

    func map<B>(_ transform: @escaping (A) -> B) -> Cont<B> {
        return .init { callback in
            self.next { value in
                callback(transform(value))
            }
        }
    }

    func run() {
        next { _ in }
    }
}
