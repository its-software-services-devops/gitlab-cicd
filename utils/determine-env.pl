#!/usr/bin/perl

my $tag = $ENV{'CI_COMMIT_TAG'};
my $branch = $ENV{'CI_COMMIT_BRANCH'};

# Example : 'xyz-dev:development;abcde-dev:development'
my $custom_branch_map = $ENV{'CUSTOM_BRANCH_MAP'};

my %branch_env_map = (    
    'develop'     => 'development',
    'development' => 'development',
    'test'       => 'alpha', 
    'alpha'      => 'alpha',
    'preprod'    => 'preprod',
    'main'       => 'production',
    'production' => 'production',
    'deploy/development'   => 'development',
    'deploy/alpha'         => 'alpha',
    'deploy/preprod'       => 'preprod',
    'deploy/production'    => 'production'
);

if (defined($custom_branch_map))
{
    %branch_env_map = ();

    # Override the 'branch_env_map' here
    my @tokens = split(';', $custom_branch_map);
    foreach my $token (@tokens)
    {
        my ($br, $customEnv) = split(':', $token);
        $branch_env_map{"$br"} = $customEnv;
    }
}

my $sem_ver = '(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)';

my %tag_env_map = (
    "^$sem_ver-dev(.*)\$"  => 'development', 
    "^$sem_ver-tst(.*)\$"  => 'alpha', 
    "^$sem_ver-pre(.*)\$"  => 'preprod', 
    "^$sem_ver\$"          => 'production'
);

my $env = undef;

if (defined($tag))
{
    # By tag
    foreach $pattern (keys %tag_env_map)
    {
        if ($tag =~ /$pattern/) 
        {
            $env = $tag_env_map{"$pattern"};
            last;
        }
    }
}
else
{
    # By branch
    $env = $branch_env_map{"$branch"};
}

if (!defined($env))
{
    print("UNDEFINED");
    exit(1);
}

print($env);
exit(0);