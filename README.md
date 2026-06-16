# Salão da Leila

Sistema de agendamento para salão de beleza desenvolvido com Flutter. Permite que clientes realizem agendamentos de serviços e que administradores gerenciem a operação do salão.

---

# Tecnologias Utilizadas

| Tecnologia | Versão | Descrição |
|---|---|---|
| [Flutter](https://flutter.dev) | SDK | Framework principal para desenvolvimento multiplataforma |
| [Dart](https://dart.dev) | ^3.8.0 | Linguagem de programação |
| [sqflite](https://pub.dev/packages/sqflite) | ^2.4.2 | Banco de dados SQLite para persistência local |
| [sqflite_common_ffi](https://pub.dev/packages/sqflite_common_ffi) | ^2.3.5 | Suporte ao SQLite em desktop (Linux, Windows, macOS) |
| [cupertino_icons](https://pub.dev/packages/cupertino_icons) | ^1.0.8 | Ícones no estilo iOS |
| Material Design 3 | — | Sistema de design visual utilizado na interface |

# Pré-requisitos

- [Flutter SDK](https://docs.flutter.dev/get-started/install) instalado e configurado
- Dart SDK ^3.8.0 (incluído no Flutter)
- Para desktop: bibliotecas SQLite disponíveis no sistema

# Acesso Padrão 

O sistema cria automaticamente um usuário *administrador* na primeira execução:

| Campo | Valor |
|---|---|
| E-mail | `leila@salao.com` |
| Senha | `leila` |

Novos clientes podem se cadastrar pela tela de login.


# Estrutura do Projeto

lib/
├── src/
│   ├── components/         # Componentes reutilizáveis (widgets)
│   │   └── todo_item.dart   # Item de tarefa individual
│   ├── models/            # Modelos de dados
│   │   └── todo_item.dart   # Estrutura da tarefa (title, completed)
│   ├── repositories/      # Camada de persistência de dados
│   │   └── todo_repository.dart # Lógica de salvar/carregar tarefas
│   └── services/          # Serviços externos ou utilitários
│       └── api_service.dart # (Opcional) Se houver integração com API
├── screens/               # Telas da aplicação
│   ├── home_screen.dart     # Tela principal
│   ├── add_task_screen.dart # Tela para adicionar tarefas
│   ├── edit_task_screen.dart# Tela para editar tarefas
│   └── settings_screen.dart # (Opcional) Configurações
├── utils/                 # Funções utilitárias
│   ├── constants.dart       # Constantes (cores, strings)
│   ├── validators.dart      # Validação de dados
│   └── theme.dart           # Configuração de tema
├── main.dart              # Ponto de entrada da aplicação

# Como Executar:

#### Verifique a instalação:

flutter doctor

#### Clone ou baixe o projeto:

git clone <https://github.com/LauraYumiOsawa/CabeleleilaLeilaSchedule>

cd ~/CabeleleilaLeilaSchedule

#### Instale as dependências:

flutter pub get

#### Execute a aplicação:

flutter run

### Opcional:

#### Para rodar em um dispositivo específico:

flutter run -d <device_id>

#### Para compilar para Android:

flutter build apk --debug

#### Para compilar para iOS (macOS):

flutter build ios --no-codesign

#### Limpeza de build:

flutter clean

### Rodar testes Flutter:

#### Rodar todos os testes:

flutter test

#### Rodar um arquivo específico:

flutter test test/features/appointment/domain/entities_test.dart # Testa as entidades de domínio
flutter test test/features/appointment/presentation/app_view_model_test.dart # Testa o AppViewModel com um repositório fake

#### Com saída detalhada:

flutter test --reporter expanded

#### Análise estática (lint):

flutter analyze

# Observação:

- Esse projeto deve rodar em qualquer ambiente que cumpra os pré-requisitos, porém ele foi produzido e testado em ambiente linux (Ubuntu 24), sendo apenas validado em 100% de suas funcionalidades nesse ambiente.