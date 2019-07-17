import Combine
import SwiftUI

struct State {
  var speed: Double = 0
}

final class Store: BindableObject {
  var state = State() {
    willSet {
      willChange.send()
    }
  }

  let willChange = PassthroughSubject<Void, Never>()
}
