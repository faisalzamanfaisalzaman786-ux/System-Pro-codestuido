package com.systempro.faisal;

import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {

    private TextView tvResult;
    private String currentNumber = "";
    private String operator = "";
    private double firstOperand = 0;
    private boolean isNewOperation = true;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        tvResult = findViewById(R.id.tvResult);

        // Number buttons
        setNumberButton(R.id.btn0, "0");
        setNumberButton(R.id.btn1, "1");
        setNumberButton(R.id.btn2, "2");
        setNumberButton(R.id.btn3, "3");
        setNumberButton(R.id.btn4, "4");
        setNumberButton(R.id.btn5, "5");
        setNumberButton(R.id.btn6, "6");
        setNumberButton(R.id.btn7, "7");
        setNumberButton(R.id.btn8, "8");
        setNumberButton(R.id.btn9, "9");
        setNumberButton(R.id.btnDot, ".");

        // Operator buttons
        setOperatorButton(R.id.btnAdd, "+");
        setOperatorButton(R.id.btnSubtract, "-");
        setOperatorButton(R.id.btnMultiply, "*");
        setOperatorButton(R.id.btnDivide, "/");

        // Clear button
        findViewById(R.id.btnClear).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                clear();
            }
        });

        // Backspace button
        findViewById(R.id.btnBackspace).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!currentNumber.isEmpty()) {
                    currentNumber = currentNumber.substring(0, currentNumber.length() - 1);
                    tvResult.setText(currentNumber.isEmpty() ? "0" : currentNumber);
                }
            }
        });

        // Equals button
        findViewById(R.id.btnEquals).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                compute();
            }
        });
    }

    private void setNumberButton(int id, final String value) {
        findViewById(id).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (isNewOperation) {
                    currentNumber = "";
                    isNewOperation = false;
                }
                if (value.equals(".")) {
                    if (!currentNumber.contains(".")) {
                        currentNumber += value;
                    }
                } else {
                    currentNumber += value;
                }
                tvResult.setText(currentNumber);
            }
        });
    }

    private void setOperatorButton(int id, final String op) {
        findViewById(id).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!currentNumber.isEmpty()) {
                    if (!operator.isEmpty()) {
                        compute();
                    }
                    firstOperand = Double.parseDouble(currentNumber);
                    operator = op;
                    isNewOperation = true;
                }
            }
        });
    }

    private void compute() {
        if (!operator.isEmpty() && !currentNumber.isEmpty()) {
            double secondOperand = Double.parseDouble(currentNumber);
            double result = 0;
            switch (operator) {
                case "+":
                    result = firstOperand + secondOperand;
                    break;
                case "-":
                    result = firstOperand - secondOperand;
                    break;
                case "*":
                    result = firstOperand * secondOperand;
                    break;
                case "/":
                    if (secondOperand != 0) {
                        result = firstOperand / secondOperand;
                    } else {
                        tvResult.setText("Error");
                        clear();
                        return;
                    }
                    break;
            }
            // Format result to avoid trailing .0
            if (result == (long) result) {
                currentNumber = String.valueOf((long) result);
            } else {
                currentNumber = String.valueOf(result);
            }
            tvResult.setText(currentNumber);
            operator = "";
            isNewOperation = true;
        }
    }

    private void clear() {
        currentNumber = "";
        operator = "";
        firstOperand = 0;
        isNewOperation = true;
        tvResult.setText("0");
    }
}