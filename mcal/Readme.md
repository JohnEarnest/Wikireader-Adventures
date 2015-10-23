MCal
====
MCal is a page-a-day calendar application which can load a database of fascinating facts from a text file called `FACTS.TXT`:

![main view](https://raw.githubusercontent.com/JohnEarnest/Wikireader-Adventures/master/mcal/screenshots/mcalmain.png) ![detail](https://raw.githubusercontent.com/JohnEarnest/Wikireader-Adventures/master/mcal/screenshots/mcaldetail.png)

This program was written over the course of about two weeks. Some aspects of the design are rather crude and cobbled together. The lack of a real-time clock in the Wikireader seriously limits the utility of a program like this- while the device can remember what date was last viewed via a timestamp stored in a file called `DATE.TXT`, the user still needs to manually advance the page each day.

The calendar logic is also implemented fairly crudely- when you step forward to a date it advances a series of registers one day at a time until it reaches the desired date. To move back, it resets to epoch (January 1st, 2014) and steps forward. Time moves slower the further you get from the epoch, and years take noticeably longer than months or days. Writing the code this way was fairly easy to verify, though, and while perhaps this is just validating my laziness I couldn't help but feel it produced a kind of poetic symbolism in its action. When I made the device I figured it would have a lifespan of a few years at most, and the algorithms employed are fast enough within that time range. Better than it ultimately needed to be.

The word-wrapping routines for text display do a fairly good job, and I would later tweak and generalize them for my next project, the Wikiwriter.
