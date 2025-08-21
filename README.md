# swift-case-projection

A Swift macro for enums that generates **case projections**, providing type-safe access to associated values via [KeyPaths](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/expressions/#Key-Path-Expression).

[Enums with associated values](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/enumerations/#Associated-Values) are one of Swift’s most powerful features—but the syntax [can be tricky](https://goshdarnifcaseletsyntax.com).  
`@CaseProjection` removes this friction by letting you work with enum cases directly through key paths, subscripts, and SwiftUI bindings.

---

## Installation

Add **swift-case-projection** with Swift Package Manager:

```swift
.package(url: "https://github.com/swhitty/swift-case-projection.git", from: "0.1.0")
```

Then add `"swift-case-projection"` as a dependency in your target.

---

## Example

Annotate your enum with `@CaseProjection` to enable projections:

```swift
import CaseProjection

@CaseProjection
enum Item {
    case foo
    case bar(String)
}
```

### Case Checking

```swift
var item: Item = .foo

item.isCase(\.foo)   // true
item.isCase(\.bar)   // false
```

### Accessing Associated Values

You can read associated values from each case using the `case:` subscript:

```swift
item = .bar("Fish")

item[case: \.bar]    // "Fish"
item[case: \.foo]    // nil
```

### Writable Subscript for Optionals

When the enum is **optional**, you can set or clear cases directly:

```swift
var item: Item?

item[case: \.bar] = "Chips"
item == .bar("Chips")

item[case: \.bar] = nil
item == nil
```

Setting `nil` on an inactive case has no effect:

```swift
item = .foo

item[case: \.bar] = nil   // still .foo
item == .foo

item[case: \.foo] = nil
item == nil
```

---

### Macro Expansion

Expanding the macro reveals the projected view of the enum with a mutable property for each case.

```swift
extension Item {
    struct Cases {
        var base: Item
        
        init(_ base: Item) {
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
}
```

When using case key paths like `item[case: \.foo]` the type is rooted in this `Cases` projection.

```
let fooPath = \Item.Cases.foo
let barPath = \Item.Cases.bar

var item: Item = .foo
item.isCase(fooPath)  // true
item.isCase(barPath)  // false
```

---


## SwiftUI Bindings

Optional enums can be projected into SwiftUI bindings, making it easy to drive view presentation from associated values.

```swift
.sheet(item: $viewModel.item.unwrapping(case: \.baz)) {
    BazView(id: $0)
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
