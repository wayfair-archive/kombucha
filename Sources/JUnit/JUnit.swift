//
// This source file is part of Kombucha, an open source project by Wayfair
//
// Copyright (c) 2019 Wayfair, LLC.
// Licensed under the 2-Clause BSD License
//
// See LICENSE.md for license information
//

import Foundation
import Prelude

public enum JUnit {
    
    public struct Tagged<Tag, RawValue> {
        private let rawValue: RawValue
        
        private init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
    }
    
    public final class ElementNode {
        
        fileprivate init(name: String, content: String?) {
            self.name = name
            self.content = content
            self.attributes = []
            self.children = []
        }
        
        private var name: String
        private var content: String?
        private var attributes: [AttributeNode]
        private var children: [ElementNode]
        
        fileprivate func render() -> String {
            
            let attributesString = attributes.reduce("") { $0 + " " + $1.render() }
            let contentString = content ?? ""
            
            if children.isEmpty {
                return "<\(name)\(attributesString)>\(contentString)</\(name)>"
            }
            
            let childrenString = children.reduce("") { $0 + $1.render() }
            return "<\(name)\(attributesString)>\(childrenString)\(contentString)</\(name)>"
        }
    }
    
    public final class AttributeNode {
        
        fileprivate init(name: String, value: String) {
            self.name = name
            self.value = value
        }
        
        private var name: String
        private var value: String
        
        fileprivate func render() -> String {
            return "\(name)=\"\(value)\""
        }
    }
    
    public final class DocumentNode {
        
        fileprivate init() {
            self.root = nil
            self.attributes = []
        }
        
        fileprivate var root: ElementNode?
        fileprivate var attributes: [AttributeNode]
        
        fileprivate func render() -> String {
            let attributesString = attributes.reduce("") { $0 + " " + $1.render() }
            let rootString = root?.render() ?? ""
            return "<?xml\(attributesString)?>" + rootString
        }
    }
    
    public typealias  Report = Tagged<JUnit, DocumentNode>
    
    public enum Failure {
        public typealias Element = Tagged<Failure, ElementNode>
        public typealias Attribute = Tagged<Failure, AttributeNode>
    }
    
    public enum TestCase {
        public typealias Element = Tagged<TestCase, ElementNode>
        public typealias Attribute = Tagged<TestCase, AttributeNode>
    }
    
    public enum TestSuite {
        public typealias Element = Tagged<TestSuite, ElementNode>
        public typealias Attribute = Tagged<TestSuite, AttributeNode>
    }
    
    public enum TestSuites {
        public typealias Element = Tagged<TestSuites, ElementNode>
        public typealias Attribute = Tagged<TestSuites, AttributeNode>
    }
}

public extension JUnit.Report {

    static func new() -> JUnit.Report {
        return .init(.init())
    }
    
    func set(version: String, characterEncoding: String) -> JUnit.Report {
        self.rawValue.attributes = [.init(name: "version", value: version), .init(name: "encoding", value: characterEncoding)]
        return self
    }
    
    func set(suites: JUnit.TestSuites.Element) -> JUnit.Report {
        self.rawValue.root = suites.rawValue
        return self
    }
    
    func create() -> String {
        return self.rawValue.render()
    }
}

private extension JUnit.ElementNode {
    
    func set(attributes: [JUnit.AttributeNode]) -> JUnit.ElementNode {
        self.attributes = attributes
        return self
    }
    
    func set(children: [JUnit.ElementNode]) -> JUnit.ElementNode {
        self.children = children
        return self
    }
}


public extension JUnit.Failure.Element {
    
    static func new(withText text: String) -> JUnit.Failure.Element {
        return .init(.init(name: "failure", content: text))
    }
    
    func set(attributes: [JUnit.Failure.Attribute]) -> JUnit.Failure.Element {
        _ = self.rawValue.set(attributes: attributes.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.Failure.Attribute {
    
     static func message(text: String) -> JUnit.Failure.Attribute {
        return .init(.init(name: "message", value: text))
    }
    
     static func type(text: String) -> JUnit.Failure.Attribute {
        return .init(.init(name: "type", value: text))
    }
}

public extension JUnit.TestCase.Element {
    
    static func new() -> JUnit.TestCase.Element {
        return .init(.init(name: "testcase", content: nil))
    }
    
    func set(failures: [JUnit.Failure.Element]) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(children: failures.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestCase.Attribute]) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(attributes: attributes.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestCase.Attribute {
    
    static func id(value: UUID) -> JUnit.TestCase.Attribute  {
        return .init(.init(name: "id", value: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestCase.Attribute  {
        return .init(.init(name: "name", value: text))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestCase.Attribute  {
        return .init(.init(name: "time", value: String(value)))
    }
}

public extension JUnit.TestSuite.Element {
    
    static func new() -> JUnit.TestSuite.Element {
        return .init(.init(name: "testsuite", content: nil))
    }
    
    func set(testCases: [JUnit.TestCase.Element]) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(children: testCases.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuite.Attribute]) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(attributes: attributes.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuite.Attribute {
    
    static func id(value: UUID) -> JUnit.TestSuite.Attribute {
        return .init(.init(name: "id", value: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestSuite.Attribute {
        return .init(.init(name:"name", value: text))
    }
    
    static func tests(number: Int) -> JUnit.TestSuite.Attribute {
        return .init(.init(name: "tests", value: String(number)))
    }
    
    static func failures(number: Int) -> JUnit.TestSuite.Attribute {
        return .init(.init(name: "failures", value: String(number)))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestSuite.Attribute {
        return .init(.init(name: "time", value: String(value)))
    }
}

public extension JUnit.TestSuites.Element {
    
    static func new() -> JUnit.TestSuites.Element {
        return .init(.init(name: "testsuites", content: nil))
    }
    
    func set(suites: [JUnit.TestSuite.Element]) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(children: suites.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuites.Attribute]) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(attributes: attributes.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuites.Attribute {
    
    static func id(value: UUID) -> JUnit.TestSuites.Attribute {
        return .init(.init(name: "id", value: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestSuites.Attribute {
        return .init(.init(name: "name", value: text))
    }
    
    static func tests(number: Int) -> JUnit.TestSuites.Attribute {
        return .init(.init(name: "tests", value: String(number)))
    }
    
    static func failures(number: Int) -> JUnit.TestSuites.Attribute {
        return .init(.init(name: "failures", value: String(number)))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestSuites.Attribute {
        return .init(.init(name: "time", value: String(value)))
    }
}
