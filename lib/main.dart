import 'package:flutter/material.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System Pro Calculator',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.black,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _display = '0';
  String _currentInput = '';
  String _operator = '';
  double _firstOperand = 0.0;
  bool _waitingForOperand = false;

  void _buttonPressed(String value) {
    setState(() {
      if (value == 'C') {
        _clearAll();
      } else if (value == '⌫') {
        _deleteLast();
      } else if (value == '=') {
        _evaluate();
      } else if (value == '+' || value == '-' || value == '×' || value == '÷') {
        _setOperator(value);
      } else {
        _inputDigit(value);
      }
    });
  }

  void _clearAll() {
    _display = '0';
    _currentInput = '';
    _operator = '';
    _firstOperand = 0.0;
    _waitingForOperand = false;
  }

  void _deleteLast() {
    if (_currentInput.isNotEmpty) {
      _currentInput = _currentInput.substring(0, _currentInput.length - 1);
      _display = _currentInput.isEmpty ? '0' : _currentInput;
    } else if (!_waitingForOperand && _display != '0') {
      _currentInput = _display.substring(0, _display.length - 1);
      _display = _currentInput.isEmpty ? '0' : _currentInput;
    }
  }

  void _inputDigit(String digit) {
    if (_waitingForOperand) {
      _currentInput = digit;
      _waitingForOperand = false;
    } else {
      _currentInput = (_currentInput == '0') ? digit : _currentInput + digit;
    }
    _display = _currentInput;
  }

  void _setOperator(String op) {
    if (_currentInput.isNotEmpty) {
      _firstOperand = double.parse(_currentInput);
      _operator = op;
      _waitingForOperand = true;
    } else if (_operator.isNotEmpty && !_waitingForOperand) {
      _operator = op;
    }
  }

  void _evaluate() {
    if (_operator.isEmpty || _currentInput.isEmpty) return;

    double secondOperand = double.parse(_currentInput);
    double result = 0.0;

    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case '×':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        if (secondOperand != 0) {
          result = _firstOperand / secondOperand;
        } else {
          _display = 'Error';
          _clearAll();
          return;
        }
        break;
    }

    String resultStr = result.toString();
    if (resultStr.contains('.') && resultStr.endsWith('0')) {
      resultStr = resultStr.substring(0, resultStr.length - 2);
    }
    _display = resultStr;
    _currentInput = resultStr;
    _firstOperand = result;
    _operator = '';
    _waitingForOperand = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                child: Text(
                  _display,
                  style: const TextStyle(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Column(
                  children: [
                    _buildButtonRow(['C', '⌫', '÷']),
                    _buildButtonRow(['7', '8', '9', '×']),
                    _buildButtonRow(['4', '5', '6', '-']),
                    _buildButtonRow(['1', '2', '3', '+']),
                    _buildButtonRow(['0', '00', '.', '=']),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons) {
    return Expanded(
      child: Row(
        children: buttons.map((btn) {
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: ElevatedButton(
                onPressed: () => _buttonPressed(btn),
                style: ElevatedButton.styleFrom(
                  backgroundColor: btn == 'C' || btn == '⌫' ? Colors.redAccent :
                                   btn == '=' ? Colors.green :
                                   btn == '+' || btn == '-' || btn == '×' || btn == '÷' ? Colors.orange : Colors.grey[850],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  btn,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
