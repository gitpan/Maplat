# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::PostgresDB;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

our $VERSION = 0.995;

use DBI;
use English '-no_match_vars';
use Carp;
use XML::Simple;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    if(defined($config{include})) {
        if(!-f $config{include} ) {
            croak("Can't find include config " . $config{include});
        }
        my $include = XMLin($config{include});
        foreach my $key (qw[dburl dbuser dbpassword]) {
            if(defined($include->{$key})) {
                $config{$key} = $include->{$key};
            }
        }
    }
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    return $self;
}

sub checkDBH {
    my ($self) = @_;

    if(defined($self->{mdbh})) {
        return;
    }

    my $dbh = DBI->connect($self->{dburl}, $self->{dbuser}, $self->{dbpassword},
                               {AutoCommit => 0, RaiseError => 0}) or croak($@);
    $self->{mdbh} = $dbh;
    #print "DBI created for PID $PID\n";
    return;
}

sub DESTROY {
    my ($self) = @_;

    if(!defined($self->{mdbh})) {
        return;
    }

    $self->{mdbh}->rollback;
    $self->{mdbh}->disconnect;
    delete $self->{mdbh};
    #print "DBI destroyed for PID $PID\n";
    return;
}


sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    
    $self->register_cleanup("cleanup");
    
    return;
}

sub cleanup {
    my ($self) = @_;
    
    $self->{mdbh}->rollback;
    
    return;
}

sub endconfig {
    my ($self) = @_;

    if($self->{forking}) {
        # forking server: disconnect from database, generate new connection
        # after the fork on demand
        #print "   *** Will fork, disconnect PostgreSQL server...\n";
        $self->rollback;
        $self->{mdbh}->disconnect;    
        delete $self->{mdbh};
    }
    return;
}

BEGIN {
    # Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes changes much easier, but
    # you need perl wizardry level +10 to understand how it works...
    my @stdFuncs = qw(prepare prepare_cached do quote);
    my @simpleFuncs = qw(commit rollback errstr);
    my @varSetFuncs = qw(AutoCommit RaiseError);
    my @varGetFuncs = qw();

    for my $a (@simpleFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { $_[0]->checkDBH(); return $_[0]->{mdbh}->$a(); };
    }
        
    for my $a (@stdFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { $_[0]->checkDBH(); return $_[0]->{mdbh}->$a($_[1]); };
    }

    for my $a (@varSetFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { $_[0]->checkDBH(); return $_[0]->{mdbh}->{$a} = $_[1]; };
    }
    
    for my $a (@varGetFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { $_[0]->checkDBH(); return $_[0]->{mdbh}->{$a}; };
    }

}

# Sample of autogenerated function
#sub prepare {
#    my ($self, $arg) = @_;
#    
#    return $self->{mdbh}->prepare($arg);
#}


1;
__END__

=head1 NAME

Maplat::Web::PostgresDB - Web module for accessing PostgreSQL databases

=head1 SYNOPSIS

This module is a wrapper around DBI/DBD::Pg.

=head1 DESCRIPTION

With this web module, you can easely maintain connections to multiple databases (just
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

As an alternative, the DB connection info can be included from an external file. The
file should look like this:

        <postgresql>
                <dburl>dbi:Pg:dbname=Maplat_DB</dburl>
                <dbuser>Maplat_Server</dbuser>
                <dbpassword>SECRET</dbpassword>
        </postgresql>
        
with the options section of the module like this:

        <options>
                <include>/path/to/configuration.xml</include>
        </options>

A combination of these two is possible, the setting from the included file overwriting
the directly configured ones.


dburl is the DBI connection string, see DBD::Pg.

=head2 AutoCommit

Get/Set the DBD::Pg "AutoCommit" setting

=head2 RaiseError

Get/Set the DBD::Pg "RaiseError" setting

=head2 errstr

Get the DBI errorstring.

=head2 do

Execute a DBI statement with "do"

=head2 prepare

Prepare a (non-cached) Statement.

=head2 prepare_cached

Prepare a server cached statement (may fall back to non-cached transparently, see DBD::Pg and PostgreSQL documentation
for details).

=head2 quote

Quote a variable for use in PostgreSQL statements.

=head2 commit

Commit transaction.

=head2 rollback

Rollback transaction.

=head2 checkDBH

Internal function. Checks if the database handle is valid and reconnects if needed.

=head2 cleanup

Internal callback function, makes sure there are no open transactions after rendering a page.

=head1 Dependencies

This module is a basic module which does not depend on other web modules.

=head1 SEE ALSO

Maplat::Web
DBD::Pg

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
