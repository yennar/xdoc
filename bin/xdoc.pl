#!/usr/bin/perl -w

BEGIN {
    use FindBin qw($Bin);
    my @paths = ("$Bin","$Bin/../lib/",".");
    #print @paths,"\n";
    foreach my $path (@paths) {
        #print "Lib $path","\n";
        eval("use lib \"\$path\"");
        opendir(my $dh, $path);
        @dots = grep { /^XDOC_.+\.pm$/ } readdir($dh);
        foreach (@dots) {
            print "Loading $_";
            s/\.pm$//g;
            $r = eval("use $_;");
            if ($r) {
                print " OK\n";
            } else {
                print "\n",$@,"\n";
            }
        }
        closedir $dh;
    }
}

use strict;
use Getopt::Long;
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use File::Path qw/make_path/;


my $opts = {};
my $r = GetOptions (
    $opts,
    'input=s',
    'output=s',
    'template=s'
);

my $output = $opts->{output} || '';
$output =~ s/^.+\.//g;
my $env = {output_format => lc($output)};

if (defined $opts->{template}) {
    $opts->{template} = '-t ' . $opts->{template};
} else {
    $opts->{template} = '';
}

check_env($env);

#print Dumper $env;

if (! $r) {
    exit;
}

#print Dumper $opts;

sub main {
    my $opts = shift;
    check_file_can_read ($opts->{input});
    
    open FR,'<',$opts->{input};
    open FW,'>',$env->{out};
    while (<FR>) {
        if (/^\&\[\s*([a-zA-Z0-9_]+)\s*\]/) {
            my $app = $1;
            #print STDERR "APP '$app'\n";
            no strict 'refs';
            if (defined &{"plugin\::$app"}) {
                #print STDERR "Parsing...\n";
                my $param = '';
                my $text = '';
                if (/^\&\[\s*[a-zA-Z0-9_]+\s*\]\s*\[([^\]]+)\]/) {
                    $param = $1;
                    #print STDERR $param,"\n";
                }
                if (/^\&\[\s*[a-zA-Z0-9_]+\s*\]\s*\[[^\]]+\]\s*\[([^\]]+)\]/) {
                    $text = $1;
                } elsif (/\[\s*$/) {
                    while (<FR>) {
                        if (/^\]/) {
                            last;
                        } else {
                            chomp;
                            $text .= $_ . "\n";
                        }
                    }
                }
                my $fn = \&{"plugin::$app"};
                #print $fn;
                print FW $fn->($param,$text,$env);
            }
        } else {
            print FW $_;
        }
    }

    close FR;
    close FW;
    my $cmd = "pandoc \"$env->{out}\" $opts->{template} -s -o \"$opts->{output}\"";
    print $cmd,"\n";
    system $cmd;
}

sub check_file_can_read {
    my $file = shift;
    if (!defined $file) {
        print STDERR "[ERROR] Invalid file handle\n";
        exit;
    }
    if (! -f $file) {
        print STDERR "[ERROR] file $file not a file\n";
        exit;
    }
    if (! open FR,"<",$file) {
        print STDERR "[ERROR] Cannot open $file for read\n";
        exit;
    }
    close FR;
}

sub check_env {
    my $env = shift;
    $env->{temp} = tempdir( CLEANUP => 0 );
    
    my $fh = File::Temp->new(SUFFIX => '.md');
    my $fname = $fh->filename;
    $env->{out} = $fname;
    close $fh;

    my $home = $ENV{HOME} || './';
    my $xdoc_cache = $home . '/.xdoc_cache/';
    make_path($xdoc_cache);
    $env->{cache} = $xdoc_cache;
    
}

sub load_library {

}

sub plugin::test {
    my $opts = shift;
    my $text = shift;
    print STDERR $text;
    return $opts . "\n$text";
}

main($opts);



