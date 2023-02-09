#!/usr/bin/perl

my $versionFile = $ARGV[0];
my $tagsStr = "";

open my $info, $versionFile or die "Could not open [$versionFile]: $!";
while (my $line = <$info>)
{
    my ($key, $value) = split('=', $line);
    $tagsStr = $tagsStr . "--set $key=$value "
}
close $info;

print($tagsStr);
exit(0);
