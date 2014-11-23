package XDOC_GRAPHVIZ;

use strict;
use Text::ParseWords;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;
use XCORE_IMAGEPROC;

sub plugin::dot {
    my $params = shift;
    #print "$params\n";
    my @params = quotewords('\s+',0,$params);
    #print Dumper \@params;
    my $code = shift;
    my $env  = shift || {};
    my $app = shift || 'dot';
    my $opts = {};
    my $r = GetOptionsFromArray (\@params,$opts,'name=s','convert=s');
    $opts->{name} = $opts->{name} || "DOT IMAGE";
    #print Dumper $opts; 

    my ($fh,$dotfile) = tempfile (SUFFIX=>'.dot');
    print $fh $code;
    close $fh;
    
    my ($fho1,$pngfile) = tempfile (SUFFIX=>'.png');
    close $fho1;
    my ($fho2,$vecfile) = tempfile (SUFFIX=>'.ps');
    close $fho2;

    my $cmd = "$app $dotfile -Tpng -o $pngfile";
    print $cmd,"\n";
    system $cmd;
    my $cmd = "$app $dotfile -Tps -o $vecfile";
    print $cmd,"\n";
    system $cmd;
    
    if ($env->{output_format} =~ /(tex)/) {
        return "\n![$opts->{name}]($vecfile)\n";
    } else {
        my $rfile = core::image_proc ($opts->{convert},$vecfile,$pngfile);
        return "\n![$opts->{name}]($rfile)\n";
    }
}

1;

