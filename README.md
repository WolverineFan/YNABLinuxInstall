YNABLinuxInstall
================

Install script for YNAB 4 on Linux.  It is released to the public domain.

First, a quick explanation: YNAB4 works fine in most modern distros that have WINE installed by just double-clicking the downloaded installer. Unfortunately what DOESN'T work is YNAB4 "seeing" local Linux Dropbox install and enabling the "Cloud Sync" options. This script will fix the problem by setting up the necessary files for YNAB4 to use your Linux Dropbox folder and avoid you having to install a Windows version of Dropbox (which IMHO is just asking for trouble). It's important to note that even though YNAB4 doesn't see Dropbox and doesn't enable the Cloud Sync option, if you manually browse to your Linux Dropbox folder and store your YNAB4 files there, they should still sync just fine. So this script is a convenience, not mandatory.

You will need:

1. WINE
2. Dropbox for Linux. I'm going to plug my Dropbox referral link here: http://db.tt/qTBkvl1b (we both get an extra 500MB if you use it)
3. The YNAB4 Windows installer: http://www.youneedabudget.com/download/ynab/redownload/
4. My script: https://github.com/WolverineFan/YNABLinuxInstall

If you want to use wget to download my script, try this:

        wget -O YNAB4_LinuxInstall.pl https://raw.github.com/WolverineFan/YNABLinuxInstall/master/YNAB4_LinuxInstall.pl

Alternatively, in your browser, right-click this link and Save Link As: https://raw.github.com/WolverineFan/YNABLinuxInstall/master/YNAB4_LinuxInstall.pl

Install WINE and Dropbox first. NOTE: Be sure to launch Dropbox, register, and complete the setup process. You should have a "Dropbox" folder in your home directory after it's done.

The newest version of the script is much more friendly. It will:

* Ask if you want to install YNAB4 or just link Dropbox to an exsting install
* Search common locations for your YNAB4 installer (if it finds more than one it will ask which one you want to use). You can still specify an installer on the command-line if you wish.
* Do a bit more error checking to see if things are where they're expected
* Happily upgrade an existing installation (but be sure you specify the correct WINE install location you used the first time!)

In a Terminal window you will type something like the following. I'm going to assume you downloaded to your Downloads directory because that's the default.

        cd Downloads
        perl ./YNAB4_LinuxInstall.pl

Then just follow the prompts!

By default, my script will install YNAB in a WINE bottle named

        ~/.wine_YNAB4

but it will prompt you for an alternate location. It will locate your Dropbox folder automatically so you don't have to do anything there. 

NOTE: From within YNAB4, your Dropbox directory will be in C:\Dropbox

Any questions or problems with the script should be directed to me not the YNAB team :)

If anyone wants to take a stab at improving it feel free! 
