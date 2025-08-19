# swift-case-projection

Macro for Swift enums that generates read-only enum case projections.

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
        fileprivate let base: Item

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
        Cases(base: self)
    }

    func isCase<T>(_ kp: KeyPath<Cases, T?>) -> Bool {
        cases[keyPath: kp] != nil
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
