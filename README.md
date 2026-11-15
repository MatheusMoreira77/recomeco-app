# 🌱 Quit Tracker

Aplicativo multiplataforma (**Android, Windows e Linux**) feito em **Flutter/Dart** para acompanhar a jornada de quem está largando um vício: quantos cigarros ou cervejas deixou de consumir, há quantos dias está sem recair e quanto dinheiro já economizou.

Projeto desenvolvido para a disciplina de **Mobile 2**.

## Funcionalidades principais

- **Cadastro, login e logout** de usuários (sessão persistida entre aberturas do app).
- **Proteção de telas**: rotas internas só abrem para usuário autenticado; caso contrário, redireciona para o login.
- **CRUD de vícios**: criar, listar, editar e excluir (ex.: Cigarro, Cerveja, Vinho...). Cada vício guarda quanto o usuário consumia por dia, o custo por unidade e a data em que começou a parar.
- **CRUD de registros diários**: anotar quanto consumiu em cada dia (0 = dia limpo), editar e excluir.
- **Estatísticas automáticas**: dias sem consumir, unidades evitadas, dinheiro economizado e total já consumido.
- **Validação de formulários** e tratamento de erros (campos vazios, e-mail inválido, e-mail já cadastrado, login inválido, senhas diferentes).

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
| `sqlite3_flutter_libs` | Fornece a biblioteca SQLite para as plataformas desktop |
| `crypto` | Hash SHA-256 com *salt* para as senhas |
| `shared_preferences` | Guardar o id do usuário logado (sessão) |
| `path_provider` | Descobrir a pasta onde o banco é salvo |
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
├── utils/format.dart             # Formatação de datas e moeda
└── widgets/
    ├── habit_card.dart
    └── stat_tile.dart
```

## Autenticação

A autenticação é **local**, feita no próprio app:

1. No cadastro, o app verifica se o e-mail já existe. Se não, gera um *salt* aleatório e salva `SHA-256(salt + senha)` na tabela `users`. A senha nunca é armazenada em texto puro.
2. No login, o app recalcula o hash com o *salt* do usuário e compara com o salvo.
3. O id do usuário logado é guardado em `shared_preferences`, mantendo a sessão ao reabrir o app.
4. No logout, a sessão é apagada e o usuário volta ao login.
5. Em `main.dart`, o `onGenerateRoute` bloqueia as rotas `/home`, `/habit-form` e `/habit-detail` para quem não está autenticado.

## Banco de dados (SQLite)

O arquivo `quit_tracker.db` é criado automaticamente na pasta de dados do aplicativo.

```
users       (id, name, email UNIQUE, password_hash, salt)
habits      (id, user_id → users, name, unit, emoji, baseline_per_day, cost_per_unit, start_date)
habit_logs  (id, habit_id → habits, date, consumed, note)
```

As chaves estrangeiras usam `ON DELETE CASCADE`: excluir um vício apaga seus registros.

## Como executar

### Pré-requisitos
- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x (rode `flutter doctor` para conferir)
- **Android**: Android Studio com um emulador ou celular com depuração USB
- **Windows**: Visual Studio com a carga de trabalho "Desenvolvimento para desktop com C++" e o *Modo de Desenvolvedor* ativado
- **Linux**: `sudo apt install clang cmake ninja-build pkg-config libgtk-3-dev libsqlite3-dev`

### Passos

```bash
git clone <URL-DO-SEU-REPOSITORIO>
cd quit_tracker

# Gera as pastas das plataformas (android/, windows/, linux/), caso ainda não existam
flutter create --platforms=android,windows,linux .

flutter pub get

flutter run -d android   # ou: flutter run -d windows | flutter run -d linux
```

### Gerar executáveis

```bash
flutter build apk        # Android
flutter build windows    # Windows
flutter build linux      # Linux
```

> **Windows:** se aparecer erro de `sqlite3.dll` não encontrado, copie o `sqlite3.dll` (baixe em sqlite.org) para a pasta do executável.
