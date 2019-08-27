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
        
    static func generateFailure(result: CheckResult, type: String, config: SnapConfiguration) throws -> JUnit.Failure.Element {
        
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
        
        let element = JUnit.Failure.Element.new(
            withText: "\n\(queryItemInfo)\nJSON error at: \(result.context.prettyPrinted)\n\(result.message)"
            ).set(attributes: [
            JUnit.Failure.Attribute.type(text: type),
            JUnit.Failure.Attribute.message(text: message)
            ])
        
        return element
    }
    
    struct FailureInfo {
        let failureElements: [JUnit.Failure.Element]
        let failures: Int
    }
    
    static func generateFailures(results: CheckResults, config: SnapConfiguration) throws -> FailureInfo {
        let errors = try results.errors.map { try generateFailure(result: $0,type: "ERROR", config: config) }
        let warnings = try results.warnings.map { try generateFailure(result: $0,type: "WARNING", config: config) }
        let infos = try results.infos.map { try generateFailure(result: $0,type: "INFO", config: config) }
        
        return FailureInfo(
            failureElements: errors + warnings + infos,
            failures: errors.count + warnings.count + infos.count
        )
        
    }
    
    struct TestCaseInfo {
        let testCase: JUnit.TestCase.Element
        let duration: TimeInterval
        let failures: Int
    }
    
    static func generateTestCase(result: Result) throws -> TestCaseInfo {
        let time = result.endDate.timeIntervalSince(result.startDate)
        let failuresInfo = try generateFailures(results: result.checkResults, config: result.config)
        
        let element = JUnit.TestCase.Element.new().set(attributes: [
            JUnit.TestCase.Attribute.id(value: UUID()),
            JUnit.TestCase.Attribute.name(text: result.config.nameIdentifier),
            JUnit.TestCase.Attribute.time(value: time)
            ]).set(failures: failuresInfo.failureElements)
        
        return TestCaseInfo(testCase: element, duration: time, failures: failuresInfo.failures)
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
                JUnit.TestSuites.Attribute.time(value: testCasesSummary.time)
                ]).set(
                    suites: [
                        JUnit.TestSuite.Element.new().set(attributes: [
                            JUnit.TestSuite.Attribute.id(value: UUID()),
                            JUnit.TestSuite.Attribute.name(text: "Kombucha"),
                            JUnit.TestSuite.Attribute.failures(number: testCasesSummary.failures),
                            JUnit.TestSuite.Attribute.tests(number: results.count),
                            JUnit.TestSuite.Attribute.time(value: testCasesSummary.time)
                            ]).set(testCases: testCasesSummary.cases)
                    ]
            )
        ).set(version: "1.0", characterEncoding: "UTF-8")
    }
}
