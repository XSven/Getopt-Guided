# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v1.0.0';

use Exporter qw( import );

@Getopt::Guided::EXPORT_OK = qw( getopts );

sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  my @argv_backup = @ARGV;
  my %opts_backup = %$opts;
  my $error;

  my @opts = split( //, $spec );
  while ( @ARGV and my ( $first, $rest ) = ( $ARGV[ 0 ] =~ m/\A-(.)(.*)/ ) ) {
    # End of options delimiter check
    shift @ARGV, last if $ARGV[ 0 ] eq '--';
    my $pos = index( $spec, $first );
    if ( $pos >= 0 ) {
      if ( defined( $opts[ $pos + 1 ] ) and ( $opts[ $pos + 1 ] eq ':' ) ) {
        shift @ARGV;
        if ( $rest eq '' ) {
          $error = "Option has no option-argument: $first", last unless @ARGV;
          $opts->{ $first } = shift @ARGV
        } else {
          $error = "Option with option-argument isn't last one: $first";
          last;
        }
      } else {
        # Option is a flag
        $opts->{ $first } = 1;
        if ( $rest eq '' ) {
          shift @ARGV
        } else {
          $ARGV[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
        }
      }
    } else {
      $error = "Unknown option: $first";
      last
    }
  }

  if ( $error ) {
    # Restore to avoid side effects
    @ARGV = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = %opts_backup;
    require Carp;
    Carp::croak( "$error, stopped" )
  }

  undef
}

1
