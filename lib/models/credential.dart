class Credential {
  final String alias; // Necessário
  final String group; // Necessário
  final String? username; // Opcional
  final String? password; // Opcional
  final String? note; // Opcional (para App, Sistema, etc)
  final String? url; // Opcional
  final Map<String, String>?
  secrets; // Opcional (para Passkeys ou chaves extras)

  Credential({
    required this.alias,
    required this.group,
    this.username,
    this.password,
    this.note,
    this.url,
    this.secrets,
  });
}
