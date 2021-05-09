#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# Trek through a tree one character at a time.
# Philip R Brenan at appaapps dot com, Appa Apps Ltd Inc., 2021
#-------------------------------------------------------------------------------
# podDocumentation
package Tree::Trek;
our $VERSION = "20210425";
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess cluck);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use feature qw(say current_sub);

my $debug = -e q(/home/phil/);                                                  # Developing

#D1 Tree::Trek                                                                  # Methods to create and traverse a trekkable tree.

sub node(;$$$$)                                                                 # Create a new node
 {my ($parent, $char, $key, $data) = @_;                                        # Optional parent, optional character we came through on, optional key for node, optional data for node
  genHash(__PACKAGE__,
    jumps  => undef,                                                            # {character => node}
    key    => $key,                                                             # The key if this node represents a complete key rather than a partial key
    data   => $data,                                                            # The data attached to this node if this node represents a complete key
    parent => $parent,                                                          # The node from whence we came
    char   => $char,                                                            # The character we trekked in on or the empty string if we are at the root
    depth  => $parent ? $parent->depth + 1 : 0,                                 # Depth of this node
   );
 }

sub put($$;$)                                                                   # Add a key to the tree
 {my ($tree, $key, $data) = @_;                                                 # Tree, key, optional data
  my $t = $tree;

  for my $i(1..length $key)                                                     # Jump on each character
   {my $c = substr $key, $i-1, 1;                                               # Next character of the key

    if (!defined(my $k = $t->key))                                              # Use empty data slot if available to store remainder of the key
     {$t->key  = $key;                                                          # Key
      $t->data = $data;                                                         # Data (if present) tracks key
      return $t;                                                                # Return node updated
     }
    elsif (defined($k) and $k eq $key)                                          # Node represents a complete key that matches the specified key
     {$t->data = $data;                                                         # Update data
      return $t;                                                                # Return node updated
     }
    elsif (exists $t->jumps->{$c})                                              # Jump through existing node
     {$t = $t->jumps->{$c};
     }
    else                                                                        # Create a new node and jump through it
     {$t = ($t->jumps->{$c} = node $t, $c, $key, $data);
      return $t;                                                                # Return node updated
     }
   }

  if (defined(my $k = $t->key))                                                 # Move any data in the final slot if necessary
   {if ($k eq $key)                                                             # Node represents a complete key that matches the specified key
     {$t->data = $data;                                                         # Update data
      return $t;                                                                # Return node updated
     }
    else                                                                        # Reinsert key that was here because it is longer and so really belongs further down the tree
     {my $d = $t->data; $t->key = $key; $t->data = $data; $t->put($k, $d);
      return $t;                                                                # Return node updated
     }
   }
  else                                                                          # Final slot is empty
   {$t->key  = $key;                                                            # Node represents a complete key that matches the specified key
    $t->data = $data;                                                           # Update data
    return $t;                                                                  # Return node updated
   }
 }

sub find($$)                                                                    # Find a key in a tree - return its node if such a node exists else undef
 {my ($tree, $key) = @_;                                                        # Tree, key

  return $tree if defined($tree->key) and $tree->key eq $key;                   # Start node contains the key

  for my $i(1..length $key)                                                     # Jump on each character
   {my $c = substr $key, $i-1, 1;                                               # Next character of the key
    if (exists $tree->jumps->{$c})                                              # Continue search
     {$tree = $tree->jumps->{$c};                                               # Jump
      return $tree if defined($tree->key) and $tree->key eq $key;               # Start node contains the key
     }
    else
     {return undef;                                                             # No such jump
     }
   }
  undef                                                                         # Not found
 }

sub delete($)                                                                   # Remove a node from a tree
 {my ($node) = @_;                                                              # Node to be removed

  $node->key  = undef;                                                          # Clear key
  $node->data = undef;                                                          # Clear data
  if (! keys $node->jumps->%*)                                                  # No jumps from this node and no data so we can clear it from the parent
   {for(my $n = $node; $n; $n = $n->parent)                                     # Up through ancestors
     {if (my $p = $n->parent)                                                   # Parent of current node
       {delete $p->jumps->{$n->char};                                           # Delete path to empty node
        last if keys $p->jumps->%*;                                             # Repeat for parent if this node is now empty
       }
     }
   }
  $node
 }

sub count($)                                                                    # Count the nodes addressed in the specified tree
 {my ($node) = @_;                                                              # Node to be counted from
  my $n = $node->data ? 1 : 0;                                                  # Count the nodes addressed in the specified tree
  for my $c(keys $node->jumps->%*)                                              # Each possible child
   {$n += $node->jumps->{$c}->count;                                            # Each child of the parent
   }
  $n                                                                            # Count
 }

sub traverse($)                                                                 # Traverse a tree returning an array of nodes
 {my ($node) = @_;                                                              # Node to be counted from
  my @n;
  push @n, $node if $node->data;
  for my $c(sort keys $node->jumps->%*)                                         # Each possible child in key order
   {push @n, $node->jumps->{$c}->traverse;
   }
  @n
 }

#d
#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA         = qw(Exporter);
@EXPORT      = qw();
@EXPORT_OK   = qw(
 );
%EXPORT_TAGS = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation
=pod

=encoding utf-8

=head1 Name

Tree::Trek - Trek through a tree one character at a time.

=head1 Synopsis

Create a trekkable tree and trek through it:

  my $n = node;

  $n->put("aa" , "AA");
  $n->put("ab" , "AB");
  $n->put("ba" , "BA");
  $n->put("bb" , "BB");
  $n->put("aaa", "AAA");

  is_deeply [map {[$_->key, $_->data]} $n->traverse],
   [["aa",  "AA"],
    ["ab",  "AB"],
    ["aaa", "AAA"],
    ["ba",  "BA"],
    ["bb",  "BB"]];

=head1 Description

Trek through a tree one character at a time.


Version "20210424".


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Tree::Trek

Methods to create a  trekkable tree.

=head2 node($parent)

Create a new node

     Parameter  Description
  1  $parent    Optional parent

B<Example:>


  if (1)

   {my $n = node;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;

    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";

    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");

    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

    ok  $n->find("a");
    ok !$n->find("b");

    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }


=head2 put($tree, $key)

Add a key to the tree

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)
   {my $n = node;

    $n->put("aa")->data = "AA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $n->put("ab")->data = "AB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $n->put("ba")->data = "BA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $n->put("bb")->data = "BB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    $n->put("aaa")->data = "AAA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    is_deeply $n->count, 5;

    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";

    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");

    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

    ok  $n->find("a");
    ok !$n->find("b");

    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }


=head2 key($node)

Return the key of a node

     Parameter  Description
  1  $node      Node

B<Example:>


  if (1)
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;

    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";


    is_deeply [map {[$_->key, $_->data]} $n->traverse],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");

    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

    ok  $n->find("a");
    ok !$n->find("b");

    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }


=head2 find($tree, $key)

Find a key in a tree - return its node if such a node exists else undef

     Parameter  Description
  1  $tree      Tree
  2  $key       Key

B<Example:>


  if (1)
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;


    is_deeply $n->find("aa") ->data, "AA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $n->find("ab") ->data, "AB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $n->find("ba") ->data, "BA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $n->find("bb") ->data, "BB";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $n->find("aaa")->data, "AAA";  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];


    ok  $n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$n->find("a")->data;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $n->find("b");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$n->find("b")->data;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$n->find("c");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    ok  $n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok !$n->find("b");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲



    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  !$n->find("a");  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

   }


=head2 delete($node)

Remove a node from a tree

     Parameter  Description
  1  $node      Node to be removed

B<Example:>


  if (1)
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;

    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";

    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");


    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $n->find("a");
    ok !$n->find("b");


    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  !$n->find("a");
   }


=head2 count($node)

Count the nodes addressed in the specified tree

     Parameter  Description
  1  $node      Node to be counted from

B<Example:>


  if (1)
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";

    is_deeply $n->count, 5;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";

    is_deeply [map {[$_->key, $_->data]} $n->traverse],
     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");


    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲


    ok  $n->find("a");
    ok !$n->find("b");


    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

    ok  !$n->find("a");
   }


=head2 traverse($node)

Traverse a tree returning an array of nodes

     Parameter  Description
  1  $node      Node to be counted from

B<Example:>


  if (1)
   {my $n = node;
    $n->put("aa")->data = "AA";
    $n->put("ab")->data = "AB";
    $n->put("ba")->data = "BA";
    $n->put("bb")->data = "BB";
    $n->put("aaa")->data = "AAA";
    is_deeply $n->count, 5;

    is_deeply $n->find("aa") ->data, "AA";
    is_deeply $n->find("ab") ->data, "AB";
    is_deeply $n->find("ba") ->data, "BA";
    is_deeply $n->find("bb") ->data, "BB";
    is_deeply $n->find("aaa")->data, "AAA";


    is_deeply [map {[$_->key, $_->data]} $n->traverse],  # 𝗘𝘅𝗮𝗺𝗽𝗹𝗲

     [["aa",  "AA"],
      ["aaa", "AAA"],
      ["ab",  "AB"],
      ["ba",  "BA"],
      ["bb",  "BB"]];

    ok  $n->find("a");
    ok !$n->find("a")->data;
    ok  $n->find("b");
    ok !$n->find("b")->data;
    ok !$n->find("c");

    ok $n->find("aa")->delete;  ok  $n->find("aa");  is_deeply $n->count, 4;
    ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
    ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
    ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

    ok  $n->find("a");
    ok !$n->find("b");

    ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
    ok  !$n->find("a");
   }



=head1 Index


1 L<count|/count> - Count the nodes addressed in the specified tree

2 L<delete|/delete> - Remove a node from a tree

3 L<find|/find> - Find a key in a tree - return its node if such a node exists else undef

4 L<key|/key> - Return the key of a node

5 L<node|/node> - Create a new node

6 L<put|/put> - Add a key to the tree

7 L<traverse|/traverse> - Traverse a tree returning an array of nodes

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Tree::Trek

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2021 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
#__DATA__
use Time::HiRes qw(time);
use Test::More;

my $localTest = ((caller(1))[0]//'Tree::Trek') eq "Tree::Trek";                 # Local testing mode

Test::More->builder->output("/dev/null") if $localTest;                         # Reduce number of confirmation messages during testing

if ($^O =~ m(bsd|linux)i)                                                       # Supported systems
 {plan tests => 33;
 }
else
 {plan skip_all =>qq(Not supported on: $^O);
 }

my $start = time;                                                               # Tests

#goto latest;

if (1)
 {my $n = node;
  $n->put("aa", "AA");
  $n->put("a",  "A");
  is_deeply $n->find("a") ->key, "a";  is_deeply $n->find("a") ->data, "A";
  is_deeply $n->find("aa")->key, "aa"; is_deeply $n->find("aa")->data, "AA";
 }

if (1)                                                                          #Tnode #Tput #Tfind #Tcount #Ttraverse #Tdelete #Tkey
 {my $n = node;
  $n->put("aa" , "AA");
  $n->put("ab" , "AB");
  $n->put("ba" , "BA");
  $n->put("bb" , "BB");
  $n->put("aaa", "AAA");

  is_deeply $n->count, 5;

  ok !$n->find("a");

  is_deeply $n->find("aa") ->key, "aa";   is_deeply $n->find("aa") ->data, "AA";
  is_deeply $n->find("ab") ->key, "ab";   is_deeply $n->find("ab") ->data, "AB";
  is_deeply $n->find("ba") ->key, "ba";   is_deeply $n->find("ba") ->data, "BA";
  is_deeply $n->find("bb") ->key, "bb";   is_deeply $n->find("bb") ->data, "BB";
  is_deeply $n->find("aaa")->key, "aaa";  is_deeply $n->find("aaa")->data, "AAA";

  is_deeply [map {[$_->key, $_->data]} $n->traverse],
   [["aa",  "AA"],
    ["ab",  "AB"],
    ["aaa", "AAA"],
    ["ba",  "BA"],
    ["bb",  "BB"]];

  ok $n->find("aa")->delete;  ok !$n->find("aa");  is_deeply $n->count, 4;
  ok $n->find("ab")->delete;  ok !$n->find("ab");  is_deeply $n->count, 3;
  ok $n->find("ba")->delete;  ok !$n->find("ba");  is_deeply $n->count, 2;
  ok $n->find("bb")->delete;  ok !$n->find("bb");  is_deeply $n->count, 1;

  ok $n->find("aaa")->delete; ok !$n->find("aaa"); is_deeply $n->count, 0;
  ok  !$n->find("a");
 }

lll "Finished:", time - $start;
