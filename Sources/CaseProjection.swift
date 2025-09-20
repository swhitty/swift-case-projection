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

@attached(extension, conformances: CaseProjecting, names: named(cases), named(CaseView), named(Cases))
public macro CaseProjection() = #externalMacro(module: "MacroPlugin", type: "CaseProjectionMacro")

public protocol CaseProjecting {
    associatedtype CaseView: CaseProjection where CaseView.Base == Self
    associatedtype Cases
}

public protocol CaseProjection {
    associatedtype Base: CaseProjecting where Base.CaseView == Self

    init(_ base: Base?)

    var base: Base? { get set }
}

public struct Case<Root: CaseProjecting, Value> {
    public let keyPath: WritableKeyPath<Root.CaseView, Value>

    public init(keyPath: WritableKeyPath<Root.CaseView, Value>) {
        self.keyPath = keyPath
    }
}

public typealias CaseViewPath<Root: CaseProjecting, Value> = KeyPath<Root.Cases.Type, WritableKeyPath<Root.CaseView, Value>>

public extension CaseProjection {

    subscript<T>(case kp: CaseViewPath<Base, T?>) -> T? {
        get {
            self[keyPath: Base.Cases.self[keyPath: kp]]
        }
        set {
            self[keyPath: Base.Cases.self[keyPath: kp]] = newValue
        }
    }
}


public extension CaseProjecting {

    func `is`<T>(case kp: CaseViewPath<Self, T?>) -> Bool {
        CaseView(self)[case: kp] != nil
    }

    func value<T>(case kp: CaseViewPath<Self, T?>) -> T? {
        CaseView(self)[case: kp]
    }

    mutating func set<T>(case kp: CaseViewPath<Self, T?>, to value: T) {
        self = Self.make(case: kp, value: value)
    }

    mutating func set(case kp: CaseViewPath<Self, Void?>) {
        self = Self.make(case: kp)
    }

    @discardableResult
    mutating func modify<Value, R>(
        case kp: CaseViewPath<Self, Value?>,
        _ body: (inout Value) throws -> R
    ) rethrows -> R? {
        guard var v = value(case: kp) else { return nil }
        let result = try body(&v)
        set(case: kp, to: v)
        return result
    }

    subscript<T>(case kp: CaseViewPath<Self, T?>) -> T? {
        get {
            CaseView(self)[case: kp]
        }
    }

    static func make<Value>(
        case kp: CaseViewPath<Self, Value?>,
        value: Value
    ) -> Self {
        var view = CaseView(nil)
        view[case: kp] = value
        return view.base!
    }

    static func make(
        case kp: CaseViewPath<Self, Void?>
    ) -> Self {
        var view = CaseView(nil)
        view[case: kp] = ()
        return view.base!
    }
}

public extension Optional where Wrapped: CaseProjecting {

    func `is`<T>(case kp: CaseViewPath<Wrapped, T?>) -> Bool {
        Wrapped.CaseView(self)[case: kp] != nil
    }

    func value<T>(case kp: CaseViewPath<Wrapped, T?>) -> T? {
        Wrapped.CaseView(self)[case: kp]
    }

    mutating func set<T>(case kp: CaseViewPath<Wrapped, T?>, to value: T?) {
        var cases = Wrapped.CaseView(self)
        cases[case: kp] = value
        self = cases.base
    }

    subscript<T>(case kp: CaseViewPath<Wrapped, T?>) -> T? {
        get {
            Wrapped.CaseView(self)[case: kp]
        }
        set {
            var cases = Wrapped.CaseView(self)
            cases[case: kp] = newValue
            self = cases.base
        }
    }
}
