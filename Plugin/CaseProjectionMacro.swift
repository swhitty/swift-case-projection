//
//  CaseProjectionMacro.swift
//  swift-case-projection
//
//  Created by Simon Whitty on 19/08/2025.
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

import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

enum CaseProjectionMacro: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {

        guard let typeDecl = TypeDecl.make(from: declaration, providingExtensionsOf: type) else {
            throw Invalid("Can only be applied to enum")
        }

        let accessControl = AccessControl.make(attachedTo: declaration, in: context) ?? .internal
        let memberList = declaration.memberBlock.members

        let cases = try memberList.compactMap { member -> CaseDecl? in
            try CaseDecl.make(from: member, accessControl: accessControl)
        }

        let casesDecl = try ExtensionDeclSyntax(
            #"""
            extension \#(type.trimmed): CaseProjecting {
            \#(raw: accessControl.syntax)struct Cases: CaseProjection {
            \#(raw: cases.map(\.projectionSyntax).joined(separator: "\n\n"))
            
            \#(raw: accessControl.syntax)init(_ base: \#(raw: typeDecl.fullyQualifiedName)?) {
                self.base = base
            }
            \#(raw: accessControl.syntax)var base: \#(raw: typeDecl.fullyQualifiedName)?
            }
            }
            """#
        )

        return [
            casesDecl
        ]
    }
}

struct TypeDecl {
    var name: String
    var fullyQualifiedName: String
    var accessControl: AccessControl

    static func make(from syntax: some DeclGroupSyntax, providingExtensionsOf type: some TypeSyntaxProtocol) -> Self? {
        guard let enumDecl = syntax.as(EnumDeclSyntax.self) else {
            return nil
        }
        let accessControl = syntax.modifiers.compactMap(AccessControl.make).first
        return TypeDecl(
            name: enumDecl.name.text,
            fullyQualifiedName: TypeSyntax(type.trimmed).description,
            accessControl: accessControl ?? .internal
        )
    }
}

private struct Invalid: Error, CustomStringConvertible {
    var description: String

    init(_ message: String) {
        self.description = message
    }
}
