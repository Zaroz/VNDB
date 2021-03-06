
package VNDB::Handler::Affiliates;

use strict;
use warnings;
use TUWF ':html';
use VNDB::Func;


TUWF::register(
  qr{affiliates} => \&list,
  qr{affiliates/del/([1-9]\d*)} => \&linkdel,
  qr{affiliates/edit/([1-9]\d*)} => \&edit,
  qr{affiliates/new} => \&edit,
);


sub list {
  my $self = shift;

  return $self->htmlDenied if !$self->authCan('affiliate');
  my $f = $self->formValidate(
    { get => 'a', required => 0, enum => [ 0..$#{$self->{affiliates}} ] },
    { get => 'h', required => 0, default => 0, enum => [ -1..1 ] },
    { get => 'o', required => 0, default => 'a', enum => ['a', 'd'] },
    { get => 's', required => 0, default => 'rel', enum => [qw|rel prio url lastfetch|] },
  );
  return $self->resNotFound if $f->{_err};

  $self->htmlHeader(title => 'Affiliate administration interface');
  div class => 'mainbox';
   h1 'Affiliate administration interface';
   p class => 'browseopts';
    a defined($f->{a}) && $f->{a} == $_ ? (class => 'optselected') : (), href => "/affiliates?a=$_", $self->{affiliates}[$_]{name}
      for (grep $self->{affiliates}[$_], 0..$#{$self->{affiliates}});
   end;
   if(defined $f->{a}) {
     p class => 'browseopts';
      a $f->{h} == -1 ? (class => 'optselected') : (), href => "/affiliates?a=$f->{a};h=-1",'all';
      a $f->{h} ==  1 ? (class => 'optselected') : (), href => "/affiliates?a=$f->{a};h=1", 'hidden';
      a $f->{h} ==  0 ? (class => 'optselected') : (), href => "/affiliates?a=$f->{a};h=0", 'non-hidden';
     end;
   }
  end;

  if(defined $f->{a}) {
    my $list = $self->dbAffiliateGet(
      affiliate => $f->{a}, hidden => $f->{h}==-1?undef:$f->{h},
      what => 'release',
      sort => $f->{s}, reverse => $f->{o} eq 'd'
    );
    $self->htmlBrowse(
      items    => $list,
      nextpage => 0,
      options  => {p=>0, %$f},
      pageurl  => '',
      sorturl  => "/affiliates?a=$f->{a};h=$f->{h}",
      header   => [
        ['Release', 'rel'],
        ['Version'],
        ['Hid'],
        ['Prio', 'prio'],
        ['Price / Lastfetch', 'lastfetch'],
        ['', 'url' ]
      ],
      row      => sub {
        my($s, $n, $l) = @_;
        Tr;
         td class => 'tc1'; a href => "/r$l->{rid}", shorten $l->{title}, 50; end;
         td class => 'tc2', $l->{version} || '<default>';
         td class => 'tc3', $l->{hidden} ? 'YES' : 'no';
         td class => 'tc4', $l->{priority};
         td class => 'tc5', sprintf '%s / %s', $l->{price}, $l->{lastfetch} ? fmtage($l->{lastfetch}) : '-';
         td class => 'tc6';
          a href => $l->{url}, 'link';
          txt ' | ';
          a href => "/affiliates/edit/$l->{id}", 'edit';
          txt ' | ';
          a href => "/affiliates/del/$l->{id}?formcode=".$self->authGetCode("/affiliates/del/$l->{id}"), 'del';
         end;
        end;
      },
    );
  }
  $self->htmlFooter;
}


sub linkdel {
  my($self, $id) = @_;
  return $self->htmlDenied if !$self->authCan('affiliate');
  return if !$self->authCheckCode;
  my $l = $self->dbAffiliateGet(id => $id)->[0];
  return $self->resNotFound if !$l;
  $self->dbAffiliateDel($id);
  $self->resRedirect("/affiliates?a=$l->{affiliate}");
}


sub edit {
  my($self, $id) = @_;
  return $self->htmlDenied if !$self->authCan('affiliate');

  my $r = $id && $self->dbAffiliateGet(id => $id)->[0];
  return $self->resNotFound if $id && !$r;

  my $frm;
  if($self->reqMethod eq 'POST') {
    return if !$self->authCheckCode;
    $frm = $self->formValidate(
      { post => 'rid',      required => 1, template => 'id' },
      { post => 'priority', required => 0, default => 0, template => 'int' },
      { post => 'hidden',   required => 0, default => 0, enum => [0,1] },
      { post => 'affiliate',required => 1, enum => [0..$#{$self->{affiliates}}] },
      { post => 'url',      required => 1 },
      { post => 'version',  required => 0, default => '' },
      { post => 'price',    required => 0, default => '' },
      { post => 'lastfetch',required => 0, template => 'uint' },
      { post => 'data',     required => 0, default => '' },
    );
    if(!$frm->{_err}) {
      $self->dbAffiliateEdit($id, %$frm) if $id;
      $self->dbAffiliateAdd(%$frm) if !$id;
      return $self->resRedirect("/affiliates?a=$frm->{affiliate}", 'post');
    }
  }

  if($id) {
    $frm->{$_} = $r->{$_} for(qw|rid priority hidden affiliate url version price lastfetch data|);
  } else {
    $frm->{rid} = $self->reqGet('rid');
  }

  $self->htmlHeader(title => 'Edit affiliate link');
  $self->htmlForm({ frm => $frm, action => $id ? "/affiliates/edit/$id" : '/affiliates/new' }, 'blah' => [ 'Edit affiliate link',
    [ input  => short => 'rid', name => 'Release ID', width => 100 ],
    [ input  => short => 'priority', name => 'Priority', width => 50 ],
    [ check  => short => 'hidden', name => 'Hidden' ],
    [ select => short => 'affiliate', name => 'Affiliate', options => [ map
        [ $_, $self->{affiliates}[$_]{name} ], grep $self->{affiliates}[$_], 0..$#{$self->{affiliates}} ] ],
    [ input  => short => 'url', name => 'URL', width => 400 ],
    [ input  => short => 'version', name => 'Version', width => 400 ],
    [ input  => short => 'price', name => 'Price' ],
    [ input  => short => 'lastfetch', name => 'Lastfetch', post => ' UNIX timestamp' ],
    [ input  => short => 'data', name => 'Data', width => 400 ],
  ]);
  $self->htmlFooter;
}


1;

