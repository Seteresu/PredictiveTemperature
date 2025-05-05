c#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

// ======== WiFi credentials ========
const char* ssid = "Wokwi-GUEST";
const char* password = "";

// ======== HiveMQ Cloud credentials ========
//Note: Must change
const char* mqttServer = "fd69f6a6be424fd3aa5e479fd691d34c.s1.eu.hivemq.cloud";
const int mqttPort = 8883;

//Note: Must change
const char* mqttUsername = "hivemq.webclient.1746412890489";
const char* mqttPassword = "CU17#8nEd0*YDr%p$ziB";

// ======== MQTT Topics ========
//Note: Must change
const char* tempTopic = "room/data";     // Publishes temperature and humidity as CSV
const char* alertTopic = "room/alert";   // Publishes "ON"/"OFF" depending on threshold

// ======== MQTT Client Setup ========
//Handles any TLS
WiFiClientSecure secureClient;
PubSubClient client(secureClient);

// ======== Setup ========
void setup() {
  Serial.begin(115200);
  delay(100);

  // Connect to WiFi
  Serial.println("Connecting to WiFi...");
  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWiFi connected");

  // TLS configuration
  secureClient.setInsecure();  // WARNING: skips certificate validation. Fine for test, not prod.

  // MQTT configuration
  client.setServer(mqttServer, mqttPort);

  // Connect to MQTT
  reconnect();
}

// ======== MQTT Reconnection Logic ========
void reconnect() {
  while (!client.connected()) {
    Serial.print("Connecting to HiveMQ Cloud...");
    if (client.connect("ESP32Client", mqttUsername, mqttPassword)) {
      Serial.println(" connected!");
    } else {
      Serial.print(" failed, rc=");
      Serial.print(client.state());
      Serial.println(" retrying in 5 seconds...");
      delay(5000);
    }
  }
}

// ======== Loop Logic ========
void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();

  // Generate random temperature (between 20 and 35 degrees Celsius)
  float temperature = random(200, 350) / 10.0; // Random value between 20.0 and 35.0
  // Generate random humidity (between 40 and 70%)
  float humidity = random(400, 700) / 10.0; // Random value between 40.0 and 70.0

  Serial.printf("Temp: %.2f°C | Hum: %.2f%%\n", temperature, humidity);

  // Publish temperature and humidity to "room/data"
  String payload = String(temperature, 2) + "," + String(humidity, 2);
  client.publish(tempTopic, payload.c_str());

  // Check threshold and publish alert
  if (temperature > 30.0) {
    client.publish(alertTopic, "ON");
  } else {
    client.publish(alertTopic, "OFF");
  }

  delay(5000);  // Wait before next reading
}
