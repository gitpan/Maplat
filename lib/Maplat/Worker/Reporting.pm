
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Worker::Reporting;
use Maplat::Worker::BaseModule;
use Maplat::Helpers::DateStrings;
@ISA = ('Maplat::Worker::BaseModule');

use strict;
use warnings;
use Carp;

our $VERSION = 0.95;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

	my @debuglog;
	$self->{debuglog} = \@debuglog;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
}

sub register {
    my $self = shift;
}


sub log {
	my ($self, $error_type, $description) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
	
    my $sth = $dbh->prepare("INSERT INTO errors (error_type, description)" .
                            "VALUES (?, ?)")
                or die($dbh->errstr);
    $sth->execute($error_type, $description) or die($dbh->errstr);
    $sth->finish;
    
    if($self->{email}) {
        $self->{server}->{modules}->{$self->{mail}}->send(
            'rene.schickbauer@magnapowertrain.com',
            'ERROR: ' . $error_type,
            $description,
            'text/plain',
        );
    }
}

sub debuglog {
	my ($self, $line) = @_;
	
	chomp $line;
	$line = getISODate() . " " . $line;
	
	push @{$self->{debuglog}}, $line;
	if(scalar @{$self->{debuglog}} > $self->{maxlines}) {
		shift @{$self->{debuglog}};
	}
	my $memh = $self->{server}->{modules}->{$self->{memcache}};
	$memh->set($self->{worker}, $self->{debuglog});
	
	if($self->{std_out}) {
		print "$line\n";
	}
}

1;
__END__

=head1 NAME

Maplat::Worker::Reporting - logging to database and STDOUT

=head1 SYNOPSIS

This module provides logging capabilities to Maplat workers.

=head1 DESCRIPTION

This module provides logging to database (table "errors"). Also, logging to STDOUT is
provided via debuglog() with current date and time prefixed to the logline. This debuglog
lines are also "logged" via the Memcache worker module so the last few lines of STDOUT can
also be visualized in the WebGUI.

=head1 Configuration

        <module>
                <modname>reporting</modname>
                <pm>Reporting</pm>
                <options>
                        <db>maindb</db>
                        <mail>sendmail</mail>
                        <memcache>memcache</memcache>
                        <email>0</email>
                        <std_out>1</std_out>
                        <maxlines>60</maxlines>
                        <worker>MyWorker</worker>
                </options>
        </module>


email (boolean) send errors logged by log() via email (via worker module Sendmail)
std_out (boolean) send debuglog() to stdout
maxlines how many lines are copied to memcache
worker name which is used in logging to memcache

=head2 debuglog

Log a information line to stdout and to memcached.

=head2 log

Log a line to database.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Worker::PostgresDB as "db"
Maplat::Worker::Memcache as "memcache"
Maplat::Worker::Sendmail as "mail"

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
