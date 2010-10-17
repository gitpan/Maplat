# MAPLAT  (C) 2008-2010 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker;
use strict;
use warnings;
use English;
use Carp;

our $VERSION = 0.994;

#=!=START-AUTO-INCLUDES
use Maplat::Worker::AdminCommands;
use Maplat::Worker::BaseModule;
use Maplat::Worker::Commands;
use Maplat::Worker::DirCleaner;
use Maplat::Worker::MemCache;
use Maplat::Worker::MemCachePg;
use Maplat::Worker::OracleDB;
use Maplat::Worker::PostgresDB;
use Maplat::Worker::Reporting;
use Maplat::Worker::SendMail;
#=!=END-AUTO-INCLUDES


sub new {
    my $class = shift;
    my $self = bless {}, $class;
    
    return $self;
}

sub startconfig {
    my ($self, $isCompiled) = @_;
    
    if(!defined($isCompiled)) {
    $isCompiled = 0;
    }
    $self->{compiled} = $isCompiled;
    
    my @workers;
    $self->{workers} = \@workers;
    
    my %tmpModules;
    $self->{modules} = \%tmpModules;
    return; 
}

sub configure {
    my ($self, $modname, $perlmodulename, %config) = @_;
    
    # Let the module know its configured module name...
    $config{modname} = $modname;
    
    # ...what perl module it's supposed to be...
    my $perlmodule = "Maplat::Worker::$perlmodulename";
    if(!defined($perlmodule->VERSION)) {
    croak("$perlmodule not loaded");
    
        ## Local module - load it first
        #my $requirestr;
        #if($self->{compiled} && $OSNAME eq 'MSWin32') {
        #    my $boundname = "Worker_" . $perlmodulename . ".pm";
        #    print "Dynamically loading bound file for $boundname...\n";
        #    my $modfilename = PerlApp::extract_bound_file($boundname);
        #    croak("$perlmodule not bound to application") unless defined $modfilename;
        #    print "  Bound file name $modfilename\n";
        #    $requirestr = "require '" . $modfilename . "'";            
        #} else {
        #    print "Dynamically loading $perlmodule...\n";
        #    $requirestr = "require \"Maplat/Web/" . $perlmodulename . ".pm\"";
        #}
        #eval $requirestr;
    }
    $config{pmname} = $perlmodule;
    
    # and its parent
    $config{server} = $self;
    
    $self->{modules}->{$modname} = $perlmodule->new(%config);
    $self->{modules}->{$modname}->register; # Register handlers provided by the module
    $self->{modules}->{$modname}->reload;   # (Re)load module's data
    print "Module $modname ($perlmodule) configured.\n";
    return; 
}

sub endconfig {
    # Nothing to do
    print "All modules loaded\n";
    print "\nWe are go for auto-sequence start!\n\n";
    return; 
}

sub run {
    my ($self) = @_;
    
    my $workCount = 0;
    foreach my $worker (@{$self->{workers}}) {
        my $module = $worker->{Module};
        my $funcname = $worker->{Function} ;
        
        $workCount += $module->$funcname();
    }
    
    return $workCount;
}

sub add_worker {
    my ($self, $module, $funcname) = @_;
    
    my %conf = (
        Module  => $module,
        Function=> $funcname
    );
    
    push @{$self->{workers}}, \%conf;
    return; 
}

1;
__END__

=head1 NAME

Maplat::Worker - the Maplat Worker

=head1 SYNOPSIS

The worker module is the one responsible for loading all actual working modules, dispatches
calls and callbacks/hooks.

  my $config = XMLin($configfile,
                      ForceArray => [ 'module', 'directory' ],);
  
  $APPNAME = $config->{appname};
  print "Changing application name to '$APPNAME'\n\n";
  
  # set required values to default if they don't exist
  if(!defined($config->{mincycletime})) {
      $config->{mincycletime} = 10;
  }
  
  
  my @modlist = @{$config->{module}};
  
  $worker->startconfig();
  
  foreach my $module (@modlist) {
      $worker->configure($module->{modname}, $module->{pm}, %{$module->{options}});
  }
  
  $worker->endconfig();
  
  # main loop
  $cycleStartTime = time;
  while(1) {
      my $workCount = $worker->run();
  
      my $tmptime = time;
      my $workTime = $tmptime - $cycleStartTime;
      my $sleeptime = $config->{mincycletime} - $workTime;
      if($sleeptime > 0) {
          print "** Fast cycle ($workTime sec), sleeping for $sleeptime sec **\n";
          sleep($sleeptime);
          print "** Wake-up call **\n";
      } else {
          print "** Cycle time $workTime sec **\n";
      }
      $cycleStartTime = time;
  }


=head1 DESCRIPTION

This worker is "the root of all evil". It loads and configures the working modules and dispatches
callbacks/hooks.

=head1 Configuration and Startup

Configuration is done in stages from the main application, after new(), the first thing to call is startconfig()
to prepare the worker for module configuration.

After that, for each module to load, configure() is called, during which the module is loaded and configured.

Next thing is to call endconfig(), which notifies the worker that all required modules are loaded (the worker
then automatically calls reload() to load all cached data).

Running is done in a while loop or similar calling run(). As most workers dont have to react in the millisecond
range, it's a good idea to have some code in place to try to do cyclic calls in a configurable cycle time. See also the
synopsis and the example included in the tarball.

=head2 new

Create a new instance of Maplat::Worker.

=head2 startconfig

Prepare the worker instance for module configuration.

=head2 configure

Configure a worker module.

=head2 endconfig

Finish up configuration and prepare for run().

=head2 add_worker

Add a worker callback. Called by the various worker modules.

=head2 run

Do a single run of all registered worker callbacks.

=head1 SEE ALSO

Maplat::Web Maplat::Worker::BaseModule

Please also take a look in the example provided in the tarball available on CPAN.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
