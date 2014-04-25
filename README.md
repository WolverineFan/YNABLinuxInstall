# YNABLinuxInstall #

Install script for YNAB 4 on Linux.  It is released to the public domain.

First, a quick explanation: YNAB4 works fine in most modern distros that
have WINE installed by just double-clicking the downloaded installer.
Unfortunately what DOESN'T work is YNAB4 "seeing" local Linux Dropbox install
and enabling the "Cloud Sync" options. This script will fix the problem
by setting up the necessary files for YNAB4 to use your Linux Dropbox folder
and avoid you having to install a Windows version of Dropbox (which IMHO
is just asking for trouble). It's important to note that even though YNAB4
doesn't see Dropbox and doesn't enable the Cloud Sync option, if you manually
browse to your Linux Dropbox folder and store your YNAB4 files there, they
should still sync just fine. So this script is a convenience, not mandatory.

## Table of Contents ##

- [What Will this Script Do?](#what-will-this-script-do)
- [What You will Need](#what-you-will-need)
  - [Optional Dependencies](#optional-dependencies)
- [Installation Instructions](#installation-instructions)

## What Will this Script Do? ##

The newest version of the script is much more friendly. It will:

* Ask if you want to install YNAB4 or just link Dropbox to an exsting install
* Search common locations for your YNAB4 installer (if it finds more than
  one it will ask which one you want to use). You can still specify an installer
  on the command-line if you wish.
* Do a bit more error checking to see if things are where they're expected
* Happily upgrade an existing installation (but be sure you specify the
  correct WINE install location you used the first time!)
* Download the latest and greatest version of YNAB4 from youneedabudget.com
  so that you don't have to worry about doing that in advance!

## What You will Need ##

1. [WINE](http://www.winehq.org)
2. Dropbox for Linux. I'm going to plug a Dropbox referral link here:
   https://db.tt/WmZzCcSX (both parties get an extra 500MB if you use it)
3. [My script](https://github.com/WolverineFan/YNABLinuxInstall)
  - If you want to use `wget` to download my script, try this:

        ```
        wget -O YNAB4_LinuxInstall.pl https://raw.github.com/WolverineFan/YNABLinuxInstall/master/YNAB4_LinuxInstall.pl
        ```
  - Alternatively, in your browser, [right-click this link and "Save Link As..."](https://raw.github.com/WolverineFan/YNABLinuxInstall/master/YNAB4_LinuxInstall.pl)

### Optional Dependencies ###

> :information_source: Some of these are optional, and some of these are
> known to be necessary under some circumstances Your mileage may vary.

1. OPTIONAL: [The YNAB4 Windows installer](http://www.youneedabudget.com/download/ynab4)
   (the script will download the installer for you, if you want)

2. [Mono](http://wiki.winehq.org/Mono) and [Gecko](http://wiki.winehq.org/Gecko)
   for WINE appear to be necessary for YNAB4 to work properly on Linux.
> :information_source: NOTE: WINE is supposed to be smart enough to know
> when these are necessary, and do the legwork of installing them for you.
> If you're having trouble running YNAB4 on Linux, you should double-check
> that these exist in your WINE bottle. Please consult your distribution's
> documentation if you're having trouble installing these packages.

3. Some users of 64-bit Arch Linux (and its derivatives) report that the
   [multilib](https://wiki.archlinux.org/index.php/Multilib) repository
   needs to be enabled.
   - Please consult the [Arch64 FAQ](https://wiki.archlinux.org/index.php/Arch64_FAQ#Multilib_repository)
     page for more details about multilib.
   - You may also need to install the `lib32-lcms` package.
   - Please see this [YNAB forum post](http://forum.youneedabudget.com/discussion/comment/269035/#Comment_269035)
     for some relevant discussion.

4. [Winetricks](http://wiki.winehq.org/winetricks) can add some bells and
   whistles to a default installation of WINE.
   - YNAB4's built-in update function is reported to work [after a winetricks
     tweak](http://forum.youneedabudget.com/discussion/16688/update-error)
   - Many distributions package winetricks in their repositories, and you
     can install it through the usual channels.
   - Use of winetricks can occasionally lead to trouble when using WINE.
     Please consider how applying a winetrick might affect your WINE installation
     or configuration.
     

## Installation Instructions ##

1. Install WINE and Dropbox first.
> :information_source: NOTE: Be sure to launch Dropbox, register, and
> complete the setup process. You should have a "Dropbox" folder in your
> home directory after it's done.

2. In a Terminal window you will type something like the following:
> :information_source: NOTE: You may need to adjust `cd ~/Downloads`, if
> the install script is located in another directory. `~/Downloads` is the
> default directory, most of the time.

    ```
    cd ~/Downloads
    perl ./YNAB4_LinuxInstall.pl
    ```

3. Then, just follow the prompts!

By default, my script will install YNAB4 in a WINE bottle named `~/.wine_YNAB4`
but it will prompt you for an alternate location, if you want to choose one.
It will locate your Dropbox folder automatically so you don't have to do
anything there. 

> :information_source: NOTE: From within YNAB4, your Dropbox directory will
> be in C:\Dropbox

Any questions or problems with the script should be directed to me not the
YNAB team :)

If anyone wants to take a stab at improving it feel free! 
