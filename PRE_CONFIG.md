Considere ter o sistema no SSD (C:) e as ferramentas pesadas/SDKs em um HD dedicado (E:), pois é uma excelente estratégia de performance e organização para um DBA e Software Engineer.

Aqui está a visão geral técnica do porquê cada peça é necessária para o **PASSWMOB** e o guia para reconfigurar tudo no seu novo layout de discos.

---

### 🧠 Visão Geral: Por que esses componentes?

Para desenvolver com Flutter, você não precisa apenas do "Flutter", mas de uma cadeia de ferramentas que conversam entre si:

1.  **Flutter SDK (Disco E:):** É o motor. Ele traduz seu código Dart em código nativo.
2.  **Android SDK (Disco E:):** É o conjunto de bibliotecas que permite ao Flutter conversar com o hardware do celular (câmera, biometria, armazenamento). Sem ele, o Flutter não consegue "empacotar" o APK.
3.  **Android Platform-Tools (ADB):** É a ponte de comunicação. O `adb` (Android Debug Bridge) é o software que identifica seu celular (ex.: Samsung M55) via USB.
4.  **Java JDK (v17):** O Android moderno e o Gradle (sistema de build) rodam sobre Java. Como configuramos seu projeto para o Java 17, o build falhará se houver outra versão.
5.  **C++ Build Tools (Visual Studio):** Necessário para o Flutter compilar plugins nativos e ferramentas de desktop, mesmo que seu foco seja Android.

---

### 🚀 Passo a Passo de Configuração

Como você já tem os arquivos baixados nos discos C: e E:, precisamos apenas "avisar" ao Windows e ao Flutter onde eles estão.

#### 1. Ajuste das Variáveis de Ambiente (O passo mais importante)
O Windows precisa saber onde o `flutter` e o `adb` estão para você usá-los em qualquer terminal.

1.  Pressione `Win + R`, digite `sysdm.cpl` e dê Enter.
2.  Vá em **Avançado > Variáveis de Ambiente**.
3.  Em **Variáveis de Usuário**, procure por **Path** e clique em Editar.
4.  Adicione estes dois novos caminhos:
    *   `E:\SDKs\flutter_windows_3.41.9-stable\flutter\bin`
    *   `E:\Android\SDK\platform-tools`
5.  Clique em OK em todas as janelas.

#### 2. Apontar os caminhos para o Flutter
Abra o terminal (PowerShell) e execute os comandos abaixo para o Flutter reconhecer seus novos caminhos no disco E:

```powershell
# Informa onde está o SDK do Android
flutter config --android-sdk "E:\Android\SDK"

# Informa onde está o Android Studio (no disco C:)
flutter config --android-studio-dir "C:\Program Files\Android\Android Studio"
```

#### 3. Instalar Componentes Internos do Android SDK
Abra o **Android Studio** e vá em `Settings > Languages & Frameworks > Android SDK > SDK Tools`:

*   Marque **Android SDK Command-line Tools (latest)** (Essencial para o `flutter doctor`).
*   Marque **Google USB Driver** (Para reconhecer o M55).
*   Clique em Apply.

#### 4. Validar Licenças e Ambiente
Agora que os caminhos estão setados, aceite os termos do Google:

```powershell
flutter doctor --android-licenses
# Digite 'y' para todas as perguntas.
```

Execute o `flutter doctor`. Ele deve mostrar o Android com um check verde `[√]`.

---

### 🛠 Preparando o Projeto PASSWMOB

Agora que o ambiente global está pronto, vamos preparar a pasta do projeto que veio do backup ou do Git:

1.  **Limpar resquícios do PC antigo:**
    ```powershell
    cd D:\projects\passwmob  # Ou o caminho onde está seu projeto
    flutter clean
    ```
2.  **Baixar dependências:**
    ```powershell
    flutter pub get
    ```
3.  **Regerar adaptadores do Hive (Criptografia):**
    Como você é DBA, sabe que o esquema do banco precisa estar sincronizado. Rode o gerador de código:
    ```powershell
    dart run build_runner build --delete-conflicting-outputs
    ```

### 📱 Conectando o Samsung M55
Com o Path configurado para o disco E:, o comando `adb devices` agora deve funcionar. Se a lista ainda vier vazia:
1.  No celular, vá em **Opções do Desenvolvedor**.
2.  Desative e ative a **Depuração USB**.
3.  Aceite o pop-up de "Confiar neste computador" que aparecerá na tela do celular.

**Dica de Ouro:** Como você tem 3 HDs, se for usar o **Git**, certifique-se de que ele também está no Path. Com essa estrutura, seu ambiente está muito mais sólido do que antes da formatação!
