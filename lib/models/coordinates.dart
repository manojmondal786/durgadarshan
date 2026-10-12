/// Range checks for WGS 84 latitude and longitude in decimal degrees.
abstract final class Coordinates {
  static bool isValidLatitude(double? value) =>
      value != null && value.isFinite && value >= -90 && value <= 90;

  static bool isValidLongitude(double? value) =>
      value != null && value.isFinite && value >= -180 && value <= 180;

  static bool isValidPair(double? latitude, double? longitude) =>
      isValidLatitude(latitude) && isValidLongitude(longitude);
}
