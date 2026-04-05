# PASSWMOB 🔐

**Gerenciador de Credenciais e 2FA Offline**

O **PASSWMOB** é um cofre de senhas seguro, moderno e totalmente offline, desenvolvido em Flutter. Ele foi projetado para usuários que priorizam a soberania dos dados, mantendo todas as informações sensíveis criptografadas exclusivamente no dispositivo, sem dependência de nuvens de terceiros.

-----

## 🚀 Funcionalidades

  * **Cofre Criptografado:** Armazenamento local utilizando **Hive** com criptografia **AES-256**.
  * **Autenticação 2FA (TOTP):** Gerador de códigos de verificação em duas etapas integrado (substituto para Google Authenticator).
  * **Segurança Biométrica:** Acesso protegido por biometria ou senha do dispositivo.
  * **Interface Adaptável:** Suporte completo a **Dark Mode** e design responsivo.
  * **Organização por Grupos:** Categorize suas senhas (Banking, Social Media, Work, etc).
  * **Importação/Exportação:** Backup e restauração via arquivos CSV seguindo um padrão rigoroso de segurança.
  * **Privacidade Total:** Apenas o campo *Alias* é obrigatório. Usuário, senha e notas são opcionais.

-----

## 🛠️ Tecnologias Utilizadas

  * **Framework:** [Flutter](https://flutter.dev) (v3.x)
  * **Banco de Dados:** [Hive](https://www.google.com/search?q=https://pub.dev/packages/hive) (NoSQL local rápido)
  * **Segurança:** \* `flutter_secure_storage` para chaves de criptografia.
      * `local_auth` para biometria.
      * `otp` para geração de tokens 2FA.
  * **Arquitetura:** Service-oriented architecture com gerenciamento de estado nativo.

-----

## 📥 Instalação (Desenvolvimento)

### Pré-requisitos

  * Flutter SDK instalado.
  * Android Studio / VS Code configurado.

### Passo a passo

1.  Clone o repositório:
    ```bash
    git clone https://github.com/seu-usuario/passwmob.git
    ```
2.  Instale as dependências:
    ```bash
    flutter pub get
    ```
3.  Gere os adaptadores do Hive:
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
4.  Execute o app:
    ```bash
    flutter run
    ```

-----

## 📂 Estrutura de Arquivos

```text
lib/
├── models/         # Definição do objeto Credential e Hive Adapters
├── screens/        # UI (Home, Form, Details, Setup, Login)
├── services/       # Lógica de negócio (Database, Security, OTP)
└── main.dart       # Inicialização e Gerenciamento de Temas
```

-----

## 🔒 Segurança de Dados

O PASSWMOB segue o princípio de **Zero-Knowledge**:

1.  Sua **Master Password** nunca é salva em texto puro; ela gera uma chave derivada via SHA-256.
2.  A chave de criptografia do banco de dados é armazenada no **Keystore/Keychain** do sistema operacional.
3.  O arquivo `.hive` é ilegível se extraído do dispositivo sem a chave de segurança.

-----

## 📄 Licença

Distribuído sob a licença MIT. Veja `LICENSE` para [mais informações](https://github.com/asideia/passwmob/blob/main/LICENSE).

-----

## 📧 Contato

ThazSobral - [Github](https://github.com/thazsobral)
Link do Projeto: [Github](https://github.com/asideia/passwmob)
