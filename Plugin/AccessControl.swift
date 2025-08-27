//
//  AccessControl.swift
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

enum AccessControl: String {
    case `private`
    case `fileprivate`
    case `internal`
    case `package`
    case `public`
    case `open`
}

extension AccessControl {
    static func make(from syntax: DeclModifierSyntax) -> Self? {
        AccessControl(rawValue: syntax.name.text)
    }

    static func make(attachedTo declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) -> Self {
        let declAccess = declaration.modifiers.compactMap(AccessControl.make).first
        var extAccess: AccessControl?
        if let extDecl = context.lexicalContext.lazy.compactMap({ $0.as(ExtensionDeclSyntax.self) }).first {
            extAccess = extDecl.modifiers.compactMap(AccessControl.make).first
        }

        let access = declAccess ?? extAccess ?? .internal
        if access == .private {
            return .fileprivate
        } else {
            return access
        }
    }

    var syntax: String {
        switch self {
        case .package, .public:
            return "\(rawValue) "
        case .private, .fileprivate, .internal, .open:
            return ""
        }
    }
}
