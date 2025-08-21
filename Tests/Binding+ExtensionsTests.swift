//
//  Binding+ExtensionsTests.swift
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
import CaseProjection
import Testing

@MainActor
struct BindingExtensionsTests {

    @Test
    func unwrappingUpdates() {
        // given
        let mock = MockBinding(value: Node.foo("Fish"))
        let fooBinding = mock.$value.unwrapping(case: \.foo)
        let barBinding = mock.$value.unwrapping(case: \.bar)

        // then
        #expect(fooBinding.wrappedValue == "Fish")
        #expect(barBinding.wrappedValue == nil)

        // when
        mock.value = .bar(42)

        // then
        #expect(fooBinding.wrappedValue == nil)
        #expect(barBinding.wrappedValue == 42)

        // when
        mock.value = nil

        // then
        #expect(fooBinding.wrappedValue == nil)
        #expect(barBinding.wrappedValue == nil)
    }

    @Test
    func isPresentUpdates() {
        // given
        let mock = MockBinding(value: Node.foo("Fish"))
        let fooBinding = mock.$value.isPresent(case: \.foo)
        let barBinding = mock.$value.isPresent(case: \.bar)

        // then
        #expect(fooBinding.wrappedValue == true)
        #expect(barBinding.wrappedValue == false)

        // when
        mock.value = .bar(42)

        // then
        #expect(fooBinding.wrappedValue == false)
        #expect(barBinding.wrappedValue == true)

        // when
        mock.value = nil

        // then
        #expect(fooBinding.wrappedValue == false)
        #expect(barBinding.wrappedValue == false)
    }

    @Test
    func unwrappingResetsOnNil() {
        // given
        let mock = MockBinding(value: Node.foo("Fish"))
        let fooBinding = mock.$value.unwrapping(case: \.foo)
        let barBinding = mock.$value.unwrapping(case: \.bar)

        // then
        #expect(fooBinding.wrappedValue == "Fish")
        #expect(barBinding.wrappedValue == nil)

        // when
        barBinding.wrappedValue = nil

        // then
        #expect(fooBinding.wrappedValue == "Fish")
        #expect(barBinding.wrappedValue == nil)

        // when
        fooBinding.wrappedValue = nil

        // then
        #expect(fooBinding.wrappedValue == nil)
        #expect(barBinding.wrappedValue == nil)
    }

    @Test
    func isPresentResetsOnFalse() {
        // given
        let mock = MockBinding(value: Node.foo("Fish"))
        let fooBinding = mock.$value.isPresent(case: \.foo)
        let barBinding = mock.$value.isPresent(case: \.bar)

        // then
        #expect(fooBinding.wrappedValue == true)
        #expect(barBinding.wrappedValue == false)

        // when
        barBinding.wrappedValue = false

        // then
        #expect(fooBinding.wrappedValue == true)
        #expect(barBinding.wrappedValue == false)

        // when
        fooBinding.wrappedValue = false

        // then
        #expect(fooBinding.wrappedValue == false)
        #expect(barBinding.wrappedValue == false)
    }
}

@CaseProjection
enum Node {
    case foo(String)
    case bar(Int)
}

@MainActor
final class MockBinding<Value> {

    @ProjectedBinding
    var value: Value?

    init(value: Value) {
        self.storage = value
        self._value.binding = Binding { [weak self] in
            self?.storage
        } set: { [weak self] in
            self?.storage = $0
        }
    }

    private var storage: Value?
}

extension MockBinding {
    @propertyWrapper
    struct ProjectedBinding {
        fileprivate var binding: Binding<Value?>!

        var projectedValue: Binding<Value?> {
            binding!
        }

        var wrappedValue: Value? {
            get { binding.wrappedValue }
            set { binding.wrappedValue = newValue }
        }

        init(wrappedValue: Value?) { }
    }
}
#endif
