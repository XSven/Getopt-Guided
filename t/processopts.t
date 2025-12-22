use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT fail is is_deeply like ok plan subtest use_ok ) ], tests => 9;
use Test::Fatal qw( exception );
use Test::Warn  qw( warning_like );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( EOOD processopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

my $fail_cb = sub { fail "'$_[ 1 ]' callback shouldn't be called" };

subtest 'Provoke exceptions' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo );
  like exception {
    processopts ':a:' => $fail_cb
  }, qr/isn't a non-empty string of alphanumeric/, "Leading ':' character is not allowed";
  is_deeply \@ARGV, [ qw( -a foo ) ], '@ARGV not changed';

  like exception { processopts 'a:b' => $fail_cb }, qr/specifies 2 options \(expected: 1\)/,
    'Single option specification expected'
};

subtest 'Usual flag' => sub {
  plan tests => 5;

  local @ARGV = qw( -b );
  ok processopts(
    'b' => sub {
      my ( $argument, $name, $indicator ) = @_;

      is $argument,  1,   'Check argument';
      is $name,      'b', 'Check name';
      is $indicator, '',  'Check indicator'
    }
    ),
    'Succeeded';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option; scalar reference instead of callback' => sub {
  plan tests => 3;

  local @ARGV = qw( -a baz );
  ok processopts( 'a:' => \my $argument ), 'Succeeded';
  is $argument, 'baz', 'Check argument';
  is @ARGV,     0,     '@ARGV is empty'
};

subtest 'Common option; callback sets closure variables' => sub {
  plan tests => 5;

  local @ARGV = qw( -a foo );
  my ( $argument, $name, $indicator );
  ok processopts( 'a:' => sub { ( $argument, $name, $indicator ) = @_ } ), 'Succeeded';
  is $argument,  'foo', 'Check argument';
  is $name,      'a',   'Check name';
  is $indicator, ':',   'Check indicator';
  is @ARGV,      0,     '@ARGV is empty'
};

subtest 'Common option and usual flag' => sub {
  plan tests => 6;

  # On purpose @ARGV doesn't contain flag
  local @ARGV = qw( -a bar );
  ok processopts(
    'a:' => sub {
      my $argument  = shift;
      my $name      = shift;
      my $indicator = shift;

      is $argument,  'bar', 'Check argument';
      is $name,      'a',   'Check name';
      is $indicator, ':',   'Check indicator';
      is @_,         0,     '@_ is empty'
    },
    'b' => $fail_cb
    ),
    'Succeeded';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'List option and incrementable flag' => sub {
  plan tests => 4;

  local @ARGV = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts(
    'v+' => sub { is $_[ 0 ],        3,                             'Check argument' },
    'I,' => sub { is_deeply $_[ 0 ], [ qw( lib local/lib/perl5 ) ], 'Check argument' }
    ),
    'Succeeded';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Unknown option' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -d bar );
  warning_like { ok !processopts( 'a:' => $fail_cb, 'b' => $fail_cb ), 'Failed' } qr/illegal option -- d/,
    'Check warning';
  is_deeply \@ARGV, [ qw( -b -d bar ) ], '@ARGV not changed'
};

subtest 'Semantic priority' => sub {
  plan tests => 2;

  # -h comes first on purpose
  local @ARGV = qw( -h -V );
  # Best pratice: -V should have higher precedence (semantic priority) than -h
  ok processopts( 'V' => sub { EOOD }, 'h' => $fail_cb ), 'Succeeded';
  is @ARGV, 0, '@ARGV is empty'
}
