//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation

// MARK: - run configuration

/// top level configuration struct for running the thing
public struct RunConfiguration: Decodable {
    public var userAgent: String
    public var snaps: [SnapConfiguration]
}

/// configuration struct that describes a single test
public struct SnapConfiguration: Decodable {
    public struct Preferences: Decodable {
        enum CodingKeys: String, CodingKey { case errors, infos, warnings }

        public var errors, infos, warnings: [String]
    }

    enum CodingKeys: String, CodingKey { case nameIdentifier = "__snapName", preferences = "__preferences"}

    /// enum that describes the request for this test
    ///
    /// - get: run an HTTP `GET`
    /// - graphQL: run a GraphQL query
    public enum Request {
        case get(GETSnap)
        case graphQL(GraphQLSnap)
    }

    public var preferences: Preferences?
    public var request: Request
    public var nameIdentifier: String

    public init(from decoder: Decoder) throws {
        request = try Request(from: decoder)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        preferences = try container.decodeIfPresent(Preferences.self, forKey: .preferences)
        nameIdentifier = try container.decode(String.self, forKey: .nameIdentifier)
    }
    
    enum FileType { case work, snapshot }
    
    func fileName(for type: FileType) -> String {
        switch type {
        case .work: return "\(self.nameIdentifier)-work"
        case .snapshot: return self.nameIdentifier
        }
    }
}

extension SnapConfiguration.Request: CustomStringConvertible {
    public var description: String {
        switch self {
        case .get(let getSnap):
            let count = getSnap.queryItems.count
            return "GET: \(getSnap.host)\(getSnap.path) - (\(count) query \(count == 1 ? "param" : "params"))"
        case .graphQL(let graphSnap):
            return "GRAPHQL: \(graphSnap.host)\(graphSnap.path)"
        }
    }
}

extension SnapConfiguration.Request: Decodable {
    enum CodingKeys: String, CodingKey {
        case snapType = "__snapType"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let snapType = try container.decode(String.self, forKey: .snapType)
        switch snapType {
        case GETSnap.snapTypeName:
            let getSnap = try GETSnap(from: decoder)
            self = .get(getSnap)
        case GraphQLSnap.snapTypeName:
            let graphQLSnap = try GraphQLSnap(from: decoder)
            self = .graphQL(graphQLSnap)
        default:
            throw DecodingError.typeMismatch(
                SnapConfiguration.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "the `__snapType` “\(snapType)” is not a known value"
                )
            )
        }
    }
}

public struct GETSnap: Decodable {
    public var host: String
    public var path: String
    public var queryItems: [String: String?]
    public var scheme: String

    fileprivate static let snapTypeName = "__GET"
}

public struct GraphQLSnap: Decodable {
    public var host: String
    public var path: String
    public var queryContent: GraphQLQueryContent
    public var scheme: String

    fileprivate static let snapTypeName = "__GRAPHQL"
}

public struct GraphQLQueryContent: Decodable {
    public var operationName: String?
    public var query: GraphQLQueryText
    public var variables: [String: String]?

    enum CodingKeys: String, CodingKey {
        case queryFile
        case queryText
        case operationName
        case variables
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        operationName = try container.decodeIfPresent(String.self, forKey: .operationName)

        if let queryText = try container.decodeIfPresent(String.self, forKey: .queryText) {
            query = .text(queryText)
        } else if let queryURLString = try container.decodeIfPresent(String.self, forKey: .queryFile) {
            query = .file(.fileURLWithPath(queryURLString))
        } else {
            throw DecodingError.typeMismatch(
                GraphQLQueryText.self,
                .init(
                    codingPath: decoder.codingPath,
                    debugDescription: "couldn’t find a “queryFile” or “queryText” key, or the data could not be parsed"
                )
            )
        }

        variables = try container.decodeIfPresent([String: String].self, forKey: .variables)
    }
}

public enum GraphQLQueryText {
    case file(FileURL)
    case text(String)
}

extension GETSnap {
    func toURL() throws -> WebURL {
        var components = URLComponents()
        components.host = host
        components.path = path
        components.queryItems = queryItems.map(URLQueryItem.init(name:value:))
        components.scheme = scheme
        guard let url = components.url, let webURL = try? WebURL(url) else {
            throw ConfigurationError(localizedDescription: """
Not a valid web URL. The URL components that were passed were: \(components)
""")
        }
        return webURL
    }
}

extension GraphQLSnap {
    func toURL() throws -> WebURL {
        var components = URLComponents()
        components.host = host
        components.path = path
        components.scheme = scheme
        guard let url = components.url, let webURL = try? WebURL(url) else {
            throw ConfigurationError(localizedDescription: """
Not a valid web URL. The URL components that were passed were: \(components)
""")
        }
        return webURL
    }
}

public struct ConfigurationError: Error {
    let localizedDescription: String
}
