import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/secret_code_service.dart';
import 'login_screen.dart';
import 'chat_list_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _expression = '';
  final SecretCodeService _secretCodeService = SecretCodeService();
  final FocusNode _focusNode = FocusNode();
  int _clearButtonPressCount = 0;
  DateTime? _lastClearPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Handle keyboard input
  void _handleKeyPress(LogicalKeyboardKey key) {
    String? buttonValue;
    
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      buttonValue = '0';
    } else if (key == LogicalKeyboardKey.digit1 || key == LogicalKeyboardKey.numpad1) {
      buttonValue = '1';
    } else if (key == LogicalKeyboardKey.digit2 || key == LogicalKeyboardKey.numpad2) {
      buttonValue = '2';
    } else if (key == LogicalKeyboardKey.digit3 || key == LogicalKeyboardKey.numpad3) {
      buttonValue = '3';
    } else if (key == LogicalKeyboardKey.digit4 || key == LogicalKeyboardKey.numpad4) {
      buttonValue = '4';
    } else if (key == LogicalKeyboardKey.digit5 || key == LogicalKeyboardKey.numpad5) {
      buttonValue = '5';
    } else if (key == LogicalKeyboardKey.digit6 || key == LogicalKeyboardKey.numpad6) {
      buttonValue = '6';
    } else if (key == LogicalKeyboardKey.digit7 || key == LogicalKeyboardKey.numpad7) {
      buttonValue = '7';
    } else if (key == LogicalKeyboardKey.digit8 || key == LogicalKeyboardKey.numpad8) {
      buttonValue = '8';
    } else if (key == LogicalKeyboardKey.digit9 || key == LogicalKeyboardKey.numpad9) {
      buttonValue = '9';
    } else if (key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      buttonValue = '+';
    } else if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      buttonValue = '-';
    } else if (key == LogicalKeyboardKey.asterisk || key == LogicalKeyboardKey.numpadMultiply) {
      buttonValue = '×';
    } else if (key == LogicalKeyboardKey.slash || key == LogicalKeyboardKey.numpadDivide) {
      buttonValue = '÷';
    } else if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.numpadEqual || key == LogicalKeyboardKey.enter) {
      buttonValue = '=';
    } else if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.delete) {
      buttonValue = 'C';
    } else if (key == LogicalKeyboardKey.backspace) {
      buttonValue = '⌫';
    }
    
    if (buttonValue != null) {
      _onButtonPressed(buttonValue);
    }
  }

  void _onButtonPressed(String value) {
    HapticFeedback.lightImpact();
    _secretCodeService.addInput(value);
    
    // Reset C button counter if any other button is pressed
    if (value != 'C') {
      _clearButtonPressCount = 0;
    }
    
    if (value == 'C') {
      _handleClearButton();
    } else if (value == '⌫') {
      _backspace();
    } else if (value == '=') {
      if (_secretCodeService.checkSecretCode(displayContent: _display)) {
        _navigateToLogin();
        return;
      }
      _calculate();
    } else if (['+', '-', '×', '÷'].contains(value)) {
      _appendOperator(value);
    } else {
      _appendNumber(value);
    }
  }

  void _handleClearButton() {
    final now = DateTime.now();
    
    // Reset counter if more than 2 seconds passed since last press
    if (_lastClearPressTime != null &&
        now.difference(_lastClearPressTime!).inSeconds > 2) {
      _clearButtonPressCount = 0;
    }
    
    _clearButtonPressCount++;
    _lastClearPressTime = now;
    
    // If C pressed 8 times, navigate to chat (if logged in)
    if (_clearButtonPressCount >= 8) {
      _clearButtonPressCount = 0;
      _navigateToChatIfLoggedIn();
      return;
    }
    
    _clear();
  }
  
  void _clear() {
    setState(() {
      _display = '0';
      _expression = '';
    });
    _secretCodeService.clearInput();
  }
  
  void _navigateToChatIfLoggedIn() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is logged in, navigate to chat list
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ChatListScreen()),
      );
    } else {
      // User not logged in, navigate to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
    _clearButtonPressCount = 0;
  }

  void _backspace() {
    setState(() {
      if (_display.length > 1 && _display != '0') {
        _display = _display.substring(0, _display.length - 1);
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else {
        _display = '0';
        _expression = '';
      }
    });
  }

  void _appendNumber(String number) {
    setState(() {
      if (_display == '0' || _display == 'Error') {
        _display = number;
        _expression = number;
      } else {
        _display += number;
        _expression += number;
      }
    });
  }

  void _appendOperator(String op) {
    setState(() {
      // Remove any trailing operators
      while (_display.isNotEmpty && ['+', '-', '×', '÷'].contains(_display[_display.length - 1])) {
        _display = _display.substring(0, _display.length - 1);
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      }
      
      _display += op;
      // Convert × and ÷ to * and / for calculation
      _expression += (op == '×' ? '*' : (op == '÷' ? '/' : op));
    });
  }

  void _calculate() {
    if (_expression.isEmpty) return;
    
    setState(() {
      try {
        // Check for secret code first
        if (_display.contains('2082-05-16')) {
          return; // Don't calculate, let secret code handler work
        }
        
        // Evaluate expression
        double result = _evaluateExpression(_expression);
        
        // Format result
        if (result % 1 == 0) {
          _display = result.toInt().toString();
        } else {
          _display = result.toStringAsFixed(10).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
        }
        
        _expression = _display;
      } catch (e) {
        _display = 'Error';
        _expression = '';
      }
    });
  }

  double _evaluateExpression(String expr) {
    // Remove whitespace
    expr = expr.replaceAll(' ', '');
    
    // Handle negative numbers at start
    if (expr.startsWith('-')) {
      expr = '0$expr';
    }
    
    // Use a simple stack-based evaluator
    List<double> numbers = [];
    List<String> operators = [];
    
    int i = 0;
    while (i < expr.length) {
      if (RegExp(r'[0-9.]').hasMatch(expr[i])) {
        String numStr = '';
        while (i < expr.length && (RegExp(r'[0-9.]').hasMatch(expr[i]))) {
          numStr += expr[i];
          i++;
        }
        numbers.add(double.parse(numStr));
        i--;
      } else if (expr[i] == '+' || expr[i] == '-') {
        while (operators.isNotEmpty && operators.last != '(') {
          _applyOperation(numbers, operators);
        }
        operators.add(expr[i]);
      } else if (expr[i] == '*' || expr[i] == '/') {
        while (operators.isNotEmpty && 
               (operators.last == '*' || operators.last == '/')) {
          _applyOperation(numbers, operators);
        }
        operators.add(expr[i]);
      }
      i++;
    }
    
    while (operators.isNotEmpty) {
      _applyOperation(numbers, operators);
    }
    
    return numbers.isEmpty ? 0 : numbers[0];
  }

  void _applyOperation(List<double> numbers, List<String> operators) {
    if (numbers.length < 2 || operators.isEmpty) return;
    
    double b = numbers.removeLast();
    double a = numbers.removeLast();
    String op = operators.removeLast();
    
    switch (op) {
      case '+':
        numbers.add(a + b);
        break;
      case '-':
        numbers.add(a - b);
        break;
      case '*':
        numbers.add(a * b);
        break;
      case '/':
        if (b == 0) throw Exception('Division by zero');
        numbers.add(a / b);
        break;
    }
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Widget _buildButton(String text, {Color? color, double? fontSize, Widget? icon}) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color ?? Colors.grey[300],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onButtonPressed(text),
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: icon ?? Text(
              text,
              style: TextStyle(
                fontSize: fontSize ?? 24,
                fontWeight: FontWeight.bold,
                color: color == Colors.orange ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          _handleKeyPress(event.logicalKey);
        }
        return KeyEventResult.handled;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              // Display
              Expanded(
                flex: 2,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomRight,
                  child: Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Buttons
              Expanded(
                flex: 3,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildButton('C', color: Colors.grey[400])),
                            Expanded(
                              child: _buildButton(
                                '⌫',
                                color: Colors.grey[400],
                                icon: const Icon(Icons.backspace_outlined, size: 24, color: Colors.black87),
                              ),
                            ),
                            Expanded(child: _buildButton('÷', color: Colors.orange)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildButton('7')),
                            Expanded(child: _buildButton('8')),
                            Expanded(child: _buildButton('9')),
                            Expanded(child: _buildButton('×', color: Colors.orange)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildButton('4')),
                            Expanded(child: _buildButton('5')),
                            Expanded(child: _buildButton('6')),
                            Expanded(child: _buildButton('-', color: Colors.orange)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildButton('1')),
                            Expanded(child: _buildButton('2')),
                            Expanded(child: _buildButton('3')),
                            Expanded(child: _buildButton('+', color: Colors.orange)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: _buildButton('0')),
                            Expanded(child: _buildButton('=')),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
