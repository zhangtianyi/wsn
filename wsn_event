/*
 *  ------Waspmote XBee 802.15.4 Events Board Code------
 *
 *  Explanation: This code is for events board module with the following sensors(and port connection): PIR(7), Temp(5), Light(2)
 *
 *  Note: XBee modules must be configured at 38400bps and with API enabled. id_mote needs to be changed accordingly to the box's number.
 *
 *  Copyright (C) 2014 National University of Singapore
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
 *  Version:                2.0
 *  Design:                 Zhang Tianyi
 *  Supervisor:             Song Xianlin
 */

int Lux_conversion(int readValue);
packetXBee* paq_sent; 
int8_t state=0; 
long previous=0; 
int DATASIZE = 10;

char aux[100];
char* macHigh="          ";
char* macLow="           ";

//waspmote info
int _battery = 0;
int _AccX = 0;
int _AccY = 0;
int _AccZ = 0;
int _RTCTemperature = 0;

//sensors' data variables
float temperature_value=0.0;
float light=0.0;
float _pir=0.0;
float R=0.0;
int _Lux=0;
int lux=0;

char _temperature[10];

#define _destinationMac "0013A2004061CF2F" //MeshliumB
#define key_access "LIBELIUM"
#define waspmote "WASPMOTE0000"
#define id_mote "B14E" //Change accordingly to Waspmote box ID.

void setup()
{
  // Write Authentication Key in EEPROM memory
  for(int i=0;i<8;i++)
  {
    Utils.writeEEPROM(107+i,key_access[i]);
  }
  
  // Write Waspmote in EEPROM memory
  for(int i=0;i<12;i++)
  {
    Utils.writeEEPROM(147+i,waspmote[i]);
  }

  // Write Mote ID in EEPROM memory
  for(int i=0;i<4;i++)
  {
    Utils.writeEEPROM(159+i,id_mote[i]);
  }

  // Initialize Xbee module
  xbee802.init(XBEE_802_15_4,FREQ2_4G,NORMAL);
  xbee802.ON();
   
  // CheckNewProgram is mandatory in every OTA program
  xbee802.checkNewProgram();  

  //init USB port (for diagnostic test on computer)
  //USB.begin();
  
  //init events sensor board
  SensorEvent.setBoardMode(SENS_ON);
  delay(100);

  //Turns on accelerometer
  ACC.ON();

  //Real Time Clock RTC init function
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
  
}


void loop()
{
  initArray();
  get_Event_Data();
  get_Waspmote_Info();
  set_Data_To_Send();
  
  paq_sent=(packetXBee*) calloc(1,sizeof(packetXBee)); 
  paq_sent->mode=UNICAST; 
  paq_sent->MY_known=0; 
  paq_sent->packetID=0x52; 
  paq_sent->opt=0; 
  xbee802.hops=0; 
  xbee802.setOriginParams(paq_sent, "5678", MY_TYPE); 
  xbee802.setDestinationParams(paq_sent,_destinationMac,aux, MAC_TYPE, DATA_ABSOLUTE);
  xbee802.sendXBee(paq_sent); 
  
  free(paq_sent);
  paq_sent = NULL;
  
  int i=0;
  for (i=0;i<8;i++)
  {
    OTA();
    BlinkLED();
  }
 
}




/* Functions */

void initArray()
{
  for(int i=0; i<DATASIZE; i++)
  {
    _temperature[i] = '\0';
  }
}

void get_Event_Data()
{
  //obtain temperature reading and convert to degrees celcius
  temperature_value = SensorEvent.readValue(SENS_SOCKET5);
  temperature_value = (temperature_value-0.5)*100;
  Utils.float2String(temperature_value, _temperature, 2);
  
  //obtain light sensor reading and a rough conversion to lux
  light = SensorEvent.readValue(SENS_SOCKET2);
  R = 10*(3.3-light)/(light);
  _Lux = pow(10,(log10(R)-1.78)/-0.78); //conversion of voltage obtain into LUX
  lux=Lux_conversion(_Lux);
  
  //obtain presence sensor reading (0 - no presence sensed, 1 - prescene sensed.)
  _pir = SensorEvent.readValue(SENS_SOCKET7);
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
       sprintf(aux,"<=>#NID:%s#STR:v1.1#TCA:%s#LUM:%d#EVENT:%d#BAT:%d#\r\n",id_mote, _temperature, lux, (int)_pir,_battery);
}


void float2string(float f, char* c, uint8_t prec)
{
  int p = f;
  f -= p;
  while (prec > 0) 
  {
    f *= 10;
    prec--;
  }
  int q = f;
  sprintf(c, "%i.%i\0",p,q);
}

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
