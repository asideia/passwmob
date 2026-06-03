# PASSWMOB 🔐

**Gerenciador de Credenciais e Autenticador 2FA 100% Offline**

O **PASSWMOB** é um cofre de segurança moderno desenvolvido em Flutter, projetado especificamente para usuários que priorizam a **soberania absoluta de seus dados digitais**. O aplicativo opera sob a filosofia de *Zero-Knowledge* (Conhecimento Zero), mantendo todas as suas credenciais e tokens MFA encriptados localmente no dispositivo, sem qualquer dependência ou tráfego de dados com servidores de terceiros ou serviços em nuvem.

---

## 🚀 Funcionalidades Principais

* **Cofre Altamente Criptografado:** Persistência de dados local de alta performance através do banco NoSQL **Hive**, envelopado por uma camada de criptografia simétrica robusta **AES-256**.
* **Módulo TOTP Integrado:** Gerador nativo de códigos de autenticação multifator (2FA) de 6 dígitos que mudam dinamicamente a cada 30 segundos (substituto ideal para o Google Authenticator / Authy).
* **Autenticação Biométrica Flawless:** Acesso instantâneo e protegido integrado às APIs nativas do sistema operacional móvel (`Fingerprint` ou `FaceID`) via hardware seguro.
* **Privacidade Granular (Minimalista):** Alinhado com o princípio de minimização de dados, apenas o campo *Alias* (nome de identificação) é obrigatório. Campos de usuário, senha e notas adicionais são opcionais.
* **Agrupamento Dinâmico:** Organize suas chaves e acessos por categorias lógicas customizáveis (ex: *Banking*, *Social Media*, *Work*, *Personal*).
* **Backup & Restauração Descentralizados:** Importação e exportação de dados via arquivos estruturados estruturados sob validação rígida.

---

## 🛡️ Engenharia de Segurança

O design do ecossistema PASSWMOB apoia-se em camadas integradas ao hardware do dispositivo do usuário:

1. **Armazenamento Isolado de Chaves:** A chave simétrica que decifra o banco de dados nunca reside em arquivos comuns de sistema; ela é gerada e trancada dentro da área criptográfica de hardware do aparelho (**Android Keystore** ou **iOS Keychain**).
2. **Prevenção de Engenharia Reversa:** O arquivo físico `.hive` de banco de dados gravado no sandbox privado do sistema operacional permanece um bloco binário indecifrável em caso de extração ou cópia maliciosa do armazenamento do celular.
3. **Isolamento de Rede:** O aplicativo **não possui a permissão de tráfego de internet habilitada** em seus manifestos nativos, eliminando completamente qualquer vetor de vazamento de dados (*data exfiltration*).

---

## 🛠️ Tecnologias e Dependências

* **Core Framework:** [Flutter](https://flutter.dev) (v3.x)
* **NoSQL Engine:** [Hive](https://pub.dev/packages/hive) com suporte a cifras `HiveAesCipher`.
* **Hardware Intermediators:** `flutter_secure_storage` (Keystore/Keychain) e `local_auth` (Segurança Biométrica).
* **Cryptographic Services:** `pointycastle`, `encrypt`, `crypto` e `otp`.

---

## 📚 Documentação Técnica e Guias

Toda a base de conhecimento, especificações de dados e processos do projeto foram modularizados e indexados na pasta `/docs`. Consulte os links abaixo para guias aprofundados:

1. [**`1-how-it-works.md`**](./docs/1-how-it-works.md): Mapeamento conceitual e fluxograma da jornada da informação (Inicialização, Salvamento e Geração TOTP).
2. [**`2-setup-guide.md`**](./docs/2-setup-guide.md): Guia de provisionamento de SDKs e configuração do ambiente local em arquitetura multi-discos.
3. [**`3-workflow-guide.md`**](./docs/3-workflow-guide.md): Ciclo de trabalho de engenharia de software diário, tags de versão e publicação via GitHub Actions.
4. [**`4-data-dictionary.md`**](./docs/4-data-dictionary.md): Dicionário de dados, especificação técnica de atributos e regras de evolução de esquemas NoSQL.
5. [**`5-troubleshooting.md`**](./docs/5-troubleshooting.md): Diagnóstico e resolução rápida de anomalias no ambiente de compilação, Gradle e Java.

---

## 📥 Como Rodar o Projeto Localmente (Quickstart)

```powershell
# 1. Clone o repositório
git clone [https://github.com/asideia/passwmob.git](https://github.com/asideia/passwmob.git)

# 2. Navegue até a pasta do projeto
cd passwmob

# 3. Baixe as dependências do ecossistema Flutter
flutter pub get

# 4. Gere os adaptadores de dados estáticos do Hive
dart run build_runner build --delete-conflicting-outputs

# 5. Execute o aplicativo no seu dispositivo conectado
flutter run

```

---

## 🤝 Contribuição e Comunidade

O PASSWMOB é um software de código aberto distribuído sob a licença **MIT**. Contribuições voltadas à otimização de UI/UX, revisões de criptografia ou correções de bugs são extremamente bem-vindas. Antes de submeter código, leia o nosso arquivo [`CONTRIBUTING.md`](https://github.com/asideia/passwmob/blob/main/CONTRIBUTING.md).

* Criado por [ThazSobral](https://github.com/thazsobral)
* **Organização:** [AsIdeia](https://www.google.com/search?q=https://github.com/asideia)
