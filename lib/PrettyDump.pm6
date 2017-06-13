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

		method PrettyDump ( PrettyDump $pretty, Int:D $depth = 0 ) {
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

		method PrettyDump ( PrettyDump $pretty, Int:D $depth = 0 ) {
			"_{$.genus} {$.species}_" ~
			$pretty.dump: $some-other-object, $depth + 1;
			}
		}

You can add a C<PrettyDump> method to an object with C<but role>:

	use PrettyDump;

	my $pretty = PrettyDump.new;

	my Int $a = 137;
	put $pretty.dump: $a;

	my $b = $a but role {
		method PrettyDump ( PrettyDump:D $pretty, Int:D $depth = 0 ) {
			"({self.^name}) {self}";
			}
		};
	put $pretty.dump: $b;

This outputs:

	137
	(Int+{<anon|140644552324304>}) 137

=head2 Per-object dump handlers

You can add custom handlers to your C<PrettyDump> object. Once added,
the object will try to use a handler first. This means that you can
override builtin methods.

	$pretty = PrettyDump.new: ... ;
	$pretty.add-handler: "SomeTypeNameStr", $code-thingy;

The code signature for C<$code-thingy> must be:

	(PrettyDump $pretty, $ds, Int:D $depth = 0 --> Str)

Once you are done with the per-object handler, you can remove it:

	$pretty.remove-handler: "SomeTypeNameStr";

This allows you to temporarily override a builtin method. You might
want to mute a particular object, for instance.

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

	method !indent-string ( Str:D $str, Int:D $depth = 0, *%_ () --> Str ) {
		return $str unless $.indent ne '';
		return $str.subst: /^^/, $.indent x $depth, :g;
		}

	method Pair ( Pair:D $ds, Int:D $depth = 0, *%_ () --> Str ) {
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

	method Hash ( Hash:D $ds, Int:D $depth = 0, Str:D $start = '${', Str:D $end = '}', *%_ () --> Str ) {
		self!balanced:  $start, $end, $ds, $depth;
		}

	method Array ( Array:D $ds, Int:D $depth = 0, Str:D $start = '$[', Str:D $end = ']', *%_ () --> Str ) {
		self!balanced:  $start, $end, $ds, $depth;
		}

	method List ( List:D $ds, Int:D $depth = 0, Str:D $start = '$(', Str:D $end = ')', *%_ () --> Str ) {
		self!balanced:  $start, $end, $ds, $depth;
		}

	method Range ( Range:D $ds, Int:D $depth = 0, *%_ () --> Str ) {
		[~]
			$ds.min,
			( $ds.excludes-min ?? '^' !! '' ),
			'..',
			( $ds.excludes-max ?? '^' !! '' ),
			( $ds.infinite ?? '*' !! $ds.max ),
		}

	method !balanced ( Str:D $start, Str:D $end, $ds, Int:D $depth = 0, *%_ () --> Str ) {
		return [~] $start, self!structure( $ds, $depth ), $end;
		}

	method !structure ( $ds, Int $depth = 0, *%_ () --> Str ) {
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

	method Map ( Map:D $ds, Int:D $depth = 0, *%_ () --> Str ) {
		my $type = $ds.^name;
		[~] qq/{$type}.new(/, self!structure( $ds, $depth ), ')';
		}

	method Match ( Match:D $ds, Int:D $depth = 0, *%_ () --> Str ) {
		my $type = $ds.^name;
		my $str = qq/{$type}.new(/;
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

	method !Numeric ( Numeric:D $ds, Int:D $depth = 0, *%_ () --> Str ) {
		do { given $ds {
			when FatRat { [~] '<', $ds.numerator, '/' , $ds.denominator, '>' }
			when Rat    { [~] '<', $ds.numerator, '/' , $ds.denominator, '>' }
			default {
				$ds.Str
				}
			}}
		}


	method Str   ( Str:D $ds, Int:D $depth = 0, *%_ () --> Str ) { $ds.perl }
	method Nil   ( Nil   $ds, Int:D $depth = 0, *%_ () --> Str ) { q/Nil/ }
	method Any   ( Any   $ds, Int:D $depth = 0, *%_ () --> Str ) { q/Any/ }
	method Mu    ( Mu    $ds, Int:D $depth = 0, *%_ () --> Str ) { q/Mu/  }
	method NQPMu (       $ds, Int:D $depth = 0, *%_ () --> Str ) { q/Mu/  }

	has %!handlers = Hash.new();

	method add-handler ( Str:D $type-name, Code:D $code ) {
		# check callable signature ( PrettyDump $pretty, $ds, Int $depth --> Str)
		my $sig = $code.signature;
		my $needed-sig = :( PrettyDump $pretty, $ds, Int:D $depth = 0 --> Str);
		unless $sig ~~ $needed-sig {
			fail X::AdHoc.new: payload => "Signature should be {$needed-sig.gist}";
			}

		%!handlers{$type-name} = $code;
		}

	method remove-handler ( Str:D $type-name, *%_ () ) {
		%!handlers{$type-name}:delete.so
		}

	method handles ( Str:D $type-name, *%_ () --> Bool ) {
		%!handlers{$type-name}:exists
		}

	method !handle ( $ds, Int:D $depth = 0, *%_ () --> Str ) {
		# fail if it doesn't exist
		my $handler = %!handlers{$ds.^name};
		$handler.( self, $ds, $depth )
		}

	method dump ( $ds, Int:D $depth = 0, *%_ () --> Str ) {
		my Str $str = do {
			# If the PrettyDump object has a user-defined handler
			# for this type, prefer that one
			if self.handles: $ds.^name { self!handle: $ds, $depth }

			# The object might have its own method to dump its structure
			elsif $ds.can: 'PrettyDump' { $ds.PrettyDump: self, $depth }

			# If it's any sort of Numeric, we'll handle it and dispatch
			# further
			elsif $ds ~~ Numeric { self!Numeric: $ds, $depth; }

			# If we have a method name that matches the class, we'll
			# use that.
			elsif self.can: $ds.^name { self."{$ds.^name}"( $ds, $depth ) }

			# If the class inherits from something that we know
			# about, use the most specific one that we know about
			elsif self.can: any( $ds.^parents.map: *.^name ) {
				my Str $str = '';
				for $ds.^parents.map: *.^name -> $type {
					next unless self.can: $type;
					$str ~= self."$type"( $ds, $depth, "{$ds.^name}.new(", ')' );
					last;
					}
				$str;
				}

			# If we're this far and the object has a .Str method,
			# we'll use that:
			elsif $ds.can: 'Str' { "({$ds.^name}): " ~ $ds.Str }

			# Finally, we'll put a placeholder method there
			else { "(Unhandled {$ds.^name})" }
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
