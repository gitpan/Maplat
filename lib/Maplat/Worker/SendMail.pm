
# MAPLAT  (C) 2008-2009 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz


package Maplat::Worker::SendMail;
use Maplat::Worker::BaseModule;
@ISA = ('Maplat::Worker::BaseModule');

use Maplat::Helpers::DateStrings;
use Mail::Sendmail;
use MIME::QuotedPrint;
use MIME::Base64;

use strict;
use warnings;
use Carp;

our $VERSION = 0.9;

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
}


sub send {
	my ($self, $reciever, $subject, $message, $contenttype) = @_;
	
	my %mail = (
                To              => $reciever,
                From            => $self->{sender},
                Subject         => $self->{subject_prefix} . " " . $subject,
                Message         => $message,
                Server          => $self->{mailserver},
                Port            => $self->{mailport},
                'X-Mailer'      => $self->{mailer_id},
                'content-type'  => $contenttype,      
                );
    
    if(defined($self->{Cc})) {
        $mail{Cc} = $self->{Cc};
    }
    if(defined($self->{Bcc})) {
        $mail{Bcc} = $self->{Bcc};
    }
    
    if(!sendmail(%mail)) {
        return (0, "Can't send status mail: " . $Mail::Sendmail::error);
    } else {
        return (1, "Status mail sent");
    }
}

sub sendFiles{
	my ($self, $reciever, $subject, $body, @files) = @_;
	
	my $boundary = "====" . time() . "====";
	my $contenttype = "multipart/mixed; boundary=\"$boundary\"";
	my $message = "--$boundary\n" .
                "Content-Type: text/plain; charset=\"iso-8859-1\"\n" .
                "Content-Transfer-Encoding: quoted-printable\n" .
                "\n" .
                encode_qp($body) . "\n" .
                "\n";
				
	foreach my $file (@files) {
		my $fdata = "";
		open(my $ifh, "<", $file) or return(0, "Can't read file $file");
		while((my $fline = <$ifh>)) {
			$fdata .= $fline;
		}
		close $ifh;
		$fdata = encode_base64($fdata);
		$file =~ /.*\/([^\/]*)$/o;
		my $shortname = $1;
		$file =~ /\.([^\.]*)$/o;
		my $type = lc $1;
		my $longtype = "text/plain";
		if($type eq "csv") {
			$longtype = "text/csv";
		} elsif($type eq "pdf") {
			$longtype = "application/pdf";
		}
		
        $message .= "--$boundary\n" .
					"Content-Type: text/csv; name=\"$shortname\"\n" .
					"Content-Transfer-Encoding: base64\n" .
					"Content-Disposition: attachment; filename=\"$shortname\"\n" .
					"\n" .
					"$fdata\n";
	}
    $message .= "--$boundary--\n";
	
	return $self->send($reciever, $subject, $message, $contenttype);	
}

1;
__END__

=head1 NAME

Maplat::Worker::SendMail - send infos and files via email

=head1 SYNOPSIS

This module provides a simplified wrapper around Mail::Sendmail

=head1 DESCRIPTION

This module provides capabilities of sending textmessages as well as files
via the Mail::Sendmail module.

=head1 Configuration

        <module>
                <modname>sendmail</modname>
                <pm>SendMail</pm>
                <options>
                        <mailserver>mail</mailserver>
                        <mailport>25</mailport>
                        <mailer_id>FooBar Notification System</mailer_id>
                        <sender>foobar.worker@example.com</sender>
                        <subject_prefix>[FooBar]</subject_prefix>
                </options>
        </module>

=head1 Dependencies

This module does not depend on other worker modules

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
