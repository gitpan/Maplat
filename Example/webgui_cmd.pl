#!/usr/bin/perl -w

# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

use strict;
use warnings;

use Maplat::Web;
use XML::Simple;
use Time::HiRes qw(sleep usleep);

use Maplat::Helpers::Logo;
our $APPNAME = "Maplat Webgui";
our $VERSION = "2009-11-09";
MaplatLogo($APPNAME, $VERSION);

our $isCompiled = 0;
if(defined($PerlApp::VERSION)) {
    $isCompiled = 1;
}

# ------------------------------------------
# MAPLAT - WebGUI
# ------------------------------------------
#   Command-line Version for Testing
# ------------------------------------------

my $configfile = shift @ARGV;
print "Loading config file $configfile\n";

my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);

$APPNAME = $config->{appname};
print "Changing application name to '$APPNAME'\n\n";

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig();

foreach my $module (@modlist) {
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();
$webserver->prepare();

# Everything ready to run - notify user
$webserver->print_banner;
while(1) {
    my $workCount = $webserver->run();
    if(!$workCount) {
        sleep(0.1);
    }
}
