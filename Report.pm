package App::MARC::Validator::Report;

use strict;
use warnings;

use Class::Utils qw(set_params);
use Cpanel::JSON::XS;
use Error::Pure qw(err);
use Getopt::Std;
use Perl6::Slurp qw(slurp);

our $VERSION = 0.01;

# Constructor.
sub new {
	my ($class, @params) = @_;

	# Create object.
	my $self = bless {}, $class;

	# Process parameters.
	set_params($self, @params);

	# Object.
	return $self;
}

# Run.
sub run {
	my $self = shift;

	# Process arguments.
	$self->{'_opts'} = {
		'h' => 0,
		'l' => 0,
		'p' => 'all',
		'v' => 0,
	};
	if (! getopts('hlp:v', $self->{'_opts'})
		|| $self->{'_opts'}->{'h'}
		|| @ARGV < 1) {

		$self->_usage;
		return 1;
	}
	my $report_file = $ARGV[0];

	my $exit_code = $self->_process_report($report_file);
	if ($exit_code != 0) {
		return $exit_code;
	}

	if ($self->{'_opts'}->{'l'}) {
		$exit_code = $self->_process_list;
	} else {
		err "Not supported\n";
	}

	return $exit_code;
}

sub _process_list {
	my $self = shift;

	foreach my $plugin (keys %{$self->{'_list'}}) {
		if ($self->{'_opts'}->{'p'} eq 'all' || $self->{'_opts'}->{'p'} eq $plugin) {
			if (keys %{$self->{'_list'}->{$plugin}} == 0) {
				next;
			}
			print "Plugin '$plugin':\n";
			foreach my $error (sort keys %{$self->{'_list'}->{$plugin}}) {
				print "- $error\n";
			}
		}
	}

	return 0;
}

sub _process_report {
	my ($self, $report_file) = @_;

	my $report = slurp($report_file);

	# JSON output.
	my $j = Cpanel::JSON::XS->new;
	my $report_hr = $j->decode($report);

	$self->{'_list'} = {};
	foreach my $plugin (keys %{$report_hr}) {
		if (! exists $report_hr->{$plugin}->{'checks'}) {
			err "Doesn't exist key '".$report_hr->{$plugin}->{'checks'}." in plugin $plugin.";
		}
		if (! exists $report_hr->{$plugin}->{'checks'}->{'not_valid'}) {
			err "Doesn't exist key '".$report_hr->{$plugin}->{'checks'}->{'not_valid'}." in plugin $plugin.";
		}
		if (! exists $self->{'_list'}->{$plugin}) {
			$self->{'_list'}->{$plugin} = {};
		}
		my $not_valid_hr = $report_hr->{$plugin}->{'checks'}->{'not_valid'};
		foreach my $record_id (keys %{$not_valid_hr}) {
			foreach my $error_hr (@{$not_valid_hr->{$record_id}}) {
				if (! exists $self->{'_list'}->{$plugin}->{$error_hr->{'error'}}) {
					$self->{'_list'}->{$plugin}->{$error_hr->{'error'}} = 1;
				} else {
					$self->{'_list'}->{$plugin}->{$error_hr->{'error'}}++;
				}
			}
		}
	}

	return 0;
}

sub _usage {
	my $self = shift;

	print STDERR "Usage: $0 [-h] [-l] [-p plugin] [-v] [--version] report.json\n";
	print STDERR "\t-h\t\tPrint help.\n";
	print STDERR "\t-l\t\tList unique errors.\n";
	print STDERR "\t-p\t\tUse plugin (default all).\n";
	print STDERR "\t-v\t\tVerbose mode.\n";
	print STDERR "\t--version\tPrint version.\n";
	print STDERR "\treport.json\tmarc-validator JSON report.\n";

	return;
}

1;
