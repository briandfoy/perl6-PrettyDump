=begin pod

=head1 NAME

PrettyDump - represent a Perl 6 data structure in a human readable way

=head1 SYNOPSIS

Use is in the OO fashion:

    use PrettyDump;
    my $pretty = PrettyDump.new:
    	after-opening-brace => True
    	;

    my $perl = { a => 1 };
    say $pretty.dump: $perl; # '{:a(1)}'

Or, use its subroutine:

	use PrettyDump qw(pretty-dump);

    my $ds = { a => 1 };

	say pretty-dump( $ds );

	# setting are named arguments
	say pretty-dump( $ds
		:indent("\t")
		);

=head1 DESCRIPTION

This module creates nicely formatted representations of your data
structure for your viewing pleasure. It does not create valid Perl 6
code and is not a serialization tool.

When C<.dump> encounters an object in your data structure, it first
checks for a C<.PrettyDump> method. It that exists, it uses it to
stringify that object. Otherwise, C<.dump> looks for internal methods.
So far, this module handles these types internally:

=item * List

=item * Array

=item * Pair

=item * Map

=item * Hash

=item * Match

=head2 Custom dump methods

If you define a C<.PrettyDump> method in your class, C<.dump> will call
that when it encounters an object in that class. The first argument to
C<.PrettyDump> is the dumper object, so you have access to some things
in that class:

	class Butterfly {
		has $.genus;
		has $.species;

		method PrettyDump ( PrettyDump $pretty, Int $depth = 0 ) {
			"_{$.genus} {$.species}_";
			}
		}

The second argument is the level of indentation so far. If you want to
dump other objects that your object contains, you should call C<.dump>
again and pass it the value of C<$depth+1> as it's second argument:

	class Butterfly {
		has $.genus;
		has $.species;
		has $.some-other-object;

		method PrettyDump ( PrettyDump $pretty, Int $depth = 0 ) {
			"_{$.genus} {$.species}_" ~
			$pretty.dump: $some-other-object, $depth + 1;
			}
		}

=head2 Configuration

You can set some tidy-like settings to control how C<.dump> will
present the data stucture:

=item indent

The default is a tab.

=item intra-group-spacing

The spacing inserted inside (empty) C<${}> and C<$[]> constructs.
The default is the empty string.

=item pre-item-spacing

The spacing inserted just after the opening brace or bracket of
non-empty C<${}> and C<$[]> constructs. The default is a newline.

=item post-item-spacing

The spacing inserted just before the close brace or bracket of
non-empty C<${}> and C<$[]> constructs. The default is a newline.

=item pre-separator-spacing

The spacing inserted just before the comma separator of non-empty
C<${}> and C<$[]> constructs. The default is the empty string.

=item post-separator-spacing

The spacing inserted just after the comma separator of non-empty
C<${}> and C<$[]> constructs. Defaults to a newline.

=head1 AUTHOR

brian d foy, C<< <bdfoy@cpan.org> >>.

This module started as L<Pretty::Printer> from Jeff Goff, which you
can find at L<https://github.com/drforr/perl6-pp>

=head1 SOURCE

The repository for this source is in GitHub at L<https://github.com/briandfoy/perl6-PrettyDump>

=head1 COPYRIGHT

=head1 LICENSE

This module is available under the Artistic License 2.0. A copy of
this license should have come with this distribution in the LICENSE
file.

=end pod

use v6;

###############################################################################


class PrettyDump {
	has Str $.pre-item-spacing       = "\n";
	has Str $.post-item-spacing      = "\n";

	has Str $.pre-separator-spacing  = '';
	has Str $.intra-group-spacing    = '';
	has Str $.post-separator-spacing = "\n";

	has Str $.indent                 = "\t";

	method !indent-string ( Str $str, Int $depth --> Str ) {
		return $str unless $.indent ne '';
		return $str.subst: /^^/, $.indent x $depth, :g;
		}

	method Pair ( Pair $ds, Int $depth --> Str ) {
		my $str = ':';
		given $ds.value.^name {
			when "Bool" {
				$str ~= '!' unless $ds.value;
				$str ~= $ds.key
				}
			when "NQPMu" { # I don't think I should ever see this, but I do
				$str ~= "{$ds.key}(Mu)";
				}
			default {
				$str ~= [~]
					$ds.key,
					'(',
					self.dump( $ds.value, 0 ).trim,
					')';
				}
			}
		return $str;
		}

	method Hash ( Hash $ds, Int $depth --> Str ) {
		self!balanced:  '${', '}', $ds, $depth;
		}

	method Array ( Array $ds, Int $depth --> Str ) {
		self!balanced:  '$[', ']', $ds, $depth;
		}

	method List ( List $ds, Int $depth --> Str ) {
		self!balanced:  '$(', ')', $ds, $depth;
		}

	method Range ( Range $ds, Int $depth --> Str ) {
		[~]
			$ds.min,
			( $ds.excludes-min ?? '^' !! '' ),
			'..',
			( $ds.excludes-max ?? '^' !! '' ),
			( $ds.infinite ?? '*' !! $ds.max ),
		}

	method !balanced ( Str $start, Str $end, $ds, Int $depth --> Str ) {
		return [~] $start, self!structure( $ds, $depth ), $end;
		}

	method !structure ( $ds, Int $depth --> Str ) {
		if @($ds).elems {
			my $separator = [~] $.pre-separator-spacing, ',', $.post-separator-spacing;
			[~]
				$.pre-item-spacing,
				join( $separator,
					map { self.dump: $_, $depth+1 }, sort @($ds)
					),
				$.post-item-spacing;
			}
		else {
			$.intra-group-spacing;
			}
		}

	method Map ( Map $ds, Int $depth --> Str ) {
		[~] q/Map.new(/, self!structure( $ds, $depth ), ')';
		}

	method Match ( Match $ds, Int $depth --> Str ) {
		my $str = Q/Match.new(/;
		my $hash = {
			made => $ds.made,
			to   => $ds.to,
			from => $ds.from,
			orig => $ds.orig,
			hash => $ds.hash,
			list => $ds.list,
			pos  => $ds.pos,
			};
		$str ~= self!structure: $hash, $depth;
		$str ~= ')';
		}

	method !Numeric ( Numeric $ds, Int $depth --> Str ) {
		do { given $ds {
			when FatRat { [~] '<', $ds.numerator, '/' , $ds.denominator, '>' }
			when Rat    { [~] '<', $ds.numerator, '/' , $ds.denominator, '>' }
			default {
				$ds.Str
				}
			}}
		}


	method Str   ( Str $ds, Int $depth --> Str ) { $ds.perl }
	method Nil   ( Nil $ds, Int $depth --> Str ) { q/Nil/ }
	method Any   ( Any $ds, Int $depth --> Str ) { q/Any/ }
	method Mu    ( Mu  $ds, Int $depth --> Str ) { q/Mu/  }
	method NQPMu ( $ds, Int $depth --> Str ) { q/Mu/  }

	method dump ( $ds, Int $depth = 0 --> Str ) {
		my Str $str = do {
			# The object might have its own method to dump its structure
			if $ds.can: 'PrettyDump' {
				$str ~= $ds.PrettyDump: self;
				}
			# If it's any sort of Numeric, we'll handle it and dispatch
			# further
			elsif $ds ~~ Numeric {
				$str ~= self!Numeric: $ds, $depth;
				}
			# If we have a method name that matches the class, we'll
			# use that
			elsif self.can: $ds.^name {
				my $what = $ds.^name;
				$str ~= self."$what"( $ds, $depth );
				}
			# If we're this far and the object has a .Str method,
			# we'll use that:
			elsif $ds.can: 'Str' {
				"({$ds.^name}): " ~ $ds.Str;
				}
			# Finally, we'll put a placeholder method there
			else {
				"(Unhandled {$ds.^name})"
				}
			};

		return self!indent-string: $str, $depth;
		}

	sub pretty-dump ( $ds,
		:$pre-item-spacing       = "\n",
		:$post-item-spacing      = "\n",
		:$pre-separator-spacing  = '',
		:$intra-group-spacing    = '',
		:$post-separator-spacing = "\n",
		:$indent                 = "\t",
		--> Str ) is export {
		my $pretty = PrettyDump.new:
			:indent\                 ($indent),
			:pre-item-spacing\       ($pre-item-spacing),
			:post-item-spacing\      ($post-item-spacing),
			:pre-separator-spacing\  ($pre-separator-spacing),
			:intra-group-spacing\    ($intra-group-spacing),
			:post-separator-spacing\ ($post-separator-spacing),
			;

		$pretty.dump: $ds;
		}
	}
