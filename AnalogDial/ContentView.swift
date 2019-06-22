import SwiftUI

struct ContentView: View {
  @ObjectBinding var store: Store

  var body: some View {
    VStack {
      AnalogDial($store.state.speed)
      Spacer()
    }
      .padding()
  }
}

/// A circular analog dial that can display a numeric value in a specified range (like an analog speedometer)
///
///          .───────.
///        ,'   30    `.
///      ,'             `.
///     ;   20       40   :
///     │                 │
///     │  10──────    50 │
///     :                 ;
///      ╲   0       60  ╱
///       `.           ,'
///          `───────'`
///
struct AnalogDial: View {
  @Binding var currentValue: Double

  /// The minimum value in the dial's range
  let minValue: Double = 0
  /// The maximum value in the dial's range
  let maxValue: Double = 60
  /// Step size between major tick marks
  let majorStep: Double = 10
  /// Number of subdivisions (minor ticks) between major tick marks.
  let subdivisions = 4

  /// The angle where the dial scale should start.
  ///
  /// Measured in SwiftUI's default coordinate system, i.e. 0º is "east" (positive x axis) and positive angles go clockwise.
  /// The `startAngle` must be smaller than `endAngle`. Use a negative angle to go counterclockwise from east.
  /// Examples:
  /// - 0º is "east" (straight right from the view's center)
  /// - -90º is straight up from the view's center (I avoid "north" and "south" because it's confusing. SwiftUI's y axis is
  ///   flipped, so would "north" mean up or down?)
  /// - -180º is "west" (straight left from the view's center)
  /// - -225º is the bottom-left "corner" of the dial.
  /// - 45º is the bottom-right "corner" of the dial.
  /// - 90º is straight down from the view's center, as is -270º. If you set startAngle to -270º and endAngle to 90º, the
  ///   dial would span the full circle.
  let startAngle = Angle(degrees: -225)

  /// The angle where the dial scale should end.
  ///
  /// Measured in SwiftUI's default coordinate system, i.e. 0º is "east" (positive x axis) and positive angles go clockwise.
  /// The `startAngle` must be smaller than `endAngle`. Use a negative angle to go counterclockwise from east.
  /// E.g. An angle of -180º is "west" (negative x axis) and -225º is "south-west".
  let endAngle = Angle(degrees: 45)

  // TODO: These should probably be SwiftUI modifiers (or styles?).
  /// The dial's background color.
  let backgroundColor = Color.black
  /// The color of the dial border. Use `Color.clear` to not draw a border.
  let borderColor = Color.clear
  let textColor = Color.white
  let tickMarkColor = Color.white
  /// The color of the dial's hand.
  let handColor = Color.orange

  private let majorTicks: [Double]
  private let minorTicks: [Double]

  init(_ value: Binding<Double>) {
    $currentValue = value
    // Compute the dial values where we must draw major and minor tick marks and labels.
    let majorTicks = Array(stride(from: minValue, through: maxValue, by: majorStep))
    let subdivisions = self.subdivisions
    let majorStep = self.majorStep
    let minorTicks = majorTicks.dropLast().flatMap { value -> [Double] in
      guard subdivisions > 0 else { return [] }
      let stepPerSubdivision = majorStep / Double(subdivisions)
      return Array(stride(from: value + stepPerSubdivision, to: value + majorStep, by: stepPerSubdivision))
    }
    self.majorTicks = majorTicks
    self.minorTicks = minorTicks
  }

  var body: some View {
    ZStack {
      // Background circle
      Circle()
        .fill(backgroundColor)
      Circle()
        .stroke(borderColor)

      // Tick marks and labels
      ForEach(minorTicks.identified(by: \.self)) { value in
        TickMark(angle: self.angle(for: value), style: .minor, color: self.tickMarkColor)
      }
      ForEach(majorTicks.identified(by: \.self)) { value in
        TickMark(angle: self.angle(for: value), style: .major, color: self.tickMarkColor)
        TickMarkLabel(number: value, angle: self.angle(for: value), color: self.textColor)
      }

      // Hand
      Hand(angle: angle(for: currentValue), color: handColor)
        .animation(Animation.fluidSpring())
    }
      .aspectRatio(1, contentMode: .fit)
      .accessibilityElement()
      .accessibility(visibility: .element)
      .accessibility(addTraits: [.isSummaryElement ,.updatesFrequently])
      // TODO: .accessibility(label:) doesn't seem to have any effect in Xcode 11 beta 2
      .accessibility(label: Text("Dial"))
      .accessibility(value: Text("\(currentValue)"))
  }

  /// Returns the angle that corresponds with the given value.
  private func angle(for value: Double) -> Angle {
    let normalized = interpolate(value, min: minValue, max: maxValue)
    return startAngle + (endAngle - startAngle) * normalized
  }

  struct TickMark: View {
    enum Style {
      case major
      case minor
    }

    var angle: Angle
    var style: Style
    var color: Color

    var body: some View {
      GeometryReader { geometryProxy in
        Rectangle()
          .scale(x: self.scaleFactorX, y: self.scaleFactorY)
          .rotation(self.angle)
          .offset(self.tickMarkCoordinate(for: geometryProxy.size).cartesian)
          .fill(self.color)
      }
    }

    private func tickMarkCoordinate(for viewSize: CGSize) -> Polar {
      let radius = viewSize.width / 2
      let tickMarkWidth = viewSize.width * scaleFactorX
      let insetRadius = radius - tickMarkWidth / 2
      return Polar(r: insetRadius, phi: angle)
    }

    private var scaleFactorX: CGFloat {
      switch style {
      case .major: return 0.06
      case .minor: return 0.04
      }
    }

    private var scaleFactorY: CGFloat {
      switch style {
      case .major: return 0.012
      case .minor: return 0.007
      }
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
          .position(self.labelPosition(for: geometryProxy.size))
      }
    }

    /// Computes the center point for the text label based on `self.angle`.
    private func labelPosition(for viewSize: CGSize) -> CGPoint {
      let radius = viewSize.width / 2 * 0.75
      let polar = Polar(r: radius, phi: angle)
      // Because we're using GeometryReader, it seems that the Text is normally positioned in the
      // top-left corner instead of the center. Because of this, we not only have to compute the
      // correct polar coordinate based on `angle` (which assumes the center as the origin),
      // we also have to translate the origin to the center point.
      // TODO: Understand the positioning. I tried wrapping the Text in a ZStack, but it didn't
      // change anything.
      let translationFromTopLeftToCenter = CGAffineTransform(translationX: viewSize.width / 2, y: viewSize.height / 2)
      return polar
        .cartesian
        .applying(translationFromTopLeftToCenter)
    }

    private func labelFontSize(for viewSize: CGSize) -> Length {
      // TODO: Dynamic font size based on `EnvironmentValues.sizeCategory`.
      return viewSize.width / 14
    }

    private static let labelFormatter: NumberFormatter = {
      let f = NumberFormatter()
      f.numberStyle = .none
      f.maximumFractionDigits = 0
      return f
    }()
  }

  struct Hand: View {
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

    static let scaleFactorX: CGFloat = 0.45
    static let scaleFactorY: CGFloat = 0.01
    /// The position of the hand's pivot point, relative to the hand's long axis.
    /// Must be between 0 and 1. A value of 0.5 means that the hand rotates around its center.
    static let pivotPosition: CGFloat = 0.1
    /// The relative size of the "knob" in the center of the dial (where the hand pivot is attached).
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

/// Linear interpolation between two values.
func interpolate(_ value: Double, min: Double, max: Double) -> Double {
  (value - min) / (max - min)
}

/// A polar coordinate (angle and radius).
///
/// Note: The angle of a polar coordinate (`phi`) goes counterclockwise, i.e. 0º is "east" and 90º is "north".
/// This is also true here but note that SwiftUI's y axis is flipped (positive values go down), so "north" in SwiftUI's
/// coordinate system is down. If you need an angle in the upper-right or upper-left quadrant, use a negative angle.
struct Polar {
  var r: Length
  var phi: Angle

  /// Converts a polar coordinate to its corresponding cartesian coordinate (x and y position).
  var cartesian: CGPoint {
    // x = r * cos(phi)
    // y = r * sin(phi)
    let p = phi.radians
    return CGPoint(x: r * CGFloat(cos(p)), y: r * CGFloat(sin(p)))
  }
}
