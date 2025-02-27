import Foundation

struct Stack<Element> {
    private var storage = [Element]()
    func peek() -> Element? { storage.last }
    mutating func push(_ element: Element) { storage.append(element)  }
    mutating func pop() -> Element? { storage.popLast() }
    func isEmpty() -> Bool {
        storage.isEmpty
    }
}
