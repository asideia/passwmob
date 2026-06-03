# Dicionário de Dados e Esquema local (data-dictionary) 🗃️

Este documento descreve a arquitetura de persistência de dados do **PASSWMOB**. O aplicativo utiliza o **Hive**, um banco de dados NoSQL de chave-valor rápido e leve escrito puramente em Dart. Como o Hive opera sem um esquema SQL rígido, este dicionário serve como a especificação formal de dados para manter a integridade transacional e a compatibilidade entre atualizações de versão do app.

---

## 🧠 1. Estrutura de Armazenamento (Boxes)

No Hive, os dados são organizados em estruturas chamadas **Boxes** (equivalentes a tabelas ou coleções). No PASSWMOB, operamos com o seguinte arranjo:

| Nome do Box | Modo de Acesso | Estrutura Interna (Tipo) | Descrição Técnica |
| :--- | :--- | :--- | :--- |
| `credentials_box` | 🔒 Criptografado (AES-256) | Chave: `String` (UUID) <br>Valor: `Credential` (Objeto) | Armazena o cofre principal contendo as senhas, usuários, notas e chaves secretas de 2FA. |

> **Nota de Segurança:** O arquivo físico gerado no disco do dispositivo (`credentials_box.hive`) passa por um processo de encriptação de blocos em nível de bytes via `HiveAesCipher` antes de ser persistido, tornando o arquivo completamente ilegível em caso de extração não autorizada do sistema de arquivos.

---

## 📋 2. Mapeamento da Entidade `Credential`

A classe `Credential` (localizada em `lib/models/credential.dart`) é anotada com `@HiveType(typeId: 0)`. O identificador de tipo (`typeId`) é imutável e garante que o Hive saiba como serializar e desserializar este objeto específico.

### Propriedades e Atributos

A tabela abaixo define os campos gerados pelo `hive_generator` por meio da anotação `@HiveField(index)`:

| Índice (`@HiveField`) | Atributo (Código) | Tipo de Dado (Dart) | Obrigatoriedade | Descrição e Regras de Negócio |
| :---: | :--- | :--- | :---: | :--- |
| **0** | `id` | `String` | **Requerido** | Identificador único universal (UUID v4) gerado automaticamente na criação do registro. Atua como a chave do mapa no Box. |
| **1** | `alias` | `String` | **Requerido** | Nome de exibição da credencial (ex: "GitHub", "Banco Inter"). É o único campo visível em texto limpo para indexação visual na tela de listagem. |
| **2** | `username` | `String?` | *Opcional* | Nome de usuário, e-mail ou identificador de login associado à conta. Pode ser nulo. |
| **3** | `password` | `String?` | *Opcional* | A senha da credencial. Mantida de forma opcional para dar suporte a registros que contenham exclusivamente tokens 2FA. |
| **4** | `totpSecret` | `String?` | *Opcional* | Chave secreta codificada em Base32 fornecida pelo serviço terceiro para a geração dinâmica do token de segundo fator (TOTP). |
| **5** | `group` | `String` | **Requerido** | Categoria/Agrupamento da credencial (Valores padrão: `Default`, `Banking`, `Social Media`, `Work`). Padrão: `"Default"`. |
| **6** | `notes` | `String?` | *Opcional* | Anotações adicionais ou observações criptografadas sobre a credencial. |
| **7** | `createdAt` | `DateTime` | **Requerido** | Timestamp do momento exato de inserção do registro no banco de dados local. |
| **8** | `updatedAt` | `DateTime` | **Requerido** | Timestamp da última modificação realizada sobre qualquer campo deste registro. |

---

## ⚠️ 3. Regras de Evolução de Esquema e Versionamento

Como o Hive depende da geração estática de código através do `build_runner`, a evolução do banco de dados deve seguir regras estritas de compatibilidade reversa para evitar a corrupção do cofre dos usuários durante atualizações do aplicativo:

1. **Imutabilidade de Índices:** Uma vez que um campo foi mapeado com um índice específico (ex: `@HiveField(2) para username`), **este índice nunca deve ser alterado ou reutilizado** para outro propósito em versões futuras.
2. **Adição de Novos Campos:** Ao estender a entidade com novos atributos, eles devem receber obrigatoriamente novos índices sequenciais superiores (ex: `@HiveField(9)`) e serem tipados como anuláveis (`?`) ou possuírem um valor padrão definido, garantindo que registros antigos sejam lidos sem lançar exceções de desserialização.
3. **Depreciação de Campos:** Se um campo não for mais utilizado pelo sistema, remova a referência no código Dart, mas mantenha o índice do `@HiveField` reservado e comentado no arquivo do modelo para evitar reutilizações acidentais.

---

## 🔄 4. Representação Conceitual do Registro em Memória

Antes de ser submetido à camada de criptografia simétrica (AES-256) e gravado fisicamente em disco, o objeto assume o seguinte formato conceitual de chave-valor na memória RAM do dispositivo (exemplo hipotético):

```json
{
  "key": "a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6",
  "value": {
    "id": "a1b2c3d4-e5f6-7a8b-9c0d-e1f2a3b4c5d6",
    "alias": "GitHub Engenharia",
    "username": "thazsobral",
    "password": "SuperSecurePassword123!",
    "totpSecret": "JBSWY3DPEHPK3PXP",
    "group": "Work",
    "notes": "Chave de deploy atrelada ao servidor de homologação.",
    "createdAt": "2026-06-03T20:13:57.000Z",
    "updatedAt": "2026-06-03T20:13:57.000Z"
  }
}

```
