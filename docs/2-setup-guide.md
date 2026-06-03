# Guia de Configuração do Ambiente (setup-guide) 🛠️

Este documento orienta a configuração do ambiente de desenvolvimento para o **PASSWMOB**. Visando otimização de performance e organização de disco, este guia adota uma estratégia de arquitetura multi-drive: mantendo o Sistema Operacional no SSD principal (`C:`) e alocando ferramentas pesadas, SDKs e compiladores em um volume dedicado (`E:`).

---

## 🧠 1. Visão Geral: Por que esses componentes?

A compilação e empacotamento do ecossistema Flutter móvel dependem de uma cadeia de ferramentas interconectadas. Cada componente desempenha um papel crítico no ciclo de build do projeto:

1. **Flutter SDK (Disco E:):** O motor de desenvolvimento. É responsável por traduzir o código-fonte escrito em Dart em código binário nativo.
2. **Android SDK (Disco E:):** Conjunto de bibliotecas nativas que habilita o ecossistema Flutter a interagir com os subcomponentes de hardware do dispositivo móvel (módulos de câmera para 2FA, biometria e APIs de persistência isolada). Sem ele, o empacotamento do APK final é inviabilizado.
3. **Android Platform-Tools (ADB):** Camada de comunicação ativa. O `adb` (*Android Debug Bridge*) gerencia o barramento de comunicação e o reconhecimento de dispositivos físicos conectados via interface USB.
4. **Java JDK (v17):** O ecossistema Android moderno e o motor de automação de builds (Gradle) operam sobre a Máquina Virtual Java (JVM). O projeto está estritamente atrelado ao Java 17; a utilização de outras versões resultará em falhas de compilação.
5. **C++ Build Tools (Visual Studio):** Camada nativa complementar necessária para compilação de plugins de baixo nível e utilitários internos no ambiente Windows.

---

## 🚀 2. Passo a Passo de Configuração

### Passo 2.1: Ajuste das Variáveis de Ambiente do Sistema
Para que os binários do `flutter` e do `adb` fiquem globalmente acessíveis a partir de qualquer instância de terminal no Windows, configure as variáveis globais do sistema:

1. Execute o comando `Win + R`, digite `sysdm.cpl` e pressione Enter.
2. Navegue até a aba **Avançado** e clique no botão **Variáveis de Ambiente**.
3. Na seção **Variáveis de Usuário**, selecione a variável **Path** e clique em **Editar**.
4. Insira os dois novos caminhos correspondentes à alocação no disco dedicado:
   * `E:\SDKs\flutter_windows_3.41.9-stable\flutter\bin`
   * `E:\Android\SDK\platform-tools`
5. Confirme as alterações clicando em **OK** em todas as janelas do sistema.

### Passo 2.2: Vinculação de Caminhos no Flutter
Abra uma instância do PowerShell e execute os comandos abaixo para registrar formalmente a localização dos SDKs e das IDEs no disco secundário:

```powershell
# Aponta a localização exata do SDK do Android
flutter config --android-sdk "E:\Android\SDK"

# Aponta a localização do executável do Android Studio alocado no drive de sistema
flutter config --android-studio-dir "C:\Program Files\Android\Android Studio"

```

### Passo 2.3: Provisionamento interno de ferramentas do Android SDK

Abra a interface do **Android Studio** e navegue em `Settings > Languages & Frameworks > Android SDK > SDK Tools`. Certifique-se de marcar os componentes abaixo:

* **Android SDK Command-line Tools (latest):** Componente vital para a execução e diagnóstico do utilitário `flutter doctor`.
* **Google USB Driver:** Componente de conectividade necessário para o reconhecimento e depuração em dispositivos físicos Android.
* Clique em **Apply** e aguarde o download dos pacotes.

### Passo 2.4: Validação de Licenças e Integridade

Com as variáveis de ambiente e caminhos devidamente mapeados, execute a validação das licenças de uso do Google:

```powershell
flutter doctor --android-licenses
# Pressione 'y' para consentir com todas as licenças apresentadas.

```

Para certificar-se de que a cadeia de ferramentas está íntegra e operacional, execute o diagnóstico de integridade do ambiente:

```powershell
flutter doctor

```

O console deverá apresentar o marcador do ecossistema Android validado com um check estável `[√]`.

---

## 🛠️ 3. Preparação Prática do PASSWMOB

Após o provisionamento do ambiente global, execute a rotina de saneamento e sincronização local do banco de dados na pasta do repositório:

1. **Purga de Resquícios e Estado Anterior:**

```powershell
   cd D:\projects\passwmob  # Substitua pelo caminho local do seu projeto
   flutter clean

```

2. **Resolução e Download de Dependências:**

```powershell
   flutter pub get

```

3. **Compilação e Geração de Esquemas do Hive (Criptografia):**
Como o ecossistema NoSQL do Hive depende de adaptadores estáticos indexados para operar o mapeamento das credenciais, execute o build runner para consolidar os arquivos `.g.dart` e garantir a integridade do esquema do banco de dados:

```powershell
   dart run build_runner build --delete-conflicting-outputs

```

---

## 📱 4. Provisionamento e Conectividade de Hardware

Para realizar o deploy e depuração direta em tempo de execução no dispositivo físico através do Path configurado no drive `E:`, estabeleça a ponte de comunicação do dispositivo:

1. No smartphone, navegue até as **Opções do Desenvolvedor**.
2. Alterne as chaves de configuração para desativar e reativar a **Depuração USB**.
3. Conecte o cabo USB e autorize explicitamente a assinatura RSA do computador no pop-up de segurança exibido na tela do aparelho.
4. Execute a verificação de barramento no terminal para validar o reconhecimento:

```powershell
   adb devices

```

> **💡 Dica de Engenharia:** Visando a robustez do ambiente multi-disco, certifique-se de que os binários utilitários do **Git** também estejam devidamente indexados no seu Path global do sistema operacional. Isso garante a estabilidade de rotinas locais de versionamento e execução de scripts complementares.
> 
