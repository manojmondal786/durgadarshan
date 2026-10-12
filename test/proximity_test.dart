import 'package:durga_darshan/models/pandal.dart';
import 'package:durga_darshan/models/proximity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

// Synthetic positions: 0.01° of latitude is about 1.11 km.
const _here = LatLng(23.0, 72.6);

Pandal _pandal(
  String id,
  double latitudeOffset, {
  VerificationStatus status = VerificationStatus.verified,
}) => Pandal(
  id: id,
  name: id,
  area: 'Test Area',
  city: 'Ahmedabad',
  latitude: _here.latitude + latitudeOffset,
  longitude: _here.longitude,
  verificationStatus: status,
);

void main() {
  test('finds pinned pandals within 3 km, nearest first', () {
    final nearby = pandalsWithin(_here, [
      _pandal('two-km', 0.02),
      _pandal('one-km', 0.01),
      _pandal('three-and-a-bit-km', 0.03),
    ]);

    expect(nearby.map((n) => n.pandal.id), ['one-km', 'two-km']);
    expect(nearby.first.meters, closeTo(1112, 5));
  });

  test('ignores pandals without a map pin', () {
    final nearby = pandalsWithin(_here, [
      _pandal('not-pinned', 0.005, status: VerificationStatus.unverified),
      const Pandal(id: 'no-coordinates', name: 'n', area: 'a', city: 'c'),
    ]);
    expect(nearby, isEmpty);
  });

  test('the radius is inclusive and adjustable', () {
    final pandals = [_pandal('one-km', 0.01)];
    expect(pandalsWithin(_here, pandals, radiusMeters: 1112.5), hasLength(1));
    expect(pandalsWithin(_here, pandals, radiusMeters: 1000), isEmpty);
  });

  test('formats distances for people', () {
    expect(formatDistance(120), '100 m');
    expect(formatDistance(960), '950 m');
    expect(formatDistance(980), '1.0 km');
    expect(formatDistance(1000), '1.0 km');
    expect(formatDistance(2449), '2.4 km');
  });
}
