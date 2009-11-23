
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Web::TemplateCache;
use Template;
use Maplat::Web::BaseModule;
@ISA = ('Maplat::Web::BaseModule');

our $VERSION = 0.9;

use strict;
use warnings;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    $self->{processor} = Template->new();
    if(!defined($self->{processor})) {
        die("Failed to load template engine");
    }
    
    return $self;
}

sub reload {
    my ($self) = shift;
    delete $self->{cache} if defined $self->{cache};

    my %files;

	foreach my $bdir (@INC) {
		next if($bdir eq ".");
		my $fulldir = $bdir . "/Maplat/Web/Templates";
		print "   ** checking $fulldir \n";
		if(-d $fulldir) {
			print "   **** loading extra static files\n";
			$self->load_dir($fulldir, \%files);
		}
	}

	$self->load_dir($self->{path}, \%files);	

    $self->{cache} = \%files;  
}

sub load_dir {
	my ($self, $dir, $files) = @_;
    opendir(my $dfh, $dir) or die($!);
    while((my $fname = readdir($dfh))) {
        next if($fname !~ /\.tt$/);
        my $nfname = $dir . "/" . $fname;
        my $kname = $fname;
        $kname =~s /\.tt$//g;
        open(my $fh, "<", $nfname) or confess($!);
        my $holdTerminator = $/;
        undef $/;
        binmode($fh);
        my $data = <$fh>;
        $/ = $holdTerminator;
        close($fh);
        close($fh);
        $files->{$kname} = $data;
    }
    closedir($dfh);
}

sub register {
    my $self = shift;
    # Templates don't register themself
}

sub get {
    my ($self, $name, $uselayout, %webdata) = @_;
    return undef unless defined($self->{cache}->{$name});
    
    #return undef unless defined($self->{cache}->{$layout});
    
    # Run a prerender callback on our webdata, so modules
    # like the "views" module can add missing data depending
    # on what the current module put into webdata
    $self->{server}->prerender(\%webdata);
    
    my $fullpage;
    
    if($uselayout) {
        $fullpage = $self->{cache}->{$self->{layout}};
        my $page = $self->{cache}->{$name};
        $fullpage =~ s/XX_BODY_XX/$page/;
    } else {
        $fullpage = $self->{cache}->{$name};
    }
    
    my $output;
    $self->{processor}->process(\$fullpage, \%webdata, \$output);
    if(defined($self->{processor}->{_ERROR}) &&
            $self->{processor}->{_ERROR}) {
        $self->{LastError} = $self->{processor}->{_ERROR};
    }
    return $output;
}

1;
__END__

=head1 NAME

Maplat::Web::TemplateCache - provide template caching and rendering

=head1 SYNOPSIS

This module provides template rendering as well as caching the template files

=head1 DESCRIPTION

During the reload() calls, this modules loads all template files in the configured directory
into RAM and renders them quite fast.

The template rendering can optionally use "meta" rendering with a base template. This is for example
used to render the complete layout of a page, and modules only have templates that use only the changing
part of the page - this way, you only have to have one global layout and only write the changing part
of the page for every module.

=head1 Configuration

        <module>
                <modname>templates</modname>
                <pm>TemplateCache</pm>
                <options>
                        <path>MaplatWeb/Templates</path>
                        <!-- Layout-Template to use for complete pages -->
                        <layout>maplatlayout</layout>
                </options>
        </module>

layout is the template name used in meta-rendering.

=head1 get()

The one public function to call in this module is get(), in the form of:

  $templatehandle->get($name, $uselayout, %webdata);

$name if the name of the template file (without the .tt suffix)

$uselayout is a boolean, indicating if meta-rendering with the configured layout.

%webdata is a hash that is passed through to the template toolkit.

=head1 Dependencies

This module is a basic web module and does not depend on other web modules.

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
