import AnalogDial
import SwiftUI

struct ContentView: View {
  @ObservedObject var store: Store
  @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?
  @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?

  var body: some View {
    VStack {
      switch (horizontalSizeClass, verticalSizeClass) {
      case (.compact, .regular):
        VStack(spacing: 40) {
          Dial(currentValue: store.state.speed, maxValue: 60, majorStep: 10)
            .environment(\.colorScheme, .light)
            .accentColor(.red)
          Dial(currentValue: store.state.speed, maxValue: 40, majorStep: 5, subdivisions: 5)
            .environment(\.colorScheme, .dark)
            .accentColor(.orange)
        }

      case (.regular, .compact):
        HStack(spacing: 40) {
          Dial(currentValue: store.state.speed, maxValue: 60, majorStep: 10)
            .environment(\.colorScheme, .light)
            .accentColor(.red)
          Dial(currentValue: store.state.speed, maxValue: 40, majorStep: 5, subdivisions: 5)
            .environment(\.colorScheme, .dark)
            .accentColor(.orange)
        }

      case (.regular, .regular):
        VStack(spacing: 40) {
          HStack(spacing: 40) {
            Dial(currentValue: store.state.speed, maxValue: 60, majorStep: 10)
              .environment(\.colorScheme, .light)
              .accentColor(.red)
            Dial(currentValue: store.state.speed, maxValue: 40, majorStep: 5, subdivisions: 5)
              .environment(\.colorScheme, .dark)
              .accentColor(.orange)
          }
          HStack(spacing: 40) {
            Dial(currentValue: store.state.speed, maxValue: 60, majorStep: 20, subdivisions: 10, startAngle: .degrees(-45), endAngle: .degrees(45))
              .environment(\.colorScheme, .dark)
              .accentColor(.yellow)
            Dial(currentValue: store.state.speed, maxValue: 50, majorStep: 10, subdivisions: 10, startAngle: .degrees(-180), endAngle: .degrees(0))
              .environment(\.colorScheme, .light)
              .accentColor(.blue)
          }
        }

      case (.compact?, .compact?), (_, _):
        Dial(currentValue: store.state.speed, maxValue: 60, majorStep: 10)
          .accentColor(.red)
      }
    }
      .padding()
  }
}

// MARK: - Previews
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView(store: Store())
  }
}
