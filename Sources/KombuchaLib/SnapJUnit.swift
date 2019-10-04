//
//  SnapJUnit.swift
//  KombuchaLib
//
//  Created by Simon-Pierre Roy on 8/23/19.
//

import Foundation
import JUnit
import JSONCheck

public enum SnapJUnit {
    
    struct Errors: Error, CustomStringConvertible {
        var description: String { return error }
        let error: String
    }
    
    static let jsonCoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .long
        return formatter
    }()
    
    static func formatTimeMinuteSecond(time: TimeInterval) -> String {
        let minutes = Int(Int(time) / 60)
        let seconds = Int(time) % 60
        return "\(minutes)m\(seconds)s"
    }
    
    static func formatTimeMilliseconds(time: TimeInterval) -> String {
        let ms = Int(time * 1000)
        return "\(String(ms)) ms"
    }
 
    
    public struct Result {
        
        public init(startDate: Date, endDate: Date, config: SnapConfiguration, checkResults: CheckResults) {
            self.startDate = startDate
            self.endDate = endDate
            self.config = config
            self.checkResults = checkResults
        }
        
        public let startDate: Date
        public let endDate: Date
        public let config: SnapConfiguration
        public let checkResults: CheckResults
    }
        
    static func generateFailuresMessage(results: CheckResults) throws -> String {
        var output: String = ""
        
        for key in results.keys.sorted() {
            output += "\nJSON error at: \(key.prettyPrinted)\n"
            
            for error in results[key]!.errors {
                output += "ERROR: \(error)\n"
            }
            
            for warning in results[key]!.warnings {
                output += "WARNING: \(warning)\n"
            }
            
            for info in results[key]!.infos {
               output += "INFO: \(info)\n"
            }
        }
        
        return output
    }
    
    static func generateFailures(results: CheckResults, config: SnapConfiguration) throws -> JUnit.Failure.Element? {
        
        guard results.isEmpty == false else {
            return nil
        }
        
        let message: String
        let queryItemInfo: String
        
        switch config.request {
        case .graphQL(let graph):
            message = "Failure for GraphQL call (POST): \(graph.host)\(graph.path)"
            
            guard let jsonVariables =  try String(data: SnapJUnit.jsonCoder.encode(graph.queryContent.variables ?? [:]), encoding: .utf8) else {
                throw Errors(error: "Invalid string conversion for graphQL variable.")
            }
            
            let fileInfo: String
            switch graph.queryContent.query {
            case .file(let safeUrl):
                var url = safeUrl.value
                url.resolveSymlinksInPath()
                fileInfo = "Path to query: \(url.absoluteString)\n"
            case .text(let query):
                fileInfo = "Query: \(query)\n"
            }
            
            queryItemInfo = "\(fileInfo)GraphQL variables \n \(jsonVariables)"
        case .rest(let rest):
            message = "Failure to \(rest.httpMethod): \(rest.host)\(rest.path)"
            
            guard let jsonQueryItems =  try String(data: SnapJUnit.jsonCoder.encode(rest.queryItems), encoding: .utf8) else {
                throw Errors(error: "Invalid string conversion for query items.")
            }
            queryItemInfo = "Query items \n \(jsonQueryItems)"
        }
        
        let type: String = results.errors.isEmpty == false ? "ERROR" : results.warnings.isEmpty == false ? "WARNING" : "INFO"
        
        let element = try JUnit.Failure.Element.new(
            withText: "\n\(queryItemInfo)\n\(generateFailuresMessage(results: results))"
            ).set(attributes: [
                JUnit.Failure.Attribute.type(text: type),
                JUnit.Failure.Attribute.message(text: message)
                ])
        
        return element
        
    }
    
    struct TestCaseInfo {
        let testCase: JUnit.TestCase.Element
        let duration: TimeInterval
        let failures: Int
    }
    
    static func generateTestCase(result: Result) throws -> TestCaseInfo {
        
        let time = result.endDate.timeIntervalSince(result.startDate)
        let failure = try generateFailures(results: result.checkResults, config: result.config)
        
        let name: String
        
        switch result.config.request {
        case .graphQL(let graph):
            name = "\(result.config.nameIdentifier)-GraphQL-(POST)-\(graph.host)\(graph.path) "
        case .rest(let rest):
            name = "\(result.config.nameIdentifier)-REST-\(rest.httpMethod)-\(rest.host)\(rest.path) "
        }
        
        var element = JUnit.TestCase.Element.new().set(attributes: [
            JUnit.TestCase.Attribute.id(value: UUID()),
            JUnit.TestCase.Attribute.name(text: name),
            JUnit.TestCase.Attribute.time(formattedValue: formatTimeMilliseconds(time: time))
            ])
        
        if let failure = failure {
            element = element.set(failures: [failure])
        }
        
        return TestCaseInfo(testCase: element, duration: time, failures: result.checkResults.count)
    }
    
    public static func generateJUnitSuite(results: [Result]) throws -> JUnit.Report {
        
        let testCasesSummary: (failures: Int, time: TimeInterval, cases: [JUnit.TestCase.Element]) = try results
         .reduce((failures: 0,time: 0, cases:[])) { (partial, result) in
                let info = try generateTestCase(result: result)
                return (failures: partial.failures + info.failures,time: partial.time + info.duration, cases: partial.cases + [info.testCase])
        }
  
        return JUnit.Report.new().set(suites:
            JUnit.TestSuites.Element.new().set(attributes: [
                JUnit.TestSuites.Attribute.id(value: UUID()),
                JUnit.TestSuites.Attribute.name(text: "Kombucha API Testing - \(dateFormatter.string(from: Date()))"),
                JUnit.TestSuites.Attribute.failures(number: testCasesSummary.failures),
                JUnit.TestSuites.Attribute.tests(number: results.count),
                JUnit.TestSuites.Attribute.time(formattedValue: formatTimeMinuteSecond(time: testCasesSummary.time))
                ]).set(
                    suites: [
                        JUnit.TestSuite.Element.new().set(attributes: [
                            JUnit.TestSuite.Attribute.id(value: UUID()),
                            JUnit.TestSuite.Attribute.name(text: "Kombucha"),
                            JUnit.TestSuite.Attribute.failures(number: testCasesSummary.failures),
                            JUnit.TestSuite.Attribute.tests(number: results.count),
                            JUnit.TestSuite.Attribute.time(formattedValue: formatTimeMinuteSecond(time: testCasesSummary.time))
                            ]).set(testCases: testCasesSummary.cases)
                    ]
            )
        ).set(version: "1.0", characterEncoding: "UTF-8")
    }
}
