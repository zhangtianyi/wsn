/× 
 *  ------ Wireless Sensor Network Test Bed  -------- 
 *  
 *  Explanation: This program is used to get data using Smart City board sensors 
 *               and send the data to a meshlium via XBee module.
 *               It also supports Over The Air Programming (OTA) using XBee modules
 *   
 *  Version:           v1.1 
 *  Design:            Zhang Tianyi 
 *  Supervisor:        Song Xianlin
 */
 
 //initialize all the variables
packetXBee* paq_sent; 
int8_t state=0; 
int DATASIZE = 10;
long previous=0; 
char aux[200];

char* macHigh="          ";
char* macLow="           ";

int _battery = 0;
int _AccX = 0;
int _AccY = 0;
int _AccZ = 0;
int _RTCTemperature = 0;

float dust_value=0.0;
float temperature_value=0.0;
float audio_value=0.0;
float light_value=0.0;
float humidity_value=0.0     ;

char _temperature[10];
char _dust[10];
char _audio[10];
char _humidity[10];
int _Lux;
int lux;

float R = 0.0;
#define _destinationMac "0013A2004061CF2F"
#define key_access "LIBELIUM"
#define waspmote "WASPMOTE00000"
#define id_mote "B10"

void OTA();
void initArray();
void BlinkLED();
void get_Smart_Cities_Data();
void getData();
void get_Waspmote_Info();
void set_Data_To_Send();
void sendData();
int Lux_conversion(int readValue);

void setup()
{
    USB.begin();

  // Write Authentication Key in EEPROM memory
  for(int i=0;i<4;i++)
  {
    Utils.writeEEPROM(107+i,key_access[i]);
  }
  
  // Write Mote ID in EEPROM memory
  for(int i=0;i<13;i++)
  {
    Utils.writeEEPROM(147+i,waspmote[i]);
  }
  
  for(int i=0;i<3;i++)
  {
    Utils.writeEEPROM(160+i,id_mote[i]);
  }

  // Initialize Xbee module
  xbee802.init(XBEE_802_15_4,FREQ2_4G,NORMAL);
  xbee802.ON();
   
  // CheckNewProgram is mandatory in every OTA program
  xbee802.checkNewProgram(); 

//  USB.begin();
  SensorCities.setBoardMode(SENS_ON);
  delay(100);
  
  ACC.ON();
  RTC.ON();
  delay(100);
  
  // Get the XBee MAC address
  int counter = 0;  
  while(xbee802.getOwnMac()==1&&counter<4){
    xbee802.getOwnMac();
    counter++;
  }
  
  Utils.hex2str(xbee802.sourceMacHigh,macHigh,4);
  Utils.hex2str(xbee802.sourceMacLow,macLow,4);
  
  //initialize needed sensors on smartcity board
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_TEMPERATURE);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_DUST);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_AUDIO);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_LDR);
  SensorCities.setSensorMode(SENS_ON, SENS_CITIES_HUMIDITY);

  delay(1000); 
}

void loop()
{ 
  // Check if new data is available

  int i=0;
  for (i=0;i<48;i++)
  {
    OTA();
    BlinkLED();
  }
  initArray();
  getData();
  set_Data_To_Send();
  sendData();
}

void OTA()
{
  //OTA Listen time window code  
  long timeout = 5000; // must be in milliseconds
  long previous=millis();
  while( (millis()-previous<timeout) )
  {
     // Check if new data is available 
     if( XBee.available() ) 
     { 
       xbee802.treatData(); 
       // Keep inside this loop while a new program is being received 
       while( xbee802.programming_ON && !xbee802.checkOtapTimeout() ) 
       { 
         if( XBee.available() ) 
         { 
           xbee802.treatData(); 
         } 
       } 
     } 
       // Condition to avoid an overflow (DO NOT REMOVE)
    if( millis()-previous < 0 ) {previous=millis();}
  } 
}

// Blink LED1 while messages are not received
void BlinkLED()
{
  Utils.setLED(LED1,LED_ON);
  delay(500);
  Utils.setLED(LED1,LED_OFF);
  delay(500);
}

void initArray()
{
  for(int i=0; i<DATASIZE; i++)
  {
    _temperature[i] = '\0';
    _dust[i] = '\0';
    _audio[i] = '\0';
    _humidity[i] = '\0';
  }
}

void getData()
{
       get_Waspmote_Info();
       get_Smart_Cities_Data();
}

void get_Smart_Cities_Data()
{
  temperature_value = SensorCities.readValue(SENS_CITIES_TEMPERATURE);
  dust_value = SensorCities.readValue(SENS_CITIES_DUST);
  audio_value = SensorCities.readValue(SENS_CITIES_AUDIO);
  light_value = SensorCities.readValue(SENS_CITIES_LDR);
  humidity_value = SensorCities.readValue(SENS_CITIES_HUMIDITY);

  R = 10*(3.3-light_value)/(light_value);
  _Lux = pow(10,(log10(R)-1.78)/-0.78); //conversion of voltage obtain into LUX
  
  lux=Lux_conversion(_Lux);

  Utils.float2String(temperature_value, _temperature, 2);
  Utils.float2String(dust_value, _dust, 3);
  Utils.float2String(audio_value, _audio, 2);
  Utils.float2String(humidity_value, _humidity, 2);
}

void get_Waspmote_Info()
{
  _battery = PWR.getBatteryLevel();
}

void set_Data_To_Send()
{
       sprintf(aux,"<=>#NID:%s#STR:v1.1#TCA:%s#DUST:%s#MCP:%s#LUM:%d#HUMA:%s#BAT:%d#\r\n",id_mote, _temperature, _dust, _audio, lux, _humidity,_battery); 
}

void sendData()
{
  paq_sent=(packetXBee*) calloc(1,sizeof(packetXBee)); 
  paq_sent->mode=UNICAST; 
  paq_sent->MY_known=0; 
  paq_sent->packetID=0x52; 
  paq_sent->opt=0; 
  xbee802.hops=0; 
  xbee802.setOriginParams(paq_sent,MAC_TYPE); 
  xbee802.setDestinationParams(paq_sent,_destinationMac,aux, MAC_TYPE, DATA_ABSOLUTE);
  xbee802.sendXBee(paq_sent); 
  if( !xbee802.error_TX )
  {
    USB.println("ok");
  }
  USB.println("Hello World, this is Waspmote!");

  free(paq_sent);
  paq_sent = NULL;
}

// the previous program get the value is the number of Lux, while what we need is just the percent of the max luminosity value
// so we need this function to do the conversion
int Lux_conversion(int readValue)
{
  float lux = 0;
  if(readValue<5) lux=readValue;
  else if(readValue<10) lux=10+10*(readValue-5)/5;
  else if(readValue<20) lux=20+10*(readValue-10)/10;
  else if(readValue<30) lux=30+10*(readValue-20)/10;
  else if(readValue<40) lux=40+10*(readValue-30)/10;
  else if(readValue<50) lux=50+10*(readValue-40)/10;
  else if(readValue<100) lux=60+10*(readValue-50)/50;
  else if(readValue<200) lux=70+10*(readValue-100)/100;
  else if(readValue<300) lux=80+10*(readValue-200)/100;
  else if(readValue<500) lux=90+10*(readValue-300)/200;
  else lux=100;

  return(lux);
}
