NEC Large-screen display - Compute Module Configuration Tool
============================================================

A menu based tool for automatically downloading and configuring various components and settings for Raspbian OS on the Raspberry Pi Compute Module for use in compatible NEC Large-screen display models. 

See the `NEC Large-Screen Pxx4 and Vxx4 Displays - Raspberry Pi Compute Module Setup Guide
<http://www.necdisplay.com/support-and-services/raspberry-pi/>`_ for more information.

Download and run
----------------
Open a Terminal window in Raspbian and paste the following commands to automatically download and run the "nec_rpi_config_tool.sh" file. 

::

  cd Desktop
  wget https://raw.githubusercontent.com/NECDisplaySolutions/nec_rpi_config_tool/master/nec_rpi_config_tool.sh
  chmod a+x nec_rpi_config_tool.sh
  ./nec_rpi_config_tool.sh

  
Important Notes:
----------------

1. Best when run on a clean system.
2. Unselecting an item does not reverse a previous setting change.
3. This has been tested on Raspbian (Jessie and Stretch) with Desktop. There is a possibility it may not work
   correctly on other distros.
 
 
Description of Options
----------------------
UART
  Enables the UART on the Compute Module to allow communications with the host display. A reboot is required to activate.

SDK
  Downloads and installs NEC Python PD SDK which provides APIs for communicating with the host display. It will also install the Python Serial module if necessary. The UART option must be installed.

SDKTEST
  Downloads and installs an example Python file showing how to use the SDK APIs to communicate with the host display. The file will be installed as "/usr/share/NEC/test_routines_example.py". The UART and SDK options must be installed.

SHUTDOWN
  Downloads and installs a Python file that provides System Shutdown support by monitoring GPIO 23 - set low by the display to signal a shutdown. The file will be installed as "/usr/share/NEC/rpi_shutdown.py". Automatic run on startup will be added to "/etc/rc.local". Be sure to enable "SHUTDOWN SIGNAL" on the "COMPUTE MODULE" OSD menu. A reboot is required to activate.

WDT
  Downloads and installs a Python file that provides hardware based Watchdog Timer support by the host display. The file will be installed as "/usr/share/NEC/reset_display_wdt.py". Automatic run on startup will be added to "/etc/rc.local". Be sure to enable "WDT" and set the "PERIOD TIME" to a minimum of 30 seconds on the "COMPUTE MODULE" OSD menu. The UART and SDK options must be installed. A reboot is required to activate.

WALLP
  Downloads and installs NEC branded desktop wallpaper.

OVERS
  Disabled Video Overscan. A reboot is required to activate.

HDMI
  Sets the HDMI Pixel (video level range) Encoding to 0-255. A reboot is required to activate.

SSAVER
  Disables the Desktop Screen Saver to prevent screen blanking. A reboot is required to activate.
  
GPU
  Sets the GPU Memory allocation to 192MB. A reboot is required to activate.
  
UPDATE
  Downloads and updates the operating system and firmware.
  
KBD
  Sets the Keyboard layout to "US".

LIRC
  Enables LIRC (IR decoder) support. Be sure to enable \"IR SIGNAL\" on the \"COMPUTE MODULE\" OSD menu. A reboot is required to activate.
  
KODI
  Installs the KODI media player. Set \"CEC\" to \"ON\" on the \"CONTROL\" OSD menu to allow remote control using the display's IR remote. Control buttons are: 1 (\|<<), 2 (play), 3 (>>\|), 5 (stop), 6 (pause), ENT (select), EXIT, UP, DOWN, LEFT, RIGHT.

REBOOT
  Reboots the Compute Module when done.



License
--------------
The MIT License

Copyright (c) 2017 NEC Display Solutions, Ltd.
Partially based on 'raspi-config' by Alex Bradbury <asb@asbradbury.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

What's New
-----------
09/05/2017
Updated to update the Raspberry Pi firmware in addition to the OS.

08/31/2017
Update and test against new Raspbian release (Jessie and Stretch).  There is a 
possibility it may not operate correctly on other distros.

Sudo no longer required to run the file, it's included.


08/10/2017
Initial release.
