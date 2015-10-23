Wikireader Adventures
=====================
The [Wikireader](https://github.com/wikireader/wikireader) is a small, inexpensive device intended for browsing an offline snapshot of Wikipedia. It has four hardware buttons, a touchscreen, a 240x208 monochrome LCD display, a MicroSD card slot, a fairly powerful Epson [S1C33E07](http://www.epsondevice.com/webapp/docs_ic/DownloadServlet?id=ID000410) 32-bit SoC and best of all it runs Forth! The device was designed to use Forth for factory tests, but with very simple alterations to the included software it can be made to run custom applications from source files stored on the MicroSD card.

On two occasions I have written personalized "desk accessories" for this platform. This repository is intended to gather together the materials for those projects as well as some of the reasoning behind their creation. Perhaps some day you might have a useful application idea for this or a similar device?

Development Tools
-----------------
Technically all you need to write Wikireader applications in Forth is a microSD reader, a computer, a Wikireader and nerves of steel. Thankfully, you can mitigate the pain of trial-and-error testing by taking advantage of the [Wikireader Simulator](http://createuniverses.blogspot.com/2011/03/wikireader-forth-simulator.html). Windows-specific source code is included, but I have found that it works just fine in Wine on a 32-bit Linux VM. If you have a serial interface available you can access some pins in the Wikireader battery compartment to enjoy wondrous "println debugging" facilities on the device itself. The Wikireader Github Wiki (phew) provides the [bootstrap source](https://github.com/wikireader/wikireader/blob/master/samo-lib/forth/ansi-forth.fs) for the onboard Forth interpreter, which is the best reference to the vocabularies available for accessing built-in hardware.

The simulator uses a slightly different configuration of [Ficl](http://www.forth.org/ficl.html) than that on the device and some subtleties of the hardware simulation are likewise inaccurate, but it can get your code a long way toward working correctly on the device. A few "gotchas" I have encountered:

- The Wikireader forth interpreter will crash on any source files which contain tab (`\t`) characters. Make sure you configure your text editor appropriately.

- The simulator has a definition for the primitive `move` in its startup file. The Wikireader does not define this word- I recommend instead making your programs rely on the `cmove` primitive. The simulator doesn't define `cmove`, so you might want to add `: cmove move ;` to its startup file.

- While working with file I/O I found that while on the simulator I can successfully use `open-file` in `w/o` mode to create and open a file that does not already exist, this operation will fail on the Wikireader. Calling `create-file` first works correctly on both the simulator and the device. There are probably more wrinkles and minor differences here, but this is the difference that actually bit me.

- There is no way to generate a power-button keypress from the simulator. You can poll this in software for short presses. (A 3-second press will force the device to power off.)

- The Wikireader's interpreter does not permit the word `s"` to be used in immediate mode; it must be used from within a word definition.

Deploying your Code
-------------------
Out of the box, the Wikireader has a file named "forth.elf" on its MicroSD card. Rename this to "kernel.elf" and it will run at power-on, executing a file named "forth.ini" from the card. All other files can be deleted if you wish. Consider backing up the contents of the card before you do any screwing around. I have included a copy of the forth interpreter binary renamed as "kernel.elf" in this repository for your convenience. I make no claims of ownership of this binary.

License
-------
With the exception of the kernel binary available in this repository, all documentation, source code and data is hereby released under the WTFPL license:

			DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
						Version 2, December 2004 
	
	 Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 
	
	 Everyone is permitted to copy and distribute verbatim or modified 
	 copies of this license document, and changing it is allowed as long 
	 as the name is changed. 
	
				DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
	   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
	
	  0. You just DO WHAT THE FUCK YOU WANT TO.
