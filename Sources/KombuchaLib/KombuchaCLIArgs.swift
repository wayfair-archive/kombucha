//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import SPMUtility

public struct KombuchaCLIArgs<C> {
    public var configuration: C
    public var printErrorsOnly: Bool
    public var recordMode: Bool
    public var snapshotsURL: FileURL
    public var workURL: FileURL
}

public extension KombuchaCLIArgs where C == FileURL {
    init(parsingArgs args: [String]) throws {
        // TODO: usage and overview
        let argumentParser = ArgumentParser(usage: "test", overview: "test")
        let parseConfigurationURL = argumentParser.add(positional: "configurationURLString", kind: String.self, optional: true)
        let parsePrintErrorsOnly = argumentParser.add(option: "--print-errors-only", shortName: "-e", kind: Bool.self, usage: nil, completion: .unspecified)
        let parseRecordMode = argumentParser.add(option: "--record", shortName: "-r", kind: Bool.self, usage: nil, completion: .unspecified)

        let parseSnapshotsDirectoryURL = argumentParser.add(option: "--snapshots-directory", shortName: "-s", kind: String.self, usage: nil, completion: .filename)
        let parseWorkDirectoryURL = argumentParser.add(option: "--work-directory", shortName: "-w", kind: String.self, usage: nil, completion: .filename)

        let parsed = try argumentParser.parse(args)

        let configurationURL = parsed.get(parseConfigurationURL).flatMap(URL.init(fileURLWithPath:)) ??
            URL(fileURLWithPath: "./kombucha.json")

        let printErrorsOnly = parsed.get(parsePrintErrorsOnly) ?? false
        let recordMode = parsed.get(parseRecordMode) ?? false

        let snapshotsURL = parsed.get(parseSnapshotsDirectoryURL).flatMap(URL.init(fileURLWithPath:)) ??
            configurationURL
                .deletingLastPathComponent()
                .appendingPathComponent("__Snapshots__", isDirectory: true)

        let workURL = parsed.get(parseWorkDirectoryURL).flatMap(URL.init(fileURLWithPath:)) ??
            configurationURL
                .deletingLastPathComponent()
                .appendingPathComponent("__Work__", isDirectory: true)

        self.init(
            configuration: try FileURL(configurationURL),
            printErrorsOnly: printErrorsOnly,
            recordMode: recordMode,
            snapshotsURL: try FileURL(snapshotsURL),
            workURL: try FileURL(workURL)
        )
    }

    func loadingConfigurationFile(jsonDecoder: JSONDecoder) throws -> KombuchaCLIArgs<RunConfiguration> {
        let configurationData = try Data(contentsOf: configuration.value)
        return .init(
            configuration: try jsonDecoder.decode(RunConfiguration.self, from: configurationData),
            printErrorsOnly: printErrorsOnly,
            recordMode: recordMode,
            snapshotsURL: snapshotsURL,
            workURL: workURL
        )
    }
}
