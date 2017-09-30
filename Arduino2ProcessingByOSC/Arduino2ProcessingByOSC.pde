
/** Arduino communication with Processing by OSC in order to send/receive from Wekinator 
  * modified by Jonas Landman (2017)

    This processing sketch allows communication to and from the Arduino (using the processing arduino library), 
    and then converts the data into/from OSC (using the oscP5 library) to communicate to/from other OSC compatible software/hardware, in particular Wekinator.
    But it can communicate with any software using OSC (eg. MaxMSP, Ableton Live) by configuring incoming and outcoming ports, and osc messages format.
    
    I/O
    analog pins listed in the array analogInputs are read, 
    digital pins listed in the array digitalInputs are read
    digital pins listed in the array pwmOutputs are used as PWM pins
    the rest of the digital pins are set to regular output pins 
    

 * In order for this sketch to communicate with the Arduino board, the StandardFirmata Arduino sketch must be uploaded onto the board
   (Examples > Firmata > StandardFirmata)
 * adapted from Processing Arduino to OSC example sketch - orignally written by Liam Lacey (http://liamtmlacey.tumblr.com)
 * OSC code adapted from 'oscP5sendreceive' by andreas schlegel
 * Arduino code taken from the tutorial at http://www.arduino.cc/playground/Interfacing/Processing
  

 */
 
 
//libraries needed for arduino communication
import processing.serial.*;
import cc.arduino.*;

//libraries needed for osc
import oscP5.*;
import netP5.*;

//variables needed for arduino communication
Arduino arduino;

//variables needed for osc
OscP5 oscP5;
NetAddress myRemoteLocation;

//set/change port numbers here
// ICI IL EST IMPORTANT DE BIEN CHOISIR LES PORTS 
// *INCOMING (pour les data en provenance des inputs Arduino et vers Wekinator : 6448 par ex.) 
// *OUTCOMING (pour les data en provenance de Wekinator, qui sont envoyé aux output Arduino, 12000 par ex.)
int incomingPort = 6448;
int outgoingPort = 12000;

//set/change the IP address that the OSC data is being sent to
//127.0.0.1 is the local address (for sending osc to an application on the same computer)
//ICI VERIFIER QUE L’HOST EST BIEN LE MÊME QUE POUR WEKINATOR (127.0.0.1 par défaut)
String ipAddress = "127.0.0.1";

//Arduino serial port
int arduinoPort = 1; //  voir la partie ci dessous "----for Arduino communication----" dans void setup


// Declarer les pins number pour les input digitaux. Les autres seront par defaut considerer comme output 
int[] analogInputs = {0,1}; //,2,3,4,5};
int[] digitalInputs = {};
int[] pwmOutputs = {5,6};
int[] servoOutputs= {}; //{7}; 
int[] digitalOutputs = {}; //{0,1}; //11,12,13}; on dirait que les rajouter fait buguer les sorties Servo


int count = 0;

//---------------setup code goes in the following function---------------------
void setup() 
{
  
  /* start oscP5, listening for incoming messages at port ##### */
  //for INCOMING osc messages (e.g. from Max/MSP)
  oscP5 = new OscP5(this,outgoingPort); //port number set above
  
  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. 
   */
  //for OUTGOING osc messages (to another device/application)
  myRemoteLocation = new NetAddress(ipAddress,incomingPort); //ip address set above
 
  //FrameRate
  size(360, 200);
  //frameRate(25);
  
  
  //----for Arduino communication----
  // Il faut peut etre changer le "arduinoPort" tout en haut, pour que dans "Arduino.list()[arduinoPort]" le bon numéro de port soit écrit.
  // Pour cela lire dans la console la liste des ports disponibles 
  println(Arduino.list()); // le premier port est numero 0, puis 1 etc.
  arduino = new Arduino(this, Arduino.list()[arduinoPort], 57600); //creates an Arduino object
  
   // set digital pins on arduino to input mode or output mode
   // En fonction des listes digitalInputs et digitalOutputs declarees plus haut
   for (int i=0; i<digitalInputs.length; i++){
     arduino.pinMode(digitalInputs[i], Arduino.INPUT);
   }
   for (int i=0; i<digitalOutputs.length; i++){
     arduino.pinMode(digitalOutputs[i], Arduino.OUTPUT);
     println(digitalOutputs[i]);
   }
   for (int i=0; i<pwmOutputs.length; i++){
     arduino.pinMode(pwmOutputs[i], Arduino.OUTPUT);
     println(pwmOutputs[i]);
   }
   for (int i=0; i<servoOutputs.length; i++){
     println(servoOutputs[i]);
     arduino.pinMode(servoOutputs[i], Arduino.SERVO);
   }

//Servo check if needed:
//   for(int k = 0; k<90; k++){
//     println(2*k);
//     arduino.servoWrite(7,2*k);
//     delay(50);
//   }
//   arduino.servoWrite(7,0);
}


//----------the following function runs continuously as the app is open------------
//In here you should enter the code that reads any arduino pin data, and sends the data out as OSC
void draw() 
{ 
  println();
  print("n°: ");
  println(count);
  count++;
  
  
  // READ ANALOG PINS:
  //read data from all the analog pins and send them out as osc data
  OscMessage analogInputMessage = new OscMessage("/wek/inputs"); //an OSC message in created in the form '/wek/inputs'
  print("ANALOG IN: ");
  for (int i=0; i<analogInputs.length; i++)
  {

    int pin = analogInputs[i];
    int analogInputData = int(arduino.analogRead(pin)); //analog pin i is read and put into the analogInputData variable
    print(analogInputData+", ");
    analogInputMessage.add(float(analogInputData)); //the analog data from pin i is added to the osc message
  }
  oscP5.send(analogInputMessage, myRemoteLocation); //the OSC message is sent to the set outgoing port and IP address
  println();
  
  // READ DIGITAL PINS:
  //read data from the digitalinput pins (declared at the begining in digitalInputs) and send them out as osc data
//  for (int i=0; i<digitalInputs.length; i++)
//  {
//      int pin = digitalOutputs[i];
//      int digitalInputData = arduino.digitalRead(pin); //digital pin i is read and put into the digitalInputData variable
//      OscMessage digitalInputMessage = new OscMessage("/wek/inputsDigital-"+pin); //an OSC message in created in the form '/wek/inputsDigital-pin'
//      digitalInputMessage.add(digitalInputData); //the digital data from pin i is added to the osc message
//      oscP5.send(digitalInputMessage, myRemoteLocation); //the OSC message is sent to the set outgoing port and IP address 
//
//  background(0);
//  
//  }

}



//--------incoming osc message are forwarded to the following oscEvent method. Write to the arduino pins here--------
//----------------------------------This method is called for each OSC message recieved------------------------------
void oscEvent(OscMessage theOscMessage) 
{
  /* print the address pattern and the typetag of the received OscMessage */
  println("### received an osc message.");
  //print(" addrpattern: "+theOscMessage.addrPattern());
  //print(" typetag: "+theOscMessage.typetag()+"\n"); //le nombre de "f" correspond au nombre de float envoye

  //-----------------------------------------------------------------------

  if(theOscMessage.addrPattern().equals("/wek/outputs") == true) //un message OSC est recu de la part de Wekinator
  {
       
    //PWM control (LEDs)
    //print("PWM");
    for(int i=0; i<pwmOutputs.length; i++){  
      int pin = pwmOutputs[i];
      //print(pin);
      float oscValue = theOscMessage.get(pin).floatValue();
      oscValue = map(oscValue, 0, 1, 0, 255);
      //print("="+oscValue+", ");
      arduino.analogWrite(pin, int(oscValue));
    }
    //println();
    
    
     //DIGITAL (1 or 0) control
     //print(" // DIGITAL:");
    for(int i=0; i<digitalOutputs.length; i++){  
      int pin = digitalOutputs[i];
      //print(", pin: "+pin);
      float oscValue = theOscMessage.get(pin).floatValue();
      if (oscValue<0.5){ //possible de remplacer par un threshold if (oscValue<0.5) par ex.
        //print(" Off");
        arduino.digitalWrite(pin, Arduino.LOW);
      }
      else{
        //print(" On");
        arduino.digitalWrite(pin, Arduino.HIGH);
      }     
    }
    //println();

        
    //SERVO control
    //print("Servo");
    for(int i=0; i<servoOutputs.length; i++){  
      int pin = servoOutputs[i];
      //print("pin: "+pin);
      float oscValue = theOscMessage.get(pin).floatValue();
      oscValue = oscValue*179;
      //print("="+oscValue+", ");
      arduino.servoWrite(pin, int(oscValue));
    }
    
  }
  
}
