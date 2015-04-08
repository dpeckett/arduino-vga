/*
* GhettoVGA Interface Library Example
*/

// Only supports upper case characters, ASCII 0x20 - 0x40
void writeCharacter(unsigned char row, unsigned char col, unsigned char val) {
  unsigned char buf[4] = {0x8D, 0, 0, 0};
  buf[1] = col;
  buf[2] = row;
  buf[3] = val-0x20;
  Serial.write(buf, 4);
}

void writeString(unsigned char row, unsigned char col, const char *str) {
  const char *ptr;
  for(ptr = str; *ptr; ptr++, col++) writeCharacter(row, col, *ptr);
}

unsigned char readCharacter(unsigned char row, unsigned char col) {
  unsigned char buf[4] = {0x8A, 0, 0, 0};
  buf[1] = col;
  buf[2] = row;
  Serial.write(buf, 4);
  return Serial.read() + 0x20;
}

void clearRow(unsigned char row) {
  for(int col = 0; col < 32; ++col) writeCharacter(row, col, ' ');
}

void clearScreen() {
  unsigned char buf[4] = {0x8C, 0, 0, 0};
  Serial.write(buf, 4);
}
 
void setup() {
  Serial.begin(115200);
}

void loop() {
  writeString(0, 0, "HELLO WORLD!");
  delay(1000);
  clearScreen();
  delay(1000);
}
