import 'package:hive/hive.dart';

part 'server.g.dart';

@HiveType(typeId: 1)
class Server extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String flag;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String city;

  @HiveField(4)
  final String protocol;

  @HiveField(5)
  int ping;

  @HiveField(6)
  bool alive;

  @HiveField(7)
  final int subId;

  @HiveField(8)
  final String subName;

  @HiveField(9)
  final String configJson;

  @HiveField(10)
  int lastCheck;

  @HiveField(11)
  int failCount;

  Server({
    required this.id,
    required this.flag,
    required this.name,
    required this.city,
    required this.protocol,
    this.ping = 999,
    this.alive = false,
    required this.subId,
    required this.subName,
    required this.configJson,
    this.lastCheck = 0,
    this.failCount = 0,
  });

  Server copyWith({
    int? ping,
    bool? alive,
    int? lastCheck,
    int? failCount,
  }) {
    return Server(
      id: id,
      flag: flag,
      name: name,
      city: city,
      protocol: protocol,
      ping: ping ?? this.ping,
      alive: alive ?? this.alive,
      subId: subId,
      subName: subName,
      configJson: configJson,
      lastCheck: lastCheck ?? this.lastCheck,
      failCount: failCount ?? this.failCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'flag': flag,
    'name': name,
    'city': city,
    'protocol': protocol,
    'ping': ping,
    'alive': alive,
    'subId': subId,
    'subName': subName,
    'configJson': configJson,
    'lastCheck': lastCheck,
    'failCount': failCount,
  };

  factory Server.fromJson(Map<String, dynamic> json) => Server(
    id: json['id'],
    flag: json['flag'],
    name: json['name'],
    city: json['city'],
    protocol: json['protocol'],
    ping: json['ping'] ?? 999,
    alive: json['alive'] ?? false,
    subId: json['subId'],
    subName: json['subName'],
    configJson: json['configJson'],
    lastCheck: json['lastCheck'] ?? 0,
    failCount: json['failCount'] ?? 0,
  );
}
