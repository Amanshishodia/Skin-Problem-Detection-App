
class DoctorModel {
final String name;
final String vicinity;
final double? rating;
final int? userRatingsTotal;
final bool? openNow;
final String businessStatus;
final double lat;
final double lng;
final String? photoReference;

DoctorModel({
required this.name,
required this.vicinity,
this.rating,
this.userRatingsTotal,
this.openNow,
required this.businessStatus,
required this.lat,
required this.lng,
this.photoReference,
});

factory DoctorModel.fromJson(Map<String, dynamic> json) {
return DoctorModel(
name: json['name'] ?? 'Unknown',
vicinity: json['vicinity'] ?? 'Address not available',
rating: json['rating']?.toDouble(),
userRatingsTotal: json['user_ratings_total'],
openNow: json['opening_hours']?['open_now'],
businessStatus: json['business_status'] ?? 'UNKNOWN',
lat: json['geometry']?['location']?['lat'] ?? 0.0,
lng: json['geometry']?['location']?['lng'] ?? 0.0,
photoReference: json['photos']?[0]?['photo_reference'],
);
}
}
