use strict;
use warnings;

#########################

# There is currently a problem under Windows with Date::Manip on
# certain non-english installations of XP (and possible others).
#
# So we set our time zone to CET
BEGIN {
    if(!defined($ENV{TZ})) {
        $ENV{TZ} = "CET";
    }
}

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More;
BEGIN { 
    plan tests => 9;
    use_ok('Maplat::Web');
    use_ok('Time::HiRes', qw(sleep usleep));
    use_ok('XML::Simple');
    use_ok('WWW::Mechanize');
};

our $APPNAME = "Maplat Webtest";
our $VERSION = "0.95";

chdir "t";
my $configfile = "configs/simple.xml";
if(!-f $configfile) {
    fail("Missing config file");
    exit(1);
}

my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);

$APPNAME = $config->{appname};
print "Changing application name to '$APPNAME'\n\n";
my $isForking = $config->{server}->{forking} || 0;

my @modlist = @{$config->{module}};
my $webserver = new Maplat::Web($config->{server}->{port});
$webserver->startconfig($config->{server}, 0);

foreach my $module (@modlist) {
    $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
}


$webserver->endconfig();

# Everything ready to run
my $pid = $webserver->background();

my $mech = new WWW::Mechanize();

my $result = $mech->get("http://localhost:9500/");
#print $result->content;
#print ref($result) . "\n";
if($result->is_success) {
    pass("Get page with redirect");
} else {
    fail("Get page with redirect");
}

my @checks = (
    "Text in main template",
    "Text in module template",
    "Dynamic module text",
);
foreach my $check (@checks) {
    like($result->content, qr/$check/, $check);
}


# Finish up
is(kill(9,$pid),1,'Signaled 1 process successfully');
wait or die "counldn't wait for sub-process completion";

done_testing();
