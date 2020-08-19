#!/usr/bin/perl -T

use LWP::UserAgent;
use XML::Simple;
use HTTP::Response;
use Data::Dumper;
use utf8;

my %changelink = (
    'Stable' => 'https://archive.ntp.org/ntp4/ChangeLog-stable',
    'Development' => 'https://archive.ntp.org/ntp4/ChangeLog-dev'
);
my $ua = new LWP::UserAgent;
my $url = 'https://support.ntp.org/rss/releases.xml';
$ua->ssl_opts( verify_hostname => 0 );
my $response = $ua->get($url);
if (!($response->is_success)) {
    print STDERR $response->status_line . "\n";
    exit;
}
my $xml = new XML::Simple;
my $data = $xml->XMLin($response->decoded_content, ForceArray => 1, KeyAttr => [], ForceContent => 1)->{'channel'}->[0];
my $entries = $data->{'item'};
my @releases = ();
my %releasedata = {};
foreach my $entry (@$entries) {
    my $item_title = $entry->{'title'}->[0]->{'content'};
    my $item_link = $entry->{'link'}->[0]->{'content'};
    my ($release, $date, $release_type) = ($item_title =~ m/^\s*(\S+) - (\S+) - (.*?)$/);
    if (($release_type eq 'md5') && exists($releasedata{$release})) {
        $releasedata{$release}{'md5link'} = $item_link;
    } else {
        push @releases, $release;
        $releasedata{$release} = {};
        $releasedata{$release}{'version'} = $release;
        $releasedata{$release}{'date'} = $date;
        $releasedata{$release}{'name'} = $release_type;
        $releasedata{$release}{'tarlink'} = $item_link;
        $releasedata{$release}{'changelink'} = exists($changelink{$release_type}) ? $changelink{$release_type} : "";;
    }
}
open(my $fh,">","/www/etc/ntp-releases.csv");
print $fh "name,version,date,tarlink,md5link,changelink\n";
foreach my $release (@releases) {
    print $fh $releasedata{$release}{'name'} . ",";
    print $fh $releasedata{$release}{'version'} . ",";
    print $fh $releasedata{$release}{'date'} . ",";
    print $fh $releasedata{$release}{'tarlink'} . ",";
    print $fh $releasedata{$release}{'md5link'} . ",";
    print $fh $releasedata{$release}{'changelink'} . "\n";
}
close $fh;
