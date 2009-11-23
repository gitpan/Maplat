
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Helpers::Mascot;

use 5.008000;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT= qw(Mascot);

our $VERSION = 0.9;

our @lines;

sub Mascot() {
	
	# Only on first call, read in DATA segment
	if(!defined($lines[1])) {
		@lines = <DATA>;
	}
	
	return \@lines;
}

1;

=head1 NAME

Maplat::Helpers::Mascot - print the Maplat mascot as ASCII Art

=head1 SYNOPSIS

  use Maplat::Helpers::Mascot;
  
  MaplatMascot();

=head1 DESCRIPTION

This Module provides an easy way to print out the Maplat Mascot as ASCII art,
which is a rabbit.

=head1 MaplatMascot()

This prints out a cute little rabbit, the mascot of the Maplat project.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

__DATA__
 \\
  \\_ 
   (')
  / )=
o( )_
