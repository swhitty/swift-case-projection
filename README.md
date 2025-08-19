# swift-case-projection

Macro for Swift enums that generates enum case projections.

## Example

```swift
@CaseProjection
enum Item {
    case foo(Int)
    case bar(String, Bool)
}
```

Expands to:

```swift
extension Item {
    struct Cases {
        var base: Item
        
        init(_ base: Item) {
            self.base = base
        }

        var foo: Int? {
            guard case let .foo(p0) = base else {
                return nil
            }
            return p0
        }

        var bar: (String, Bool)? {
            guard case let .bar(p0, p1) = base else {
                return nil
            }
            return (p0, p1)
        }
    }

    var cases: Cases {
        Cases(self)
    }
}
```

The generated Cases struct exposes each associated value as an optional, so you can easily inspect enum cases in a type-safe way.

```swift
let val = Item.foo(1)

val.cases.foo == 1
val.cases.bar == nil

val.isCase(\.foo) // true
val.isCase(\.bar) // false
```

## WritableKeyPath

Optional enums include a `case` subscript with a `WritableKeyPath`

```swift
var item: Item?

item[case: \.foo] == nil
item[case: \.bar] == nil

item[case: \.foo] = 1
item[case: \.foo] == 1
item[case: \.bar] == nil

item[case: \.bar] = ("Fish", false)
item[case: \.foo] == nil
item[case: \.bar] == ("Fish", false)

item[case: \.bar] = nil
item == nil
```

## SwiftUI Bindings

Optional enums can be projected into SwiftUI `Binding`s, making it easy to drive presentation from cases.

```swift
.sheet(isPresented: $viewModel.item.resetOnFalse(\.cases.foo)) {
    FooView()
}
```

This transforms `$viewModel.item` into a `Binding<Bool>` that is true when the case .foo is present, and resets item back to nil when the sheet is dismissed.
