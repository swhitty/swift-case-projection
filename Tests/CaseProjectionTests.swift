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
import Testing

struct CaseProjectionTests {

    @Test
    func projectedCase() {
        #expect(Item.foo.isCase(\.foo))
        #expect(Item.bar(1).isCase(\.bar))
        #expect(Item.baz("fish", true, 5).isCase(\.baz))
    }


    @Test
    func readonly() {
        var item: Item = .foo

        #expect(item[case: \.foo] != nil)
        #expect(item[case: \.bar] == nil)

        item = .bar(50)
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 50)
    }

    @Test
    func writeable() {
        var item: Item?

        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == nil)

        item[case: \.foo] = ()
        #expect(item[case: \.foo] != nil)
        #expect(item[case: \.bar] == nil)

        item[case: \.bar] = 10
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 10)

        item[case: \.foo] = nil
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == 10)

        item[case: \.bar] = nil
        #expect(item[case: \.foo] == nil)
        #expect(item[case: \.bar] == nil)
    }
}

@CaseProjection
public enum Item {
    case foo
    case bar(Int)
    case baz(String, Bool, Int)
}


enum Namespace { }

extension Namespace {

    @CaseProjection
    enum Item {
        case fish
        case chips(Bool)
    }
}
