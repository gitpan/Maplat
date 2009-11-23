
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Web::VariablesADM;
use Maplat::Web::BaseModule;
@ISA = ('Maplat::Web::BaseModule');
use Maplat::Helpers::DateStrings;

our $VERSION = 0.9;

# WARNING: This uses mainly hardcoded stuff

use strict;
use warnings;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
	
	my @variables = qw[LogoDate HeaderMessage HeaderInfo];
	$self->{variables} = \@variables;
	
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{webpath}, "get");
}

sub get {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
	my $memh = $self->{server}->{modules}->{$self->{memcache}};

	# Need to handle setting/deleting variables before getting the
	# default webdata so changes take effect instantly
	my $mode = $cgi->param('mode') || 'view';
	
	if($mode eq "setvalue") {
		my $varname = $cgi->param('varname');
		my $varvalue = $cgi->param('varvalue') || "";
		my $setter = "set_$varname";
		$self->$setter($varvalue);
	} elsif($mode eq "delvalue") {
		my $varname = $cgi->param('varname');
		my $setter = "del_$varname";
		$self->$setter;
	} elsif($mode eq "reload") {
		$self->{server}->reload;
	}

	my %webdata =
	(
		$self->{server}->get_defaultwebdata(),
	    PageTitle   	=>  $self->{pagetitle},
	    webpath			=>  $self->{webpath},
	);
	
	my @varlist;
	foreach my $var (@{$self->{variables}}) {
		my $getter = "get_$var";
		my $val = $self->$getter;
		if(!defined($val)) {
			$val = "";
		}
		my %line = (
			name	=> $var,
			value	=> $val,
		);
		push @varlist, \%line;
	}
	$webdata{variables} = \@varlist;
	
	my $template = $self->{server}->{modules}->{templates}->get("variablesadm", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub set_LogoDate {
	my ($self, $value) = @_;
	
	$self->{server}->{modules}->{logo}->{today} = $value;
}

sub get_LogoDate {
	my ($self) = @_;
	
	return $self->{server}->{modules}->{logo}->{today};
}

sub del_LogoDate {
	my ($self) = @_;
	
	undef $self->{server}->{modules}->{logo}->{today};
}

sub set_HeaderMessage {
	my ($self, $value) = @_;
	
	$self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message} = $value;
}

sub get_HeaderMessage {
	my ($self) = @_;
	
	return $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message};
}

sub del_HeaderMessage {
	my ($self) = @_;
	
	undef $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message};
}

sub set_HeaderInfo {
	my ($self, $value) = @_;
	
	$self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info} = $value;
}

sub get_HeaderInfo {
	my ($self) = @_;
	
	return $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info};
}

sub del_HeaderInfo {
	my ($self) = @_;
	
	undef $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info};
}

1;
__END__

=head1 NAME

Maplat::Web::Variables - change some webgui variables online

=head1 SYNOPSIS

This modules lets you change some internal webgui variables online

=head1 DESCRIPTION

This module is mostly used for debugging. It may or may not be of use to use, since
currently all changeable variables are hardcoded.

Basically, this module lets you change the variables online, it also lets you call the main
reload() routine from the webgui, which may (or may not) work as expected.

=head1 Configuration

        <module>
                <modname>variablesadm</modname>
                <pm>VariablesADM</pm>
                <options>
                        <pagetitle>Variables</pagetitle>
                        <webpath>/admin/variables</webpath>
                        <memcache>memcache</memcache>
                </options>
        </module>


=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::memcache as "memcache"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::Memcache

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
