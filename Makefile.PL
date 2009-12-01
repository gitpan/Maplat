use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Maplat',
    VERSION_FROM      => 'lib/Maplat.pm', # finds $VERSION
    PREREQ_PM         => {
			"CGI" => 0,
			"Data::Dumper" => 0,
			"Date::Manip" => 0,
			"Date::Simple" => 0,
			"DBI" => 0,
			"DBD::Pg" => 0,
			"Digest::MD5" => 0,
			"Digest::SHA1" => 0,
			"File::stat" => 0,
			"HTML::FormatText" => 0,
			"HTML::Parse" => 0,
			"IO::Handle" => 0,
			"Mail::Sendmail" => 0,
			"MIME::Base64" => 0,
			"MIME::QuotedPrint" => 0,
			"PDF::Report" => 0,
			"Storable" => 0,
			"String::CRC32" => 0,
			"Sys::Hostname" => 0,
			"Template" => 0,
			"Time::HiRes" => 0,
			"URI::Escape" => 0,
			"XML::Simple" => 0,
			"HTTP::Server::Simple::CGI" => 0,
			"Net::Server::PreFork" => 0,
			"IO::Socket::SSL" => 0,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Maplat.pm', # retrieve abstract from module
       AUTHOR         => 'Rene Schickbauer <rene.schickbauer@magnapowertrain.com>') : ()),
);
