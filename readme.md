# **GalaKong: A Galaga Themed Shoot 'Em Up Plugin for Donkey Kong (and Donkey Kong Junior)** #

Tested with latest MAME version 0.244

Fully compatible with all MAME versions from 0.227

Jumpman is assisted by an accompanying ship which can take out enemies including barrels, fireballs, firefoxes, pies and springs.  Bonus points are awarded for destroying multiple targets.


![GalaKong Plugin Screenshots](https://i.imgur.com/R3BX3Wv.png)


The default mode is single player,  with your ship following Jumpman's position.  Jumpman can control the ship independently when he is on a ladder (or a vine).  The jump button also shoots.

There is also a 2 player co-op mode where a 2nd player controls the ship using separate controls.
 	
	P1 Start = Left
	P2 Start = Right	
	Coin     = Fire

Bonus points are awarded for destroying multiple targets.

The hack features a scrolling starfield background and animated explosions.
You can disable some features by setting environmental variables before you launch MAME.

```SET GALAKONG_NOSTARS=1```

```SET GALAKONG_NOEXPLOSIONS=1```

The hack becomes "Extreme Galakong" when used in combination with the "Wild Barrel Hack" rom.

  
## Installing and running
 
The Plugin is installed by copying the "galakong" folder into your MAME plugins folder.
Galaga game sounds are supported on Windows and Raspberry Pi 4/400.

The Plugin is run by adding `-plugin galakong` to your MAME arguments e.g.

```mame dkong -plugin galakong```  

or

```mame dkongjr -plugin galakong```  


## Feedback

Please send feedback to jon123wilson@hotmail.com

Jon

