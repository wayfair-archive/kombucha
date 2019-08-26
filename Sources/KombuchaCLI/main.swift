//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import KombuchaLib

let jsonDecoder = JSONDecoder()

let args = Array(CommandLine.arguments.dropFirst())
let (configuration, printErrorsOnly, recordMode, snapshotsURL, workURL, report) = try parseKombuchaArgs(args, jsonDecoder: jsonDecoder)

var standardError = FileHandle.standardError.outputStream
var standardOutput = FileHandle.standardOutput.outputStream

var sessionConfiguration: URLSessionConfiguration
// `URLSessionConfiguration.ephemeral` is not implemented on Linux
#if os(Linux)
sessionConfiguration = .default
sessionConfiguration.requestCachePolicy = .reloadIgnoringLocalCacheData
#else
sessionConfiguration = URLSessionConfiguration.ephemeral
#endif

let httpAdditionalHeaders = ["Accept": "application/json"]
    .merging(configuration.sharedHttpHeadersForSnaps ?? [:], uniquingKeysWith: {(_, new) in new })

sessionConfiguration.httpAdditionalHeaders = httpAdditionalHeaders as [AnyHashable : Any]

let session = URLSession(configuration: sessionConfiguration)

var isError = false
var results: [SnapJUnit.Result] = []

for snap in configuration.snaps {
    let runner = SnapRunner(
        jsonCheck: snap.jsonCheck,
        jsonDecoder: jsonDecoder,
        outputStreams: (error: standardError, output: standardOutput),
        session: session,
        snapshotsURL: snapshotsURL,
        workURL: workURL
    )

    guard !recordMode else {
        try runner.recordReference(for: snap, setError: &isError)
        continue
    }

    print("", to: &standardOutput)
    
    let startDate = Date()
    let checkResults = try runner.executeCheck(for: snap, setError: &isError)
    let endDate = Date()
    results.append(.init(startDate: startDate, endDate: endDate, config: snap, checkResults: checkResults))
    
    for key in checkResults.results.keys.sorted() {
        if printErrorsOnly {
            guard !checkResults.results[key]!.errors.isEmpty else { continue }
            isError = true

            print(key.prettyPrinted, to: &standardOutput)

            for error in checkResults.results[key]!.errors {
                print("    > ERROR: \(error)", to: &standardOutput)
            }
        } else {
            print(key.prettyPrinted, to: &standardOutput)

            for info in checkResults.results[key]!.infos {
                print("    > INFO: \(info)", to: &standardOutput)
            }
            for warning in checkResults.results[key]!.warnings {
                print("    > WARNING: \(warning)", to: &standardOutput)
            }
            for error in checkResults.results[key]!.errors {
                isError = true

                print("    > ERROR: \(error)", to: &standardOutput)
            }
        }
    }
}

if case .junit(saveTo: let file) = report {
    var url = file.value
    url.resolveSymlinksInPath()
    let document = SnapJUnit.generateJUnitSuite(results: results)
    
    do {
        try document.create().write(to: url, atomically: true, encoding: .utf8)
        print("saved JUnitXML to \(url.path)")
    } catch {
        print("failed to save JUnitXML: \(error)")
    }
}

if recordMode {
    print("finished recording", to: &standardOutput)
    exit(EXIT_SUCCESS)
} else if isError {
    print("finished with errors", to: &standardOutput)
    exit(EXIT_FAILURE)
} else {
    print("finished", to: &standardOutput)
    exit(EXIT_SUCCESS)
}
