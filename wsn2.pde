/*
 *  ------Waspmote XBee 802.15.4 Events Board Code------
 *
 *  Explanation: This code is for events board module with the following sensors(and port connection): PIR(7), Temp(5), Light(2)
 *
 *  Note: XBee modules must be configured at 38400bps and with API enabled. id_mote needs to be changed accordingly to the box's number.
 *
 *  Copyright (C) 2013 National University of Singapore
 *  www.nus.edu.sg
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 2 of the License, or
 *  (at your option) any later version.
 * 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 * 
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *  Version:                1.0
 *  Design:                 Tan Xian Ling and Li Wenfeng
 *  Implementation:         Tan Xian Ling and Li Wenfeng
 */
packetXBee* paq_sent; 
int8_t state=0; 
int DATASIZE = 10;
long previous=0; 
char aux[200];

char* macHigh="          ";
char* macLow="           ";

//int aux_1 = 0;
//int aux_2 = 0;

//int value = 0;

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

int dataFlag=0;
float R = 0.0;
#define _destinationMac "0013A20040AAF116"
#define key_access "LIBELIUM"
#define waspmote "WASPMOTE00000"
#define id_mote "A08"

void OTA();
void initArray();
void BlinkLED();
void get_Smart_Cities_Data();
void getData();
void get_Waspmote_Info();
void set_Data_To_Send();
void sendData();

void setup()
{
  
  // Write Authentication Key in EEPROM memory
  for(int i=0;i<8;i++)
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
  OTA();
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
  delay(100);
  Utils.setLED(LED1,LED_OFF);
  delay(100);
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
   switch(dataFlag)
  {
     case 0:
       get_Waspmote_Info();
       break;
     
     case 1:
       get_Smart_Cities_Data();
  } 
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

  Utils.float2String(temperature_value, _temperature, 2);
  Utils.float2String(dust_value, _dust, 3);
  Utils.float2String(audio_value, _audio, 2);
  Utils.float2String(humidity_value, _humidity, 2);
}

void get_Waspmote_Info()
{
  _battery = PWR.getBatteryLevel();
  _AccX = ACC.getX();
  _AccY = ACC.getY();
  _AccZ = ACC.getZ();
  _RTCTemperature = RTC.getTemperature();
}

void set_Data_To_Send()
{
  switch(dataFlag)
  {
     case 0:
       dataFlag = 1;
       sprintf(aux,"<>S1 mac:%s%s id:%s x:%d y:%d z:%d temp:%d bat:%d<>\r\n" ,macHigh, macLow, id_mote, _AccX, _AccY, _AccZ, _RTCTemperature, _battery);
       break;     
     case 1:
       dataFlag = 0;
       sprintf(aux,"<>S2 mac:%s%s id:%s T:%s D:%s M:%s L:%d H:%s<>\r\n" ,macHigh, macLow, id_mote, _temperature, _dust, _audio, _Lux, _humidity); 
       break;    
     default: 
       dataFlag = 0;
  }
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

  free(paq_sent);
  paq_sent = NULL;
}
