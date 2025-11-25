class SecretCodeService {
  static const String secretCode = '2082-05-16';
  
  String _currentInput = '';
  
  void addInput(String input) {
    _currentInput += input;
    // Keep only last 15 characters to accommodate secret code + operations
    if (_currentInput.length > 15) {
      _currentInput = _currentInput.substring(_currentInput.length - 15);
    }
  }
  
  void clearInput() {
    _currentInput = '';
  }
  
  bool checkSecretCode({String? displayContent}) {
    // Check both the input sequence and display content
    if (displayContent != null && displayContent.contains(secretCode)) {
      _currentInput = '';
      return true;
    }
    if (_currentInput.contains(secretCode)) {
      _currentInput = '';
      return true;
    }
    return false;
  }
  
  String getCurrentInput() => _currentInput;
}

