
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


# Serialize/deserialize complex data structures in a way compatible to a
# postgres TEXT field (achieved through Storable and Base64 encoding)

package Maplat::Helpers::DBSerialize;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(dbfreeze dbthaw);
our $VERSION = 0.95;

use Storable qw(freeze thaw);
use MIME::Base64;

sub dbfreeze {
    my ($data) = @_;
    
    return encode_base64(freeze($data), "");
}

sub dbthaw {
    my ($data) = @_;
    
    return thaw(decode_base64($data));
}
1;
__END__

=head1 NAME

Maplat::Helpers::DBSerialize - serialize data structures for saving them into a database text field

=head1 SYNOPSIS

  use Maplat::Helpers::DBSerialize;
  
  my $textstring = dbfreeze($reftodata);
  my $reftodata = dbthaw($textstring);

=head1 DESCRIPTION

This module provides functions to encode data structures in a way so they can be saved to
non-binary text strings in databases (like the "text" data type in PostgreSQL).

Internally, it uses Storable and MIME::Base64 to do its job.

=head2 dbfreeze

Takes one argument, the reference to the data structure to be encoded. Returns a text string.

=head2 dbthaw

Takes one argument, a text string encoded by dbfreeze(). Returns a reference to a data structure.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
