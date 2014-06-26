/****************************************
*  LOAD AUDIO CALIBRATION COEFFICIENTS
*
* for 284
*
*  UPLOAD THE CODE, AND RUN IT ONCE. The coefficient will be updated
*  because the sensitivity of the sensor and smart city board, 
*  the audio sensor, smart city board and the waspmote must be used as one set
*  there is a label on each audio sensor, smart city board and waspmote
*  we can only use the them with the same number on the label
*  or we have to calibrate the coefficients on the waspmote
****************************************/
#define DELAY_TIME 1
//---------------------------------------------------------------
int lookUpTable[11]={ 44,47,52,57,63,87,135,185,243,272,300};
//---------------------------------------------------------------

float value_sound=0;
float value=0;
float value2=0;
char* sound_value;
unsigned long previous=0;
uint8_t num_sec=0;
uint8_t car=0;
int ret=0;
char macDest[9];
char numMoteChar[8];
int LUT[11];

void setup()
{
  pinMode(DIGITAL6, OUTPUT);
  USB.ON();
  //RTC.ON();
  delay(50);
  // Powers de Sensors
  PWR.setSensorPower(SENS_3V3,SENS_ON);
  digitalWrite(DIGITAL6, HIGH);
  delay(50);

  setGain();

  setEepromParams();
  readEepromParams();

}

void loop()
{
  value=0;

  for(int g=0;g<1000;g++){
    value += analogRead(ANALOG6);
    delay(1);
  }
  value = value / 1000;


  USB.print("value:");
  USB.println((int)value);

  // Conversion a dB
  value2=(int)audio_conversion(value);

  free(sound_value);
  sound_value=NULL;
  sound_value=(char*)calloc(10,sizeof(char));
  sprintf(sound_value,"%d",(int)value2);

  USB.print("sound_value(dB):");
  USB.println(sound_value);
  USB.println("-------------:");
}

/*****************************************************
 *  Function audio_conversion
 *  Function used for audio conversion from bits to dB
 *
 *  Returns: audio in dB
 ******************************************************/
float audio_conversion(int readValue)
{
  float audio = 0;

  if(readValue<LUT[0]) audio=50.0;
  else if(readValue<LUT[1]) audio=50.0+5.0*(readValue-LUT[0])/(LUT[1]-LUT[0]);
  else if(readValue<LUT[2]) audio=55.0+5.0*(readValue-LUT[1])/(LUT[2]-LUT[1]);
  else if(readValue<LUT[3]) audio=60.0+5.0*(readValue-LUT[2])/(LUT[3]-LUT[2]);
  else if(readValue<LUT[4]) audio=65.0+5.0*(readValue-LUT[3])/(LUT[4]-LUT[3]);
  else if(readValue<LUT[5]) audio=70.0+5.0*(readValue-LUT[4])/(LUT[5]-LUT[4]);
  else if(readValue<LUT[6]) audio=75.0+5.0*(readValue-LUT[5])/(LUT[6]-LUT[5]);
  else if(readValue<LUT[7]) audio=80.0+5.0*(readValue-LUT[6])/(LUT[7]-LUT[6]);
  else if(readValue<LUT[8]) audio=85.0+5.0*(readValue-LUT[7])/(LUT[8]-LUT[7]);
  else if(readValue<LUT[9]) audio=90.0+5.0*(readValue-LUT[8])/(LUT[9]-LUT[8]);
  else if(readValue<LUT[10]) audio=95.0+5.0*(readValue-LUT[9])/(LUT[10]-LUT[9]);
  else audio=100.0;

  return(audio);
}






/*****************************************************
 *  Function setEepromParams
 *  Function used for setting EEPROM LUT (Look Up Table)
 *  for audio calibration
 *
 *  Returns: void
 ******************************************************/
void setEepromParams()
{

  int address=164;
  //int lookUpTable[11]={ 65,76,94,130,165,230,270,310,350,410,445};


  for(int i=0;i<11;i++)
  {
    eeprom_write_byte((unsigned char *) address, lookUpTable[i]/256);
    eeprom_write_byte((unsigned char *) address+1, lookUpTable[i]%256);
    address+=2;
  }

}




/*****************************************************
 *  Function readEepromParams
 *  Function used for reading EEPROM LUT (Look Up Table)
 *  for audio calibration
 *
 *  Returns: void
 ******************************************************/
void readEepromParams()
{
  int address=164;
  uint8_t low,high=0;

  for(int i=0;i<11;i++)
  {
    high=Utils.readEEPROM(address);
    low=Utils.readEEPROM(address+1);

    LUT[i]=high*256+low;
    USB.println(LUT[i],DEC);
    address+=2;
  }
}

void setGain()
{

    if( !Wire.I2C_ON ) Wire.begin();
    delay(100);
    Wire.beginTransmission(B0101110);
    Wire.send(B00000000);
    Wire.send(B01000011);
    Wire.endTransmission();
    delay(DELAY_TIME);

    Wire.beginTransmission(B0101110);
    Wire.send(B00010000);
    Wire.send(B01111000);
    Wire.endTransmission();

    delay(DELAY_TIME);
    if( Wire.I2C_ON && !ACC.isON && RTC.isON!=1){
        PWR.closeI2C();
        RTC.setMode(RTC_OFF, RTC_I2C_MODE);
    }
}

