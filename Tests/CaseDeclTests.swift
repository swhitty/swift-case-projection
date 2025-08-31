//
//  CaseDeclTests.swift
//  swift-case-projection
//
//  Created by Simon Whitty on 26/08/2025.
//  Copyright 2025 Simon Whitty
//
//  Distributed under the permissive MIT license
//  Get the latest version from here:
//
//  https://github.com/swhitty/swift-case-projection
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Foundation
import CaseProjection
@testable import MacroPlugin
import Testing

import SwiftSyntax
import SwiftParser

//import SwiftSyntax
//import SwiftParser
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import SwiftSyntaxMacrosGenericTestSupport

struct CaseProjectionMacroTests {

    @Test
    func fullyQualifiedName() {
        #expect(
            EnumDecl.make(from: """
               enum Foo { }
               """)?.fullyQualifiedName == "Foo"
        )
        #expect(
            EnumDecl.make(from: """
               struct Zoo {
                  enum Foo { }
               }
               """)?.fullyQualifiedName == "Zoo.Foo"
        )
        #expect(
            EnumDecl.make(from: """
               struct Zoo<Element> {
                  enum Foo { }
               }
               """)?.fullyQualifiedName == "Zoo.Foo"
        )
        #expect(
            EnumDecl.make(from: """
               extension Zoo {
                  enum Foo { }
               }
               """)?.fullyQualifiedName == "Zoo.Foo"
        )
        #expect(
            EnumDecl.make(from: """
               extension Zoo<Int> {
                  enum Foo { }
               }
               """)?.fullyQualifiedName == "Zoo<Int>.Foo"
        )
    }

    @Test
    func emptyCase() throws {
        let decl = try CaseDecl.parse("case foo")

        #expect(
            decl.projectionType == "Void?"
        )
        #expect(
            decl.projectionGetterSyntax == """
                get {
                    guard case .foo? = base else { 
                        return nil 
                    }
                    return ()
                }
            """
        )
        #expect(
            decl.projectionSetterSyntax == """
                set {
                    if newValue != nil {
                        base = .foo
                    } else if case .foo? = base {
                        base = nil
                    }
                }
            """
        )
    }

    @Test
    func singleSyntax() throws {
        let decl = try CaseDecl.parse("case foo(f: String)")

        #expect(
            decl.projectionType == "String?"
        )
        #expect(
            decl.projectionGetterSyntax == """
                get {
                    guard case let .foo(p0)? = base else { 
                        return nil 
                    }
                    return p0
                }
            """
        )
        #expect(
            decl.projectionSetterSyntax == """
                set {
                    if let newValue {
                        base = .foo(f: newValue)
                    } else if case .foo? = base {
                        base = nil
                    }
                }
            """
        )
    }

    @Test
    func tuplePairSyntax() throws {
        let decl = try CaseDecl.parse("case foo(f: String, Bool)")

        #expect(
            decl.projectionType == "(f: String, Bool)?"
        )
        #expect(
            decl.projectionGetterSyntax == """
                get {
                    guard case let .foo(p0, p1)? = base else { 
                        return nil 
                    }
                    return (p0, p1)
                }
            """
        )
        #expect(
            decl.projectionSetterSyntax == """
                set {
                    if let (f: p0, p1) = newValue {
                        base = .foo(f: p0, p1)
                    } else if case .foo? = base {
                        base = nil
                    }
                }
            """
        )
    }

    @Test
    func expands() {
        myAssertMacroExpansion(
            """
            @CaseProjection
            enum Item {
               case foo(String)
            }
            """,
            expandedSource: """
            enum Item {
               case foo(String)
            }

            extension Item: CaseProjecting {
                struct Cases: CaseProjection {
                    var foo: String? {
                        get {
                            guard case let .foo(p0)? = base else {
                                return nil
                            }
                            return p0
                        }
                        set {
                            if let newValue {
                                base = .foo(newValue)
                            } else if case .foo? = base {
                                base = nil
                            }
                        }
                    }
            
                    init(_ base: Item?) {
                        self.base = base
                    }
                    var base: Item?
                }
            }
            """,
            macros: ["CaseProjection": CaseProjectionMacro.self],
        )
    }
}

private extension CaseDecl {

    static func make(
        accessControl: AccessControl = .internal,
        name: String,
        associatedTypes: [AssociatedType] = []
    ) throws -> Self {
        fatalError()
    }

    static func parse(_ caseSource: String) throws -> Self {

        let source = """
            enum Item {
               \(caseSource)
            }
            """
        
        let tree = Parser.parse(source: source)
        guard let enumDecl = tree.statements.first?.item.as(EnumDeclSyntax.self) else {
            throw CancellationError()
        }
        let cases = try enumDecl.memberBlock.members.compactMap {
            try CaseDecl.make(from: $0)
        }

        guard let first = cases.first else {
            throw CancellationError()
        }
        return first
    }
}


func myAssertMacroExpansion(
    _ originalSource: String,
    expandedSource expectedExpandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    macros: [String: any Macro.Type],
    applyFixIts: [String]? = nil,
    fixedSource expectedFixedSource: String? = nil,
    testModuleName: String = "TestModule",
    testFileName: String = "test.swift",
    indentationWidth: Trivia = .spaces(4),
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: Int = #line,
    column: Int = #column
) {
    let macroSpecs = macros.mapValues { MacroSpec(type: $0) }
    SwiftSyntaxMacrosGenericTestSupport.assertMacroExpansion(
        originalSource,
        expandedSource: expectedExpandedSource,
        diagnostics: diagnostics,
        macroSpecs: macroSpecs,
        applyFixIts: applyFixIts,
        fixedSource: expectedFixedSource,
        testModuleName: testModuleName,
        testFileName: testFileName,
        indentationWidth: indentationWidth,
        failureHandler: { failure in
            Issue.record(
                Error(failure.message),
                sourceLocation: .init(
                    fileID: "\(fileID)",
                    filePath: "\(filePath)",
                    line: line,
                    column: column
                )
            )
        },
        fileID: "",
        filePath: filePath,
        line: UInt(line),
        column: UInt(column)
    )

    struct Error: LocalizedError {
        var errorDescription: String?
        init(_ message: String) {
            self.errorDescription = message
        }
    }
}

private extension EnumDecl {

    static func make(from source: String) -> Self? {
        let tree = Parser.parse(source: source)

        if let enumDecl = firstEnumDecl(in: tree) {
            return try? make(from: enumDecl, providingExtensionsOf: enumDecl.syntacticQualifiedTypeContext!, in: .basic(decl: enumDecl, in: tree))
        }

        return nil
    }
}

private extension SyntaxProtocol {
    /// Retrieve the qualified type for the nearest extension or name decl.
    ///
    /// For example, for `struct Foo { struct Bar {} }`, calling this on the
    /// inner struct (`Bar`) will return `Foo.Bar`.
    var syntacticQualifiedTypeContext: TypeSyntax? {
        if let ext = self.as(ExtensionDeclSyntax.self) {
            // Don't handle nested 'extension' cases - they are invalid anyway.
            return ext.extendedType.trimmed
        }

        let base = self.parent?.syntacticQualifiedTypeContext
        if let named = self.asProtocol((any NamedDeclSyntax).self) {
            if let base = base {
                return TypeSyntax(MemberTypeSyntax(baseType: base, name: named.name.trimmed))
            }
            return TypeSyntax(IdentifierTypeSyntax(name: named.name.trimmed))
        }
        return base
    }
}

func firstEnumDecl(in node: some SyntaxProtocol) -> EnumDeclSyntax? {
    if let e = node.as(EnumDeclSyntax.self) {
        return e
    }
    for child in node.children(viewMode: .all) {
        if let e = firstEnumDecl(in: child) {
            return e
        }
    }
    return nil
}

extension MacroExpansionContext where Self == BasicMacroExpansionContext {

    static func basic(decl: some SyntaxProtocol, in source: SourceFileSyntax) -> BasicMacroExpansionContext {
        BasicMacroExpansionContext(
            lexicalContext: decl.allMacroLexicalContexts(),
            sourceFiles: [source: .init(moduleName: "TestModule", fullFilePath: "Test.swift")]
        )
    }
}
