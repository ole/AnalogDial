import Combine
import SwiftUI

struct State {
  var speed: Double = 0
}

final class Store: BindableObject {
  var state = State() {
    didSet {
      didChange.send()
    }
  }

  let didChange = PassthroughSubject<Void, Never>()
}
