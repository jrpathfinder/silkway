/// Имя и email — то, что покупатель заполняет сам, отдельно от телефона
/// (тот приходит из сессии/входа по SMS). Хранится только локально
/// (LocalKv) — бэкенд ещё не имеет ручки для профиля покупателя.
class UserProfile {
  const UserProfile({this.name, this.email});

  final String? name;
  final String? email;

  bool get isEmpty => (name == null || name!.isEmpty) && (email == null || email!.isEmpty);

  Map<String, dynamic> toJson() => {
        if (name != null && name!.isNotEmpty) 'name': name,
        if (email != null && email!.isNotEmpty) 'email': email,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        name: json['name'] as String?,
        email: json['email'] as String?,
      );
}
