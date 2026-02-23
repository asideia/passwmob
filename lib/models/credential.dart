// lib/models/credential.dart

class Credential {
  final String id;
  final String alias;
  final String group;
  final String? username;
  final String? password; // Este será salvo criptografado!

  Credential({
    required this.id,
    required this.alias,
    required this.group,
    this.username,
    this.password,
  });
}
