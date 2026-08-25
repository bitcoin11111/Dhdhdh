import 'package:hive/hive.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 3)
class AppSettings extends HiveObject {
  @HiveField(0)
  bool autoSwitch = true;

  @HiveField(1)
  bool fallbackEnabled = true;

  @HiveField(2)
  bool killSwitch = true;

  @HiveField(3)
  bool alwaysOn = true;

  @HiveField(4)
  int checkInterval = 60;

  @HiveField(5)
  bool checkOnStartup = true;

  @HiveField(6)
  bool ipv6Enabled = false;

  @HiveField(7)
  String theme = 'system';

  @HiveField(8)
  String language = 'ru';

  @HiveField(9)
  int selectedServerId = -1;

  @HiveField(10)
  bool tlsFragmentation = false;

  @HiveField(11)
  String remoteDNS = '8.8.8.8, 1.1.1.1';

  @HiveField(12)
  String localDNS = 'system';

  // NEW: Battery optimization
  @HiveField(13)
  bool batteryOptimization = true;

  @HiveField(14)
  bool adaptiveInterval = true;

  @HiveField(15)
  bool preferWifiChecks = false;

  // NEW: Split tunneling
  @HiveField(16)
  bool splitTunneling = false;

  // NEW: AdBlock
  @HiveField(17)
  bool adBlockEnabled = false;

  @HiveField(18)
  bool adBlockAutoUpdate = true;

  // NEW: Geo bypass
  @HiveField(19)
  List<String> enabledGeoServices = [];

  // NEW: Night mode
  @HiveField(20)
  bool nightMode = false;

  @HiveField(21)
  int nightModeStart = 23;

  @HiveField(22)
  int nightModeEnd = 7;

  // NEW: Multi-hop
  @HiveField(23)
  bool multiHop = false;

  @HiveField(24)
  int multiHopEntryId = -1;

  @HiveField(25)
  int multiHopExitId = -1;

  // NEW: Compression
  @HiveField(26)
  bool compression = false;

  // NEW: Widget
  @HiveField(27)
  bool showWidget = true;
}
