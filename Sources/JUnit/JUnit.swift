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
        public let rawValue: RawValue
        
        fileprivate init(_ rawValue: RawValue) {
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
        
        public static func new(withText text: String) -> Element {
            return .init(.new(withName: "failure", text: text))
        }
        
        public static func message(text: String) -> Attribute {
            return .init(.new(withName: "message", text: text))
        }
        
        public static func type(text: String) -> Attribute {
            return .init(.new(withName: "type", text: text))
        }
    }
    
    public enum TestCase {
        
        public typealias Element = Tagged<TestCase, ElementNode>
        public typealias Attribute = Tagged<TestCase, AttributeNode>
        
        public static func new() -> Element {
            return .init(.new(withName: "testcase", text: nil))
        }
        
        public static func id(value: UUID) -> Attribute {
            return .init(.new(withName: "id", text: value.uuidString))
        }
        
        public static func name(text: String) -> Attribute {
            return .init(.new(withName: "name", text: text))
        }
        
        public static func time(value: TimeInterval) -> Attribute {
            return .init(.new(withName: "time", text: String(value)))
        }
    }
    
    public enum TestSuite {
        
        public typealias Element = Tagged<TestSuite, ElementNode>
        public typealias Attribute = Tagged<TestSuite, AttributeNode>
        
        public static func new() -> Element {
            return .init(.new(withName: "testsuite", text: nil))
        }
        
        public static func id(value: UUID) -> Attribute {
            return .init(.new(withName: "id", text: value.uuidString))
        }
        
        public static func name(text: String) -> Attribute {
            return .init(.new(withName:"name", text: text))
        }
        
        public static func tests(number: Int) -> Attribute {
            return .init(.new(withName: "tests", text: String(number)))
        }
        
        public static func failures(number: Int) -> Attribute {
            return .init(.new(withName: "failures", text: String(number)))
        }
        
        public static func time(value: TimeInterval) -> Attribute {
            return .init(.new(withName: "time", text: String(value)))
        }
    }
    
    public enum TestSuites {
        
        public typealias Element = Tagged<TestSuites, ElementNode>
        public typealias Attribute = Tagged<TestSuites, AttributeNode>
        
        public static func new() -> Element {
            return .init(.new(withName: "testsuites", text: nil))
        }
        
        public static func id(value: UUID) -> Attribute {
            return .init(.new(withName: "id", text: value.uuidString))
        }
        
        public static func name(text: String) -> Attribute {
            return .init(.new(withName: "name", text: text))
        }
        
        public static func tests(number: Int) -> Attribute {
            return .init(.new(withName: "tests", text: String(number)))
        }
        
        public static func failures(number: Int) -> Attribute {
            return .init(.new(withName: "failures", text: String(number)))
        }
        
        public static func time(value: TimeInterval) -> Attribute {
            return .init(.new(withName: "time", text: String(value)))
        }
    }
}

public extension JUnit.Document {
    static func new(version: String, characterEncoding: String, suites: JUnit.TestSuites.Element) -> JUnit.Document {
        let document = XMLDocument(rootElement: suites.rawValue.value)
        document.version = version
        document.characterEncoding = characterEncoding
        return .init(document)
    }
}

public extension JUnit.ElementNode {
    fileprivate static func new(withName name: String, text: String?) -> JUnit.ElementNode {
        let element = XMLElement(kind: .element)
        element.name = name
        element.stringValue = text
        return try! .init(element)
    }
    
    fileprivate func set(attributes: [JUnit.AttributeNode]?) -> JUnit.ElementNode {
        self.value.attributes = attributes?.map { $0.value }
        return self
    }
    
    fileprivate func set(children: [JUnit.ElementNode]?) -> JUnit.ElementNode {
        self.value.setChildren(children?.map { $0.value })
        return self
    }
}

public extension JUnit.AttributeNode {
    fileprivate static func new(withName name: String, text: String?) -> JUnit.AttributeNode {
        let attribute = XMLNode(kind: .attribute)
        attribute.name = name
        attribute.stringValue = text
        return try! .init(attribute)
    }
}

public extension JUnit.Failure.Element {
    func set(attributes: [JUnit.Failure.Attribute]?) -> JUnit.Failure.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestCase.Element {
    func set(failures: [JUnit.Failure.Element]?) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(children: failures?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestCase.Attribute]?) -> JUnit.TestCase.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuite.Element {
    func set(testCases: [JUnit.TestCase.Element]?) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(children: testCases?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuite.Attribute]?) -> JUnit.TestSuite.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}

public extension JUnit.TestSuites.Element {
    func set(suites: [JUnit.TestSuite.Element]?) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(children: suites?.map { $0.rawValue } )
        return self
    }
    
    func set(attributes: [JUnit.TestSuites.Attribute]?) -> JUnit.TestSuites.Element {
        _ = self.rawValue.set(attributes: attributes?.map { $0.rawValue } )
        return self
    }
}
