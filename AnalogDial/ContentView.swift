import SwiftUI

struct ContentView: View {
  var body: some View {
    AnalogDial()
      .padding()
  }
}

struct AnalogDial: View {
  var body: some View {
    Circle()
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
