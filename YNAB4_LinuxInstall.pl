#!/usr/bin/perl
use strict;
use warnings;
use LWP::Simple;

# This script is released to the public domain.

##############################################################################
# VERSION HISTORY
#
# 2012-06-24 - 0.1 - Initial Release
# 2012-06-30 - 0.5 - Added support for linking Dropbox only, upgrading
#                    versions, and automatically searching for installers
# 2012-07-04 - 0.6 - Look for YNAB installer in . too
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

eval "use MIME::Base64;";
mydie "This script requires the Perl MIME::Base64 module to work, which you seem to be missing: $@\n" if $@;

my $WINE = '/usr/bin/wine';
mydie "\nYNAB 4 requires WINE to work, please install WINE and try again\n" unless -x $WINE;

my $YNAB_WINDOWS = $ARGV[0];
my $INSTALL_MODE = 'YNAB';
unless ($YNAB_WINDOWS && -s $YNAB_WINDOWS) {
  print <<"END_MESSAGE";
Would you like to:
1. Install YNAB4 and link Dropbox
2. Link Dropbox ONLY
END_MESSAGE
  ;
  print "Select an option: [1] ";
  my $ans = <STDIN>;
  my ($num) = ($ans =~ /(\d+)/);
  $num = 1 if $ans =~ /^\s*$/;
  if ($num == 1) {
    $INSTALL_MODE = 'YNAB';
  }
  else {
    $INSTALL_MODE = 'DROPBOX';
  }
}

if ($INSTALL_MODE eq 'YNAB' && (!$YNAB_WINDOWS || !-s $YNAB_WINDOWS)) {
  print "\nSearching for YNAB4 Installer...\n";
  my @installers;

  my @search_paths = ('.',
                      $ENV{HOME} . "/Downloads",
                      '/tmp',
                      $ENV{HOME} . "/Dropbox",
                      $ENV{HOME},
                     );
  foreach my $search_path (@search_paths) {
    print "Searching in $search_path\n";
    &find_installers($search_path, \@installers);
    last if @installers;
  }
  
  if (!@installers) {
    $YNAB_WINDOWS = '';
    while (!$YNAB_WINDOWS) {
      print "Unable to find YNAB4 installer\n";
      print "What would you like to do?\n";
      print "  1. Download the latest version of YNAB4\n";
      print "  2. Quit\n";
      print "Select an action: [1] ";
      my $ans = <STDIN>;
      my ($num) = ($ans =~ /(\d+)/);
      $num = 1 if $ans =~ /^\s*$/;
      if ($num == 1) {
        $YNAB_WINDOWS = &download_latest_version;
      }
      if ($num == 2) {
        mydie("Received quit signal");
      }
    }
  }
  if (@installers == 1) {
    $YNAB_WINDOWS = $installers[0];
    print "\nFound Installer: '$installers[0]'\n\n";
  }
  else {
    $YNAB_WINDOWS = '';
    while (!$YNAB_WINDOWS) {
      print "\nAvailable Installers:\n";
      print $YNAB_WINDOWS;
      @installers = reverse(@installers);
      for (my $i = 0; $i < @installers; $i++) {
        print "  " . $i+1 . ". " . $installers[$i] . "\n";
      }
      print "Select an installer: [1] ";
      my $ans = <STDIN>;
      my ($num) = ($ans =~ /(\d+)/);
      $num = 1 if $ans =~ /^\s*$/;
      if ($num > 0 && $num <= @installers) {
        $YNAB_WINDOWS = $installers[$num-1];
      }
    }
    print "\n";
  }
}
if ($INSTALL_MODE eq 'YNAB' && (!$YNAB_WINDOWS || !-s $YNAB_WINDOWS)) {
  mydie "\nNo YNAB4 Installer found!\n";
}

my $DROPBOX_HOSTDB = $ENV{HOME} . "/.dropbox/host.db";
my $DROPBOX_INSTALLDIR = "";
if (-s $DROPBOX_HOSTDB) {
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
    print "Dropbox detected but not found in '$DROPBOX_INSTALLDIR'\n";
    $DROPBOX_INSTALLDIR = '';
  }
  else {
    print "Found Dropbox Installation: '$DROPBOX_INSTALLDIR'\n";
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

my $WINEDIR = $ENV{HOME} . "/.wine_YNAB4";
print "\nSpecify WINE directory to use: [$WINEDIR] ";
my $input = <STDIN>;
chomp $input;
$WINEDIR = $input if $input !~ /^\s*$/;
my $WINE_DRIVEC_DIR = "$WINEDIR/drive_c";
my $WINE_APPDATA_DIR = "$WINE_DRIVEC_DIR/users/$ENV{USER}/Application\ Data";

if ($INSTALL_MODE eq 'YNAB') {
  # Might need to use $ENV{LOGNAME} here?
  system('mkdir', '-p', "$WINEDIR");
  mydie "Unable to create $WINEDIR\n" unless -d $WINEDIR;
}
else {
  # Check to see if YHAB is installed already..
  my $YNAB_APPDATA_DIR = "$WINE_APPDATA_DIR/com.ynab.YNAB4.LiveCaptive";
  if (! -d $YNAB_APPDATA_DIR) {
    print "\nWARNING: YNAB4 does not appear to be installed in $WINEDIR\n";
    print "Continue Linking Dropbox? [yN] ";
    my $ans = <STDIN>;
    if ($ans !~ /^y/i) {
      exit;
    }
  }
}

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
  my ($dir, $found) = @_;
  &recursive_find_installers($dir, $found);
}

sub recursive_find_installers ($\@) {
  my ($dir, $found) = @_;

  opendir(DIR, $dir) or return;
  my @files = readdir DIR;
  closedir DIR;

  foreach my $file (sort @files) {
    next if $file =~ /^\./;
    my $path = "$dir/$file";

    next if -l $path;
    if (-d $path) {
      &recursive_find_installers($path, $found);
    }

    if ($file =~ /^YNAB.*4.*setup.*\.exe$/i) {
      push @$found, $path;
    }
  }
}

sub check_latest_version {
    my $download_page = get('http://www.youneedabudget.com/download') or die 'Unable to get page';
    if ($download_page =~ /(<p><strong><a href=")(.+)(" class="desktop-download">Version )(.+)( for Windows)/ or die 'Unable to match regex') {
        return ($2, $4);
    }
}

sub download_latest_version {
    print "\nDownloading latest version of YNAB4...\n";
    my ($file_url, $latest_version) = &check_latest_version;
    my $file_prefix = "/tmp/YNAB 4_";
    my $file_suffix = "_Setup.exe";
    my $file_path = $file_prefix . $latest_version . $file_suffix;
    getstore($file_url, $file_path);
    return $file_path;
}
