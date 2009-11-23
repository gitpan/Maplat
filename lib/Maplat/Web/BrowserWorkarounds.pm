
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::BrowserWorkarounds;
use Maplat::Web::BaseModule;
@ISA = ('Maplat::Web::BaseModule');
use Maplat::Helpers::DateStrings;

our $VERSION = 0.9;

use strict;
use warnings;

use Carp;

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
}

sub register {
    my $self = shift;
	
	$self->register_prefilter("prefilter");
	$self->register_postfilter("postfilter");
	$self->register_defaultwebdata("get_defaultwebdata");
}


sub prefilter {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
	my $userAgent = $cgi->user_agent() || "Unknown";
	
	my $browser = "Unknown";
	if($userAgent =~ /Firefox/) {
		$browser = "Firefox";
	}
	
	my %browserData = (
		Browser		=>	$browser,
		UserAgent	=>	$userAgent,
	);
	
	$self->{BrowserData} = \%browserData;
	
	return;
	
}
sub postfilter {
    my ($self, $cgi, $header, $result) = @_;
    
	if(!defined($self->{BrowserData}->{Browser})) {
		return;
	} elsif($self->{BrowserData}->{Browser} eq "Firefox") {
		# *** Workarounds for Firefox ***
		if($result->{status} eq "307") {
			# Firefox makes troubles with a 307 resulting
			# from a POST (for example viewselect), it pops
			# up a completly stupid extra YES/NO box.
			# Soo... rewrite to a 200 and HTML-redirect the page
			# instead
			
			my $location = $result->{location};
			undef $result->{location};
			$result->{status} = 200;
			$result->{statustext} = "Using HTML redirect for broken Firefox";
			
			my %webdata = (
				$self->{server}->get_defaultwebdata(),
				PageTitle   		=>  "Redirect",
				ExtraHEADElements	=> "<meta HTTP-EQUIV=\"REFRESH\" content=\"0; url=$location\">",
				NextLocation		=> $location,
			);
				
			my $template = $self->{server}->{modules}->{templates}->get("browserworkarounds_redirect", 1, %webdata);
			$result->{data} = $template;
		}
	}
    
    return;
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
	$webdata->{BrowserData} = $self->{BrowserData};
}

1;
__END__

=head1 NAME

Maplat::Web::BrowserWorkarounds - filter pages to display correctly in various browsers

=head1 SYNOPSIS

This module filters generated pages and headers so they will display correctly in different browsers

=head1 DESCRIPTION

This module registers itself in pre- and postfilter. It does various things to the browser request
and server response to compensate for different browser issues. Currently, only a workaround for
Firefox is implemented.

=head1 Configuration

        <module>
                <modname>workarounds</modname>
                <pm>BrowserWorkarounds</pm>
                <options>
                        <pagetitle>Workarounds</pagetitle>
                </options>
        </module>

it is highly recommended to configure this module as the last module, so it can clean up after everything
else is done.

=head1 Dependencies

This module does not depend on other webgui modules.

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
