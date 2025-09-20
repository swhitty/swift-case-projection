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

@attached(extension, conformances: CaseProjecting, names: named(cases), named(isCase), named(Cases))
public macro CaseProjection() = #externalMacro(module: "MacroPlugin", type: "CaseProjectionMacro")

public protocol CaseProjecting {
    associatedtype Cases: CaseProjection where Cases.Base == Self
}

public protocol CaseProjection {
    associatedtype Base

    init(_ base: Base?)

    var base: Base? { get set }
}

public extension CaseProjecting {

    func `is`<T>(case kp: KeyPath<Cases, T?>) -> Bool {
        Cases(self)[keyPath: kp] != nil
    }

    func value<T>(case kp: KeyPath<Cases, T?>) -> T? {
        Cases(self)[keyPath: kp]
    }

    mutating func set<T>(case kp: WritableKeyPath<Cases, T?>, to value: T) {
        self = Self.make(case: kp, value: value)
    }

    mutating func set(case kp: WritableKeyPath<Cases, Void?>) {
        self = Self.make(case: kp)
    }

    @discardableResult
    mutating func modify<Value, R>(
        case kp: WritableKeyPath<Cases, Value?>,
        _ body: (inout Value) throws -> R
    ) rethrows -> R? {
        guard var v = value(case: kp) else { return nil }
        let result = try body(&v)
        set(case: kp, to: v)
        return result
    }

    subscript<T>(case kp: KeyPath<Cases, T?>) -> T? {
        get {
            Cases(self)[keyPath: kp]
        }
    }

    static func make<Value>(
        case kp: WritableKeyPath<Cases, Value?>,
        value: Value
    ) -> Self {
        var cases = Cases(nil)
        cases[keyPath: kp] = value
        return cases.base!
    }

    static func make(
        case kp: WritableKeyPath<Cases, Void?>
    ) -> Self {
        var cases = Cases(nil)
        cases[keyPath: kp] = ()
        return cases.base!
    }
}

public extension Optional where Wrapped: CaseProjecting {

    func `is`<T>(case kp: KeyPath<Wrapped.Cases, T?>) -> Bool {
        Wrapped.Cases(self)[keyPath: kp] != nil
    }

    func value<T>(case kp: KeyPath<Wrapped.Cases, T?>) -> T? {
        Wrapped.Cases(self)[keyPath: kp]
    }

    mutating func set<T>(case kp: WritableKeyPath<Wrapped.Cases, T?>, to value: T?) {
        var cases = Wrapped.Cases(self)
        cases[keyPath: kp] = value
        self = cases.base
    }

    subscript<T>(case kp: KeyPath<Wrapped.Cases, T?>) -> T? {
        get {
            Wrapped.Cases(self)[keyPath: kp]
        }
    }

    subscript<T>(case kp: WritableKeyPath<Wrapped.Cases, T?>) -> T? {
        get {
            Wrapped.Cases(self)[keyPath: kp]
        }
        set {
            var cases = Wrapped.Cases(self)
            cases[keyPath: kp] = newValue
            self = cases.base
        }
    }
}
