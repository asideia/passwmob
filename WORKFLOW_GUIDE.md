# 🚀 Guia de Operação e Deploy - PASSWMOB

Este guia descreve o fluxo de trabalho para desenvolvimento, versionamento e publicação automatizada utilizando GitHub Actions.

---

## 🛠 1. Ciclo de Desenvolvimento Diário

Sempre que realizar alterações no código, siga esta ordem para garantir a integridade dos dados (especialmente por conta do Hive):

1. **Atualizar modelos (se houver mudança em classes `@HiveType`):**
   ```powershell
   dart run build_runner build --delete-conflicting-outputs
   ```
2. **Testar localmente no dispositivo:**
   ```powershell
   flutter run --release
   ```

---

## 📦 2. Fluxo de Release (Publicação Automatizada)

O arquivo `release.yml` está configurado para disparar um novo build sempre que uma **tag** começando com `v` (ex: `v1.0.0`) for enviada ao GitHub.

### Passo 1: Atualizar a Versão do App
Antes de subir a tag, você **precisa** atualizar o arquivo `pubspec.yaml`:
```yaml
version: 1.0.1+2  # Onde 1.0.1 é o nome da versão e 2 é o código do build
```

### Passo 2: Commit e Push do Código
Envie suas alterações para o branch principal:
```powershell
git add .
git commit -m "feat: descrição da nova funcionalidade"
git push origin main
```

### Passo 3: Criar e Enviar a Tag
Este é o gatilho que ativa o **GitHub Actions**:
```powershell
git tag v1.0.1
git push origin v1.0.1
```

---

## ⚙️ 3. Configuração de Secrets (GitHub)

Para que o `release.yml` funcione no repositório do GitHub, as seguintes **Secrets** devem estar configuradas em `Settings > Secrets and variables > Actions`:

| Secret | Descrição |
| :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | O arquivo `.jks` convertido para Base64. |
| `ANDROID_KEYSTORE_PASSWORD` | A senha do seu arquivo de keystore. |
| `ANDROID_KEY_ALIAS` | O alias da chave definida na criação do JKS. |

> **Dica:** Para gerar o Base64 do seu arquivo de chave no Windows:
> `[Convert]::ToBase64String([IO.File]::ReadAllBytes("caminho/do/seu/upload-keystore.jks"))`

---

## 📈 4. Acompanhando o Build

1. Vá até a aba **Actions** no seu repositório do GitHub.
2. Selecione o workflow **"Gerar Release (Android & iOS)"**.
3. Quando o ícone ficar verde (✅), o APK estará disponível automaticamente na aba **Releases** do repositório para download e instalação no seu Samsung M55.

---

## ⚠️ Observações Importantes
- **iOS:** O build de iOS está configurado apenas para checagem (`--no-codesign`). Para publicar na App Store, será necessário configurar os certificados da Apple futuramente.
- **Segurança:** Nunca dê commit nos arquivos `.jks` ou `key.properties`. O Actions lida com isso através das Secrets.
```