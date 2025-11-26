# Prefer numeric version for backwards compatibility
BEGIN { require 5.010_001 }; ## no critic ( RequireUseStrict, RequireUseWarnings )
use strict;
use warnings;

package Getopt::Guided;

$Getopt::Guided::VERSION = 'v1.0.0';

use Carp           qw( croak );
use Exporter       qw( import );
use File::Basename qw( basename );

@Getopt::Guided::EXPORT_OK = qw( getopts );

# https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html#tag_12_02>
sub getopts ( $\% ) {
  my ( $spec, $opts ) = @_;

  croak "getopts: \$spec parameter isn't a string of alphanumeric characters, stopped"
    unless $spec =~ m/\A (?: [[:alnum:]] :?)+ \z/x;
  foreach ( keys %$opts ) {
    # A default option has to have an option-argument
    croak 'getopts: $opts parameter hash contains illegal default option, stopped'
      if index( $spec, "$_:" ) < 0;
  }

  my @argv_backup = @ARGV;
  my %opts_backup = %$opts;
  my @error;

  my @chars = split( //, $spec );
  # Guideline 4, Guideline 9
  while ( @ARGV and my ( $first, $rest ) = ( $ARGV[ 0 ] =~ m/\A-(.)(.*)/ ) ) {
    # Guideline 10
    shift @ARGV, last if $ARGV[ 0 ] eq '--';
    my $pos = index( $spec, $first );
    if ( $pos >= 0 ) {
      # The option-argument indicator ":" is the character that follows an
      # option character if the option requires an option-argument
      my $ind = $chars[ $pos + 1 ];
      if ( defined $ind and $ind eq ':' ) {
        shift @ARGV;
        if ( $rest eq '' ) {
          # Guideline 7
          @error = ( 'option requires an argument', $first ), last
            unless @ARGV;
          # Guideline 6, Guideline 8
          @error = ( 'option requires an argument', $first ), last
            unless defined( my $argv = shift @ARGV );
          $opts->{ $first } = $argv    # Option-argument overwrite situation!
        } else {
          # Guideline 5
          @error = ( "option with argument isn't last one in group", $first );
          last;
        }
      } else {
        ++$opts->{ $first };
        if ( $rest eq '' ) {
          shift @ARGV
        } else {
          # Guideline 5
          $ARGV[ 0 ] = "-$rest" ## no critic ( RequireLocalizedPunctuationVars )
        }
      }
    } else {
      @error = ( 'illegal option', $first ), last
    }
  }

  if ( @error ) {
    # Restore to avoid side effects
    @ARGV = @argv_backup; ## no critic ( RequireLocalizedPunctuationVars )
    %$opts = %opts_backup;
    # Prepare and print warning message:
    # Program name, type of error, and invalid option character
    warn sprintf( "%s: %s -- %s\n", basename( $0 ), @error ); ## no critic ( RequireCarping )
  }

  @error == 0
}

1
