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
    
    public enum IsXMLElement: Refinement {
        public typealias BaseType = XMLElement
        
        public static func isValid(_ value: XMLElement) -> Bool {
            return value.kind == .element
        }
    }
    
    public enum IsXMLAttribute: Refinement {
        public typealias BaseType = XMLNode
        
        public static func isValid(_ value: XMLNode) -> Bool {
            return value.kind == .attribute
        }
    }
    
    public typealias ElementNode = Refined<XMLElement, IsXMLElement>
    public typealias AttributeNode = Refined<XMLNode, IsXMLAttribute>
    public typealias Document = Tagged<JUnit, XMLDocument>
    
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

public extension JUnit.Document {
    
    static func new(version: String = "1.0", characterEncoding: String = "UTF-8", suites: JUnit.TestSuites.Element) -> JUnit.Document {
        let document = XMLDocument(rootElement: suites.rawValue.value)
        document.version = version
        document.characterEncoding = characterEncoding
        return .init(document)
    }
    
    func xmlString() -> String {
        return self.rawValue.xmlString
    }
}

private extension JUnit.ElementNode {
    
    static func new(withName name: String, text: String?) -> JUnit.ElementNode {
        let element = XMLElement(kind: .element)
        element.name = name
        element.stringValue = text
        return try! .init(element)
    }
    
    func set(attributes: [JUnit.AttributeNode]?) -> JUnit.ElementNode {
        self.value.attributes = attributes?.map { $0.value }
        return self
    }
    
    func set(children: [JUnit.ElementNode]?) -> JUnit.ElementNode {
        self.value.setChildren(children?.map { $0.value })
        return self
    }
}

private extension JUnit.AttributeNode {
    
    static func new(withName name: String, text: String?) -> JUnit.AttributeNode {
        let attribute = XMLNode(kind: .attribute)
        attribute.name = name
        attribute.stringValue = text
        return try! .init(attribute)
    }
}

public extension JUnit.Failure.Element {
    
    static func new(withText text: String) -> JUnit.Failure.Element {
        return .init(.new(withName: "failure", text: text))
    }
    
    func set(attributes: [JUnit.Failure.Attribute]?) -> JUnit.Failure.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.Failure.Attribute {
    
     static func message(text: String) -> JUnit.Failure.Attribute {
        return .init(.new(withName: "message", text: text))
    }
    
     static func type(text: String) -> JUnit.Failure.Attribute {
        return .init(.new(withName: "type", text: text))
    }
}

public extension JUnit.TestCase.Element {
    
    static func new() -> JUnit.TestCase.Element {
        return .init(.new(withName: "testcase", text: nil))
    }
    
    func set(failures: [JUnit.Failure.Element]?) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(children: failures?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestCase.Attribute]?) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestCase.Attribute {
    
    static func id(value: UUID) -> JUnit.TestCase.Attribute  {
        return .init(.new(withName: "id", text: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestCase.Attribute  {
        return .init(.new(withName: "name", text: text))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestCase.Attribute  {
        return .init(.new(withName: "time", text: String(value)))
    }
}

public extension JUnit.TestSuite.Element {
    
    static func new() -> JUnit.TestSuite.Element {
        return .init(.new(withName: "testsuite", text: nil))
    }
    
    func set(testCases: [JUnit.TestCase.Element]?) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(children: testCases?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuite.Attribute]?) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuite.Attribute {
    
    static func id(value: UUID) -> JUnit.TestSuite.Attribute {
        return .init(.new(withName: "id", text: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestSuite.Attribute {
        return .init(.new(withName:"name", text: text))
    }
    
    static func tests(number: Int) -> JUnit.TestSuite.Attribute {
        return .init(.new(withName: "tests", text: String(number)))
    }
    
    static func failures(number: Int) -> JUnit.TestSuite.Attribute {
        return .init(.new(withName: "failures", text: String(number)))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestSuite.Attribute {
        return .init(.new(withName: "time", text: String(value)))
    }
}

public extension JUnit.TestSuites.Element {
    
    static func new() -> JUnit.TestSuites.Element {
        return .init(.new(withName: "testsuites", text: nil))
    }
    
    func set(suites: [JUnit.TestSuite.Element]?) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(children: suites?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuites.Attribute]?) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuites.Attribute {
    
    static func id(value: UUID) -> JUnit.TestSuites.Attribute {
        return .init(.new(withName: "id", text: value.uuidString))
    }
    
    static func name(text: String) -> JUnit.TestSuites.Attribute {
        return .init(.new(withName: "name", text: text))
    }
    
    static func tests(number: Int) -> JUnit.TestSuites.Attribute {
        return .init(.new(withName: "tests", text: String(number)))
    }
    
    static func failures(number: Int) -> JUnit.TestSuites.Attribute {
        return .init(.new(withName: "failures", text: String(number)))
    }
    
    static func time(value: TimeInterval) -> JUnit.TestSuites.Attribute {
        return .init(.new(withName: "time", text: String(value)))
    }
}
