# Como Funciona o PASSWMOB (how-it-works) 🔐

Este documento descreve a jornada da informação dentro do PASSWMOB. Sendo um gerenciador de credenciais estritamente **offline** e baseado no princípio de **Zero-Knowledge**, o aplicativo foi desenhado para que nenhum dado sensível trafegue pela rede ou seja armazenado em texto limpo.

Abaixo, detalhamos visual e logicamente o comportamento do sistema diante das interações do usuário.

---

## 1. Inicialização e Desbloqueio do Cofre

Este processo determina como o aplicativo valida a identidade do usuário e prepara o ambiente local para ler as senhas com segurança.

### Fluxograma de Eventos
```text
[Usuário abre o app] 
       │
       ▼
[Sistema verifica se há uma chave no Secure Storage]
       │
       ├────────────────────────────────────────┐
       ▼ (Sim, usuário recorrente)              ▼ (Não, primeiro acesso)
[Pede Biometria ou Master Pass]          [Usuário cria Master Password]
       │                                        │
       │                                        ▼
       │                                 [Gera chave AES de 32 bytes]
       │                                        │
       │                                        ▼
       │                                 [Salva chave no Secure Storage]
       │                                        │
       └───────────────────┬────────────────────┘
                           ▼
     [Injeta a chave no Hive e abre o Box criptografado]

```

### Mecânica do Processo

1. **Ação do Usuário:** O usuário abre o aplicativo. Se for o primeiro acesso, ele define uma senha mestre (*Master Password*). Caso contrário, o app solicita a autenticação biométrica ou a redigitação da senha mestre.
2. **Checagem de Estado:** O subsistema de banco de dados interroga o pacote `flutter_secure_storage` para verificar se já existe uma chave de criptografia de cofre registrada.
3. **Fluxo de Primeiro Acesso:**
* O sistema recebe a senha criada pelo usuário, gera um *salt* pseudo-aleatório seguro e deriva a identidade mestre.
* Simultaneamente, gera uma chave simétrica criptograficamente forte de 32 bytes (256 bits).
* Essa chave de 32 bytes é injetada e persistida no armazenamento isolado de hardware do sistema operacional (Keystore no Android / Keychain no iOS) através do `flutter_secure_storage`.


4. **Fluxo de Acesso Subsequente:**
* O sistema invoca a API nativa via `local_auth` para validar a biometria do aparelho.
* Com a autenticação bem-sucedida, o Flutter ganha permissão temporária para ler a chave de 32 bytes guardada no armazenamento isolado do chip de segurança.


5. **Abertura do Banco:** O microsserviço de banco de dados injeta essa chave diretamente na inicialização do Hive usando o inicializador `HiveAesCipher(key)`. A partir deste momento, o "Box" (tabela/esquema NoSQL) fica aberto e pronto para consultas em memória RAM.

---

## 2. Criação e Persistência de uma Nova Credencial

Este processo demonstra o ciclo de vida do dado desde o momento em que ele é digitado em texto limpo nas caixas de entrada até se transformar em um bloco binário ilegível em disco.

### Mecânica do Processo

1. **Ação do Usuário:** No formulário de cadastro (`screens/Form`), o usuário preenche o campo obrigatório *Alias* (ex: "Banco X") e os campos opcionais de usuário, senha ou chaves secretas de segundo fator (TOTP). Ao terminar, clica em "Salvar".
2. **Captação e Modelagem:** O Flutter captura o estado dos componentes visuais através de seus respectivos `TextEditingControllers` e encapsula as informações em uma instância da entidade `Credential` (definida em `models/`).
3. **Criptografia Simétrica (AES-256):** O modelo é despachado para o serviço de persistência (`services/`). O Hive intercepta o objeto e utiliza a cifra `HiveAesCipher` (configurada com a chave secreta de 32 bytes obtida no *Fluxo 1*) para encriptar os blocos de bytes do objeto gerado.
4. **Escrita em Disco (Offline):** O Hive realiza o *commit* dos bytes cifrados diretamente no arquivo físico com extensão `.hive`. Este arquivo reside no diretório protegido e privado alocado pelo Sistema Operacional para o aplicativo. O dado é gravado localmente e o arquivo gerado torna-se completamente ilegível caso seja extraído do celular sem a chave correspondente do Keystore.
5. **Atualização do Estado Visual:** Uma notificação de alteração de dados é emitida para o gerenciador de estado nativo do Flutter. A tela de listagem (`screens/Home`) intercepta o evento, lê o novo registro descriptografado em tempo de execução e atualiza a interface do usuário. As strings de texto limpo do formulário são limpas e descartadas da memória RAM imediatamente após a gravação.

---

## 3. Geração em Tempo Real do Token de Duplo Fator (TOTP)

Este processo demonstra o motor de cálculo matemático determinístico que permite ao PASSWMOB atuar como um autenticador de 2FA integrado, sem necessitar de qualquer conexão com servidores externos ou com a internet.

### Mecânica do Processo

1. **Ação do Usuário:** O usuário navega até o card de uma credencial que possui autenticação em duas etapas configurada e visualiza o token de 6 dígitos sofrendo mutações periódicas ao lado de um temporizador visual.
2. **Leitura e Decodificação:**
* O aplicativo lê a *Secret Key* associada (que foi armazenada de forma segura e criptografada no *Fluxo 2*) e a descriptografa em memória RAM.
* O pacote `base32` decodifica a string alfanumérica da *Secret* para transformá-la em uma matriz de bytes brutos.


3. **Sincronização de Tempo:** O sistema operacional fornece a hora exata do relógio interno do dispositivo baseado no padrão *Unix Epoch* (contagem de segundos desde 1º de janeiro de 1970). O pacote `otp` divide esse timestamp atual por 30 segundos, gerando um número inteiro que atua como o "contador/janela de tempo" atual.
4. **Cálculo de Hash Criptográfico (HMAC-SHA1):** O motor de segurança combina os bytes brutos da *Secret Key* decodificada com os bytes do contador de tempo atual através de um algoritmo de hashing pseudo-aleatório seguro de via única (HMAC-SHA1).
5. **Truncamento Dinâmico:** O hash gerado (um vetor longo de bytes) sofre uma operação matemática de extração e mascaramento de bits (Truncamento Dinâmico) para isolar um número inteiro específico de 6 dígitos.
6. **Ciclo de Atualização da UI:** O Flutter renderiza o código obtido na interface. Paralelamente, um temporizador regressivo de 1 segundo atualiza uma barra de progresso visual. Assim que o relógio do dispositivo muda para a próxima janela de 30 segundos, o contador de tempo altera seu valor, disparando um novo cálculo em cadeia de forma instantânea e alterando o token exibido na tela do usuário.
