enum AgendamentoStatus {
  pendente,
  confirmado,
  // ignore: constant_identifier_names
  em_andamento,
  concluido,
  cancelado,
}

extension AgendamentoStatusExt on AgendamentoStatus {
  String toLabel() {
    switch (this) {
      case AgendamentoStatus.pendente:
        return 'Pendente';
      case AgendamentoStatus.confirmado:
        return 'Confirmado';
      case AgendamentoStatus.em_andamento:
        return 'Em Andamento';
      case AgendamentoStatus.concluido:
        return 'Concluído';
      case AgendamentoStatus.cancelado:
        return 'Cancelado';
    }
  }

  String toChar() {
    switch (this) {
      case AgendamentoStatus.pendente:
        return 'P';
      case AgendamentoStatus.confirmado:
        return 'C';
      case AgendamentoStatus.em_andamento:
        return 'E';
      case AgendamentoStatus.concluido:
        return 'F';
      case AgendamentoStatus.cancelado:
        return 'X';
    }
  }

  static AgendamentoStatus fromChar(String char) {
    switch (char) {
      case 'P':
        return AgendamentoStatus.pendente;
      case 'C':
        return AgendamentoStatus.confirmado;
      case 'E':
        return AgendamentoStatus.em_andamento;
      case 'F':
        return AgendamentoStatus.concluido;
      case 'X':
        return AgendamentoStatus.cancelado;
      default:
        return AgendamentoStatus.pendente;
    }
  }
}

enum ServicoStatus {
  pendente,
  // ignore: constant_identifier_names
  em_andamento,
  concluido,
}

extension ServicoStatusExt on ServicoStatus {
  String toLabel() {
    switch (this) {
      case ServicoStatus.pendente:
        return 'Pendente';
      case ServicoStatus.em_andamento:
        return 'Em Andamento';
      case ServicoStatus.concluido:
        return 'Concluído';
    }
  }

  String toChar() {
    switch (this) {
      case ServicoStatus.pendente:
        return 'P';
      case ServicoStatus.em_andamento:
        return 'E';
      case ServicoStatus.concluido:
        return 'F';
    }
  }

  static ServicoStatus fromChar(String char) {
    switch (char) {
      case 'P':
        return ServicoStatus.pendente;
      case 'E':
        return ServicoStatus.em_andamento;
      case 'F':
        return ServicoStatus.concluido;
      default:
        return ServicoStatus.pendente;
    }
  }
}
