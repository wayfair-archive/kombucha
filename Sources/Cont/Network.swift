//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

public extension URLSession {
    func task(_ request: URLRequest) -> Cont<(Data?, URLResponse?, Error?)> {
        return .init { complete in
            let task = self.dataTask(with: request, completionHandler: { d, r, e in
                complete((d, r, e))
            })
            task.resume()
        }
    }
}

public struct NetworkError: Error { let statusCode: Int }

public extension Result where Success == Data {
    static func extractResponse(data: Data?, response: URLResponse?, error: Error?) -> Result<Data, Error> {
        if let data = data {
            return .success(data)
        } else if let error = error {
            return .failure(error)
        } else if let response = response as? HTTPURLResponse {
            return .failure(NetworkError(statusCode: response.statusCode))
        } else {
            fatalError("this should not happen")
        }
    }
}

public extension Cont {
    func runSync(_ dispatchGroup: DispatchGroup = .init()) -> A {
        dispatchGroup.enter()

        var storage: A? = nil
        next { value in
            storage = value
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        return storage!
    }
}
