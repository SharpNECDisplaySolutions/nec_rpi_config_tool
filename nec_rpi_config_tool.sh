#!/bin/bash
###############################################################
# nec_rpi_config_tool.sh                                      #
# NEC Display Solutions - Large-screen display                #
#  Raspberry Pi Compute Module Configuration Tool             #
#  for Raspbian OS                                            #
#                                                             #
# by Will Hollingworth & Tammy Denny                          #
#    NEC Display Solutions, Ltd.                              #
# partially based on 'raspi-config' by:                       #
#  Alex Bradbury <asb@asbradbury.org>                         #
#                                                             #
# Usage:                                                      #
#    First set the file permissons to allow execution.        #
#      From a terminal use:                                   #
#        chmod a+x nec_rpi_config_tool.sh                     #
#      or right-click on the file and select:                 #
#        Properties->Permissions->Execute->Anyone             #
#    Next run the script execute the following on the         #
#    command line:                                            #
#      ./nec_rpi_config_tool                                  #
#    Make the appropriate selections.                         #
#                                                             #
# Notes:                                                      #
#    1. Best when run on a clean system                       #
#    2. Unselecting an item does not reverse a previous       #
#       setting change.                                       #
#    3. This has been tested on Raspbian (Jessie and Stretch) #
#       Desktop - August 2017. Other distros may not function #
#       correctly.                                            #
#    4. The latest verson of this file is available on Github #
#  https://github.com/NECDisplaySolutions/nec_rpi_config_tool #
###############################################################

BUILD_NUMBER=220601

# File names and locations
CONFIG=/boot/config.txt
LIGHTDM=/etc/lightdm/lightdm.conf
NEC_SCRIPTS_DIR=/usr/share/NEC
NEC_SCRIPTS_SHUTDOWN_SCRIPT=rpi_shutdown.py
NEC_SCRIPTS_WDT_RESET=reset_display_wdt.py
NEC_PYTHON_SDK_TEST=test_routines_example.py
WALLPAPER_DIR2=/usr/share/pixel-wallpaper
WALLPAPER_DIR1=/usr/share/rpd-wallpaper
WALLPAPER_BITMAP_NAME=NEC_RaspberryPi_BG_Screen_1920x1080.jpg
CMDLINE_TXT=/boot/cmdline.txt
GITHUB_NEC_EXAMPLE_FILES=https://raw.githubusercontent.com/SharpNECDisplaySolutions/necpdsdk/master/examples
OUTPUT_MSG=""
DONE_UPDATE=0
ASK_TO_REBOOT=0
CM4=0
BULLSEYE=0

#####################################################
# do_install_nec_wallpaper                          #
# Install the NEC Wallpaper                         #
# Params: None                                      #
# Return: None                                      #
# Note:  Must be set as a "normal" user             #
#####################################################
do_install_nec_wallpaper() {
  if [ -e $WALLPAPER_DIR1 ]; then
    sudo wget -O $WALLPAPER_DIR1/$WALLPAPER_BITMAP_NAME http://www.necds-engineering.com/nec_pd_sdk/$WALLPAPER_BITMAP_NAME
    if [ $? != 0 ]; then return -1 ; fi
    # need to set this while as the 'pi' user
    pcmanfm --set-wallpaper $WALLPAPER_DIR1/$WALLPAPER_BITMAP_NAME

  else
    if [ -e $WALLPAPER_DIR2 ]; then
      sudo wget -O $WALLPAPER_DIR2/$WALLPAPER_BITMAP_NAME http://www.necds-engineering.com/nec_pd_sdk/$WALLPAPER_BITMAP_NAME
      if [ $? != 0 ]; then return -1 ; fi
      # need to set this while as the 'pi' user
      pcmanfm --set-wallpaper $WALLPAPER_DIR2/$WALLPAPER_BITMAP_NAME
    fi
  fi 
}


#####################################################
# show_error                                        #
# Shows OK or ERROR message                         #
# Params: $1 = error text                           #
# Params: $2 = error code                           #
# Return: None                                      #
#####################################################
show_error() {
  if [ "$2" == 0 ]; then 
    echo -e "setaf 2\nsetab 0" | tput -S ; tput bold
    printf "< OK > "
  else
    echo -e "setaf 1\nsetab 0" | tput -S ; tput bold
    printf "<ERROR> "
  fi
  echo -e "setaf 7\nsetab 0" | tput -S ; tput bold
  echo $1
  tput dim
}



#####################################################
# do_install_python_serial                          #
# Install the python-serial package                 #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  None                                       #
#####################################################
do_install_python_serial() {
  if [ $DONE_UPDATE -eq 0 ]; then
    sudo apt-get update
    if [ $? != 0 ]; then return -1 ; fi
    DONE_UPDATE=1
  fi
  sudo apt-get install python-serial
  if [ $? != 0 ]; then return -1 ; fi
}

#####################################################
# do_install_nec_pd_sdk                             #
# Install the NEC SDK                               #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  Have to use pip instead of easy_install.   #
#        easy_install is depracated and no longer   #
#        included.                                  #
#####################################################
do_install_nec_pd_sdk() {
  sudo pip install nec_pd_sdk
  if [ $? != 0 ]; then return -1 ; fi
  if [ $BULLSEYE == 0 ]
  then
    do_install_python_serial
    if [ $? != 0 ]; then return -1 ; fi
  fi
}

#####################################################
# do_update                                         #
# Update the RPI                                    #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  None                                       #
#####################################################
do_update() {
  if [ $DONE_UPDATE -eq 0 ] 
  then
    sudo apt update
    if [ $? != 0 ] 
    then 
      return -1 
    fi
    DONE_UPDATE=1
  fi
  sudo apt dist-upgrade -y
  if [ $? != 0 ] 
  then  
    return -1 
  fi
  sudo apt upgrade -y
  if [ $? != 0 ] 
  then 
    return -1 
  fi
  sudo apt autoremove -y
  if [ $? != 0 ]
  then
    return -1
  fi
}

#####################################################
# do_enable_uart                                    #
# Enable the UART                                   #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_enable_uart() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi
  # modify /boot/cmdline.txt to remove console=serial0,115200 
  sudo awk '{gsub("console=serial0,115200 ", "");print}' $CMDLINE_TXT > /tmp/cmdline.txt
  sudo cp /tmp/cmdline.txt $CMDLINE_TXT
  rm /tmp/cmdline.txt

  set_config_var enable_uart 1 $CONFIG
  if [ $CM4 -eq 0 ]
  then
    add_config_var dtoverlay dtoverlay uart1 uart1 $CONFIG
    set_config_var core_freq 250 $CONFIG
  fi

  ASK_TO_REBOOT=1
}

#####################################################
# do_set_hdmi_pixel_encoding                        #
# Set the HDMI pixel encoding in the config file    #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_set_hdmi_pixel_encoding() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi
  set_config_var hdmi_pixel_encoding 2 $CONFIG
  ASK_TO_REBOOT=1  
}

#####################################################
# do_enable_lirc                                    #
# Enable the dtoverlay lirc-rpi in the config file  #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_enable_lirc() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi
  if [ $CM4 == 1 ]
  then
    add_config_var dtoverlay dtoverlay gpio%-ir,gpio%-pin=18 gpio-ir,gpio-pin=18 $CONFIG
  else
    add_config_var dtoverlay dtoverlay gpio%-ir gpio-ir $CONFIG
  fi
  ASK_TO_REBOOT=1  
}

#####################################################
# do_set_gpu_memory                                 #
# Set the gpu_mem to 192 in the config file         #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_set_gpu_memory() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi
  set_config_var gpu_mem 192 $CONFIG
  ASK_TO_REBOOT=1  
}

#####################################################
# do_setup_wdt                                      #
# Download and setup the WDT.                       #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  NOT IMPLEMENTED                            #
#####################################################
do_setup_wdt() {
  # download WDT script
  if [ ! -e $NEC_SCRIPTS_DIR ]; then
    sudo mkdir $NEC_SCRIPTS_DIR
  fi
  if [ -e $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_WDT_RESET ]; then
    sudo rm $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_WDT_RESET
  fi
  sudo wget -O $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_WDT_RESET $GITHUB_NEC_EXAMPLE_FILES/$NEC_SCRIPTS_WDT_RESET
  if [ $? != 0 ]; then return -1 ; fi

  # Add the line to the "/etc/rc.local"
  # Look for the wdt_reset scipt in rc.local.
  # If it doesn't exist in the file ($?==1), then add it
  # If grep or awk has an error ($? != 0), then return with an error
  made_change=false
  /bin/grep -q "$NEC_SCRIPTS_WDT_RESET" /etc/rc.local
  check=$?
  if [ $check == 1 ]; then
    sudo awk -v line='python '$NEC_SCRIPTS_DIR/$NEC_SCRIPTS_WDT_RESET' &' '/^exit 0$/ {print line; print; next}; 1' /etc/rc.local > /tmp/rc.local
    check=$?
    made_change=true
  fi
  # If grep or awk has an error, return -1
  if [ $check != 0 ]; then return -1 ; fi
  if [ $made_change == true ]; then
    sudo cp /tmp/rc.local /etc/rc.local
    rm /tmp/rc.local
  fi
  # Set execute permissions to enable
  sudo chmod a+x /etc/rc.local
  ASK_TO_REBOOT=1  
}

#####################################################
# do_set_keyboard                                   #
# Set the keyboard layout to US.                    #
# Params: None                                      #
# Return: -1 on error                               #
#####################################################
do_set_keyboard() {
  # Set the keyboard layout
  sudo setxkbmap us
  if [ $? != 0 ]; then return -1 ; fi
}

#####################################################
# do_setup_shutdown_signal_script                   #
# Setup the shutdown script                         #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  None                                       #
#####################################################
do_setup_shutdown_signal_script()
{
  if [ ! -e $NEC_SCRIPTS_DIR ]; then
    sudo mkdir $NEC_SCRIPTS_DIR
  fi
  if [ -e $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_SHUTDOWN_SCRIPT ]; then
    sudo rm $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_SHUTDOWN_SCRIPT
  fi
  sudo wget -O $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_SHUTDOWN_SCRIPT $GITHUB_NEC_EXAMPLE_FILES/$NEC_SCRIPTS_SHUTDOWN_SCRIPT
  if [ $? != 0 ]; then return -1 ; fi

  # Add the line to the "/etc/rc.local"
  # Look for the shutdown scipt.
  # If it doesn't exist in the file ($?==1), then add it
  # If grep or awk has an error ($? != 0), then return with an error
  made_change=false
  /bin/grep -q "$NEC_SCRIPTS_SHUTDOWN_SCRIPT" /etc/rc.local
  check=$?
  if [ $check == 1 ]; then
      sudo awk -v line='python '$NEC_SCRIPTS_DIR/$NEC_SCRIPTS_SHUTDOWN_SCRIPT' &' '/^exit 0$/ {print line; print; next}; 1' /etc/rc.local > /tmp/rc.local
      check=$?
      made_change=true
  fi
  # If grep or awk has an error, return -1
  if [ $check != 0 ]; then return -1; fi

  if [ $made_change == true ]; then
      sudo cp /tmp/rc.local /etc/rc.local 
      rm /tmp/rc.local
  fi
  # Set execute permissions to enable  
  sudo chmod a+x /etc/rc.local
  ASK_TO_REBOOT=1  
}

#####################################################
# do_install_SDK_test_python_file                   #
# Install the SDK test routines example             #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  None                                       #
#####################################################
do_install_SDK_test_python_file()
{
  if [ ! -e $NEC_SCRIPTS_DIR ]; then
    sudo mkdir $NEC_SCRIPTS_DIR
  fi
  if [ -e $NEC_SCRIPTS_DIR/$NEC_PYTHON_SDK_TEST ]; then
    sudo rm $NEC_SCRIPTS_DIR/$NEC_PYTHON_SDK_TEST
  fi
  sudo wget -O $NEC_SCRIPTS_DIR/$NEC_PYTHON_SDK_TEST $GITHUB_NEC_EXAMPLE_FILES/$NEC_PYTHON_SDK_TEST
  if [ $? != 0 ]; then return -1 ; fi
}


#####################################################
# do_disable_screen_saver                           #
# Disable the screen saver                          #
# Params: None                                      #
# Return: None                                      #
# Note: The '%' before the dash (-) in              #
#       xserver-command has to be there to escape   #
#       the dash.  Otherwise, when the match is done#
#       with lua it treats the - as a pattern item  #
#       and does not find the key. The magic        #
#       characters in lua are:  ^$()%.[]*+-?        #
#####################################################
do_disable_screen_saver() {
  edit_ini_file "Seat:%*" "xserver%-command" "xserver-command=X -s 0 -dpms" $LIGHTDM

  ASK_TO_REBOOT=1
}


#####################################################
# edit_ini_file                                     #
# Edit an INI file. Either edit existing or add new.#
# Params: $1 = Section to find                      #
#         $2 = Key to find in section               #
#         $3 = Replacement/addition Line            #
#         $4 = Full Path to ini File                #
# Return: None                                      #
# Note:  This either edits an existing line or adds #
#        a new line in the given section.           #
#####################################################
edit_ini_file()
{
  sudo lua - "$1" "$2" "$3" "$4"<<EOF > /tmp/editini.txt

  local section=assert(arg[1])
  local key=assert(arg[2])
  local line_value=assert(arg[3])
  local fn=assert(arg[4])
  local file=assert(io.open(fn))
  local found_section=false
  local change_made=false
  
  for line in file:lines() do
    if line:match("^%["..section.."%]$") then
      found_section=true
    elseif found_section then
      if line:match("^#?%s*"..key.."=.*$") then
        change_made=true
        line=line_value
      elseif line:match("^%[.*%]$") then
        if not change_made then
           print(line_value)
        end
        found_section=false
      end
    end
    print(line)
  end

EOF
  sudo cp "/tmp/editini.txt" "$4"
  rm /tmp/editini.txt 
}

#####################################################
# add_config_var                                    #
# Add a config variable to the config file.         #
# Params: $1 = Key to find.                         #
#         $2 = Un-escaped key                       #
#         $3 = Value to add                         #
#         $4 = Unescaped Value to add               #
#         $5 = Full Path to file name               #
# Return: None                                      #
# Note:  This either edits an existing line or adds #
#        a new line. The search is made based on the#
#        entire config line.                        #
#####################################################
add_config_var() {
  sudo lua - "$1" "$2" "$3" "$4" "$5" <<EOF > "/tmp/addvar.txt"
  local key=assert(arg[1])
  local unescaped_key=assert(arg[2])
  local value=assert(arg[3])
  local unescaped_value=assert(arg[4])
  local fn=assert(arg[5])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."%s*=.*%s*"..value) then
      line=unescaped_key.."="..unescaped_value
      made_change=true
    end
    print(line)
  end

  if not made_change then
    print(unescaped_key.."="..unescaped_value)
  end
EOF
  sudo cp "/tmp/addvar.txt" "$5"
  rm "/tmp/addvar.txt"
}

#####################################################
# set_config_var                                    #
# Add a config variable to the config file.         #
# Params: $1 = Key to find.                         #
#         $2 = Value to add                         #
#         $3 = Full Path to file name               #
# Return: None                                      #
# Note:  This either edits an existing line or adds #
#        a new line. This searches based just on the#
#        key to the left of the "=" in the file.    #
#####################################################
set_config_var() {
  sudo lua - "$1" "$2" "$3" <<EOF > "/tmp/setvar.txt"
  local key=assert(arg[1])
  local value=assert(arg[2])
  local fn=assert(arg[3])
  local file=assert(io.open(fn))
  local made_change=false
  for line in file:lines() do
    if line:match("^#?%s*"..key.."=.*$") then
      line=key.."="..value
      made_change=true
    end
    print(line)
  end
  
  if not made_change then
    print(key.."="..value)
  end
EOF
  sudo cp "/tmp/setvar.txt" "$3"
  rm "/tmp/setvar.txt"
}

#####################################################
# get_config_var                                    #
# Get the config variable given the key             #
# Params: $1 = The key to look for                  #
#         $2 = The full path of the file name       #
# Return: The value the key points to.              #
# Note:  None                                       #
#####################################################
get_config_var() {
  lua - "$1" "$2" <<EOF
  local key=assert(arg[1])
  local fn=assert(arg[2])
  local file=assert(io.open(fn))
  for line in file:lines() do
  local val = line:match("^#?%s*"..key.."=(.*)$")
    if (val ~= nil) then
      print(val)
      break
    end
  end
EOF
}

#####################################################
# set_overscan                                      #
# Enable or Disable the overscan                    #
# Params: $1 = 1 enables and 0 disables             #
# Return: None                                      #
# Note:  None                                       #
#####################################################
set_overscan() {
  # Stop if /boot is not a mountpoint
  if ! mountpoint -q /boot; then
    return 1
  fi

  [ -e $CONFIG ] || sudo touch $CONFIG

  if [ "$1" -eq 0 ]; then # disable overscan
    sudo sed $CONFIG -i -e "s/^overscan_/#overscan_/"
    set_config_var disable_overscan 1 $CONFIG
  else # enable overscan
    set_config_var disable_overscan 0 $CONFIG
  fi
  ASK_TO_REBOOT=1  
}

#####################################################
# do_kodi                                           #
# Install KODI                                      #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  None                                       #
#####################################################
do_kodi() {
  if [ $DONE_UPDATE -eq 0 ]; then
    sudo apt-get update
    DONE_UPDATE=1
  fi
  sudo apt-get install kodi -y
  if [ $? != 0 ]; then return -1 ; fi
}

#####################################################
# do_install_initramfs                              #
# Install Bootloader                                #
# Params: None                                      #
# Return: -1 on error                               #
# Note:  No Longer Used since Yodeck is not         # 
#        maintaining the bootloader.                #
#####################################################
do_install_initramfs() {
  if [ $DONE_UPDATE -eq 0 ]; then
    sudo apt-get update
    DONE_UPDATE=1
  fi
  sudo apt-get install figlet hdparm pv ntfs-3g -y
  if [ $? != 0 ]; then return -1 ; fi

  rm -f /tmp/nec_initramfs.tar.gz
  rm -rf /tmp/nec_initramfs
  mkdir /tmp/nec_initramfs

  wget https://player-image.yodeck.com/nec_initramfs.tar.gz -O /tmp/nec_initramfs.tar.gz
  if [ $? != 0 ]; then return -1 ; fi

  tar xvf /tmp/nec_initramfs.tar.gz -C /tmp/nec_initramfs
  if [ $? != 0 ]; then return -1 ; fi

  pushd . > /dev/null
  cd /tmp/nec_initramfs
  sudo ./generate_yodeck_initramfs.sh
  if [ $? != 0 ]; then return -1 ; fi

  popd > /dev/null
}

#####################################################
# do_reboot                                         #
# Reboot the machine                                #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_reboot() {
  sudo sync
  sudo reboot
  exit 0
}


#####################################################
# do_finish                                         #
# Reboot the machine                                #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
do_finish() {
  if [ $ASK_TO_REBOOT -eq 1 ]; then
    whiptail --yesno "Would you like to reboot now?" 20 60 2
    if [ $? -eq 0 ]; then # yes
      do_reboot
    fi
  fi
  exit 0
}


#####################################################
# menu                                              #
# Main Menu of the script.  Allows the user to      #
# select a function to be performed.                #
# Params: None                                      #
# Return: None                                      #
# Note:  None                                       #
#####################################################
menu() {
  FUN=""
  if [ $CM4 == 1 ]
  then
    FUN=$(whiptail --separate-output --title "NEC Large-screen display Compute Module Configuration Tool $BUILD_NUMBER" --checklist "Selection Options" 22 79 15\
            "UART" "Enable UART (serial link to display - required for SDK)" on \
	    "SDK" "Download & install NEC Python PD SDK" on \
            "SDKTEST" "Download & install NEC PD SDK test file (requires SDK)" on \
            "SHUTDOWN" "Download & install System Shutdown support" on \
            "WDT_FAN" "Download & install Watchdog Timer and Fan Control (req SDK)" on \
            "WALLP" "Download & install NEC desktop wallpaper"    on \
            "OVERS" "Disable Video Overscan"   on  \
            "HDMI" "Set Pixel Encoding to 0-255"   on \
            "SSAVER" "Disable Desktop Screen Saver"   on \
            "GPU" "Set GPU Memory allocation to 192MB"    on \
            "UPDATE" "Update System (Warning: May take a long time)"    off \
	    "KBD" "Set Keyboard layout to US"    off \
	    "LIRC" "Enable LIRC (IR decoder)"    off \
 	    "KODI" "Install KODI media player"    off \
            "REBOOT" "Reboot when done"   off \
   3>&1 1>&2 2>&3)
  else
    FUN=$(whiptail --separate-output --title "NEC Large-screen display Compute Module Configuration Tool $BUILD_NUMBER" --checklist "Selection Options" 22 79 15\
            "UART" "Enable UART (serial link to display - required for SDK)" on \
	    "SDK" "Download & install NEC Python PD SDK" on \
            "SDKTEST" "Download & install NEC PD SDK test file (requires SDK)" on \
            "SHUTDOWN" "Download & install System Shutdown support" on \
            "WDT_FAN" "Download & install Watchdog Timer and Fan Control (req SDK)" on \
            "WALLP" "Download & install NEC desktop wallpaper"    on \
            "OVERS" "Disable Video Overscan"   on  \
            "HDMI" "Set Pixel Encoding to 0-255"   on \
            "SSAVER" "Disable Desktop Screen Saver"   on \
            "GPU" "Set GPU Memory allocation to 192MB"    on \
            "UPDATE" "Update System (Warning: May take a long time)"    off \
	    "KBD" "Set Keyboard layout to US"    off \
	    "LIRC" "Enable LIRC (IR decoder)"    off \
 	    "KODI" "Install KODI media player"    off \
            "REBOOT" "Reboot when done"   off \
   3>&1 1>&2 2>&3)
  fi
  RET=$?
  if [ $RET != 0 ]; then
    return 0
  elif [ $RET = 0 ]; then
 
    for choice in $FUN
      do
      case $choice in
      SDK) OUTPUT_MSG+="\nSDK) Python NEC PD SDK test file will be:\n   $NEC_SCRIPTS_DIR/$NEC_PYTHON_SDK_TEST\n   Be sure to enable \"MONITOR CONTROL\" on the \"COMPUTE MODULE\" OSD menu." ;;
      SDKTEST) OUTPUT_MSG+="\nSDKTEST) Python NEC PD SDK test file will be:\n   $NEC_SCRIPTS_DIR/$NEC_PYTHON_SDK_TEST" ;;
      WDT_FAN) OUTPUT_MSG+="\nWDT_FAN) Watchdog Timer and Fan Control file will be:\n   $NEC_SCRIPTS_DIR/$NEC_SCRIPTS_WDT_RESET\n   Edit the file configuration settings as necessary to disable either\n   function or set the operating parameters.\n   Be sure to enable \"WDT\" and set the \"PERIOD TIME\" to a minimum of 30\n   seconds on the \"COMPUTE MODULE\" OSD menu. Startup will be added to\n   \"/etc/rc.local\"." ;;
      SHUTDOWN) OUTPUT_MSG+="\nSHUTDOWN) Be sure to enable \"SHUTDOWN SIGNAL\" on the \"COMPUTE MODULE\"\n   OSD menu. Startup will be added to \"/etc/rc.local\"." ;;
      LIRC) OUTPUT_MSG+="\nLIRC) Be sure to enable \"IR SIGNAL\" on the \"COMPUTE MODULE\" OSD menu." ;;
      KODI) OUTPUT_MSG+="\nKODI) Set \"CEC\" to \"ON\" on the \"CONTROL\" OSD menu to allow remote control\n   using the display's IR remote." ;;
	  esac  
    done      
    if [ -n "$OUTPUT_MSG" ]; then
      whiptail --msgbox "Notice: $OUTPUT_MSG" 24 80 1
    fi  
    for choice in $FUN
    do
      case $choice in
      SDK) do_install_nec_pd_sdk ;  ERR=$? ; show_error $choice $ERR ;;
      SDKTEST) do_install_SDK_test_python_file ;  ERR=$? ; show_error $choice $ERR ;;
      SHUTDOWN) do_setup_shutdown_signal_script ;  ERR=$? ; show_error $choice $ERR ;;
      WDT_FAN) do_setup_wdt ;  ERR=$? ; show_error $choice $ERR ;;
      UART) do_enable_uart ;;
      WALLP) do_install_nec_wallpaper ; ERR=$? ; show_error $choice $ERR ;;
      OVERS) set_overscan 0 ;;
      HDMI) do_set_hdmi_pixel_encoding ;;
      SSAVER) do_disable_screen_saver ;;
      GPU) do_set_gpu_memory ;;
      LIRC) do_enable_lirc ;;
      UPDATE) do_update ;  ERR=$? ; show_error $choice $ERR ;;
      KBD) do_set_keyboard ;  ERR=$? ; show_error $choice $ERR ;;
      KODI) do_kodi ;  ERR=$? ; show_error $choice $ERR ;;
      REBOOT) do_reboot ;;
	*) whiptail --msgbox "Unrecognized option: $choice" 20 60 1 ;;
    esac || whiptail --msgbox "There was an error running option $choice" 20 60 1

    done
    do_finish	
 fi
}


# Verify that the script has not been run as root.
if [ $(id -u) == 0 ]; then
  printf "Script must NOT be run as root. Try 'nec_rpi_config_tool.sh'\n"
  exit 1
fi


# Get the OS version/compute module version
/bin/grep -q "Module 4" /proc/device-tree/model
if [ $? ==  0 ]
then
  CM4=1
fi

/bin/grep -q "bullseye" /etc/os-release
if [ $? == 0 ]
then
  BULLSEYE=1
fi

# Execute the menu and exit
menu
exit
