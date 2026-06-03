# Contribuindo para o PASSWMOB 🔐

Ficamos muito felizes com o seu interesse em contribuir! Sendo um gerenciador de senhas open-source e offline, revisamos as contribuições com foco extremo em segurança, performance e privacidade.

## 🧭 Como Começar

1. Faça um **Fork** do repositório.
2. Crie uma branch para sua modificação: `git checkout -b feat/minha-melhoria` ou `git checkout -b fix/correcao-bug`.
3. Siga as instruções do `SETUP_GUIDE.md` para configurar seu ambiente local.
4. Antes de commitar, certifique-se de rodar o linter do Flutter:
   ```bash
   flutter analyze
   ```

## 🔒 Diretrizes de Código e Segurança

* **Zero dependências desnecessárias:** Evite adicionar pacotes no `pubspec.yaml` que não tenham sido amplamente discutidos em Issues. Menos código de terceiros = menor superfície de ataque.
* **Logs Limpos:** Nunca envie código que faça `print()` ou `debugPrint()` de variáveis que manipulem dados sensíveis (senhas, chaves, salts, campos de texto do cofre).
* **Mudanças em Modelos:** Se alterar alguma classe com `@HiveType`, lembre-se de rodar o `build_runner` e incluir os arquivos `.g.dart` gerados no mesmo Commit.

## 📥 Enviando seu Pull Request

* Garanta que o seu PR responda a uma Issue existente.
* Preencha o modelo de Pull Request por completo.
* Todo código de criptografia ou lógica de negócios deve vir acompanhado de testes unitários ou justificativa plausível de impossibilidade.
