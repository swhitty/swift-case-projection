//
//  CaseProjectionTests.swift
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

import Foundation
import CaseProjection
@testable import MacroPlugin
import Testing

struct CaseProjectionTests {

    @Test
    func isCase() {
        #expect(Item.foo.is(case: \.foo))
        #expect(Item.bar(b: 1).is(case: \.bar))
        #expect(Item.baz("fish", true, c: 5).is(case: \.baz))
    }

    @Test
    func set() {
        var item: Item = .foo

        #expect(item.value(case: \.foo) != nil)
        #expect(item.value(case: \.bar) == nil)

        item.set(case: \.bar, to: 3)
        #expect(item.value(case: \.foo) == nil)
        #expect(item.value(case: \.bar) == 3)

        item.set(case: \.foo, to: ())
        #expect(item.value(case: \.foo) != nil)
        #expect(item.value(case: \.bar) == nil)
    }

    @Test
    func modify() {
        var item: Item = .bar(b: 5)

        item.modify(case: \.bar) {
            $0 += 100
        }
        #expect(item[case: \.bar] == 105)
    }

    @Test
    func readonly_subscript() {
        var item: Item = .foo

        #expect(item[case: \.foo] != nil)
        #expect(item[case: \.bar] == nil)

        item = .bar(b: 50)
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 50)
    }

    @Test
    func set_value() {
        var item: Item?

        #expect(item.value(case: \.foo) == nil)
        #expect(item.value(case: \.bar) == nil)

        item.set(case: \.bar, to: 3)
        #expect(item.value(case: \.foo) == nil)
        #expect(item.value(case: \.bar) == 3)

        item.set(case: \.foo, to: nil)
        #expect(item.value(case: \.foo) == nil)
        #expect(item.value(case: \.bar) == 3)

        item.set(case: \.bar, to: nil)
        #expect(item.value(case: \.foo) == nil)
        #expect(item.value(case: \.bar) == nil)
    }

    @Test
    func writeable_subscript() {
        var item: Item?

        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == nil)

        item[case: \.foo] = ()
        #expect(item.is(case: \.foo))
        #expect(!item.is(case: \.bar))
        #expect(item[case: \.foo] != nil)
        #expect(item[case: \.bar] == nil)

        item[case: \.bar] = 10
        #expect(!item.is(case: \.foo))
        #expect(item.is(case: \.bar))
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 10)

        item[case: \.foo] = nil
        #expect(!item.is(case: \.foo))
        #expect(item.is(case: \.bar))
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 10)

        item[case: \.bar] = nil
        #expect(!item.is(case: \.foo))
        #expect(!item.is(case: \.bar))
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == nil)
    }

    @Test
    func make() {
        var item = Item.make(case: \.bar, value: 10)
        #expect(item[case: \.bar] == 10)

        item = Item.make(case: \.foo)
        #expect(item == .foo)
    }
}

@CaseProjection
public enum Item: Equatable {
    case foo
    case bar(b: Int)
    case baz(_ s: String, Bool, c: Int)
    case zing(_ b: Float)
}

public enum Namespace { }

public extension Namespace {

    @CaseProjection
    enum Item {
        case fish
        case chips(Bool)
    }
}
