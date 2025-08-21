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

        let accessControl = declaration.modifiers.compactMap(AccessControl.make).first ?? .internal

        let memberList = declaration.memberBlock.members

        let cases = try memberList.compactMap { member -> CaseDecl? in
            try CaseDecl.make(from: member, accessControl: accessControl)
        }

        let casesDecl = try ExtensionDeclSyntax(
            #"""
            extension \#(type.trimmed): CaseProjecting {
            \#(raw: accessControl.syntax)struct Cases: CaseProjection {
            \#(raw: cases.map(\.extractCaseSyntax).joined(separator: "\n\n"))
            
            \#(raw: accessControl.syntax)init(_ base: \#(raw: typeDecl.fullyQualifiedName)?) {
                self.base = base
            }
            private var base: \#(raw: typeDecl.fullyQualifiedName)?
            \#(raw: accessControl.syntax)func __base() -> \#(raw: typeDecl.fullyQualifiedName)? { base }
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

struct CaseDecl {
    var name: String
    var associatedTypes: [String]
    var accessControl: AccessControl
}

enum AccessControl: String {
    case `fileprivate`
    case `private`
    case `internal`
    case `package`
    case `public`
}

extension AccessControl {
    static func make(from syntax: DeclModifierSyntax) -> Self? {
        AccessControl(rawValue: syntax.name.text)
    }

    var syntax: String {
        switch self {
        case .package, .public:
            return "\(rawValue) "
        case .private, .fileprivate, .internal:
            return ""
        }
    }
}

extension CaseDecl {
    static func make(from syntax: MemberBlockItemSyntax, accessControl: AccessControl) throws -> Self? {
        guard let caseSyntax = syntax.decl.as(EnumCaseDeclSyntax.self) else {
            return nil
        }
        guard let el = caseSyntax.elements.first else {
            return nil
        }
        let params = el.parameterClause?.parameters ?? []
        let associatedTypes = params.compactMap {
            $0.type.as(IdentifierTypeSyntax.self)?.name.text
        }

        return CaseDecl(
            name: el.name.text,
            associatedTypes: associatedTypes,
            accessControl: accessControl
        )
    }

    var extractCaseSyntax: String {
        if associatedTypes.count > 1 {
            let type = "(" + associatedTypes.joined(separator: ", ") + ")"
            let args = associatedTypes.indices
                .map { "p\($0)" }
                .joined(separator: ", ")

            return """
                \(accessControl.syntax)var \(name): \(type)? {
                    get {
                        guard case let .\(name)(\(args)) = base else { 
                            return nil 
                        }
                        return (\(args))
                    }
                    set {
                        if let newBase = newValue.map(Base.\(name)) {
                            base = newBase
                        } else if \(name) != nil {
                            base = nil
                        }
                    }
                }
                """
        } else if let type = associatedTypes.first {
            return """
                \(accessControl.syntax)var \(name): \(type)? {
                    get {
                        guard case let .\(name)(p0) = base else { 
                            return nil 
                        }
                        return p0
                    }
                    set {
                        if let newBase = newValue.map(Base.\(name)) {
                            base = newBase
                        } else if \(name) != nil {
                            base = nil
                        }
                    }
                }
                """
        } else {
            return """
                \(accessControl.syntax)var \(name): Void? {
                    get {
                        guard case .\(name) = base else { 
                            return nil 
                        }
                        return ()
                    }
                    set {
                        if newValue != nil {
                            base = .\(name)
                        } else if \(name) != nil {
                            base = nil
                        }
                    }
                }
                """
        }
    }
}

private struct Invalid: Error, CustomStringConvertible {
    var description: String

    init(_ message: String) {
        self.description = message
    }
}
