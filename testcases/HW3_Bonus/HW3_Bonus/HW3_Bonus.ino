extern "C" {
#include <nds_intrinsic.h>
uint32_t ext_dsp_codegen(uint32_t a, uint32_t b) asm ("ext_dsp_codegen");
}

void setup() {
  Serial.begin(9600);
}

void loop() {
  // Check if data is available to read
  if (Serial.available() > 0) {
    // Read the input as a string
    String input = Serial.readString();

    // Split the input into two parts
    int commaIndex = input.indexOf(',');
    if (commaIndex == -1) {
      Serial.println("Invalid input. Please enter two numbers separated by a comma.");
      return;
    }

    // Extract the two numbers
    uint32_t a = input.substring(0, commaIndex).toInt();
    uint32_t b = input.substring(commaIndex + 1).toInt();

    // Calculate the outputs of the functions
    uint32_t result_golden = ext_dsp_golden(a, b);
    uint32_t result = ext_dsp_codegen(a, b);

    // Compare the results and print the output
    if (result_golden == result) {
      Serial.println("The results are equal.");
    } else {
      Serial.print("The results are not equal. ");
      Serial.print("ext_dsp_golden: ");
      Serial.print(result_golden);
      Serial.print(", ext_dsp: ");
      Serial.println(result);
    }

    // Prompt for next input
    Serial.println("Enter two numbers (a, b): ");
  }
}

uint32_t ext_dsp_golden(uint32_t a, uint32_t b) {
  uint32_t c = __rv__ukadd8(a, b);
  return c;
}