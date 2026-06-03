# Guia de Operação e Deploy (workflow-guide) 🚀

Este documento descreve o fluxo de trabalho operacional e o pipeline de integração e entrega contínua (CI/CD) do **PASSWMOB**. O ecossistema utiliza o GitHub Actions para automatizar o empacotamento, a assinatura e a distribuição de novas versões (Releases) do aplicativo móvel.

---

## 🛠️ 1. Ciclo de Desenvolvimento Diário

Durante as iterações locais de desenvolvimento, a manutenção da consistência do esquema NoSQL do Hive e o isolamento de estados são críticos. Siga rigorosamente a ordem de execução abaixo antes de submeter novos blocos de código:

### Passo 1.1: Sincronização e Geração de Código Stático
Sempre que houver qualquer modificação, adição ou remoção de campos nas classes anotadas com `@HiveType` ou `@HiveField` (camada `models/`), force a regeneração dos adaptadores binários:
```powershell
dart run build_runner build --delete-conflicting-outputs

```

### Passo 1.2: Validação de Performance e Execução Local

Para testar o comportamento do aplicativo de forma fidedigna ao ambiente de produção (mitigando gargalos de renderização e garantindo o tempo correto de derivação criptográfica no dispositivo físico), execute o app sob a flag de otimização:

```powershell
flutter run --release

```

---

## 📦 2. Fluxo de Release e Publicação Automatizada

O pipeline configurado em `.github/workflows/release.yml` adota um modelo baseado em gatilhos de versionamento (*Tag-driven deployment*). O build automatizado é disparado no ecossistema do GitHub sempre que uma nova tag com o prefixo `v` (ex: `v1.0.0`) é integrada ao servidor remoto.

### Passo 2.1: Incremento de Versão do Artefato

Antes de consolidar a release, altere o arquivo de metadados `pubspec.yaml` para atualizar a versão semântica e o número incremental de build (utilizado pelo sistema operacional Android para gerenciar atualizações no dispositivo):

```yaml
version: 1.0.1+2  # Onde '1.0.1' representa a versão do app e '2' é o código único do build

```

### Passo 2.2: Consolidação do Código fonte (Git Commit)

Submeta as alterações para o branch principal (`main`):

```powershell
git add .
git commit -m "feat: descrição clara da funcionalidade ou correção"
git push origin main

```

### Passo 2.3: Disparo do Pipeline via Tag de Versionamento

Crie a tag correspondente à versão especificada no passo 2.1 e envie-a para o GitHub. Este comando atua como o gatilho direto do Actions:

```powershell
git tag v1.0.1
git push origin v1.0.1

```

---

## ⚙️ 3. Governança de Segredos (GitHub Secrets)

Para viabilizar a assinatura digital do APK do Android em ambiente de execução virtualizado e seguro (Cloud Runner), as seguintes credenciais e chaves devem estar previamente configuradas no repositório em `Settings > Secrets and variables > Actions`:

| Variável Secreta (Secret) | Descrição Técnica do Conteúdo |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | O arquivo de chave de produção `.jks` serializado e convertido para uma string em formato Base64. |
| `ANDROID_KEYSTORE_PASSWORD` | A senha global de proteção do arquivo de Keystore. |
| `ANDROID_KEY_ALIAS` | O identificador (alias) atribuído à chave privada durante a geração do JKS. |

> **💡 Procedimento para Geração do Base64 (Ambiente Windows):**
> Para codificar o seu arquivo binário de assinatura em uma string segura aceita pelo GitHub, execute no PowerShell:
> `[Convert]::ToBase64String([IO.File]::ReadAllBytes("caminho/do/seu/upload-keystore.jks"))`

---

## 📈 4. Monitoramento do Pipeline e Instalação

1. Acesse a aba **Actions** na interface web do seu repositório no GitHub.
2. Selecione o workflow correspondente ao script **"Gerar Release (Android & iOS)"**.
3. Acompanhe a esteira de execução. Assim que o indicador retornar o status de sucesso (✅), o pipeline publicará o artefato de forma automatizada.
4. O pacote final assinado (`app-release.apk`) estará disponível para download na aba **Releases** lateral do repositório, pronto para instalação e validação no seu dispositivo físico.

---

## ⚠️ Diretrizes e Restrições de Segurança

* **Isolamento de Certificados (iOS):** O build voltado ao ecossistema Apple está parametrizado estritamente para validação de integridade de compilação sintática (`--no-codesign`). O provisionamento de perfis e certificados digitais da Apple Store será acoplado em etapas futuras.
* **Vazamento de Segredos:** Nunca, sob nenhuma circunstância, adicione arquivos de chave física (`.jks`, `.keystore`) ou arquivos descritores de propriedades de credenciais (`key.properties`) ao histórico de commits do Git. O rastreamento desses artefatos deve ser gerenciado de forma exclusiva pelas variáveis de ambiente criptografadas do GitHub Actions.
* 
