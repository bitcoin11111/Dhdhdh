import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 2)
class Subscription extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  int serverCount;

  @HiveField(4)
  String lastUpdate;

  @HiveField(5)
  bool active;

  @HiveField(6)
  String? rawContent;

  Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.serverCount = 0,
    this.lastUpdate = 'never',
    this.active = true,
    this.rawContent,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'serverCount': serverCount,
    'lastUpdate': lastUpdate,
    'active': active,
  };

  factory Subscription.fromJson(Map<String, dynamic> json) => Subscription(
    id: json['id'],
    name: json['name'],
    url: json['url'],
    serverCount: json['serverCount'] ?? 0,
    lastUpdate: json['lastUpdate'] ?? 'never',
    active: json['active'] ?? true,
    rawContent: json['rawContent'],
  );
}
