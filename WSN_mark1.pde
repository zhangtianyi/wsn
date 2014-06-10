/*  
 *  ------ Wireless Sensor Network Test Bed  -------- 
 *  
 *  Explanation: This program is used to get data using Smart City board sensors 
 *               and send the data to a meshlium via XBee module.
 *               It also supports Over The Air Programming (OTA) using XBee modules
 *   
 *  Version:           0.1 
 *  Design:            Zhang Tianyi 
 *  Supervisor:        Song Xianlin
 */

//Include all the necessary library
#include <WaspSensorCities.h>
#include <WaspXBee802.h>
#include <WaspFrame.h>

// Pointer an XBee packet structure 
packetXBee* packet; 

// Node identifier
char* NODE_ID="A01";

// Destination MAC address
char* MAC_ADDRESS="0013A2004090A932";

// Initial sensor variables
float temperature = 0.0;
float dust = 0;
float audio = 0;
float light = 0;
float humidity = 0;

// define Authentication Key and Mote ID for OTAP
#define key_access "LIBELIUM"
#define id_mote "A01"


void setup()
{
  // 0. Init USB port for debugging
  USB.ON();
  USB.println(F("test"));


  // 1.1 Switch on the XBee module
  xbee802.ON();  
  
  // 1.2 Switch on the Smart City board to use needed the sensors
  SensorCities.ON();
    
  // 1.3 Set up the OTAP
  xbee802.checkNewProgram();  
  
  // 1.4 Set up RTC 
  RTC.ON();
  
  // 1.5 Switch on the the needed sensors on the Smart City board
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_TEMPERATURE);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_DUST);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_AUDIO);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_LDR);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_HUMIDITY);
  
    // 1.6 Write Authentication Key to EEPROM memory
  Utils.setAuthKey(key_access);
  
  //  1.7 Write Mote ID to EEPROM memory
  Utils.setID(id_mote);
  
}
 
void loop()
{
   ////////////////////////////////////////////////
  // 2. Measure corresponding values
  ////////////////////////////////////////////////
  USB.println(F("Measuring sensors..."));

  temperature = SensorCities.readValue(SENS_CITIES_TEMPERATURE);
  dust = SensorCities.readValue(SENS_CITIES_DUST);
  audio = SensorCities.readValue(SENS_CITIES_AUDIO);
  light = SensorCities.readValue(SENS_CITIES_LDR);
  humidity = SensorCities.readValue(SENS_CITIES_HUMIDITY);

  ////////////////////////////////////////////////
  // 3. Message composition
  ////////////////////////////////////////////////

  // 3.1 Create new frame
  frame.createFrame(ASCII, "A01");
  
  // 3.2 Add frame fields
  frame.addSensor(SENSOR_STR, "senor reading");  

  frame.addSensor(SENSOR_TCA, temperature);
  frame.addSensor(SENSOR_DUST, dust);
  frame.addSensor(SENSOR_MCP, audio);
  frame.addSensor(SENSOR_LUM, light);
  frame.addSensor(SENSOR_HUMA, humidity);

  frame.addSensor(SENSOR_BAT, PWR.getBatteryLevel());
  
  USB.println(F("ok"));
  
  // 3.3 Print frame
  // Example: 
  //Current ASCII Frame: 
  // Length:  97
  // Frame Type (decimal): 128
  // HEX:     3C 3D 3E 80 07 23 33 38 32 35 33 38 31 36 32 23 41 30 31 23 30 23 53 54 52 3A 73 65 6E 6F 72 20 72 65 61 64 69 6E 67 23 54 43 41 3A 32 33 2E 32 32 23 44 55 53 54 3A 30 2E 34 33 30 23 4D 43 50 3A 35 30 2E 23 4C 55 4D 3A 37 34 2E 31 39 33 23 48 55 4D 41 3A 36 30 2E 31 23 42 41 54 3A 36 39 23 
  // String:  <=>#382538162#A01#0#STR:senor reading#TCA:23.22#DUST:0.430#MCP:50.#LUM:74.193#HUMA:60.1#BAT:69#

  frame.showFrame();


  ////////////////////////////////////////////////
  // 4. Send message
  ////////////////////////////////////////////////

  // 4.1 Set parameters to packet:
  packet = (packetXBee*) calloc(1,sizeof(packetXBee)); // Memory allocation
  packet -> mode = UNICAST; // Choose transmission mode: UNICAST or BROADCAST

  // 4.2 Set destination XBee parameters to packet
  xbee802.setDestinationParams(packet, MAC_ADDRESS, frame.buffer, frame.length, MAC_TYPE); 

  // 4.3 Send XBee packet
  xbee802.sendXBee(packet);

  // 4.4 Check TX flag
  // if the frame sent successfully, it will print "OK" on serial monitor and turn on the yellow LED for 1s. Or it will print "error" and no LED turns on
  if( xbee802.error_TX == 0 ) 
  {
    USB.println(F("ok"));
    Utils.setLED(LED1, LED_ON);
    delay(1000);
    Utils.setLED(LED1, LED_OFF);
  }
  else 
  {
    USB.println(F("error"));
  }

  // 4.5 Free memory
  free(packet);
  packet = NULL;
  
  ////////////////////////////////////////////////
  // 5 time control and check OTAP
  ////////////////////////////////////////////////
  
  // OTAP window for 59s with LED blinking
  int i=0;
  for(i=0; i<59; i++)
  {
      // Check if new data is available
  if( xbee802.available() )
  {
    xbee802.treatData();
    // Keep inside this loop while a new program is being received
    while( xbee802.programming_ON  && !xbee802.checkOtapTimeout() )
    {
      if( xbee802.available() )
      {
        xbee802.treatData();
      }
    }
  }
  // blink the red LED
  Utils.setLED(LED0, LED_ON);
  delay(500);
  Utils.setLED(LED0, LED_OFF);
  delay(500);
  }
  
}
