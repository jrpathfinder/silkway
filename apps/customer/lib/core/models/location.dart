/// Ресторан. В доменной модели это `Brand -> City -> Location`, поэтому
/// у точки есть `cityId` даже при одном городе.
class RestaurantLocation {
  const RestaurantLocation({
    required this.id,
    required this.cityId,
    required this.name,
    required this.address,
    required this.timezone,
    required this.isActive,
  });

  final String id;
  final String cityId;
  final String name;
  final String address;
  final String timezone;
  final bool isActive;

  factory RestaurantLocation.fromJson(Map<String, dynamic> json) => RestaurantLocation(
        id: json['id'] as String,
        cityId: json['cityId'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        timezone: json['timezone'] as String,
        isActive: json['isActive'] as bool,
      );
}
