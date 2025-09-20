[![Build](https://github.com/swhitty/swift-case-projection/actions/workflows/build.yml/badge.svg)](https://github.com/swhitty/swift-case-projection/actions/workflows/build.yml)
[![CodeCov](https://codecov.io/gh/swhitty/swift-case-projection/graphs/badge.svg)](https://codecov.io/gh/swhitty/swift-case-projection)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2Fswift-case-projection%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/swhitty/swift-case-projection) [![Swift 6.1](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fswhitty%2Fswift-case-projection%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/swhitty/swift-case-projection)

# swift-case-projection

A Swift macro for enums that generates **case projections**, providing type-safe access to associated values via [KeyPaths](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/#Key-Path-Expression).

[Enums with associated values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/#Associated-Values) are one of Swift’s most powerful features—but the syntax [can be tricky](https://goshdarnifcaseletsyntax.com).  
`@CaseProjection` removes this friction by letting you work with enum cases directly through key paths, subscripts, and SwiftUI bindings.

---

## Installation

Add **swift-case-projection** with Swift Package Manager:

```swift
.package(url: "https://github.com/swhitty/swift-case-projection.git", from: "0.3.0")
```

Then add `"swift-case-projection"` as a dependency in your target.

---

## Example

Annotate with `@CaseProjection` to project a view of an enum with a `KeyPath` for every case:

```swift
import CaseProjection

@CaseProjection
enum Item {
    case foo
    case bar(String)
}

extension Item {
    struct CaseView {
        var foo: Void? { get set }
        var bar: String? { get set }
    }
    struct Cases {
        static var foo: WritableKeyPath<Item.CaseView, Void?> { \.foo }
        static var bar: WritableKeyPath<Item.CaseView, String?> { \.bar }   
    }
  }
}
```

### Case Checking

These key paths can then be used to check if the enum is currently in a particular case:

```swift
var item: Item = .foo

item.is(case: \.foo)       // true
item.is(case: \.bar)       // false
```

### Accessing Associated Values

Read associated values from each case:

```swift
item = .bar("Fish")

item.value(case: \.bar)    // "Fish"
item.value(case: \.foo)    // nil
```

Write associated values updating the underlying enum case:

```swift
item.set(case: \.bar, to: "Chips")
item == .bar("Chips")

item.set(case: \.foo)
item == .foo
```

When the enum is **optional**, the active case can be cleared by setting `nil`

```swift
var item: Item? = .foo

item.set(case: \.bar, to: nil)
item == .foo

item.set(case: \.foo, to: nil)
item == nil
```

Setting `nil` on an inactive case has no effect:

```swift
item = .foo

item.set(case: \.bar, to: nil)  // still .foo
item == .foo

item.set(case: \.foo, to: nil)
item == nil
```

Modify associated values in place:

```swift
var item = Item.bar("Fish")

item.modify(case: \.bar) {
    $0 = $0.uppercased()
}
item == .bar("FISH")
```

Construct a new instance of a case embedding its associated value:

```
let item = Item.make(case: \.bar, value: "Mushy Peas")
item == .bar("Mushy Peas")
```

### Subscript

A Readonly subscript also provides access to the associated value:

```swift
var item: Item = .bar("Fish")

item[case: \.bar]          // "Fish"
item[case: \.foo]          // nil
```

When the enum is **optional**, a read-write subscript can be used to set and clear associated values:

```swift
var item: Item?

item[case: \.bar] = "Chips"
item == .bar("Chips")

item[case: \.bar] = nil
item == nil
```

---

### Macro Expansion

Expanding the macro reveals the projected view of the enum with a mutable property for each case.

```swift
extension Item: CaseProjecting {
    struct CaseView: CaseProjection {
        var base: Item?
        
        init(_ base: Item?) {
            self.base = base
        }

        var foo: Void? {
            get {
                guard case .foo = base else { return nil }
                return ()
            }
            set {
                if newValue != nil {
                    base = .foo
                } else if foo != nil {
                    base = nil
                }
            }
        }

        var bar: String? {
            get {
                guard case let .bar(p0) = base else {
                    return nil
                }
                return p0
            }
            set {
                if let newBase = newValue.map(Base.bar) {
                    base = newBase
                } else if bar != nil {
                    base = nil
                }
            }
        }
    }
    
    struct Cases {
        static var foo: WritableKeyPath<Item.CaseView, Void?> { \.foo }
        static var bar: WritableKeyPath<Item.CaseView, String?> { \.bar }   
    }
}
```

Each method with a `case:` parameter accepts `CaseViewPath<Root, Value?>. Static member lookup is available for all cases:

```
let fooPath: CaseViewPath<Item, Void?> = \.foo
let barPath: CaseViewPath<Item, String?> = \.bar
```

`CaseViewPath` is a generic typealias for the underlying keypath preventing chaining into associated values:

```swift
typealias CaseViewPath<Root: CaseProjecting, Value> = KeyPath<Root.Cases.Type, WritableKeyPath<Root.CaseView, Value>>
```

```swift
item[case: \.bar?.count] ❌ Cannot convert value of type 'KeyPath...
```

Instances of these key paths can be used in all of the api to query and update the enum:

```
let fooPath: CaseViewPath<Item, Void?> = \.foo
let barPath = \Item.Cases.Type.bar

var item: Item = .foo
item.is(case: fooPath)  // true
item.is(case: barPath)  // false

let another = Item.make(case: barPath, value: "Fish")
another == .bar("Fish")
```

---


## SwiftUI Bindings

Project optional enums into SwiftUI bindings to drive presentation from associated values.

```swift
.sheet(item: $viewModel.item.unwrapping(case: \.baz)) { id in
    BazView(id: id)
}
```

Prefer stricter semantics? Use `.guarded(case:)` to allow writes only when the enum is already in that case; otherwise, assignments are ignored.

```swift
.sheet(item: $viewModel.item.guarded(case: \.baz)) { id in
    BazView(id: id)
}
```

Or trigger presentations when a case is present.

```swift
.sheet(isPresented: $viewModel.item.isPresent(case: \.baz)) {
    BazView()
}
```

When presented views are dismissed, the binding calls `wrappedValue[case: \.baz] = nil`, which clears the associated value and resets the enum to `nil` if that case was active.

---


## Credits

CaseProjection is primarily the work of [Simon Whitty](https://github.com/swhitty).

([Full list of contributors](https://github.com/swhitty/swift-case-projection/graphs/contributors))
