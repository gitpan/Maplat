
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Web::MemCache;
use Maplat::Web::BaseModule;
@ISA = ('Maplat::Web::BaseModule');
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::BuildNum;

our $VERSION = 0.91;

use strict;
use warnings;
use Maplat::Helpers::Cache::Memcached;
use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

	my $memd;
	my $memd_loaded = 0;
	# Decide which Memcached module we want to use
	# First, we try the festest one, then the standard
	# one and if everything fails we use our own
	if(eval('require Cache::Memcached::Fast')) {
		print "    Cache::Memcached::Fast available.\n";
		$memd = new Cache::Memcached::Fast {
						servers   => [ $self->{service} ],
						namespace => $self->{namespace} . "::",
						connect_timeout  => 0,
					};
		$memd_loaded = 1;
	} elsif(eval('require Cache::Memcached')) {
		print "    No Cache::Memcached::Fast ... falling back to Cache::Memcached\n";
		$memd = new Cache::Memcached {
						servers   => [ $self->{service} ],
						namespace => $self->{namespace} . "::",
						connect_timeout  => 0,
					};
		$memd_loaded = 1;
	} else {
		print "    No Cache::Memcached* available ... will try to use Maplat::Helpers::Cache::Memcached\n";
	}

	# Check if the selected Memcached lib is working correctly
	my $key = "test_" . int(rand(10000)) . "_" . int(rand(10000));
	my $val = "test_" . int(rand(10000)) . "_" . int(rand(10000));
	my $newval;
	if($memd_loaded) {
		$memd->set($key, $val);
		$newval = $memd->get($key);
	}
	if(!defined($newval) || $newval ne $val) {
		if($memd_loaded) {
			print "    Selected Memcached client lib is broken - falling back to Maplat::Helpers::Cache::Memcached\n";
		}
		$memd = new Maplat::Helpers::Cache::Memcached {
						servers   => [ $self->{service} ],
						namespace => $self->{namespace} . "::",
						connect_timeout  => 0,
					};
		$memd->set($key, $val);
		$newval = $memd->get($key);
		if(!defined($newval) || $newval ne $val) {
			die("Maplat Memcached client lib is also broken - giving up!"); 
		} else {
			$memd->delete($key);
		}
	} else {
		$memd->delete($key);
	}



	print "    Selected Memcached library seems to be working. Good!\n";
	$self->{memd} = $memd;
	
	# Add version information about our to the memcached storage
	# for the rare cases we need that for other programs to run
	# a compatibility API or something
	# APPNAME and VERSION in main needs to be declared "our ..."
	$self->set("VERSION::" . $main::APPNAME, $main::VERSION);
	$self->set("BUILD::" . $main::APPNAME, readBuildNum());

	$self->{oldtime} = 0;

    return $self;
}

sub reload {
    my ($self) = shift;

}

sub register {
    my $self = shift;
	$self->register_task("refresh_lifetick");
}

sub refresh_lifetick {
	my ($self) = @_;
	
	my $ticktime = time;
	
	if(($ticktime - $self->{oldtime}) > 10) {
		# only refresh every 10 seconds or so to keep
		# resource usage low - otherwise we'd be setting
		# the lifetick 1000 times a second or so
		my $tickkey = "LIFETICK::" . $$;
		$self->set($tickkey, $ticktime);
		$self->{oldtime} = $ticktime;
		return 1;
	}
	return 0;
}

sub get {
	my ($self, $key) = @_;
	
	$key = $self->sanitize_key($key);
	
	return $self->{memd}->get($key);
}

sub set {
	my ($self, $key, $data) = @_;
	
	$key = $self->sanitize_key($key);
	
	return $self->{memd}->set($key, $data);
}

sub delete {
	my ($self, $key) = @_;
	
	$key = $self->sanitize_key($key);
	
	return $self->{memd}->delete($key);
}

sub sanitize_key {
	my ($self, $key) = @_;
	
	# Certain chars are not allowed in keys for whatever reason.
	# This *should* be handled by the Cache::Memcached module, but isn't
	# We handle this by substituting them with a tripple underline
	
	$key =~ s/\ /___/go;
	
	return $key;
}

# Helpers for "active commands"
sub set_activecommand {
	my ($self, $commandid) = @_;
	
	$self->set($main::APPNAME . "::activecommand", $commandid);
}

sub get_activecommands {
	my ($self) = @_;
	
	my %commands;
	
	foreach my $cmd (@{$self->{viewcommands}->{view}}) {
		my $value = $self->get($cmd . "::activecommand");
		if(defined($value) && $value ne "0") {
			$commands{$value} = $cmd;
		}
	}
	
	return %commands;
}

1;
__END__

=head1 NAME

Maplat::Web::MemCache - Module for access to memcached

=head1 SYNOPSIS

This is a wrapper around Cache::Memcache (and similar) with a few addons.

=head1 DESCRIPTION

This module provides a web module that gives the caller an interface to the memcached service.
Internally, it tries to use (in that order) Cache::Memcached::Fast, Cache::Memcached and
Maplat::Helpers::Cache::Memcached and test if they actually can set and retrieve keys.

=head1 Configuration

        <module>
                <modname>memcache</modname>
                <pm>MemCache</pm>
                <options>
                        <service>127.0.0.1:11211</service>
                        <namespace>RBSMem</namespace>
                        <viewcommands>
                                <view>Adm Worker</view>
                                <view>Other Worker</view>
                        </viewcommands>
                </options>
        </module>

service is IP address and port of the memcached service

namespace if a single name assigned to all programs of the same project. Different projects
accessing the same memcached server must use different namespaces, while all programs working
on a common project must use the same namespace. this is so, because next to caching, memcached
in the Maplat framework is also used for interprocess communication.

maxage is the maximum age in days the files are allowed to reside in the directory

limit denotes the limit of how many files to clean out in a single run. This option prevents
the module of monopolizing harddisk IO.

Further, the main script must declare the variables $VERSION and $APPNAME, because some functionality
of the wrapper needs those. This values are set in memcached and can be read out by the WebGUI as a central
point of determing which versions and build of which program are running on the server. So, the variables

  $main::APPNAME
  $main::VERSION

must be accesible and hold reasonable values.

viewcommands is a list of workers that can work on the commandqueue table. This helps checking every worker
for active commands and highlighting them in various other modules

=head1 refresh_lifetick()

Refreshed the lifetick variable for this application in memcached.

=head1 set()

Save data in memcached.

Takes two arguments, a key name and a reference to the data to be stored in memcached. Returns a boolean
to indicate success or failure.

=head1 get()

Read data from memcached. Takes one argument, the key name, returns a reference to the data from memcached
or undef.

=head1 delete()

Delete a key from memcached. Takes one argument, the key name, returns a boolean indicating success or failure.

=head1 set_activecommand()

Sets the command currently processed by this application (or 0 to indicate no active command). Takes one argument,
the id of the currently active command. Returns a boolean indicating success or failure.

=head1 get_activecommands()

Returns a hash with all currently active commands in all (configured) workers, webguis and other apps.

=head1 Dependencies

This module is a basic module which does not depend on other web modules.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
