import SwiftUI

/// A polar coordinate (angle and radius).
///
/// Note: The angle of a polar coordinate (`phi`) goes counterclockwise, i.e. 0º is "east" and 90º is "north".
/// This is also true here but note that SwiftUI's y axis is flipped (positive values go down), so "north" in SwiftUI's
/// coordinate system is down. If you need an angle in the upper-right or upper-left quadrant, use a negative angle.
struct Polar {
  var r: CGFloat
  var phi: Angle

  /// Converts a polar coordinate to its corresponding cartesian coordinate (x and y position).
  var cartesian: CGPoint {
    // x = r * cos(phi)
    // y = r * sin(phi)
    let p = phi.radians
    return CGPoint(x: r * CGFloat(cos(p)), y: r * CGFloat(sin(p)))
  }
}
