Background
----------
I need a controller that will switch my porch light on at sunset and remain on for 3 hours.
If I went out for the evening and return home after the light was switched off, the light must be switched on for 10 minutes to allow me to park the car and enter the house.
  
For safety reasons, the light and the controller will be powered by 12V DC supplied by a commercial converter which is plugged into the electrical mains (220V AC, in my case).
  
Design decisions
----------------
- Initially, I wanted to create the entire controller using logic ICs; eg. timer chips, logic gates, etc. But, due to availability issues of suitable chips from my local suppliers, I decided to use an ATTiny85 to do as much as possible, but program it with assembly for fun.
- The light level sensor is a voltage divider formed by an LDR and a potentiometer (and a fixed resistor if necessary).
  The potentiometer allows the controller to be set at a suitable arbitrary level when the light must be switched on.
  The uC will read the analog value between the LDR and the pot/resistor to determine "Night mode" according to a hard-coded treshold value.
  Another hard-coded higher threshold will determine "Day mode"; ie. a Schmitt trigger will be created in software.
- An alternative design would be to use a hardware Schmitt trigger (using a 555 or an opAmp) which will allow a digital input for the uC.
- I have not yet designed the motion detector, but assuming that it will be an assembled component providing a digital output.

Challenges
----------
- The most significant challenge is the 3 hour timer. Although the timing is not critical, an analogue RC circuit is impractical. I decided to use the ATTiny's timer, but since it is an 8-bit timer, counting the large number of seconds (ie. >>255) will need special attention.
- Perhaps an external shift register with LEDs would make an entertaining countdown display?

Inputs
------
- Light level sensor (analog)
- Motion sensor (digital)

Outputs
-------
- Motion detector power
- Light power

Components
----------
- ATTiny85 
- LDR and potentiometer
- A motion sensor
