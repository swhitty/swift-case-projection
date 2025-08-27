//
//  CaseDecl.swift
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

import SwiftParser
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

struct CaseDecl {
    var name: String
    var associatedTypes: [AssociatedType]
    var accessControl: AccessControl

    struct AssociatedType {
        var label: String?
        var typeName: String

        var displayLabel: String? {
            label == "_" ? nil : label
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
        let associatedTypes: [AssociatedType] = params.compactMap {
            if let t = $0.type.as(IdentifierTypeSyntax.self)?.name.text {
                return AssociatedType(label: $0.firstName?.text, typeName: t)
            } else {
                return nil
            }
        }

        return CaseDecl(
            name: el.name.text,
            associatedTypes: associatedTypes,
            accessControl: accessControl
        )
    }

    var projectionType: String {
        if associatedTypes.count > 1 {
            let elements = associatedTypes.map {
                if let label = $0.displayLabel {
                    return "\(label): \($0.typeName)"
                } else {
                    return $0.typeName
                }
            }
            return "(" + elements.joined(separator: ", ") + ")?"
        } else if let type = associatedTypes.first {
            return "\(type.typeName)?"
        } else {
            return "Void?"
        }
    }

    var projectionGetterSyntax: String {
        if associatedTypes.isEmpty {
            return """
                get {
                    guard case .\(name)? = base else { 
                        return nil 
                    }
                    return ()
                }
            """
        } else {
            let getterList = associatedTypes.makeParameterList(includeLabels: false)
            let getterArgs = "(" + getterList + ")"
            let getterReturn = associatedTypes.count > 1 ? "(\(getterList))" : getterList
            return """
                get {
                    guard case let .\(name)\(getterArgs)? = base else { 
                        return nil 
                    }
                    return \(getterReturn)
                }
            """
        }
    }

    var projectionSetterSyntax: String {
        if associatedTypes.isEmpty {
            return """
                set {
                    if newValue != nil {
                        base = .\(name)
                    } else if case .\(name)? = base {
                        base = nil
                    }
                }
            """
        } else {
            let setterArgs = "(" + associatedTypes.makeParameterList(includeLabels: true) + ")"
            let setterLet = associatedTypes.count > 1 ? "\(setterArgs) = newValue" : "newValue"
            return """
                set {
                    if let \(setterLet) {
                        base = .\(name)\(setterArgs)
                    } else if case .\(name)? = base {
                        base = nil
                    }
                }
            """
        }
    }

    var projectionSyntax: String {
        return """
            \(accessControl.syntax)var \(name): \(projectionType) {
            \(projectionGetterSyntax)
            \(projectionSetterSyntax)
            }
            """
    }
}

extension [CaseDecl.AssociatedType] {

    func makeParameterList(includeLabels: Bool) -> String {
        if includeLabels {
            guard count > 1 else {
                let prefix = first?.displayLabel.map { "\($0): " } ?? ""
                return prefix + "newValue"
            }
            return enumerated()
                .map { idx, arg in
                    if let label = arg.displayLabel {
                        return "\(label): p\(idx)"
                    } else {
                        return "p\(idx)"
                    }
                }
                .joined(separator: ", ")
        } else {
            return indices
                .map { "p\($0)" }
                .joined(separator: ", ")
        }
    }
}

private struct Invalid: Error, CustomStringConvertible {
    var description: String

    init(_ message: String) {
        self.description = message
    }
}
