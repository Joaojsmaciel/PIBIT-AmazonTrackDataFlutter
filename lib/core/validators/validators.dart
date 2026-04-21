class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email é obrigatório';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Email inválido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Senha é obrigatória';
    }
    if (value.length < 6) {
      return 'Senha deve ter no mínimo 6 caracteres';
    }
    return null;
  }

  static String? validatePasswordConfirmation(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Confirmação de senha é obrigatória';
    }
    if (value != password) {
      return 'As senhas não coincidem';
    }
    return null;
  }

  static String? validateCPF(String? value) {
    if (value == null || value.isEmpty) {
      return 'CPF é obrigatório';
    }
    
    final cleanCPF = value.replaceAll(RegExp(r'\D'), '');
    
    if (cleanCPF.length != 11) {
      return 'CPF deve ter 11 dígitos';
    }
    
    if (!isValidCPF(cleanCPF)) {
      return 'CPF inválido';
    }
    
    return null;
  }

  static bool isValidCPF(String cpf) {
    if (cpf.isEmpty) return false;
    
    final clean = cpf.replaceAll(RegExp(r'\D'), '');
    
    if (clean.length != 11) return false;
    
    // Verifica se todos os dígitos são iguais
    if (RegExp(r'^(\d)\1{10}$').hasMatch(clean)) {
      return false;
    }
    
    // Calcula primeiro dígito verificador
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      sum += int.parse(clean[i]) * (10 - i);
    }
    int firstDigit = 11 - (sum % 11);
    if (firstDigit >= 10) firstDigit = 0;
    
    if (int.parse(clean[9]) != firstDigit) {
      return false;
    }
    
    // Calcula segundo dígito verificador
    sum = 0;
    for (int i = 0; i < 10; i++) {
      sum += int.parse(clean[i]) * (11 - i);
    }
    int secondDigit = 11 - (sum % 11);
    if (secondDigit >= 10) secondDigit = 0;
    
    if (int.parse(clean[10]) != secondDigit) {
      return false;
    }
    
    return true;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nome completo é obrigatório';
    }
    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Digite seu nome completo (mínimo 2 palavras)';
    }
    return null;
  }

  static String? validateNotEmpty(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    return null;
  }

  static String? validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName é obrigatório';
    }
    if (int.tryParse(value) == null) {
      return '$fieldName deve ser um número';
    }
    return null;
  }

  static String formatCPF(String cpf) {
    final clean = cpf.replaceAll(RegExp(r'\D'), '');
    if (clean.length != 11) return cpf;
    return '${clean.substring(0, 3)}.${clean.substring(3, 6)}.${clean.substring(6, 9)}-${clean.substring(9, 11)}';
  }
}
