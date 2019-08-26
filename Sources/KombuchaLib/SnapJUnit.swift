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
    
    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .full
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
    
    static func uniqueNameForTestCase(config: SnapConfiguration) -> String {
        
        switch config.request {
        case .rest(let rest):
            return "\(config.nameIdentifier)-\(rest.httpMethod)-\(rest.host)-\(rest.path)"
        case .graphQL(let graph):
            return "\(config.nameIdentifier)-GraphQL-\(graph.host)-\(graph.path)"
        }
    }
    
    static func generateFailure(result: CheckResult, type: String) -> JUnit.Failure.Element {
        let element = JUnit.Failure.Element.new(
            withText: "\n\(result.context.prettyPrinted)\n\(result.message)"
            ).set(attributes: [
            JUnit.Failure.Attribute.type(text: type),
            JUnit.Failure.Attribute.message(text: "Api contract broken")
            ])
        return element
    }
    
    struct FailureInfo {
        let failureElements: [JUnit.Failure.Element]
        let failures: Int
    }
    
    static func generateFailures(results: CheckResults) -> FailureInfo {
        let errors = results.errors.map { generateFailure(result: $0,type: "ERROR") }
        let warnings = results.warnings.map { generateFailure(result: $0,type: "WARNING") }
        let infos = results.infos.map { generateFailure(result: $0,type: "INFO") }
        
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
    
    static func generateTestCase(result: Result) -> TestCaseInfo {
        let time = result.endDate.timeIntervalSince(result.startDate)
        let failuresInfo = generateFailures(results: result.checkResults)
        
        let element = JUnit.TestCase.Element.new().set(attributes: [
            JUnit.TestCase.Attribute.id(value: UUID()),
            JUnit.TestCase.Attribute.name(text: uniqueNameForTestCase(config: result.config)),
            JUnit.TestCase.Attribute.time(value: time)
            ]).set(failures: failuresInfo.failureElements)
        
        return TestCaseInfo(testCase: element, duration: time, failures: failuresInfo.failures)
    }
    
    public static func generateJUnitSuite(results: [Result]) -> JUnit.Report {
        
        let testCasesSummary: (failures: Int, time: TimeInterval, cases: [JUnit.TestCase.Element]) = results
         .reduce((failures: 0,time: 0, cases:[])) { (partial, result) in
                let info = generateTestCase(result: result)
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
