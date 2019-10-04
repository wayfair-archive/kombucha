//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import JSONCheck
import JSONValue
import Prelude

#if os(Linux)
import FoundationNetworking
#endif

public final class SnapRunner<A: Monoid, S: TextOutputStream> {
    let fileManager: FileManager
    let jsonCheck: JSONCheck<A>

    let jsonDecoder: JSONDecoder
    let jsonEncoder: JSONEncoder
    var outputStreams: (error: S, output: S)
    let session: URLSession

    let snapshotsURL: FileURL
    let workURL: FileURL

    public init(
        fileManager: FileManager = .default,
        jsonCheck: JSONCheck<A>,
        jsonDecoder: JSONDecoder = .init(),
        jsonEncoder: JSONEncoder = .init(),
        outputStreams: (error: S, output: S),
        session: URLSession,
        snapshotsURL: FileURL,
        workURL: FileURL) {
        self.fileManager = fileManager
        self.jsonCheck = jsonCheck

        self.jsonDecoder = jsonDecoder
        self.jsonEncoder = jsonEncoder

        if #available(OSX 10.13, *) {
            jsonEncoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        } else {
            jsonEncoder.outputFormatting = [.prettyPrinted]
        }

        self.outputStreams = outputStreams
        self.session = session

        self.snapshotsURL = snapshotsURL
        self.workURL = workURL
    }

    /// execute `self.jsonCheck` for the given `snap`. If a reference file for the snap does not exist, this function will set the `error` out parameter to `true`, write a reference file, and then return `.empty`. MINOR GOTCHA: if `self.jsonCheck` produces errors, this function itself will _NOT_ set `error` to `true`, it’s up to the caller to do that (sorry). The reason is that this function is not specialized to any particular `jsonCheck` result type, only to `A: Monoid`, so we aren’t able to look inside the results here. We could probably clean this up in the future with an additional overload.
    ///
    /// - Parameters:
    ///   - snap: a `SnapConfiguration` describing the request to check
    ///   - error: an `inout Bool` that will be set if this function cannot perform the check (because a reference file is missing)
    /// - Returns: a `Monoid` `A`
    /// - Throws: various errors if there are problems with file paths or decoding reference data
    public func executeCheck(for snap: SnapConfiguration, setError error: inout Bool) throws -> A {
        print("testing: \(snap.request)", to: &outputStreams.output)

        let referenceURL: FileURL = try .init(baseURL: snapshotsURL, fileName: snap.fileName(for: .snapshot))

        guard fileManager.fileExists(atPath: referenceURL.value.path) else {
            print("reference file doesn’t exist, writing it and failing the test…", to: &outputStreams.error)
            try recordReference(for: snap, setError: &error)
            return .empty
        }

        let referenceData = try Data(contentsOf: referenceURL.value)
        let reference = try jsonDecoder.decode(JSONValue.self, from: referenceData)

        let test = try snap.fetch(decoder: jsonDecoder, encoder: jsonEncoder, session: session).runSync().get()

        try fileManager.createDirectory(at: workURL.value, withIntermediateDirectories: true, attributes: nil)

        let temporaryURL: FileURL = try .init(baseURL: workURL, fileName: snap.fileName(for: .work))
        try jsonEncoder.encode(test).write(to: temporaryURL.value)

        print("wrote to: \(temporaryURL)", to: &outputStreams.output)

        return jsonCheck.run(.empty, reference, test)
    }

    public func recordReference(for snap: SnapConfiguration, setError error: inout Bool) throws {
        error = true

        let reference = try snap.fetch(decoder: jsonDecoder, encoder: jsonEncoder, session: session).runSync().get()

        try fileManager.createDirectory(at: snapshotsURL.value, withIntermediateDirectories: true, attributes: nil)
        let referenceURL: FileURL = try .init(baseURL: snapshotsURL, fileName: snap.fileName(for: .snapshot))
        try jsonEncoder.encode(reference).write(to: referenceURL.value)

        print("wrote a reference to: \(referenceURL)", to: &outputStreams.output)
    }
}
