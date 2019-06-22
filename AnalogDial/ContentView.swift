import SwiftUI

struct ContentView: View {
  @ObjectBinding var store: Store

  var body: some View {
    VStack {
      AnalogDial($store.state.speed)
      Text(verbatim: "\(store.state.speed)")
      Spacer()
    }
      .padding()
  }
}

struct AnalogDial: View {
  @Binding var currentValue: Double

  let minValue: Double = 0
  let maxValue: Double = 60
  let majorStep: Double = 10
  let startAngle = Angle(degrees: -220)
  let endAngle = Angle(degrees: 40)
  let backgroundColor = Color.white
  let textColor = Color.black
  let tickMarkColor = Color.black
  let handColor = Color.red
  let strokeColor = Color.black

  let majorLabels: [Double]

  init(_ value: Binding<Double>) {
    $currentValue = value
    majorLabels = Array(stride(from: minValue, through: maxValue, by: majorStep))
  }

  var body: some View {
    VStack {
      ZStack {
        // Background circle
        Circle()
          .fill(backgroundColor)
        Circle()
          .stroke(strokeColor)

        // Tick marks and labels
        ForEach(majorLabels.identified(by: \.self)) { labelValue in
          TickMark(angle: self.polarAngle(for: labelValue), color: self.tickMarkColor)
          TickMarkLabel(number: labelValue, angle: self.polarAngle(for: labelValue), color: self.textColor)
        }

        // Hand
        Hand(angle: polarAngle(for: currentValue), color: handColor)
          .animation(Animation.fluidSpring())
      }
        .aspectRatio(1, contentMode: .fit)
    }
  }

  private func polarAngle(for value: Double) -> Angle {
    let normalized = interpolate(value, min: minValue, max: maxValue)
    return startAngle + (endAngle - startAngle) * normalized
  }

  struct TickMark: View {
    var angle: Angle
    var color: Color

    var body: some View {
      GeometryReader { geometryProxy in
        Rectangle()
          .scale(x: Self.scaleFactorX, y: Self.scaleFactorY)
          .rotation(self.angle)
          .offset(self.tickMarkCoordinate(for: geometryProxy.size).cartesian)
          .fill(self.color)
      }
    }

    static let scaleFactorX: CGFloat = 0.06
    static let scaleFactorY: CGFloat = 0.01

    private func tickMarkCoordinate(for viewSize: CGSize) -> Polar {
      let radius = viewSize.width / 2
      let tickMarkWidth = viewSize.width * Self.scaleFactorX
      let insetRadius = radius - tickMarkWidth / 2
      return Polar(r: insetRadius, phi: angle)
    }

    private func tickMarkSize(for viewSize: CGSize) -> CGSize {
      return CGSize(width: viewSize.width / 20, height: viewSize.height / 40)
    }
  }

  struct TickMarkLabel: View {
    var number: Double
    var angle: Angle
    var color: Color

    var body: some View {
      GeometryReader { geometryProxy in
        Text("\(NSNumber(value: self.number), formatter: Self.labelFormatter)")
          .font(Font.system(size: self.labelFontSize(for: geometryProxy.size), design: .rounded)
            .monospacedDigit()
          )
          .foregroundColor(self.color)
          .position(x: geometryProxy.size.width / 2, y: geometryProxy.size.height / 2)
          .offset(CGSize(self.labelCoordinate(for: geometryProxy.size).cartesian))
      }
    }

    private func labelCoordinate(for viewSize: CGSize) -> Polar {
      let radius = viewSize.width / 2 * 0.75
      return Polar(r: radius, phi: angle)
    }

    private func labelFontSize(for viewSize: CGSize) -> Length {
      return viewSize.width / 14
    }

    private static let labelFormatter: NumberFormatter = {
      let f = NumberFormatter()
      f.numberStyle = .none
      f.maximumFractionDigits = 0
      return f
    }()
  }

  struct Hand: View, Animatable {
    var angle: Angle
    var color: Color

    var body: some View {
      GeometryReader { geometryProxy in
        ZStack {
          Circle()
            .scale(Self.knobScaleFactor)
            .fill(self.color)
          Rectangle()
            .scale(x: Self.scaleFactorX, y: Self.scaleFactorY)
            .offset(x: geometryProxy.size.width * Self.scaleFactorX * -(Self.pivotPosition - 0.5), y: 0)
            .rotation(self.angle)
            .fill(self.color)
        }
      }
    }

    var animatableData: Angle {
      get { return angle }
      set { angle = newValue }
    }

    static let scaleFactorX: CGFloat = 0.5
    static let scaleFactorY: CGFloat = 0.01
    /// The position of the pivot point, relative to its main axis.
    /// Must be between 0 and 1. A value of 0.5 means that the hand rotates around its center.
    static let pivotPosition: CGFloat = 0.2
    static let knobScaleFactor: CGFloat = 0.03
  }
}

#if DEBUG
struct ContentView_Previews : PreviewProvider {
  static let store = Store()

  static var previews: some View {
    ContentView(store: store)
  }
}
#endif

func interpolate(_ value: Double, min: Double, max: Double) -> Double {
  (value - min) / (max - min)
}

/// Polar coordinate
struct Polar {
  var r: Length
  var phi: Angle

  var cartesian: CGPoint {
    // x = r * cos(phi)
    // y = r * sin(phi)
    let p = phi.radians
    return CGPoint(x: r * CGFloat(cos(p)), y: r * CGFloat(sin(p)))
  }
}

extension CGSize {
  init(_ point: CGPoint) {
    self.init(width: point.x, height: point.y)
  }
}
