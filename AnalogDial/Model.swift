import Combine
import SwiftUI

struct State {
  var speed: Double = 0
}

final class Store: ObservableObject {
  @Published var state = State()
}
