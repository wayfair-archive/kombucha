//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Prelude
import Foundation
import JSONValue

#if os(Linux)
import FoundationNetworking
#endif

public extension SnapConfiguration {
    func fetch(
        decoder: JSONDecoder,
        encoder: JSONEncoder,
        session: URLSession) throws -> AnyLater<Result<JSONValue, Error>> {
        let request = try toURLRequest(encoder: encoder)
        return Laters.DataTask(request: request, session: session)
            .tryMapSuccess { tuple in try decoder.decode(JSONValue.self, from: tuple.0) }
            .eraseToAnyLater()
    }

    func toURLRequest(encoder: JSONEncoder) throws -> URLRequest {
        switch request {
        case .rest(let restSnap):
            var request = URLRequest(url: try restSnap.toURL().value)
            request.httpMethod = restSnap.httpMethod
            if let httpHeaders = restSnap.httpHeaders { for (key, header) in httpHeaders { request.setValue(header, forHTTPHeaderField: key) } }
            if let body = restSnap.body { request.httpBody = try encoder.encode(body) }
            return request
        case .graphQL(let graphQLSnap):
            var request = URLRequest(url: try graphQLSnap.toURL().value)
            request.httpBody = try encoder.encode(try EncodableGraphQLQueryContent(graphQLSnap.queryContent))
            request.httpMethod = "POST"
            if let httpHeaders = graphQLSnap.httpHeaders { for (key, header) in httpHeaders { request.setValue(header, forHTTPHeaderField: key) } }
            return request
        }
    }
}

private struct EncodableGraphQLQueryContent: Encodable {
    let operationName: String?
    let query: String
    let variables: [String: JSONValue]?

    init (_ content: GraphQLQueryContent) throws {
        query = try content.getQueryText()
        operationName = content.operationName
        variables = content.variables
    }
}
