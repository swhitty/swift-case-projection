//
//  CaseProjection.swift
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

#if canImport(SwiftUI)

import SwiftUI

public extension Binding where Value: Sendable {

    func resetOnNil<Wrapped, R>(_ transform: @escaping @Sendable (Wrapped) -> R?) -> Binding<R?> where Value == Wrapped? {
        Binding<R?> {
            guard let wrappedValue else { return nil }
            return transform(wrappedValue)
        } set: {
            guard $0 == nil,
                  let val = wrappedValue,
                  transform(val) != nil else {
                return
            }
            wrappedValue = .none
        }
    }

    func resetOnFalse<Wrapped, R>(_ transform: @escaping @Sendable (Wrapped) -> R?) -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool> {
            guard let wrappedValue else { return false }
            return transform(wrappedValue) != nil
        } set: {
            guard $0 == false,
                  let val = wrappedValue,
                  transform(val) != nil else {
                return
            }
            wrappedValue = .none
        }
    }
}

#endif
