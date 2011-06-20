#!/usr/bin/perl

# monitor_lso.pl - Monitor directory for new Flash LSOs
# Darian Anthony Patrick <darian@criticode.com>
#
# Uses inotify to monitor a directory for the
# creation/modification of new Flash LSO files
# and directories

use Modern::Perl;
use threads;
use Thread::Queue;
use File::Find;
use Growl::NotifySend;
use App::Daemon qw(daemonize);
use Sys::Syslog qw(:standard :macros);
use Linux::Inotify2;
use IO::All;

my $directory = '/home/'. getlogin() . '/.macromedia';

sub inspect_file {
	my $file_path = shift;

	my $message = "$file_path written.";

	#my $notify = Growl::NotifySend->show(
	#	summary => 'LSO Alert',
	#	body => $message,
	#	# TODO: Find and report bug with expire_time passing
	#	#expire_time => 2,
	#);
	syslog(LOG_ALERT, $message);
	
	return;
}

sub main {
	# Check that a directory was set
	unless ( defined $directory && -d $directory ) {
		say STDERR 'Error: $directory invalid.';
		exit 1;
	}

	# Open syslog
	openlog('monitor_lso', '', LOG_USER);

	# Daemonize process
	daemonize();
	syslog(LOG_INFO, "Daemon started; watching $directory");

	# Create queue for processing new files
	my $file_queue = Thread::Queue->new();

	# Create thread handling file inspection
	my $inspect_thread
		= threads->create(sub {
			while ( my $file_path = $file_queue->dequeue() ) {
				inspect_file($file_path);
			}
		})->detach();

	my $inotify = Linux::Inotify2->new()
		or die "Could not create new inotify object: $!";

	# Define filesystem events which require inspection
	no warnings 'File::Find';
	find( sub{
		my $dir = $File::Find::name;
		return unless -d $dir;
		$inotify->watch( $dir, IN_CREATE | IN_MODIFY | IN_MOVED_TO, sub {
			# TODO add a watcher is a new directory is created
			my $e = shift;
			$file_queue->enqueue($e->fullname);
		});
	}, $directory);

	# Start manual event loop, waiting for events in supplied directory
	1 while $inotify->poll;

	syslog(LOG_INFO, "Daemon started; watching $directory");	
}

main() if $0 eq __FILE__;
