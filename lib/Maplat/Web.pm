package Maplat::Web;
use base qw(Maplat::Server::Simple::CGI);

# ------------------------------------------
# MAPLAT - Magna ProdLan Administration Tool
# ------------------------------------------
#   Command-line Version
# ------------------------------------------

our $VERSION = 0.9;

use strict;
use warnings;
use Template;
use Data::Dumper;
use FileHandle;
use Socket;
use Data::Dumper;
use Maplat::Helpers::Mascot;

#=!=START-AUTO-INCLUDES
use Maplat::Web::BrowserWorkarounds;
use Maplat::Web::CommandQueue;
use Maplat::Web::Debuglog;
use Maplat::Web::DirCleaner;
use Maplat::Web::DocsSearch;
use Maplat::Web::DocsSpreadSheet;
use Maplat::Web::DocsWordProcessor;
use Maplat::Web::Errors;
use Maplat::Web::Login;
use Maplat::Web::LogoCache;
use Maplat::Web::BaseModule;
use Maplat::Web::MemCache;
use Maplat::Web::PathRedirection;
use Maplat::Web::PostgresDB;
use Maplat::Web::SendMail;
use Maplat::Web::SessionSettings;
use Maplat::Web::StandardFields;
use Maplat::Web::StaticCache;
use Maplat::Web::Status;
use Maplat::Web::TemplateCache;
use Maplat::Web::UserSettings;
use Maplat::Web::VariablesADM;
#=!=END-AUTO-INCLUDES

use Carp;

sub handle_request {
    my ($self, $cgi) = @_;
    my $webpath = $cgi->path_info();
    my %header = (  -system  =>  "MAPLAT Version $VERSION",
                    -creator => 'Rene \'cavac\' Schickbauer',
                    -complaints_to   => 'rene.schickbauer@magnapowertrain.com',
                    -expires => 'now',
                    -cache_control=>"no-cache, no-store, must-revalidate",
                    -charset => 'utf-8',
                    -lang => 'en-EN',
                    -title => 'MAPLAT WebGUI');
    
    my %result = (status    => 404, # Default result
                  type      => "text/plain",
                  data      => "Error 404: Kindly check you URL and try again!\n" .
                                "If you think this error is in error, please contact your " .
                                "system administrator or local network expert\n.",
                  pagedone => 0, # Remember if we still have only the ugly default page.
                  );
    my %fallbackresult = %result; # Just in case

    
    # This works on "prefilters" like Authentification checks, path
    # re-routing ("/" -> "302 /index") and similar.
    # We don't do this behind the scenes but use the appropriate return codes
    # as per RFC. This avoids browser troubles and search engines will show correct
    # results (with the correct links).
    if(!$result{pagedone}) {
        foreach my $filtermodule (@{$self->{prefilter}}) {
            my $module = $filtermodule->{Module};
            my $funcname = $filtermodule->{Function};
            my %preresult = $module->$funcname($cgi);
            if(%preresult) {
                %result = %preresult;
                $result{pagedone} = 1;
                last;
            }
        }
    }
    
    if(!$result{pagedone}) {
        foreach my $dpath (keys %{$self->{webpaths}}) {
            if($webpath =~ /^$dpath/) {
                my $pathmodule = $self->{webpaths}->{$dpath};
                my $module = $pathmodule->{Module};
                my $funcname = $pathmodule->{Function};
                %result = $module->$funcname($cgi);
                last;
            }
        }
    }
    
    foreach my $filtermodule (@{$self->{postfilter}}) {
        my $module = $filtermodule->{Module};
        my $funcname = $filtermodule->{Function};
        $module->$funcname($cgi, \%header, \%result);
    }
    
    # workaround for simpler in-module handling of 404, when no data segment is given
    if($result{status} == 404 && !defined($result{data})) {
        %result = %fallbackresult;
    }
    
    # workaround for lazy modules without status text
    if(!defined($result{statustext}) || $result{statustext} eq "") {
        if($result{status} eq "200") {
            $result{statustext} = "OK";
        } elsif($result{status} eq "404") {
            $result{statustext} = "Resource not found";
        } elsif($result{status} eq "307") {
            $result{statustext} = "See elsewhere";
        } else {
            # depending on resultcode, this may trigger the browser into
            # some confusion... If you see this, you where *too* lazy
            # programming your module
            $result{statustext} = "OK but something weird happend";
        }
    }
       
    print "HTTP/1.1 " . $result{status} . " " . $result{statustext} . "\r\n";
    
    if(defined($result{type})) {
        $header{"-type"} = $result{type};
    }
    if(defined($result{location})) {
        $header{"-location"} = $result{location};
    }
    if(defined($result{expires})) {
        $header{"-expires"} = $result{expires};
    }
    if(defined($result{cache_control})) {
        $header{"-cache_control"} = $result{cache_control};
    }
    
    print $cgi->header(%header);
    print $result{data};
 
}

sub housekeeping {
    my $self = shift;
    #print "x\n";
    return 0;
}

sub startconfig() {
    my ($self) = @_;
        
    # Clean up configuration
    my %tmpPaths;
    $self->{paths} = \%tmpPaths;
    my %tmpModules;
    $self->{modules} = \%tmpModules;
    my @prefilter;
    $self->{prefilter} = \@prefilter;
    my @prerender;
    $self->{prerender} = \@prerender;
    my @tasks;
    $self->{tasks} = \@tasks;
    my @postfilter;
    $self->{postfilter} = \@postfilter;
    my @default_webdata;
    $self->{default_webdata} = \@default_webdata;
    my @loginitems;
    $self->{loginitems} = \@loginitems;
    my @logoutitems;
    $self->{logoutitems} = \@logoutitems;
    my @sessionrefresh;
    $self->{sessionrefresh} = \@sessionrefresh;
    
}

sub endconfig() {
    my ($self) = @_;
    
    # TODO: IMPLEMENT SOME SANITY CHECKS HERE
    
    print "For great justice...\n"; # We REQUIRE an all-your-base reference here!!!
    print "Loading dynamic data...\n";
    foreach my $modname (keys %{$self->{modules}}) {
        print "  Loading data for $modname\n";
        $self->{modules}->{$modname}->reload;   # Reload module's data
    }
    print "Data loaded!\n";
    print "\n";
    print "Startup configuration complete!\n";
    print "Starting Maplat Server...\n";
    my $lines = Mascot();
    foreach my $line (@{$lines}) {
        print "$line";
    }
    print "\n";

}

sub configure {
    my ($self, $modname, $perlmodulename, %config) = @_;
    
    # Let the module know its configured module name...
    $config{modname} = $modname;
    
    # ...what perl module it's supposed to be...
	my $perlmodule = "Maplat::Web::$perlmodulename";
    if(!defined($perlmodule->VERSION)) {
		# Local module - load it first
		print "Dynamically loading $perlmodule...\n";
		require "Maplat/Web/" . $perlmodulename . ".pm";
	}
    $config{pmname} = $perlmodule;

    # and its parent
    $config{server} = $self;
    
    $self->{modules}->{$modname} = $perlmodule->new(%config);
    $self->{modules}->{$modname}->register; # Register handlers provided by the module
    print "Module $modname ($perlmodule) configured.\n";
}

sub reload {
    my ($self) = @_;
    
    foreach my $modname (keys %{$self->{modules}}) {
        $self->{modules}->{$modname}->reload;   # Reload module's data
    }
}

sub prepare {
    my ($self) = @_;
    
    $self->{weblistener} = $self->SUPER::prepare();
    return;
}

sub run {
    my ($self) = @_;
    
    my $conCount = $self->{weblistener}->run;
    
    # only run tasks if there was no connection (there might be a browser just loading more files)
    my $taskCount = 0;
    if(!$conCount) {
        foreach my $task (@{$self->{tasks}}) {
            my $module = $task->{Module};
            my $funcname = $task->{Function};
            $taskCount += $module->$funcname();
        }
    }
    return ($conCount + $taskCount);
}

# Multi-Module calls: Called from one module to run multiple other module functions
sub get_defaultwebdata {
    my ($self) = @_;

    my %webdata = ();
    foreach my $item (@{$self->{default_webdata}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname(\%webdata);
    }
    
    return %webdata;
}

# This is used by the template engine to get last-minute data fields
# just before rendering webdata with a template into a webpage
# Takes a reference to webdata
sub prerender {
    my ($self, $webdata) = @_;

    foreach my $item (@{$self->{prerender}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($webdata);
    }
}

sub user_login {
    my ($self, $username, $sessionid) = @_;

    foreach my $item (@{$self->{loginitems}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($username, $sessionid);
    }
}

sub user_logout {
    my ($self, $sessionid) = @_;

    foreach my $item (@{$self->{logoutitems}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($sessionid);
    }
}

sub sessionrefresh {
    my ($self, $sessionid) = @_;

    foreach my $item (@{$self->{sessionrefresh}}) {
        my $module = $item->{Module};
        my $funcname = $item->{Function};
        $module->$funcname($sessionid);
    }
}

# TRIGGER REGISTRATION: Reserve calls from modules
sub add_webpath {
    my ($self, $path, $module, $funcname) = @_;
    
    my %conf = (
        Module  => $module,
        Function=> $funcname
    );
    
    $self->{webpaths}->{$path} = \%conf;
}

BEGIN {
	# Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes consistent changes much easier, but
    # you need perl wizardry level +12 to understand how it works...

	no strict 'refs';
    
    # -- Deep magic begins here...
    my %varsubs = (
        prefilter       => "prefilter",
        postfilter      => "postfilter",
        defaultwebdata  => "default_webdata",
        task            => "tasks",
        loginitem       => "loginitems",
        logoutitem      => "logoutitems",
        sessionrefresh  => "sessionrefresh",
        prerender       => "prerender",
    );
	for my $a (keys %varsubs){
		*{__PACKAGE__ . "::add_$a"} =
            sub {
                my %conf = (
                    Module  => $_[1],
                    Function=> $_[2],
                );
                push @{$_[0]->{$varsubs{$a}}}, \%conf;
            };
	}
    # ... and ends here
}

1;
__END__

=head1 NAME

Maplat::Web - the Maplat WebGUI

=head1 SYNOPSIS

The webgui module is the one responsible for loading all actual rendering modules, dispatches
calls and handles the browser requests.

  my $config = XMLin($configfile,
                    ForceArray => [ 'module', 'redirect', 'menu', 'view', 'userlevel' ],);
  
  $APPNAME = $config->{appname};
  print "Changing application name to '$APPNAME'\n\n";
  
  my @modlist = @{$config->{module}};
  my $webserver = MaplatWeb->new($config->{server}->{port});
  $webserver->startconfig();
  
  foreach my $module (@modlist) {
      $webserver->configure($module->{modname}, $module->{pm}, %{$module->{options}});
  }
  
  
  $webserver->endconfig();
  $webserver->prepare();
  
  # Everything ready to run - notify user
  $webserver->print_banner;
  while(1) {
      my $workCount = $webserver->run();
      if(!$workCount) {
          sleep(0.1);
      }
  }


=head1 DESCRIPTION

This webgui is "the root of all evil". It loads and configures the rendering modules, dispatches
browser requests and callbacks/hooks and renders the occasional 404 error messages if no applicable
module for the the browsers request is found.

=head1 Configuration and Startup

Configuration is done in stages from the main application, after new(), the first thing to call is startconfig()
to prepare the webserver for module configuration.

After that, for each module to load, configure() is called, during which the module is loaded and configured.

Next thing is to call endconfig(), which notifies the webserver that all required modules are loaded (the webserver
then automatically calls reload() to load all cached data).

After a call to prepare() and an optional call to print_banner() (which the author strongly recommends *grin*) the webserver
is ready to handle browser requests.

This is done in a while loop or similar calling run().

=head1 SEE ALSO

Maplat::Worker

Please also take a look in the example provided in the tarball available on CPAN.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@magnapowertrain.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
