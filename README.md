# 🌱 Recomeço

Aplicativo multiplataforma feito em **Flutter/Dart** para acompanhar a jornada de quem está largando um vício: quantos maços de cigarro ou latas de cerveja deixou de consumir, há quantos dias está sem recair e quanto dinheiro já economizou.

- **Aluno:** Matheus Santos Moreira
- **Turma:** D.S.M 2026-2
- **Disciplina:** Mobile 2

## Plataformas

| Plataforma | Situação |
|---|---|
| Android | ✅ Testado em celular físico |
| Windows | ✅ Testado |

## Telas

| Login | Início | Detalhe do vício |
|---|---|---|
| [![Login](docs/login.png)](lib/screens/login_screen.dart) | [![Início](docs/home.png)](lib/screens/home_screen.dart) | [![Detalhe](docs/detalhe.png)](lib/screens/habit_detail_screen.dart) |
| [Ver código](lib/screens/login_screen.dart) | [Ver código](lib/screens/home_screen.dart) | [Ver código](lib/screens/habit_detail_screen.dart) |

## Funcionalidades principais

- **Cadastro, login e logout** de usuários (sessão mantida ao reabrir o app).
- **Proteção de telas:** as rotas internas só abrem para usuário autenticado; caso contrário, o app redireciona para o login.
- **CRUD de vícios:** criar, listar, editar e excluir. Cada vício tem sua própria unidade (maços de cigarro, latas de cerveja, reais apostados, doces...) e guarda quanto o usuário consumia por dia (aceita decimais, como 0,5 maço), o custo por unidade e a data em que começou a parar. A tela de cadastro oferece atalhos prontos para os vícios mais comuns.
- **CRUD de registros diários:** anotar quanto consumiu em cada dia (0 = dia limpo), editar e excluir.
- **Estatísticas automáticas:** dias sem consumir, unidades evitadas, dinheiro economizado e total já consumido, por vício e somado na tela inicial.
- **Validação de formulários** e tratamento de erros: campos vazios, e-mail inválido, e-mail já cadastrado, login inválido, senhas diferentes e valores numéricos inválidos.

### Como as estatísticas são calculadas

```
dias de jornada   = dias desde a data de início (contando hoje)
unidades evitadas = (consumo diário antigo × dias de jornada) − total consumido nos registros
economizado       = unidades evitadas × custo por unidade
dias sem consumir = dias desde o último registro com consumo > 0
```

## Tecnologias utilizadas

| Tecnologia | Uso |
|---|---|
| Flutter / Dart | Interface e lógica (Material 3) |
| SQLite (`sqflite` + `sqflite_common_ffi`) | Banco de dados local; plugin nativo no Android e FFI no Windows/Linux |
| `sqlite3_flutter_libs` | Biblioteca SQLite para as plataformas desktop |
| `crypto` | Hash SHA-256 com *salt* para as senhas |
| `shared_preferences` | Guardar o id do usuário logado (sessão) |
| `path` e `path_provider` | Descobrir a pasta onde o banco é salvo |
| Navigator + `onGenerateRoute` | Navegação entre telas e proteção de rotas |

## Estrutura do projeto

```
lib/
├── main.dart                     # Inicialização, rotas e proteção de telas
├── models/
│   ├── app_user.dart
│   ├── habit.dart
│   ├── habit_log.dart
│   └── habit_stats.dart          # Cálculo das estatísticas
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart          # Lista de vícios + total economizado
│   ├── habit_form_screen.dart    # Criar / editar vício
│   └── habit_detail_screen.dart  # Estatísticas + CRUD de registros
├── services/
│   ├── auth_service.dart         # Cadastro, login, logout, sessão
│   └── database_service.dart     # Acesso ao SQLite
├── utils/
│   ├── app_info.dart             # Nome do app
│   └── format.dart               # Formatação de datas, moeda e números
└── widgets/
    ├── habit_card.dart
    └── stat_tile.dart
```

## Autenticação

A autenticação é **local**, feita no próprio app, sem serviços externos. Essa escolha permite que o app funcione offline e igual em Android, Windows e Linux (o Firebase não tem suporte oficial completo para as plataformas desktop).

1. No cadastro, o app verifica se o e-mail já existe. Se não, gera um *salt* aleatório e salva `SHA-256(salt + senha)` na tabela `users`. A senha nunca é armazenada em texto puro.
2. No login, o app recalcula o hash com o *salt* do usuário e compara com o salvo.
3. O id do usuário logado é guardado em `shared_preferences`, mantendo a sessão ao reabrir o app.
4. No logout, a sessão é apagada e o usuário volta ao login.
5. Em `main.dart`, o `onGenerateRoute` bloqueia as rotas `/home`, `/habit-form` e `/habit-detail` para quem não está autenticado.

## Banco de dados (SQLite)

O arquivo `quit_tracker.db` é criado automaticamente na pasta de dados do aplicativo, na primeira execução.

```
users       (id, name, email UNIQUE, password_hash, salt)
habits      (id, user_id → users, name, unit, emoji, baseline_per_day, cost_per_unit, start_date)
habit_logs  (id, habit_id → habits, date, consumed, note)
```

As chaves estrangeiras usam `ON DELETE CASCADE`: excluir um vício apaga seus registros, e excluir um usuário apaga seus vícios.

## Como executar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (rode `flutter doctor` para conferir)
- **Android:** celular com depuração USB ativada ou emulador (Android Studio)
- **Windows:** Visual Studio (ou Build Tools) com a carga de trabalho "Desenvolvimento para desktop com C++" e o Modo de Desenvolvedor ativado
- **Linux:** `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev`

### Passos

```bash
git clone https://github.com/MatheusMoreira77/recomeco-app.git
cd recomeco-app

flutter pub get

# Veja os aparelhos disponíveis e copie o id do que quiser usar
flutter devices

flutter run -d windows        # Windows
flutter run -d linux          # Linux
flutter run -d <id-do-celular> # Android
```

As pastas `android/`, `windows/` e `linux/` já estão no repositório, então não é preciso rodar `flutter create`.

### Gerar executáveis

```bash
flutter build apk        # Android
flutter build windows    # Windows
flutter build linux      # Linux
```

### Erros comuns no Android

| Erro | Causa | Solução |
|---|---|---|
| `INSTALL_FAILED_USER_RESTRICTED: Install canceled by user` | O celular bloqueou a instalação via USB (comum em Xiaomi, Redmi e POCO) | Em *Opções do desenvolvedor*, ative **Instalar via USB** e **Depuração USB**. Deixe a tela desbloqueada e toque em **Instalar** no pop-up que aparece no celular durante a instalação. |
| `Device ... is not authorized` | O celular ainda não autorizou o computador | Desbloqueie o celular, aceite o pop-up "Permitir depuração USB" (marque "Sempre permitir") e rode `flutter devices` de novo. |
| `Unable to delete directory ...\build\app\intermediates\...` (tarefa `cleanMergeDebugAssets`) | Algum programa está usando arquivos da pasta `build` (o app aberto no Windows, um Gradle antigo, OneDrive ou antivírus) | Feche o app aberto em outra plataforma, rode `.\gradlew --stop` dentro da pasta `android`, apague a pasta `build` e tente de novo. Se persistir, mova o projeto para uma pasta fora do OneDrive (ex.: `C:\dev`). |
| `cmdline-tools component is missing` ou `Android sdkmanager not found` | Falta o *Command-line Tools* do Android SDK | No Android Studio: *SDK Manager > SDK Tools* > marque **Android SDK Command-line Tools (latest)** e aplique. Depois rode `flutter doctor --android-licenses` e aceite as licenças. |
| `No supported devices found with name or id matching '...'` | O id informado em `-d` não existe | Rode `flutter devices` e copie o id exato do seu aparelho. |
| A primeira compilação parece travada | O Gradle baixa SDKs e dependências na primeira vez | Aguarde: pode levar vários minutos. As próximas compilações são bem mais rápidas. |

### Erros comuns no Windows

| Erro | Causa | Solução |
|---|---|---|
| `Unable to find suitable Visual Studio toolchain` | Falta o compilador C++ | Instale o Visual Studio (ou o *Build Tools*) com a carga de trabalho **Desenvolvimento para desktop com C++**, reinicie o PC e confira com `flutter doctor -v`. |
| `Failed to remove ...` ao rodar `flutter clean` | Arquivos do projeto em uso por outro programa | Feche o app e o editor, ative o Modo de Desenvolvedor (`start ms-settings:developers`) e tente de novo. |
| `sqlite3.dll` não encontrado | A biblioteca do SQLite não foi encontrada | Copie o `sqlite3.dll` (baixe em sqlite.org) para a pasta do executável. |
