Carrier Pigeon
=============

Carrier Pigeon is an iOS app that allows you to send messages to your friends while online and offline. If you go offline your messages are shared with the people next to you. If they reach the internet sooner than you, they will deliver the message on your behalf.
	
Say you're in the subway and you want to send your mom a message that you'll be late. Your message can piggy back on other users who access the internet sooner. These "Carrier Pigeons" will bring your message to your mom faster than you can because you don't have the internet they do!

Authors
=======
Abdullah Al-Syed (aza2105), Chris D’Angelo (cd2665), Ifeoma Okereke (iro2103), Riley Spahn (rbs2152)

Getting Started
===============

1. Install [cocoapods](http://cocoapods.org).
2. Before opening the project from command line run `pod install`.
3. Open the .xcworkspace file.

Changes Made to the XMPP Framework
==================================
The [verbose logging](https://github.com/robbiehanson/XMPPFramework/wiki/IntroToFramework#xmpp-logging) in the default [XMPP Framework](https://github.com/robbiehanson/XMPPFramework) has been turned off in certain files. 

Server Details
==============
CarrierPigeon uses a custom XMPP Server which is partially closed source. The following elements of the Ejabberd server are open source:
* [relay module](https://github.com/mychrisdangelo/mod_bot_relay)
* [push notifications module](https://github.com/mychrisdangelo/CarrierPigeonPushNotifications)
* [time stamp module](https://github.com/mychrisdangelo/mod_server_timestamp)

Documentation
=============

* [April 26, 2014 Demo Video](http://bit.ly/carrierpigeondemo)
* [May 5, 2014 Presentation](assets/CarrierPigeonPresentation.pdf)
* [May 12, 2014 Paper](assets/CarrierPigeonPaper.pdf)
