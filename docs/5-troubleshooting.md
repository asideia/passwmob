# Resolução de Problemas e Diagnósticos (troubleshooting) 🩺

Este documento centraliza as falhas mais comuns conhecidas no ciclo de desenvolvimento, compilação e deploy do **PASSWMOB**, bem como os procedimentos operacionais para mitigá-las. Se o seu ambiente apresentar comportamento inconsistente, consulte este guia antes de abrir uma Issue.

---

## 💥 1. Falhas no Motor de Geração de Código (`build_runner`)

Como o PASSWMOB utiliza codegen stático para os adaptadores binários do Hive, o compilador pode entrar em estado de inconsistência se houver arquivos órfãos de builds anteriores.

### Erro: `Conflicting outputs detected` ou `TypeAdapter already registered`
Isso ocorre quando você altera uma classe em `models/` e o compilador encontra um arquivo `.g.dart` antigo incompatível.

#### **Como Resolver:**
Force a limpeza do cache de compilação e execute a geração expurgando os conflitos:
```powershell
# Purga os arquivos temporários do Flutter
flutter clean

# Reconstrói a árvore de dependências
flutter pub get

# Executa o build eliminando saídas conflitantes
dart run build_runner build --delete-conflicting-outputs

```

---

## 📱 2. Problemas de Conectividade com Dispositivos Físicos (`adb`)

Se o terminal ou a IDE não listarem o seu smartphone conectado via interface USB, o subsistema de ponta de comunicação está inacessível ou sem privilégios.

### Erro: `adb devices` retorna uma lista vazia ou o dispositivo como `unauthorized`

#### **Como Resolver:**

1. **Validação de Variáveis de Ambiente:** Certifique-se de que o Path aponta corretamente para o seu HD dedicado (`E:\Android\SDK\platform-tools`).
2. **Ciclo do Servidor ADB:** Force a reinicialização do daemon do ADB via PowerShell:
```powershell
adb kill-server
adb start-server
adb devices

```


3. **Revogação de Autorizações:** No seu smartphone Android, navegue até as *Opções do Desenvolvedor*, clique em **Revogar autorizações de depuração USB**, desconecte o cabo e reconecte-o. Certifique-se de marcar a opção *"Sempre permitir a partir deste computador"* no pop-up RSA exibido na tela do aparelho.

---

## ☕ 3. Conflitos de Versão da JVM (Java Development Kit)

O motor de automação Gradle do Android é altamente sensível à versão do Java instalada no escopo global do sistema operacional. O PASSWMOB exige estritamente a **versão 17**.

### Erro: `Unsupported class file major version` ou falhas no `flutter doctor --android-licenses`

#### **Como Resolver:**

1. No terminal, verifique qual binário do Java está respondendo globalmente:
```powershell
java -version

```


2. Se o retorno indicar uma versão diferente da `17.x.x`, verifique a variável de ambiente `JAVA_HOME` no seu Windows (através do comando `sysdm.cpl`).
3. Certifique-se de apontar a variável `JAVA_HOME` para o diretório correto da JDK 17 (geralmente instalada internamente no Android Studio ou em um diretório customizado) e mova a referência dela para o topo da sua variável de usuário **Path**.

---

## 🔐 4. Falhas de Inicialização do Cofre Seguro

Erros que impedem o aplicativo de abrir ou ler o banco local geralmente estão associados à falha na comunicação com o chip de segurança do hardware móvel.

### Erro: `SecureStorageException` ou falha ao abrir o Box criptografado do Hive

#### **Como Resolver:**

* **No Emulador:** Emuladores Android sem serviços do Google ou sem uma tela de bloqueio configurada (PIN/Padrão) podem falhar ao tentar emular o Keystore seguro. Vá nas configurações do emulador e adicione uma senha de bloqueio de tela ao dispositivo virtual.
* **No Dispositivo Físico:** Certifique-se de que o hardware possui suporte ativo a biometria ou credenciais de sistema operacionais e que o aplicativo possui as permissões necessárias. Se o armazenamento seguro local for corrompido durante testes de desenvolvimento, você pode resetar o estado de sandbox do app executando:
```powershell
flutter run --clear-asset-cache
```
