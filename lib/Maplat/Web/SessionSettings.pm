# MAPLAT  (C) 2008-2010 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::SessionSettings;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

our $VERSION = 0.98;


sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_loginitem("on_login");
    $self->register_logoutitem("on_logout");
    $self->register_sessionrefresh("on_refresh");
    return;
}

# NOTE: We have TWO sets of data for each session:
# The first data set is the used keys within a session (a hash),
# the second set of data are the actual entries.
# We don't actually have to manage something like "last access"
# right now, we depend on beeing onLogout() called by the
# login module for timed-out sessions

sub get {
    my ($self, $settingname) = @_;
    
    my $settingref;
        
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    
    $settingref = $memh->get($keyname);
    if(defined($settingref)) {
        return (1, $settingref);
    }
    
    return 0;
}

sub set {
    my ($self, $settingname, $settingref) = @_;
    
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    my $listname = "SessionSettings::Sessions";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        $list = {};
    }
    
    if(defined($list->{$sessionid})) {
        $list->{$sessionid}->{memkeys}->{$keyname} = 1;
    }

    $memh->set($keyname, $settingref);
    $memh->set($listname, $list);
    
    return 1;
}

sub delete {## no critic(BuiltinHomonyms)
    my ($self, $settingname) = @_;
    
    my $settingref;

    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    my $listname = "SessionSettings::Sessions";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        $list = {};
    }
    
    if(defined($list->{$sessionid})) {
        delete $list->{$sessionid}->{memkeys}->{$keyname};
    }

    $memh->delete($keyname);
    $memh->set($listname, $list);

    
    return 1;
}

sub list {
    my ($self) = @_;
    
    my @settingnames = ();
    
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $listname = "SessionSettings::Sessions";
    my $keyrm = "SessionSettings::" . $sessionid . "::";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        return 0;
    }
    
    if(defined($list->{$sessionid}) && defined($list->{$sessionid}->{memkeys})) {
        foreach my $memkey (sort keys %{$list->{$sessionid}->{memkeys}}) {
            my $tmp = $memkey;
            $tmp =~ s/$keyrm//g;
            push @settingnames, $tmp;
        }
        return (1, @settingnames);
    }
    return (0, @settingnames);
}

sub on_login {
    my ($self, $username, $sessionid) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $listname = "SessionSettings::Sessions";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        $list = {};
    }
    
    $list->{$sessionid}->{lastUpdate} = time;
    $list->{$sessionid}->{userName} = $username;
    $list->{$sessionid}->{memkeys} = {};
    
    $memh->set($listname, $list);    
    return;
}

sub on_logout {
    my ($self, $sessionid) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $listname = "SessionSettings::Sessions";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        return;
    }
    
    if(defined($list->{$sessionid}) && defined($list->{$sessionid}->{memkeys})) {
        foreach my $key (keys %{$list->{$sessionid}->{memkeys}}) {
            $memh->delete($key);
        }
        delete $list->{$sessionid};
    }
    
    $memh->set($listname, $list);
    return;
}

sub on_refresh {
    my ($self, $sessionid) = @_;

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $listname = "SessionSettings::Sessions";
    
    my $list = $memh->get($listname);
    if(!defined($list)) {
        return;
    }
    
    # FIRST, delete all sessions that are over 2 hours old (Login uses 1 hour, so
    # we should be on the save side)
    my $currTime = time;
    foreach my $session (keys %{$list}) {
        my $oldTime = $list->{$sessionid}->{lastUpdate} || 0;
        my $age = ($currTime - $oldTime) / 3600;
        if($age > 2) {
            # Ok, delete this session
            if(defined($list->{$sessionid}) && defined($list->{$sessionid})->{memkeys}) {
                foreach my $key (keys %{$list->{$sessionid}->{memkeys}}) {
                    $memh->delete($key);
                }
            }
            delete $list->{$session};
        }
    }
    
    # Update sessions timestamp
    if(defined($list->{$sessionid})) {
        $list->{$sessionid}->{lastUpdate} = $currTime;
    }
    
    $memh->set($listname, $list);
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::SessionSettings - save and load session/module specific data

=head1 SYNOPSIS

This module provides handling module-specific data handling on a per session basis

=head1 DESCRIPTION

This module provides a simple interface to memcached for saving and loading module
specific data on a per session basis. It can, for example, be used to save session specific filters
to memcache. It can handle complex data structures.

Data is not permanently stored, but rather it's deleted when a user logs out or the session times out (auto
user logout)

=head1 Configuration

        <module>
                <modname>sessionsettings</modname>
                <pm>SessionSettings</pm>
                <options>
                        <memcache>memcache</memcache>
                        <login>authentification</login>
                </options>
        </module>

=head2 set

This function adds or updates a setting (data structure) in memcache.

It takes two arguments, $settingname is the key name of the setting, and
$settingref is a reference to the data structure you want to store, e.g.:

  $is_ok = $us->set($settingname, $settingref);

It returns a boolean to indicate success or failure.

=head2 get

This function reads a setting from memcached and returns a reference to the data structure.

It takes one arguments, $settingname is the key name of the setting.

  $settingref = $us->get($settingname);

=head2 delete

This function deletes a setting from database and returns a boolean to indicate success or failure.

It takes one arguments, $settingname is the key name of the setting.

  $is_ok = $us->delete($settingname);

=head2 list

This function lists all available settings for a session.

  @settingnames = $us->list();

=head2 on_login

Internal function.

=head2 on_logout

Internal function.

=head2 on_refresh

Internal function.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"
Maplat::Web::Login as "login"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::Memcache
Maplat::Web::Login

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
