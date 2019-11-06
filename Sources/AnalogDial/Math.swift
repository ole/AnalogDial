/// Linear interpolation between two values.
func interpolate(_ value: Double, min: Double, max: Double) -> Double {
  (value - min) / (max - min)
}
