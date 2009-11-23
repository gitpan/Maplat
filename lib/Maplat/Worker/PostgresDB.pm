
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Worker::PostgresDB;
use Maplat::Worker::BaseModule;
@ISA = ('Maplat::Worker::BaseModule');
use Maplat::Helpers::DateStrings;

use strict;
use warnings;
use DBI;
use Carp;

our $VERSION = 0.9;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

	my $dbh = DBI->connect($self->{dburl}, $self->{dbuser}, $self->{dbpassword},
                               {AutoCommit => 0, RaiseError => 0}) or die($@);
	$self->{mdbh} = $dbh;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. 
}

sub register {
    my $self = shift;
	# Nothing to do...
}

BEGIN {
	# Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes changes much easier, but
    # you need perl wizardry level +10 to understand how it works...
	my @stdFuncs = qw(prepare prepare_cached do quote);
	my @simpleFuncs = qw(commit rollback errstr);
    my @varSetFuncs = qw(AutoCommit RaiseError);
	my @varGetFuncs = qw();
	no strict 'refs';

	for my $a (@simpleFuncs){
		*{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->$a(); };
	}
		
	for my $a (@stdFuncs){
		*{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->$a($_[1]); };
	}

	for my $a (@varSetFuncs){
		*{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->{$a} = $_[1]; };
	}
	
	for my $a (@varGetFuncs){
		*{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->{$a}; };
	}

}
1;
__END__

=head1 NAME

Maplat::Worker::PostgreSQL - Worker module for accessing PostgreSQL databases

=head1 SYNOPSIS

This module is a wrapper around DBI/DBD::Pg.

=head1 DESCRIPTION

With this worker module, you can easely maintain connections to multiple databases (just
declare multiple modules with different modnames).

=head1 Configuration

        <module>
                <modname>maindb</modname>
                <pm>PostgresDB</pm>
                <options>
                        <dburl>dbi:Pg:dbname=Maplat_DB</dburl>
                        <dbuser>Maplat_Server</dbuser>
                        <dbpassword>SECRET</dbpassword>
                </options>
        </module>


dburl is the DBI connection string, see DBD::Pg.

=head1 Dependencies

This module is a basic module which does not depend on other worker modules.

=head1 SEE ALSO

Maplat::Worker
DBD::Pg

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
