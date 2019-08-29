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
import SPMUtility

enum KombuchaReportMode {
    case junit(saveTo: FileURL)
    case none
}

struct KombuchaArgsError: Error, CustomStringConvertible {
    var description: String { return error }
    let error: String
}


typealias KombuchaArgs = (configuration: RunConfiguration, printErrorsOnly: Bool, recordMode: Bool, snapshotsURL: FileURL, workURL: FileURL, report: KombuchaReportMode)

func parseKombuchaArgs(_ args: [String], jsonDecoder: JSONDecoder) throws -> KombuchaArgs {
    
    let argumentParser = ArgumentParser(
        usage: "configurationURLString <options>",
        overview: "Kombucha is a command-line program for performing API snapshot testing."
    )
    
    let parseConfigurationURL = argumentParser.add(
        positional: "configurationURLString",
        kind: String.self,
        optional: true,
        usage: "Path to the configuration file."
    )
    
    let parsePrintErrorsOnly = argumentParser.add(
        option: "--print-errors-only",
        shortName: "-e",
        kind: Bool.self,
        usage: "Omit INFO and WARNING output when printing to the console. ",
        completion: .unspecified
    )
    
    let parseRecordMode = argumentParser.add(
        option: "--record",
        shortName: "-r",
        kind: Bool.self,
        usage: "Rewrite all the stored snapshots it knows about.",
        completion: .unspecified
    )
    
    let parseSnapshotsDirectoryURL = argumentParser.add(
        option: "--snapshots-directory",
        shortName: "-s",
        kind: String.self,
        usage: "Directory of the snapshots for the test run. If not specified, the default is ./__Snapshots/.",
        completion: .filename
    )
    
    let parseWorkDirectoryURL = argumentParser.add(
        option: "--work-directory",
        shortName: "-w",
        kind: String.self,
        usage: "Directory use as the “work directory” (storage for live responses) for the test run. If not specified, the default is ./__Work__/.",
        completion: .filename
    )
    
    let parseReportType = argumentParser.add(
        option: "--report-type",
        shortName: "-t",
        kind: String.self,
        usage: "If specified, a report will be created on disk for the current test run. `junit` is currently the only support type. You need to specify the `--report-output-url` path for the report.",
        completion: .none
    )
    
    let parseReportOutputURL = argumentParser.add(
        option: "--report-output-url",
        shortName: "-o",
        kind: String.self,
        usage: "The path to the report file (existing or not).",
        completion: .filename
    )

    let parsed = try argumentParser.parse(args)

    let configuration: RunConfiguration
    if let configurationURL = parsed.get(parseConfigurationURL).flatMap(URL.init(fileURLWithPath:)) {
        let configurationData = try Data(contentsOf: configurationURL)
        configuration = try jsonDecoder.decode(RunConfiguration.self, from: configurationData)
    } else {
        let configurationURL = URL(fileURLWithPath: "./kombucha.json")
        let configurationData = try Data(contentsOf: configurationURL)
        configuration = try jsonDecoder.decode(RunConfiguration.self, from: configurationData)
    }

    let printErrorsOnly = parsed.get(parsePrintErrorsOnly) ?? false
    let recordMode = parsed.get(parseRecordMode) ?? false

    let snapshotsURL = parsed.get(parseSnapshotsDirectoryURL).flatMap(URL.init(fileURLWithPath:)) ??
        URL(fileURLWithPath: "./__Snapshots__/")

    let workURL = parsed.get(parseWorkDirectoryURL).flatMap(URL.init(fileURLWithPath:)) ??
        URL(fileURLWithPath: "./__Work__/")
    
    
    var report: KombuchaReportMode = .none
    
    if let reporType = parsed.get(parseReportType) {
        guard reporType == "junit" else {
            throw KombuchaArgsError(error: "The type \(reporType) is not supported.")
        }
        
        guard let url = try parsed.get(parseReportOutputURL).flatMap(URL.init(fileURLWithPath:)).map(FileURL.init) else {
            throw KombuchaArgsError(error: "A URL to a filename is needed in order to save the report (--report-type)")
        }
        
        report = .junit(saveTo: url)
    }
    
    return (
        configuration: configuration,
        printErrorsOnly: printErrorsOnly,
        recordMode: recordMode,
        snapshotsURL: try FileURL(snapshotsURL),
        workURL: try FileURL(workURL),
        report: report
    )
}
