#!/bin/bash
#### This script is copyright Tadd Torborg KA2DEW 2014-2025.  All rights reserved.
##### Please leave this copyright notice in the document and if changes are made,
##### indicate at the copyright notice as to what the intent of the changes was.
##### Thanks. - Tadd Raleigh NC

cd ~
echo "######"
sleep 0.5
echo "######"
sleep 0.5
#### 012  fix echo stating the name of the instructions web page.
#### 013  change the final shutdown from shutdown -rF  to shutdown -r.    The F is not supported in Wheezy JESSIE.
#### JESSIE-101  add support for JESSIE.
#### JESSIE-102  call for FSCK at the end when we reboot.
#### JESSIE-103  add debug code for downloading tarpn.service.
#### JESSIE-104  add a check for a flag to make sure tarpn-start-1 completed.
#### JESSIE-105  add a note that you can ignore the NODE INIT error message
#### JESSIE-106  add PI SHUTDOWN service
#### JESSIE-107  Remove some excess copied stuff from PI SHUTDOWN installer
#### JESSIE-108  tarpn.log has moved to /var/log/tarpn.log.  Change where we cat the log from.
#### JESSIE-109  do update and dist-upgrade again, now that the boot firmware has been updated.
#### JESSIE-110  use com7 for tarpn host instead of com4
#### JESSIE-111  Put back com4 link to tty8  sudo ln -s /home/pi/minicom/com4 tty8
#### STRETCH-001  support for STRETCH
#### STRETCH-002  turn off systemctl status because that prompted the user for Q and we don't need it.
#### STRETCH-003  add some -y options to apt-get for updates and upgrades
#### STRETCH-004  add install of statusmonitor.sh and bbs checker application
#### STRETCH-005  install linktest-app and listen-app
#### STRETCH-006  add download of rx_tarpnstat, service, app and shellscript.  Change the name of the service downloads from the web site from .service to -service.txt
#### STRETCH-007  add download of sendroutestocq application.
#### STRETCH-008  Minor changes to fix bug K4RGN ran into around tarpn-service.txt
#### STRETCH-009  Fix bug in tarpn_start1_finished.flag check
#### STRETCH-010  Write to tarpn_command.log on completion
#### BUSTER-001   Change the name to remove confusion from STRETCH to BUSTER
#### BUSTER-002   don't proceed if tarpn_start2 has already been run
#### BUSTER-003   remove specific TNC-PI claims.
#### BULLSEYE-001 don't subscribe to the I2C group anymore
#### BULLSEYE-002 fix trailing null in source-url
#### BULLSEYE-003 Create the tarpn.log before we use it - write good data into tarpncommand log file as well as tarpn.log.
#### BULLSEYE-004 Use the ZIP file version of rx_tarpnstatapp.
#### BULLSEYE-005 Move the install of ZIP to tarpn_start1dl.
#### BULLSEYE-006 move bbs-checker and sendroutestocq to being go via ZIP file.
#### BULLSEYE-007 fix two errors where the ZIP operations were wrongly referencing zip-temp.
#### BULLSEYE-008 Fix error in version string, affecting tarpn sysinfo.
#### BULLSEYE-009 Fix bug where rx_tarpnstat050app was still expected. Now rx_tarpnstatapp.
#### BULLSEYE-010 Add install of logfiletruncate.sh
#### BULLSEYE-011 delete/rm leftover zip-files before quiting tarpn-start2
#### BULLSEYE-012 fix install of linktest via zip for bullseye OS
#### BULLSEYE-013 fix install of listen via zip for bullseye OS
#### BULLSEYE-014 Change the name of the log we create here to tarpn_startstop.log - also create /var/log/tarpn_service.log here
#### BULLSEYE-015 tarpn.log features are moved to tarpn_service.log.
#### BULLSEYE-016 minor change to the ignore-the-error message before starting TARPN service.
#### BULLSEYE-017 move log file creation to tarpn-start-1dl
#### BULLSEYE-018 it is ok for tarpn_service.log to exist.  remove failure
#### BULLSEYE-019 just before starting pi-shutdown service, write to the log announcing that we're doing so.
#### BULLSEYE-020 Install Midori web browser
#### 10-15-2022 BULLSEYE-021  add a -y directive to the midori install
#### 03-22-2023 BULLSEYE-022  download 10K test file
#### 05-06-2023 BULLSEYE-023  use tarpnget and tarpnget_path_and_filename
#### 06-05-2023 BULLSEYE-024  Add ncpacket wallpaper for Raspberry PI desktop
#### 06-08-2023 BULLSEYE-025  Fix address for storing the ncpacket wallpaper
#### 06-08-2023 BULLSEYE-026  Change the error message numbers to be somewhat consistant and non redundant
#### 01-01-2024 BULLSEYE-027  Use CONTROL_PANEL log instead of PWRMAN log
#### 02-02-2024 BULLSEYE-028  download and install getver.py to read the NinoTNC version
#### 03-01-2025 BULLSEYE-029  Fix bug where getver.py was installed in /usr/tarpn/sbin instead of /usr/local/sbin

echo "###### =TARPN START 2 BULLSEYE 029" #=  --VERSION--#########


sleep 0.5
echo "######"
sleep 0.5
echo "######"
sleep 0.5
echo "######"


if [ -f /usr/local/sbin/tarpn_start1_finished.flag ];
then
   sleep 1
   echo " --- "
   echo "###### TARPN START 1 completed ok.  We're almost done"
   echo " --- "
   sleep 1
else
   sleep 1
   echo " -- "
   echo " -- "
   echo " -- "
   echo "### ERROR801.001:TARPN START 1 didn't finish.  Please restart the init"
   echo "###              process and complain to the author."
   echo " -- "
   exit 1
fi

if [ -f /usr/local/etc/tarpn_start2_top.txt ];
then
   ls -lrats
   echo "### ERROR801.002:TARPN INSTALL 2 has already run. "
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io."
   echo "###              Aborting"
   exit 1;
fi
_source_url=$(tr -d '\0' </usr/local/sbin/source_url.txt);
rm -f ~/tarpn_start1*



source /usr/local/sbin/tarpnget.sh
source /usr/local/sbin/sleep_with_count.sh


################################### INSTALL TARPN SERVICES



if [ -f ~/tarpn.service ];
then
   ls -lrats
   echo "### ERROR801.003:Premature existence of tarpn.service file in home directory"
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io."
   echo "###              Aborting"
   exit 1;
fi



sleep 1
echo -e "\n\n\n\n"
echo "#####"
echo "#####"
echo "##### APT-GET-UPDATE"
echo "#####   --- I know we just did this."
echo "#####   --- It won't take long if there is nothing to update."
cd ~
sleep 1
sudo apt-get -y update

sleep 1
echo -e "\n\n\n\n"
echo "#####"
echo "#####"
echo "##### APT-GET DIST-UPGRADE"
echo "#####"
echo "#####"
sleep 1
sudo apt-get -y dist-upgrade



###################################### AFTER THIS we are not allowed to run TARPN START2 over again. ########################################
###################################### AFTER THIS we are not allowed to run TARPN START2 over again. ########################################
###################################### AFTER THIS we are not allowed to run TARPN START2 over again. ########################################
###################################### AFTER THIS we are not allowed to run TARPN START2 over again. ########################################

sudo touch /usr/local/etc/tarpn_start2_top.txt





echo "#####"
echo "#####"
echo "##### Set up minicom port linkage so minicom can find host port"
echo "#####"
echo "#####"
sleep 1
cd /etc
sudo ln -s /home/pi/minicom/com4 tty8
sleep 1

cd ~
sleep 1
echo
echo "##### Turn up the volume to max.  You can adjust amixer cset numid=1 -- 100%  "
amixer cset numid=1 -- 100%
echo
sleep 1


echo "######"
echo "######"
echo "######"
echo "######"
echo "######  Adding service for tarpn background operations"

tarpnget tarpn-service.txt
##### now tarpn-service.txt should exist in the home directory
if [ -f ~/tarpn-service.txt ];
then
   echo " "
else
   ls -lrats
   echo "### ERROR801.004:Failed to obtain TARPN-SERVICE.TXT from the web server."
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io"
   echo "###              Note: Outputting debug information to be relayed to debugger."
   pwd
   echo "url"
   echo $_source_url
   echo "###              Aborting"
   exit 1
fi

cd ~

if [ -f /etc/systemd/system/tarpn.service ];
then
   echo "### ERROR801.005:TARPN SERVICE file already existed in /etc/system.d/system."
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io."
   echo "###              Aborting"
   exit 1;
fi




STARTSTOPLOGFILE="/var/log/tarpn_startstop.log"
SERVICELOGFILE="/var/log/tarpn_service.log"
TARPN_CONTROL_PANEL_LOGFILE="/var/log/tarpn_control_panel.log"

echo -ne $(date) " " >> $STARTSTOPLOGFILE
echo "New TARPN install in progress - running tarpn-start2.sh" >> $STARTSTOPLOGFILE

echo -ne $(date) " " >> $SERVICELOGFILE
echo "New TARPN install in progress - running tarpn-start2.sh" >> $SERVICELOGFILE


_source_url=$(tr -d '\0' </usr/local/sbin/source_url.txt);
mv tarpn-service.txt tarpn.service
sudo mv tarpn.service /etc/systemd/system/tarpn.service
if [ -f /etc/systemd/system/tarpn.service ];
then
   echo "tarpn.service moved to system.d"
else
   echo " "
   echo " "
   echo " "
   pwd
   echo "/etc/systemd/system directory contains"
   ls -lrats /etc/systemd/system
   echo "local system /home/pi directory contains"
   ls -lrats
   echo " "
   echo "### ERROR801.006:TARPN SERVICE file failed to copy to /etc/system.d/system."
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io"
   echo "###              Aborting"
   exit 1;
fi


### get the desktop/wallpaper image for ncpacket
tarpnget ncpacket-wallpaper.gif
sudo mv ncpacket-wallpaper.gif /usr/share/rpd-wallpaper

### get the Version-reader python script
tarpnget getver.py
sudo mv getver.py /usr/local/sbin

### Download files related to automatic operation
tarpnget tarpn_background.sh
chmod +x tarpn_background.sh
sudo mv tarpn_background.sh /usr/local/sbin


#### Disable background execution of G8BPQ node
sudo rm -f /usr/local/etc/background.ini
sudo rm -f ~/bpq/background.ini
echo "BACKGROUND:OFF" > ~/background.ini
sudo mv ~/background.ini /usr/local/etc/background.ini
sudo chown root /usr/local/etc/background.ini

### Start TARPN service from the OS
echo "##### TARPN SERVICE file installed"
sudo systemctl daemon-reload
sudo systemctl enable tarpn.service
sudo systemctl start tarpn.service
echo "##### starting TARPN service  pause 10 seconds"
sleep_with_count_10
echo "######"
sleep 1
echo "###### NOTE!   You will see an error message that says:"
sleep 1
echo "#######        NODE INIT file not found "
sleep 1
echo "#######    and  Aborting in 180 seconds"
sleep 1
echo "#######"
echo "#######     That's OK.  Nothing to see here.  These are not the"
echo "                        error messages you are looking for."
sleep 1
echo "            Move along..."
sleep 1
echo "########"
##sudo systemctl status tarpn.service
echo "###########################################################"
sleep 1
cat /var/log/tarpn_service.log
echo "###########################################################"
sleep 2


echo "######"
echo "######   LOG-FILE-TRUNCATE script"
######### Install logfiletruncate.sh
tarpnget logfiletruncate.sh

if [ -f logfiletruncate.sh ];
then
    chmod +x logfiletruncate.sh
    sudo rm -f /usr/local/sbin/logfiletruncate.sh
    sudo mv logfiletruncate.sh /usr/local/sbin/logfiletruncate.sh
    echo "##### logfiletruncate.sh script has been installed."
else
    echo
    echo
    echo "### ERROR801.007:Something is wrong.  Program had access to TARPN server but "
    echo "###              could not acquire the logfiletruncate.sh script from TARPN"
    echo "###              server.  Please send a missive about this to tarpn@groups.io."
    echo "###              Abort"
    exit 1;
fi

echo
echo

echo "######"
echo "######"
echo "######"
echo "######   PI SHUTDOWN SERVICE"
echo "######  Adding service for raspberry pi automatic shutdown and UP notification"
echo "######"
sleep 1
echo "########"

cd ~

if [ -f /etc/systemd/system/pi_shutdown-service.txt ];
then
    echo
    echo
    echo "### ERROR801.008:PI SHUTDOWN SERVICE file already existed in /etc/system.d/system."
    echo "###              If you got this message during a clean install, then"
    echo "###              Please send a missive about this to tarpn@groups.io."
    echo "###              Aborting"
   exit 1;
fi

if [ -f ~/pi_shutdown.service ];
then
   echo "### ERROR801.009:Premature existence of pi_shutdown.service file in home directory"
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io."
   echo "###              Aborting"
   exit 1;
fi

tarpnget pi_shutdown-service.txt
##### now pi_shutdown-service.txt  should exist in the home directory
if [ -f ~/pi_shutdown-service.txt ];
then
   echo "got PI_SHUTDOWN-SERVICE.TXT"
else
   echo "### ERROR801.010:Failed to obtain pi_shutdown.service from the web page."
   echo "###              If you got this message during a clean install, then"
   echo "###              please send a missive about this to tarpn@groups.io"
   echo "###        Note: Outputting debug information to be relayed to support."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "ERROR: Aborting"
   exit 1
fi

mv pi_shutdown-service.txt pi_shutdown.service
sudo mv ~/pi_shutdown.service /etc/systemd/system/pi_shutdown.service
if [ -f /etc/systemd/system/pi_shutdown.service ];
then
### Download files related to automatic operation
   tarpnget pi_shutdown_background.sh
   chmod +x pi_shutdown_background.sh
   sudo mv pi_shutdown_background.sh /usr/local/sbin


### Start SHUTDOWN service from the OS
   echo "##### PI SHUTDOWN SERVICE file installed"
   sudo echo -ne $(date) " " >> $TARPN_CONTROL_PANEL_LOGFILE
   sudo echo "tarpn-start2 is enabling and starting pi-shutdown-service" >> $TARPN_CONTROL_PANEL_LOGFILE
   sudo chmod 666 $TARPN_CONTROL_PANEL_LOGFILE


   sudo systemctl daemon-reload
   sudo systemctl enable pi_shutdown.service
   sudo systemctl start pi_shutdown.service
   echo "##### starting PI SHUTDOWN service  pause 10 seconds"
   sleep_with_count_10
   ##sudo systemctl status pi_shutdown.service
   echo "###########################################################"
   sleep 1
else
   echo "### ERROR801.011:PI SHUTDOWN SERVICE file failed to copy to /etc/system.d/system."
   echo "        If you got this message during a clean install, then"
   echo "        please send a missive about this to tarpn@groups.io."
   echo "ERROR: Aborting"
   exit 1;
fi




########### INSTALL LISTEN Application ###########################################3
########### INSTALL LISTEN Application ###########################################3
########### INSTALL LISTEN Application ###########################################3
########### INSTALL LISTEN Application ###########################################3
echo
echo "#### INSTALL LISTEN APPLICATION"
echo

cd /home/pi

tarpnget listen.zip
if [ -f /home/pi/listen.zip ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.012:Failed to obtain listen.zip from the web server."
   echo "        please send a missive about this to tarpn@groups.io"
   echo "        Include the terminal output from this update."
   echo "ERROR806.062: Aborting"
   exit 1
fi

unzip listen.zip

if [ -f /home/pi/listen ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.013:Error in unzipping listen.zip."
   echo "###              please send a missive about this to tarpn@groups.io"
   echo "###              Include the terminal output from this update."
   echo "###              Aborting"
   exit 1
fi

sudo mv listen /usr/local/sbin/listen
rm listen.zip






########### INSTALL LINKTEST Application ###########################################3
########### INSTALL LINKTEST Application ###########################################3
########### INSTALL LINKTEST Application ###########################################3
########### INSTALL LINKTEST Application ###########################################3
echo
echo "#### INSTALL LINKTEST APPLICATION"
echo

cd /home/pi

tarpnget linktest.zip
##### now neighbor_port_association-service.app should exist in the home directory
if [ -f /home/pi/linktest.zip ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.014:Failed to obtain linktest.zip from the web server."
   echo "        please send a missive about this to tarpn@groups.io"
   echo "        Include the terminal output from this update."
   echo "ERROR801.014: Aborting"
   exit 1
fi

unzip linktest.zip

if [ -f /home/pi/linktest-app ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.015:Error in unzipping linktest.zip."
   echo "                 please send a missive about this to tarpn@groups.io"
   echo "                 Include the terminal output from this update."
   echo "###              Aborting"
   exit 1
fi

sudo mv linktest-app /usr/local/sbin/linktest
rm linktest.zip




################################################################################################################################################################
################################################################################################################################################################


############################# INSTALL BBS-CHECKER APPLICATION FROM ZIP FILE

echo "##### Starting get of BBS-CHECKER app"
cd /home/pi

tarpnget bbs_checker.zip
##### now bbs_checker.zip should exist in the home directory
if [ -f /home/pi/bbs_checker.zip ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.016:Failed to obtain bbs_checker.zip from the web server."
   echo "                 please send a missive about this to tarpn@groups.io"
   echo "                 Include the terminal output from this update."
   echo "###              Aborting"
   exit 1
fi

echo "##### received BBS-CHECKER.ZIP file"
unzip bbs_checker.zip

if [ -f /home/pi/bbs_checker ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.017:Error in unzipping bbs_checker.zip."
   echo "              please send a missive about this to tarpn@groups.io"
   echo "              Include the terminal output from this update."
   echo "###             Aborting"
   exit 1
fi

echo "##### received bbs_checker  application"
chmod +x bbs_checker
sudo mv bbs_checker /usr/local/sbin/bbs_checker
echo "##### bbs_checker application has been installed."
echo
###################### DONE WITH BBS-CHECKER APPLICATION from ZIP FILE

############################# INSTALL SENDROUTESTOCQ APPLICATION FROM ZIP FILE


cd /home/pi

echo "##### Starting get of SENDROUTESTOCQ app"
tarpnget sendroutestocq.zip
##### now sendroutestocq.zip should exist in the home directory
if [ -f /home/pi/sendroutestocq.zip ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.018:Failed to obtain SENDROUTESTOCQ.zip from the web server."
   echo "                 please send a missive about this to tarpn@groups.io"
   echo "                 Include the terminal output from this update."
   echo "###              Aborting"
   exit 1
fi
echo "##### received SENDROUTESTOCQ.ZIP file"

unzip sendroutestocq.zip

if [ -f /home/pi/sendroutestocq ];
then
   echo " "
else
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.019:Error in unzipping SENDROUTESTOCQ.zip."
   echo "              please send a missive about this to tarpn@groups.io"
   echo "              Include the terminal output from this update."
   echo "###             Aborting"
   exit 1
fi

echo "##### received SENDROUTESTOCQ  application"
chmod +x sendroutestocq
sudo mv sendroutestocq /usr/local/sbin/sendroutestocq
echo "##### SENDROUTESTOCQ application has been installed."
echo



###################### DONE WITH SENDROUTESTOCQ APPLICATION from ZIP FILE

################################################################################################################################################################
################################################################################################################################################################





###################################################
echo "#### get ring.wav file for bbs checker "
cd /home/pi
tarpnget ring.wav
sudo mv ring.wav /usr/local/sbin/ring.wav

###################################################
######## INSTALL statusmonitor.sh

### Delete a temporary downloaded copy of the script (may be left-over from failed install)
rm -f statusmonitor.sh*

### Get new copy of the script
tarpnget statusmonitor.sh
tarpnget statusmonitor-service.txt

### Check if we have the script file now.
if [ -f statusmonitor.sh ];
then
   echo "##### received STATUSMONITOR_BACKGROUND script"

   if [ -f /etc/systemd/system/statusmonitor.service ];
   then
      echo "### ERROR801.020:statusmonitor service already existed!. "
      echo "###              Aborting"
      exit 1;
   else
      mv statusmonitor-service.txt statusmonitor.service
      sudo mv ~/statusmonitor.service /etc/systemd/system/statusmonitor.service
      if [ -f /etc/systemd/system/statusmonitor.service ];
      then
         echo "##### statusmonitor.service has been installed"
         echo "##### moving new background shell script file into place"
         chmod +x statusmonitor.sh
         sudo mv statusmonitor.sh /usr/local/sbin/statusmonitor.sh
         echo "##### STATUSMONITOR_BACKGROUND script has been installed."
         echo ##### start service
         sudo systemctl daemon-reload
         sudo systemctl enable statusmonitor.service
         sudo systemctl start statusmonitor.service
         echo "##### STATUSMONITOR_BACKGROUND script has been installed and the"
         echo "##### OS has been told to call it."
         echo -e "\n\n\n\n"
      else
         echo "### ERROR801.021:statusmonitor.service was not installed"
         echo "###              Aborting"
         exit 1;
      fi
   fi
else
      echo "### ERROR801.022:Did not receive STATUSMONITOR_BACKGROUND."
   echo
   echo "##### Aborting"
   exit 1;
fi
rm -f statusmonitor-service*
rm -f statusmonitor.service*
rm -f statusmonitor.sh*




###################################################
######## INSTALL RX_TARPNSTAT

### Delete a temporary downloaded copy of the script (may be left-over from failed install)
rm -f rx_tarpnstat.sh*

### Get new copy of the script
tarpnget rx_tarpnstat.sh
tarpnget rx_tarpnstat-service.txt

### Check if we have the script file now.
if [ -f rx_tarpnstat.sh ];
then
   echo "##### received rx_tarpnstat script"

   if [ -f /etc/systemd/system/rx_tarpnstat.service ];
   then
      echo "### ERROR801.023:rx_tarpnstat service already existed!. "
      echo "##### Aborting"
      exit 1;
   else
      mv rx_tarpnstat-service.txt rx_tarpnstat.service
      sudo mv ~/rx_tarpnstat.service /etc/systemd/system/rx_tarpnstat.service
      if [ -f /etc/systemd/system/rx_tarpnstat.service ];
      then
         echo "##### rx_tarpnstat.service has been installed"
         echo "##### moving new background shell script file into place"
         chmod +x rx_tarpnstat.sh
         sudo mv rx_tarpnstat.sh /usr/local/sbin/rx_tarpnstat.sh
         echo "##### STATUSMONITOR_BACKGROUND script has been installed."
         echo ##### start service
         sudo systemctl daemon-reload
         sudo systemctl enable rx_tarpnstat.service
         sudo systemctl start rx_tarpnstat.service
         echo "##### rx_tarpnstat script has been installed and the"
         echo "##### OS has been told to call it."
         echo -e "\n\n\n\n"
      else
         echo "### ERROR801.041:rx_tarpnstat.service was not installed"
         echo "##### Aborting"
         exit 1;
      fi
   fi
else
   echo "### ERROR801.042:Did not receive rx_tarpnstat.sh."
   echo
   echo "##### Aborting"
   exit 1;
fi
rm -f rx_tarpnstat-service*
rm -f rx_tarpnstat.service*
rm -f rx_tarpnstat.sh*


########### UPDATE rx_tarpnstatapp application
cd /home/pi
echo "ignore the no-process-found missive if printed here:"
sudo killall rx_tarpnstatapp
rm -f rx_tarpnstatapp*


echo "###### Install rx_tarpnstatapp"

tarpnget rx_tarpnstatapp.zip
if [ -f rx_tarpnstatapp.zip ];
then
    echo "##### received rx_tarpnstatapp  zip file"
    unzip rx_tarpnstatapp.zip
else
    echo -ne $(date) "" >> $TARPN_COMMAND_LOGFILE
    echo "### ERROR801.046:tarpn-start2.sh: rx_tarpnstatapp.zip not available from TARPN server"  >> $TARPN_COMMAND_LOGFILE
    pwd
    ls -lrats
    echo "###              Did not receive rx_tarpnstatapp.zip file.  FAIL FAIL FAIL"
    echo
    echo "###              Abort -- complain to tarpn@groups.io."
    exit 1
fi

if [ -f rx_tarpnstatapp ];
then
    echo "##### received and unzipped rx_tarpnstatapp Application"
    chmod +x rx_tarpnstatapp
    ./rx_tarpnstatapp version
    sudo mv rx_tarpnstatapp /usr/local/sbin/rx_tarpnstatapp
    echo -e "##### rx_tarpnstatapp application has been updated.\n"
else
    echo -ne $(date) "" >> $TARPN_COMMAND_LOGFILE
    echo "### ERROR801.051:tarpn-start2.sh: rx_tarpnstatapp not available from TARPN server"  >> $TARPN_COMMAND_LOGFILE
    pwd
    ls -lrats
    echo "### ERROR801.053:Unable to unzip rx_tarpnstatapp!  FAIL FAIL FAIL"
    echo
    echo "##### Abort -- complain to tarpn@groups.io."
    exit 1
fi

sleep 1

echo "#####"
echo "##### Install Midori web browser"
sudo apt install midori -y

sleep 1
echo "#####"


###############################################################################################################
###############################################################################################################
###############################################################################################################
###############################################################################################################

echo "Install 10K Test loop file "
######### Get a 10K test file and put it in the Files folder
if [ -d /home/pi/bpq/Files ]; then
   echo "  Files folder already exists"
else
   echo " Create bpq FILES folder"
   cd /home/pi/bpq
   mkdir Files
fi

cd /home/pi/bpq/Files
tarpnget g8bpqloop.txt
echo "Test loop file installed"

sleep 1
echo "#####"



echo "#####"
echo "##### Download g8bpq_link_stress.py"
echo "#####"
tarpnget g8bpq_link_stress.zip
if [ -f g8bpq_link_stress.zip ];
then
   echo " "
else
   echo -ne $(date) "" >> $TARPN_COMMAND_LOGFILE
   echo "### ERROR801.061:Error in downloading g8bpq_link_stress.zip"  >> $TARPN_COMMAND_LOGFILE
   resume_services
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   echo "   Note: Outputting debug information to be relayed to he who debugs."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.061:Error in dpwnloading g8bpq_link_stress.zip."
   echo "              please send a missive about this to tarpn@groups.io"
   echo "              Include the terminal output from this update."
   echo "### ERROR801.061:Aborting"
   exit 1
fi

echo "#####"
echo "##### Unzip g8bpq_link_stress.zip"
echo "#####"
unzip g8bpq_link_stress.zip
if [ -f g8bpq_link_stress.py ];
then
   echo "##### unzip successful.  Moving g8bpq_link_stress.py sbin"
   sudo mv g8bpq_link_stress.py /usr/local/sbin/g8bpq_link_stress.py
else
   echo -ne $(date) "" >> $TARPN_COMMAND_LOGFILE
   echo "### ERROR801.065.  Error in unzip of g8bpq_link_stress.zip"  >> $TARPN_COMMAND_LOGFILE
   resume_services
   echo "   Note: Outputting debug information to be relayed to support."
   echo "   Note: Outputting debug information to be relayed to support."
   echo "   Note: Outputting debug information to be relayed to support."
   echo "   Note: Outputting debug information to be relayed to support."
   ls -lrat
   pwd
   echo "url"
   echo $_source_url
   echo "### ERROR801.065:Error in unzip of g8bpq_link_stress.zip."
   echo "              please send a missive about this to tarpn@groups.io"
   echo "              Include the terminal output from this update."
   echo "### ERROR801.065:Aborting"
   exit 1
fi


###############################################################################################################
###############################################################################################################
###############################################################################################################
###############################################################################################################





sleep 1
echo "#####"
sleep 1
echo "##### Done.  After reboot you will be ready to test and/or "
echo "##### configure your TNC boards and to start BPQ node."
sleep 1
echo "#####"
echo "#####"

cd ~

rm -f bbs_checker.zip
rm -f rx_tarpnstatapp.zip
rm -f sendroutestocq.zip
rm -f test.txt
rm -f parse.tmp

sleep 1;
echo "######"
echo "######"
echo "######"
echo "######"
echo "######      Raspberry PI will now reboot.  All is going well so far."
echo "######      When we come back up, reconnect and try the   tarpn   command"
echo "######      as per the"
echo "######      Set Up Raspberry PI for TARPN Node - Make SDcard"
echo "######      web page"
sleep 1;
echo "######"
sleep 1;
echo "######"
echo "tarpn_start2" > /home/pi/tarpn_start2.flag;
sudo mv /home/pi/tarpn_start2.flag /usr/local/sbin/tarpn_start2.flag;

TARPNCOMMANDLOGFILE="/var/log/tarpn_command.log"

uptime >> $TARPNCOMMANDLOGFILE
echo -ne $(date) " " >> $TARPNCOMMANDLOGFILE
echo "New TARPN install2 completed - rebooting in 4 seconds" >> $TARPNCOMMANDLOGFILE

echo -ne $(date) " " >> $STARTSTOPLOGFILE
echo "New TARPN install2 completed - rebooting in 4 seconds" >> $STARTSTOPLOGFILE

###### REBOOT in 5 seconds
sleep_with_count_5
sudo touch /forcefsck
sudo shutdown -r now;
exit 0
