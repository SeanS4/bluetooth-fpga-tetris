#include <DabbleESP32.h>

#define BTN_UP     13 // pinout on the ESP32
#define BTN_DOWN   12 // pinout on the ESP32
#define BTN_LEFT   14 // pinout on the ESP32
#define BTN_RIGHT  27 // pinout on the ESP32
#define BTN_START  26 // pinout on the ESP32
#define BTN_DROP   25
#define BTN_RESET  33
#define DEBOUNCE_DELAY 50  // in the millis


unsigned long lastDebounceTime_UP = 0;
bool lastState_UP = false;
bool debouncedState_UP = false;
unsigned long lastDebounceTime_START = 0;
bool lastState_START = false;
bool debouncedState_START = false;
unsigned long lastDebounceTime_SELECT = 0;
bool lastState_SELECT = false;
bool debouncedState_SELECT = false;

void setup() {
  Serial.begin(115200);
  Dabble.begin("Tetris_ECE_385");

  pinMode(BTN_UP, OUTPUT); // pinout looking down on breadboard up, down, left, right, start, drop, reset
  pinMode(BTN_DOWN, OUTPUT);
  pinMode(BTN_LEFT, OUTPUT);
  pinMode(BTN_RIGHT, OUTPUT);
  pinMode(BTN_START, OUTPUT);
  pinMode(BTN_DROP, OUTPUT);
  pinMode(BTN_RESET, OUTPUT);
}

void loop() {
  Dabble.processInput();
  unsigned long currentTime = millis();
  bool reading_UP = GamePad.isUpPressed();
  bool reading_START = GamePad.isStartPressed();
  bool reading_SELECT = GamePad.isSelectPressed();

  if (reading_UP != lastState_UP) {
    lastDebounceTime_UP = currentTime;
  }
  if ((currentTime - lastDebounceTime_UP) > DEBOUNCE_DELAY) {
    debouncedState_UP = reading_UP;
  }
  lastState_UP = reading_UP;
  digitalWrite(BTN_UP, debouncedState_UP ? HIGH : LOW);


  if (reading_START != lastState_START) {
    lastDebounceTime_START = currentTime;
  }
  if ((currentTime - lastDebounceTime_START) > DEBOUNCE_DELAY) {
    debouncedState_START = reading_START;
  }
  lastState_START = reading_START;
  digitalWrite(BTN_START, debouncedState_START ? HIGH : LOW);


  if (reading_SELECT != lastState_SELECT) {
    lastDebounceTime_SELECT = currentTime;
  }
  if ((currentTime - lastDebounceTime_SELECT) > DEBOUNCE_DELAY) {
    debouncedState_SELECT = reading_SELECT;
  }
  lastState_SELECT = reading_SELECT;
  digitalWrite(BTN_RESET, debouncedState_SELECT ? HIGH : LOW);


  digitalWrite(BTN_DOWN, GamePad.isDownPressed() ? HIGH : LOW);
  digitalWrite(BTN_LEFT, GamePad.isLeftPressed() ? HIGH : LOW);
  digitalWrite(BTN_RIGHT, GamePad.isRightPressed() ? HIGH : LOW);
  digitalWrite(BTN_DROP, GamePad.isCrossPressed() ? HIGH : LOW);

  delay(10);
}