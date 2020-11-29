#!/usr/bin/perl
use strict;
use warnings;

# This script is released to the public domain.

##############################################################################
# VERSION HISTORY
#
# 2012-06-24 - 0.1 - Initial Release
# 2012-06-30 - 0.5 - Added support for linking Dropbox only, upgrading
#                    versions, and automatically searching for installers
# 2012-07-04 - 0.6 - Look for YNAB installer in . too
# 2014-02-09 - 0.7 - Automatically download the YNAB4 installer
#
##############################################################################

$| =1 ;

sub mydie {
  warn @_;
  unless ($ENV{_}) {
    print "Press enter to quit";
    my $ans = <STDIN>;
  }
  exit 1;
}

# Ensure that all dependencies are met (Base64 & WINE)
eval "use MIME::Base64;";
mydie "This script requires the Perl MIME::Base64 module to work, which you seem to be missing: $@\n" if $@;

my $WINE = '/usr/bin/wine';
mydie "\nYNAB 4 requires WINE to work, please install WINE and try again\n" unless -x $WINE;

# Take an (optional) argument to be a YNAB windows installer
my $YNAB_WINDOWS = $ARGV[0];
my $INSTALL_MODE = 'YNAB';

# If an installer wasn't specified, ask the user what they want to do
unless ($YNAB_WINDOWS && -s $YNAB_WINDOWS) {
  print <<"END_MESSAGE";
Would you like to:
1. Install YNAB4 and link Dropbox
2. Link Dropbox ONLY
3. Download YNAB4, install it, and link Dropbox
END_MESSAGE
  ;
  print "Select an option: [1] ";
  # Take the user's response from STDIN, and we'll go from there
  my $ans = <STDIN>;
  my ($num) = ($ans =~ /(\d+)/);
  $num = 1 if $ans =~ /^\s*$/;
  if ($num == 1) {
    $INSTALL_MODE = 'YNAB';
  }
  elsif ($num == 2) {
    $INSTALL_MODE = 'DROPBOX';
  }
  else {
    $INSTALL_MODE = 'DOWNLOAD';
  }
}

# If we're trying to install YNAB, but no installer has been specified
# or the installer specified is just an empty file
if ($INSTALL_MODE eq 'YNAB' && (!$YNAB_WINDOWS || !-s $YNAB_WINDOWS)) {
  print "\nSearching for YNAB4 Installer...\n";
  # empty array
  my @installers;

  # places to search for an installer
  my @search_paths = ('.',
                      $ENV{HOME} . "/Downloads",
                      '/tmp',
                      $ENV{HOME} . "/Dropbox",
                      $ENV{HOME},
                     );
  # Search through each of the paths for an installer
  foreach my $search_path (@search_paths) {
    print "Searching in $search_path\n";
    &find_installers($search_path, \@installers);
    last if @installers;
  }

  if (!@installers) {
    # If no installers are found, quit
    mydie("Unable to find YNAB4 installer\n");
  }
  if (@installers == 1) {
    # If one (1) installer is found, use that
    $YNAB_WINDOWS = $installers[0];
    print "\nFound Installer: '$installers[0]'\n\n";
  }
  else {
    $YNAB_WINDOWS = '';
    while (!$YNAB_WINDOWS) {
      # If multiple installers are found, list them
      print "\nAvailable Installers:\n";
      @installers = reverse(@installers);
      for (my $i = 0; $i < @installers; $i++) {
        print "  " . $i+1 . ". " . $installers[$i] . "\n";
      }
      print "Select an installer: [1] ";
      # Ask the user to select which installer to use
      my $ans = <STDIN>;
      # check if the response is a digit
      my ($num) = ($ans =~ /(\d+)/);
      # if the response is just whitespace, assume the default [1] (newest version found)
      $num = 1 if $ans =~ /^\s*$/;
      if ($num > 0 && $num <= @installers) {
        # select the installer, provided it's a valid selection
        $YNAB_WINDOWS = $installers[$num-1];
      }
    }
    print "\n";
  }
}

# The user is trying to install YNAB, but something has gone wrong
if ($INSTALL_MODE eq 'YNAB' && (!$YNAB_WINDOWS || !-s $YNAB_WINDOWS)) {
  mydie "\nNo YNAB4 Installer found!\n";
}

if ($INSTALL_MODE eq 'DOWNLOAD') {
  print "\nDownloading the most current version of YNAB4...\n";
  # Setting some variables to use through the various download options
  my $DOWNLOAD_LOCATION = "/tmp/ynab4_installer.exe";
  my $UPDATE_PAGE = "http://www.youneedabudget.com/dev/ynab4/liveCaptive/Win/update.xml";
  my $UPDATE_LOCATION = "/tmp/ynab4_update.xml";

  # Check to see if the LWP::Simple perl module is installed
  eval("use LWP::Simple;");
  if ($@) {
    # If LWP::Simple is not installed, let's try wget
    my $WGET = '/usr/bin/wget';
    if (-x $WGET) {
      # If wget is installed, let's download the update page,
      system($WGET, '-O', $UPDATE_LOCATION, $UPDATE_PAGE);
      my $UPDATE_DATA = &save_file_data($UPDATE_LOCATION);
      # look through the xml to find the download url and md5sum,
      my ($CURRENT_VERSION, $INSTALLER_URL, $GIVEN_MD5) = &find_version_url_and_md5($UPDATE_DATA, $DOWNLOAD_LOCATION);
      # quit if the current version is the same as the installed version
      mydie "It looks like you already have the latest version of YNAB4 installed: $CURRENT_VERSION" unless &compare_versions($CURRENT_VERSION);
      # download the installer,
      system($WGET, '-O', $DOWNLOAD_LOCATION, $INSTALLER_URL);
      # and check to make sure that the file we downloaded matches the md5 that YNAB gave us
      &validate_download($GIVEN_MD5, $DOWNLOAD_LOCATION);
    }

    else {
      # If wget is not installed, let's try curl
      my $CURL = '/usr/bin/curl';
      if (-x $CURL) {
        # If curl is installed, let's download the update page,
        system($CURL, '-o', $UPDATE_LOCATION, $UPDATE_PAGE);
        my $UPDATE_DATA = &save_file_data($UPDATE_LOCATION);
        # look through the xml to find the download url and md5sum,
        my ($CURRENT_VERSION, $INSTALLER_URL, $GIVEN_MD5) = &find_version_url_and_md5($UPDATE_DATA, $DOWNLOAD_LOCATION);
        # quit if the current version is the same as the installed version
        mydie "It looks like you already have the latest version of YNAB4 installed: $CURRENT_VERSION" unless &compare_versions($CURRENT_VERSION);
        # download the installer,
        system($CURL, '-o', $DOWNLOAD_LOCATION, $INSTALLER_URL);
        # and check to make sure that the file we downloaded matches the md5 that YNAB gave us
        &validate_download($GIVEN_MD5, $DOWNLOAD_LOCATION);
      }

      else {
        # If LWP::Simple, wget, and curl are all NOT installed, I don't know how
        # else we could try to download the file, ask the user to download it
        # on their own and come back to us.
        mydie "It looks like you don't have anything installed
               that we can use to download the latest version of YNAB4.
               Please download the Windows installer from here:\n\n
               https://www-assets.youneedabudget.com/ynab4/\n\n
               and then try running this script with Option 1.\n";
      }
    }
  }

  else {
    # LWP::Simple is installed, let's download the update page,
    my $UPDATE_DATA = get($UPDATE_PAGE);
    # look through the xml to find the download url and md5sum,
    my ($CURRENT_VERSION, $INSTALLER_URL, $GIVEN_MD5) = &find_version_url_and_md5($UPDATE_DATA, $DOWNLOAD_LOCATION);
    # quit if the current version is the same as the installed version
    mydie "It looks like you already have the latest version of YNAB4 installed: $CURRENT_VERSION" unless &compare_versions($CURRENT_VERSION);
    # download the installer,
    getstore($INSTALLER_URL, $DOWNLOAD_LOCATION);
    # and check to make sure that the file we downloaded matches the md5 that YNAB gave us
    &validate_download($GIVEN_MD5, $DOWNLOAD_LOCATION);
  }
}

# Get started by opening the dropbox configuration
my $DROPBOX_HOSTDB = $ENV{HOME} . "/.dropbox/host.db";
my $DROPBOX_INSTALLDIR = "";
if (-s $DROPBOX_HOSTDB) {
  # Find and return the location of the Dropbox installation
  open(HOSTDB, $DROPBOX_HOSTDB) or mydie "Unable to read Dropbox configuration file";
  my $line1 = <HOSTDB>;
  my $b64_location = <HOSTDB>;
  chomp $b64_location;
  #print "'$b64_location'\n";
  close HOSTDB;
  $DROPBOX_INSTALLDIR = decode_base64($b64_location);
}

# For debugging:
#$DROPBOX_INSTALLDIR = undef;
if ($DROPBOX_INSTALLDIR) {
  if (! -d $DROPBOX_INSTALLDIR) {
    # Dropbox setup hasn't been completed yet
    print "\nDropbox detected but not found in '$DROPBOX_INSTALLDIR'\n";
    $DROPBOX_INSTALLDIR = '';
  }
  else {
    # Dropbox was successfully found
    print "\nFound Dropbox Installation: '$DROPBOX_INSTALLDIR'\n";
  }
}
else {
  if ($INSTALL_MODE eq 'DROPBOX') {
    print <<"END_MESSAGE";
No Dropbox installation found.

To complete the Dropbox installation, start Dropbox,
register, select a plan, and optionally view the tutorial.
When you have a "Dropbox" folder in your home directory,
setup is complete.

END_MESSAGE
    ;
    mydie "Please start the script again after setup is complete\n";
  }

  print <<"END_MESSAGE";
No Dropbox installation found.

Cloud Sync will still work, but you will have to navigate
to the Z: drive and save your budget file in the correct
location.

If you want this script to create the Dropbox link for
YNAB4, you will need to complete the Dropbox installation
and restart the script.

To complete the Dropbox installation, start Dropbox,
register, select a plan, and optionally view the tutorial.
When you have a "Dropbox" folder in your home directory,
setup is complete.

NOTE: You can install YNAB4 now and re-run the script later
to link Dropbox if you wish.

END_MESSAGE
  ;
  print "Continue Installation? [yN] ";
  my $ans = <STDIN>;
  if ($ans !~ /^y/i) {
    exit;
  }
}

# Suggest a winedir for YNAB, but ask for input from the user
my $WINEDIR = $ENV{HOME} . "/.wine_YNAB4";
print "\nSpecify WINE directory to use: [$WINEDIR] ";
my $input = <STDIN>;
chomp $input;
$WINEDIR = $input if $input !~ /^\s*$/;
my $WINE_DRIVEC_DIR = "$WINEDIR/drive_c";
my $WINE_APPDATA_DIR = "$WINE_DRIVEC_DIR/users/$ENV{USER}/Application\ Data";

if ($INSTALL_MODE eq 'YNAB' || $INSTALL_MODE eq 'DOWNLOAD') {
  # Create the winedir, unless it already exists
  # Might need to use $ENV{LOGNAME} here?
  system('mkdir', '-p', "$WINEDIR");
  mydie "Unable to create $WINEDIR\n" unless -d $WINEDIR;
}
else {
  # Check to see if YNAB is installed already..
  my $YNAB_APPDATA_DIR = "$WINE_APPDATA_DIR/com.ynab.YNAB4.LiveCaptive";
  if (! -d $YNAB_APPDATA_DIR) {
    # Something is here, but it doesn't look like YNAB. Better check with the user
    print "\nWARNING: YNAB4 does not appear to be installed in $WINEDIR\n";
    print "Continue Linking Dropbox? [yN] ";
    my $ans = <STDIN>;
    if ($ans !~ /^y/i) {
      exit;
    }
  }
}

# Twist WINE's arm to play nice with Dropbox
if ($DROPBOX_INSTALLDIR) {
  print "\nConfiguring $WINEDIR for Dropbox\n";
  my $DROPBOX_WINE_CONFIG_DIR = "$WINE_APPDATA_DIR/Dropbox";
  my $DROPBOX_WINE_HOSTDB = "$DROPBOX_WINE_CONFIG_DIR/host.db";
  system('mkdir', '-p', "$DROPBOX_WINE_CONFIG_DIR");
  mydie "Unable to create $DROPBOX_WINE_CONFIG_DIR\n" unless -d "$DROPBOX_WINE_CONFIG_DIR";
  open(WINEHOSTDB, '>', "$DROPBOX_WINE_HOSTDB") or mydie "Unable to create host.db file for Dropbox in WINE";
  print WINEHOSTDB "0000000000000000000000000000000000000000\n";
  print WINEHOSTDB "QzpcRHJvcGJveA==\n";
  close WINEHOSTDB;

  my $DROPBOX_SYMLINK = "Dropbox";
  symlink($DROPBOX_INSTALLDIR, "$WINE_DRIVEC_DIR/$DROPBOX_SYMLINK");
  if ($INSTALL_MODE eq 'DROPBOX') {
    print "\n\nDone!\n";
    unless ($ENV{_}) {
      print "Press enter to quit";
      my $ans = <STDIN>;
    }
    exit;
  }
}

# Actually get down to installing YNAB, and keep track of everything in our log
print "\nInstalling YNAB4 in $WINEDIR\n";
my $INSTALL_LOG = '/tmp/ynab4_install.log';
print "Installer output will be in $INSTALL_LOG\n";
$ENV{WINEPREFIX} = $WINEDIR;

open(my $oldout, ">&STDOUT")     or mydie "Can't dup STDOUT: $!";
no warnings;
open(OLDERR,     ">&", \*STDERR) or mydie "Can't dup STDERR: $!";
use warnings;

open(STDOUT, '>>', $INSTALL_LOG) or mydie "Can't redirect STDOUT: $!";
open(STDERR, ">&STDOUT")     or mydie "Can't dup STDOUT: $!";

select STDERR; $| = 1;  # make unbuffered
select STDOUT; $| = 1;  # make unbuffered

print scalar localtime, ": BEGIN INSTALLATION OF '$YNAB_WINDOWS'\n";
system($WINE, $YNAB_WINDOWS);
print scalar localtime, ": END INSTALLATION OF '$YNAB_WINDOWS'\n\n\n";

open(STDOUT, ">&", $oldout) or mydie "Can't dup \$oldout: $!";
open(STDERR, ">&OLDERR")    or mydie "Can't dup OLDERR: $!";

print "\n\nDone!\n";
unless ($ENV{_}) {
  print "Press enter to quit";
  my $ans = <STDIN>;
}

sub find_installers ($\@) {
  # Take our two arguments and recursively search for a YNAB installer
  my ($dir, $found) = @_;
  &recursive_find_installers($dir, $found);
}

sub recursive_find_installers ($\@) {
  # Snatch up our two arguments again
  my ($dir, $found) = @_;

  # Open the directory we're currently looking in and create an array of filenames
  opendir(DIR, $dir) or return;
  my @files = readdir DIR;
  closedir DIR;


  foreach my $file (sort @files) {
    # Don't even think about those pesky hidden files
    next if $file =~ /^\./;
    my $path = "$dir/$file";

    # Don't bother with symbolic links, either
    next if -l $path;
    # If we've stumbled upon a directory, search through that, too
    if (-d $path) {
      &recursive_find_installers($path, $found);
    }

    # If an installer exists, add it to the end of our @installers array
    if ($file =~ /^YNAB.*4.*setup.*\.exe$/i) {
      push @$found, $path;
    }
  }
}

sub save_file_data ($) {
  local $/ = undef;
  # Get the location of the update file that was provided, and store it as DATA
  my $UPDATE_LOCATION = $_[0];
  open DATA, $UPDATE_LOCATION or mydie "Couldn't open file: $!";
  binmode DATA;
  # Read from <DATA> and store it as a string: $UPDATE_DATA and return
  my $UPDATE_DATA = <DATA>;
  close DATA;
  return $UPDATE_DATA;
}

sub find_version_url_and_md5 ($\@) {
  # Get the update information and name of the download file
  my ($DATA, $FILE_LOCATION) = @_;
  $DATA =~ /<version>(.*)<\/version>/g;
  # Find the current version number
  my $VERSION = $1;
  $DATA =~ /<url>(.*)<\/url>/g;
  # Find the installer URL
  my $URL = $1;
  $DATA =~ /<md5>(.*)<\/md5>/g;
  # Find the MD5 and store it
  my $MD5SUM = $1;
  # Return both
  return ($VERSION, $URL, $MD5SUM);
}

sub validate_download ($\@) {
  eval("use Digest::MD5 qw( md5_hex )");
  mydie "Validating the downloaded installer requires the Perl Digest::MD5 module to work, which you seem to be missing: $@\n" if $@;
  # Grab the MD5 we got from upstream, and the location of the downloaded file
  my ($GOOD_MD5, $FILE_DOWNLOAD) = @_;
  print "\nValidating installer...\n";
  # Generate the MD5 hash of the file that was downloaded
  my $CALC_MD5 = md5_hex(&save_file_data($FILE_DOWNLOAD));
  if (uc($CALC_MD5) eq $GOOD_MD5) {
    # If the MD5 is good, save the location as our windows installer
    $YNAB_WINDOWS = $FILE_DOWNLOAD;
  }
  else {
    # Otherwise, something went wrong.
    # Quit the script and instruct the user to try again.
    mydie "Could not validate downloaded file. Please try again.";
  }
}

sub compare_versions ($) {
  # Pass in the current version of YNAB4 from the ynab4_update.xml file
  my $CURRENT_VERSION = $_[0];
  my $APPLICATION_XML;
  my $WINEDIR = $ENV{HOME} . "/.wine_YNAB4";
  if (-d $WINEDIR) {
    # If the suggested wine directory exists, check what the installed version is
    if (!qx(find $WINEDIR -name application.xml)) {
      mydie "Wine directory exists. Could not confirm installed version of YNAB4.\n
Please ensure that YNAB4 is actually installed. If a previous version of\n
YNAB4 failed to install, please move or delete the $WINEDIR directory.\n";
    }
    else {
      $APPLICATION_XML = &save_file_data(qx(find $WINEDIR -name application.xml));
    }
    $APPLICATION_XML =~ /<versionNumber>(.*)<\/versionNumber>/g;
    my $INSTALLED_VERSION = $1;
    # If the installed version is the same as the current version, return false
    if ($INSTALLED_VERSION eq $CURRENT_VERSION) {
      return 0;
    }
    # If the installed and current versions are different, return true
    else {
      return 1;
    }
  }
  # If the suggested wine directory does not exist, return true
  else {
    return 1;
  }
}
