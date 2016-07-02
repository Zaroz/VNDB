# This module implements various templates for formValidate()

package VNDB::Util::ValidateTemplates;

use strict;
use warnings;
use TUWF 'kv_validate';
use VNDB::Func 'json_decode';
use VNDBUtil 'gtintype';
use Time::Local 'timegm';


TUWF::set(
  validate_templates => {
    id    => { template => 'uint', max => 1<<40 },
    page  => { template => 'uint', max => 1000 },
    uname => { regex => qr/^[a-z0-9-]*$/, minlength => 2, maxlength => 15 },
    gtin  => { func => \&gtintype },
    editsum => { maxlength => 5000, minlength => 2 },
    json  => { func => \&json_validate, inherit => ['json_fields','json_maxitems','json_unique','json_sort'], default => [] },
    rdate => { template => 'uint', min => 0, max => 99999999, func => \&rdate_validate, default => 0 },
  }
);


# Figure out if a field is treated as a number in kv_validate().
sub json_validate_is_num {
  my $opts = shift;
  return 0 if !$opts->{template};
  return 1 if $opts->{template} eq 'num' || $opts->{template} eq 'int' || $opts->{template} eq 'uint';
  my $t = TUWF::set('validate_templates')->{$opts->{template}};
  return $t && json_validate_is_num($t);
}


sub json_validate_sort {
  my($sort, $fields, $data) = @_;

  # Figure out which fields need to use number comparison
  my %nums;
  for my $k (@$sort) {
    my $f = (grep $_->{field} eq $k, @$fields)[0];
    $nums{$k}++ if json_validate_is_num($f);
  }

  # Sort
  return [sort {
    for(@$sort) {
      my $r = $nums{$_} ? $a->{$_} <=> $b->{$_} : $a->{$_} cmp $b->{$_};
      return $r if $r;
    }
    0
  } @$data];
}

# Special validation function for simple JSON structures as form fields. It can
# only validate arrays of key-value objects. The key-value objects are then
# validated using kv_validate.
# TODO: json_unique implies json_sort on the same fields? These options tend to be the same.
sub json_validate {
  my($val, $opts) = @_;
  my $fields = $opts->{json_fields};
  my $maxitems = $opts->{json_maxitems};
  my $unique = $opts->{json_unique};
  my $sort = $opts->{json_sort};
  $unique = [$unique] if $unique && !ref $unique;
  $sort = [$sort] if $sort && !ref $sort;

  my $data = eval { json_decode $val };
  $_[0] = $@ ? [] : $data;
  return 0 if $@ || ref $data ne 'ARRAY';
  return 0 if defined($maxitems) && @$data > $maxitems;

  my %known_fields = map +($_->{field},1), @$fields;
  my %unique;

  for my $i (0..$#$data) {
    return 0 if ref $data->[$i] ne 'HASH';
    # Require that all keys are known and have a scalar value.
    return 0 if grep !$known_fields{$_} || ref($data->[$i]{$_}), keys %{$data->[$i]};
    $data->[$i] = kv_validate({ field => sub { $data->[$i]{shift()} } }, $TUWF::OBJ->{_TUWF}{validate_templates}, $fields);
    return 0 if $data->[$i]{_err};
    return 0 if $unique && $unique{ join '|||', map $data->[$i]{$_}, @$unique }++;
  }

  $_[0] = json_validate_sort($sort, $fields, $data) if $sort;
  return 1;
}


sub rdate_validate {
  return 0 if $_[0] ne 0 && $_[0] !~ /^(\d{4})(\d{2})(\d{2})$/;
  my($y, $m, $d) = defined $1 ? ($1, $2, $3) : (0,0,0);

  # Normalization ought to be done in JS, but do it here again because we can't trust browsers
  ($m, $d) = (0, 0) if $y == 0;
  $m = 99 if $y == 9999;
  $d = 99 if $m == 99;
  $_[0] = $y*10000 + $m*100 + $d;

  return 0 if $y && $d != 99 && !eval { timegm(0, 0, 0, $d, $m-1, $y) };
  return 1;
}
