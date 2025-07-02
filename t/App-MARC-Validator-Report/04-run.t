use strict;
use warnings;

use App::MARC::Validator::Report;
use English;
use File::Object;
use File::Spec::Functions qw(abs2rel);
use Test::More 'tests' => 5;
use Test::NoWarnings;
use Test::Output;
use Test::Warn 0.31;

# Test.
@ARGV = (
	'-h',
);
my $right_ret = help();
stderr_is(
	sub {
		App::MARC::Validator::Report->new->run;
		return;
	},
	$right_ret,
	'Run help (-h).',
);

# Test.
@ARGV = ();
$right_ret = help();
stderr_is(
	sub {
		App::MARC::Validator::Report->new->run;
		return;
	},
	$right_ret,
	'Run help (no arguments).',
);

# Test.
@ARGV = (
	'-x',
);
$right_ret = help();
stderr_is(
	sub {
		warning_is { App::MARC::Validator::Report->new->run; } "Unknown option: x\n",
			'Warning about bad argument';
		return;
	},
	$right_ret,
	'Run help (-x - bad option).',
);

sub help {
	my $script = abs2rel(File::Object->new->file('04-run.t')->s);
	# XXX Hack for missing abs2rel on Windows.
	if ($OSNAME eq 'MSWin32') {
		$script =~ s/\\/\//msg;
	}
	my $help = <<"END";
Usage: $script [-h] [-l] [-p plugin] [-v] [--version] report.json
	-h		Print help.
	-l		List unique errors.
	-p		Use plugin (default all).
	-v		Verbose mode.
	--version	Print version.
	report.json	marc-validator JSON report.
END

	return $help;
}
