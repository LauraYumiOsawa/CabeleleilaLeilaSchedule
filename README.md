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
