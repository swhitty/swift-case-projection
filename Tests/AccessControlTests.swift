//
//  AccessControlTests.swift
//  swift-case-projection
//
//  Created by Simon Whitty on 28/08/2025.
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
import SwiftSyntaxMacros
import SwiftSyntaxMacroExpansion

struct AccessControlTests {

    @Test
    func typeAccessControl() {
        #expect(
            AccessControl.make(from: "enum Foo { }") == .internal
        )
        #expect(
            AccessControl.make(from: "fileprivate enum Foo { }") == .fileprivate
        )
        #expect(
            AccessControl.make(from: "private enum Foo { }") == .fileprivate
        )
        #expect(
            AccessControl.make(from: "internal enum Foo { }") == .internal
        )
        #expect(
            AccessControl.make(from: "package enum Foo { }") == .package
        )
        #expect(
            AccessControl.make(from: "public enum Foo { }") == .public
        )
    }

    @Test
    func extAccessControl() {
        #expect(
            AccessControl.make(from: """
                extension Foo {
                    enum Bar { }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                fileprivate extension Foo {
                    enum Bar { }
                }
            """) == .fileprivate
        )
        #expect(
            AccessControl.make(from: """
                private extension Foo {
                    enum Bar { }
                }
            """) == .fileprivate
        )
        #expect(
            AccessControl.make(from: """
                internal extension Foo {
                    enum Bar { }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                package extension Foo {
                    enum Bar { }
                }
            """) == .package
        )
        #expect(
            AccessControl.make(from: """
                public extension Foo {
                    enum Bar { }
                }
            """) == .public
        )
    }

    @Test
    func extOverrideAccessControl() {
        #expect(
            AccessControl.make(from: """
                public extension Foo {
                    package enum Bar { }
                }
            """) == .package
        )
        #expect(
            AccessControl.make(from: """
                public extension Foo {
                    internal enum Bar { }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                public extension Foo {
                    fileprivate enum Bar { }
                }
            """) == .fileprivate
        )
        #expect(
            AccessControl.make(from: """
                public extension Foo {
                    private enum Bar { }
                }
            """) == .fileprivate
        )
    }

    @Test
    func nested() {
        #expect(
            AccessControl.make(from: """
                struct Foo {
                    enum Bar { }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                struct Foo<Element> {
                    enum Bar { }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                public struct Foo {
                    struct Bar {
                        enum Baz { }
                    }
                }
            """) == .internal
        )
        #expect(
            AccessControl.make(from: """
                public struct Foo {
                    public struct Bar {
                        public enum Baz { }
                    }
                }
            """) == .public
        )
    }
}

private extension AccessControl {

    static func make(from source: String) -> Self? {
        let tree = Parser.parse(source: source)

        if let enumDecl = firstEnumDecl(in: tree) {
            return make(attachedTo: enumDecl, in: .basic(decl: enumDecl, in: tree))
        }

        return nil
    }
}
