#!/usr/bin/perl

my $versionFile = $ARGV[0];
my $customVersionField = $ENV{'CUSTOM_HELM_DOCKER_VERSION_FIELD'};
my $customVersionFieldOrg = $ENV{'CUSTOM_HELM_DOCKER_VERSION_FIELD'};
my @customVersionFields = split(':', $customVersionField);
my $imageTag = $ENV{'SYSTEM_DOCKER_IMAGE_TAG'};
my %versionMap = ();

print("Variable CUSTOM_HELM_DOCKER_VERSION_FIELD is [$customVersionField]\n");

if (!defined($customVersionField))
{    
    $customVersionField = $ENV{'HELM_DOCKER_VERSION_FIELD'};
}

print("Variable customVersionField is [$customVersionField]\n");
my $count = 0;

open my $info, $versionFile or die "Could not open [$versionFile]: $!";
while (my $line = <$info>)  
{
    chomp($line);

    my ($tagName, $tagValue) = split('=', $line);

    if (!defined($customVersionFieldOrg))
    {
        #Preserve old logic
        my $tmpFld = $ENV{'HELM_DOCKER_VERSION_FIELD'};

        if ($tagName eq $tmpFld)
        {
            $versionMap{"$tmpFld"} = "$imageTag";
            print("DEBUG2.1 : Preserve old logic - [$tmpFld]=[$imageTag], line=[$line]\n");
        }
        else
        {
            #Preserve the other existing values
            $versionMap{"$tagName"} = "$tagValue";
            print("DEBUG2.1 : Preserve old value - [$tagName]=[$tagValue], line=[$line]\n");
        }
    }
    elsif (grep( /^$tagName$/, @customVersionFields)) # Check if value in array
    {
        #Update the existing one
        $versionMap{"$tagName"} = "$imageTag";
        print("DEBUG2.0 : Match - [$tagName]=[$imageTag], line=[$line]\n");
        $count++;
    }
    else
    {
        #Preserve the other existing values
        if ($tagName ne '')
        {
            $versionMap{"$tagName"} = "$tagValue";
            print("DEBUG2.2 : Preserve old value - [$tagName]=[$tagValue], line=[$line]\n");
        }
    }
}

if ($count <= 0)
{
    foreach my $field (@customVersionFields) 
    {
        #Add one if it does not exist
        $versionMap{"$field"} = "$imageTag";
        print("DEBUG3 : [$field]=[$imageTag]\n");
	}
}
close $info;

#Delete file
unlink($versionFile);

#Write the values back to $versionFile
open(FH, '>', $versionFile) or die $!;
foreach my $key (keys %versionMap)
{
    my $value = $versionMap{$key};
    print(FH "$key=$value\n");
}
close(FH);

exit(0);

