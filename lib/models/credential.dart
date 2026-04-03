import 'package:hive/hive.dart';

// O nome abaixo DEVE ser exatamente o nome do arquivo + .g.dart
part 'credential.g.dart';

@HiveType(typeId: 0)
class Credential extends HiveObject {
  @HiveField(0)
  final String alias;

  @HiveField(1)
  final String? username;

  @HiveField(2)
  final String? password;

  @HiveField(3)
  final String group;

  @HiveField(4)
  final String? note;

  @HiveField(5)
  final String? url;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final String? twoFactorSecret;

  @HiveField(9)
  final String? twoFactorLabel;

  Credential({
    required this.alias,
    this.username,
    this.password,
    required this.group,
    this.note,
    this.url,
    required this.createdAt,
    required this.updatedAt,
    this.twoFactorSecret,
    this.twoFactorLabel,
  });
}
