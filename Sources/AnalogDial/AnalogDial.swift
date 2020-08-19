import SwiftUI

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
/// Use the `.accentColor(_:)` modifier to set the color of the dial's hand.
public struct Dial: View {
  /// The value the dial's hand should display.
  /// Should be between `minValue` and `maxValue`.
  public let currentValue: Double
  /// The minimum value in the dial's range.
  public let minValue: Double
  /// The maximum value in the dial's range.
  public let maxValue: Double
  /// The step size between major tick marks.
  public let majorStep: Double
  /// The number of subdivisions (minor ticks) between major tick marks.
  public let subdivisions: Int

  /// The angle where the dial scale should start.
  ///
  /// Measured in SwiftUI's default coordinate system, i.e. 0° is "east" (positive x axis) and positive angles go clockwise.
  /// The `startAngle` must be smaller than `endAngle`. Use a negative angle to go counterclockwise from east.
  /// Examples:
  /// - 0° is "east" (straight right from the view's center)
  /// - -90° is straight up from the view's center (I avoid "north" and "south" because it's confusing. SwiftUI's y axis is
  ///   flipped, so would "north" mean up or down?)
  /// - -180° is "west" (straight left from the view's center)
  /// - -225° is the bottom-left "corner" of the dial.
  /// - 45° is the bottom-right "corner" of the dial.
  /// - 90° is straight down from the view's center, as is -270°. If you set startAngle to -270° and endAngle to 90°, the
  ///   dial would span the full circle.
  ///
  /// - SeeAlso: `endAngle`
  public let startAngle: Angle

  /// The angle where the dial scale should end.
  ///
  /// Measured in SwiftUI's default coordinate system, i.e. 0° is "east" (positive x axis) and positive angles go clockwise.
  /// The `endAngle` must be greater than `startAngle`. Use a negative angle to go counterclockwise from east.
  ///
  /// - SeeAlso: `startAngle`
  public let endAngle: Angle

  @Environment(\.colorScheme) private var colorScheme: ColorScheme
  private let majorTicks: [Double]
  private let minorTicks: [Double]

  /// Creates an analog dial view.
  ///
  /// - Parameters:
  ///   - currentValue: The value the dial's hand should display. Should be between `minValue`
  ///     and `maxValue`.
  ///   - minValue: The minimum value in the dial's range.
  ///   - maxValue: The maximum value in the dial's range.
  ///   - majorStep: The step size between major tick marks.
  ///   - subdivisions: The number of subdivisions (minor ticks) between major tick marks.
  ///   - startAngle: The angle where the dial scale should start.
  ///   - endAngle: The angle where the dial scale should end.
  public init(currentValue: Double, minValue: Double = 0, maxValue: Double = 100, majorStep: Double = 20, subdivisions: Int = 4, startAngle: Angle = .degrees(-225), endAngle: Angle = .degrees(45)) {
    self.currentValue = currentValue
    self.minValue = minValue
    self.maxValue = maxValue
    self.majorStep = majorStep
    self.subdivisions = subdivisions
    self.startAngle = startAngle
    self.endAngle = endAngle

    // Compute the dial values where we must draw major and minor tick marks and labels.
    let majorTicks = Array(stride(from: minValue, through: maxValue, by: majorStep))
    let minorTicks = majorTicks.dropLast().flatMap { value -> [Double] in
      guard subdivisions > 0 else { return [] }
      let stepPerSubdivision = majorStep / Double(subdivisions)
      return Array(stride(from: value + stepPerSubdivision, to: value + majorStep, by: stepPerSubdivision))
    }
    self.majorTicks = majorTicks
    self.minorTicks = minorTicks
  }

  public var body: some View {
    ZStack {
      // Background circle
      Circle()
        .fill(backgroundColor)
      Circle()
        .stroke(borderColor)

      // Tick marks and labels
      ForEach(minorTicks, id: \.self) { value in
        TickMark(angle: self.angle(for: value), style: .minor, color: self.tickMarkColor)
      }
      ForEach(majorTicks, id: \.self) { value in
        Group {
          TickMark(angle: self.angle(for: value), style: .major, color: self.tickMarkColor)
          TickMarkLabel(number: value, angle: self.angle(for: value), color: self.textColor)
        }
      }

      // Hand
      Hand(angle: angle(for: currentValue))
        .animation(.spring())
    }
    .drawingGroup()
    .aspectRatio(1, contentMode: .fit)
    .accessibilityElement(children: .ignore)
    .accessibility(addTraits: [.isSummaryElement ,.updatesFrequently])
    .accessibility(label: Text("Dial"))
    .accessibility(value: Text("\(currentValue)"))
  }

  /// Returns the angle that corresponds with the given value.
  private func angle(for value: Double) -> Angle {
    let normalized = interpolate(value, min: minValue, max: maxValue)
    return startAngle + (endAngle - startAngle) * normalized
  }

  // MARK: - Colors
  // TODO: These should probably be SwiftUI modifiers (or styles?).
  /// The dial's background color.
  var backgroundColor: Color {
    switch colorScheme {
    case .light: return .white
    case .dark: return .black
    @unknown default: return .white
    }
  }

  /// The color of the dial border. Use `Color.clear` to not draw a border.
  var borderColor: Color {
    switch colorScheme {
    case .light: return .black
    case .dark: return .clear
    @unknown default: return .black
    }
  }

  var textColor: Color {
    switch colorScheme {
    case .light: return .black
    case .dark: return .white
    @unknown default: return .black
    }
  }

  var tickMarkColor: Color {
    return textColor
  }
}

// MARK: - TickMark
extension Dial {
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
}

// MARK: - TickMarkLabel
extension Dial {
  struct TickMarkLabel: View {
    var number: Double
    var angle: Angle
    var color: Color

    var body: some View {
      GeometryReader { geometryProxy in
        Text("\(NSNumber(value: self.number), formatter: Self.labelFormatter)")
          .font(Font.system(size: self.labelFontSize(for: geometryProxy.size), design: .rounded)
            .monospacedDigit()
            .bold()
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

    private func labelFontSize(for viewSize: CGSize) -> CGFloat {
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
}

// MARK: - Hand
extension Dial {
  struct Hand: View {
    var angle: Angle

    var body: some View {
      GeometryReader { geometryProxy in
        ZStack {
          Circle()
            .scale(Self.knobScaleFactor)
            .fill(Color.accentColor)
          Rectangle()
            .scale(x: Self.scaleFactorX, y: Self.scaleFactorY)
            .offset(x: geometryProxy.size.width * Self.scaleFactorX * -(Self.pivotPosition - 0.5), y: 0)
            .rotation(self.angle)
            .fill(Color.accentColor)
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

// MARK: - Previews
struct Dial_Previews: PreviewProvider {
  static var previews: some View {
    Dial(currentValue: 20, maxValue: 60, majorStep: 10)
      .accentColor(.red)
  }
}
