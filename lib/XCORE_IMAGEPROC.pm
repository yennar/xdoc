package XCORE_IMAGEPROC;

use strict;
use Getopt::Long qw(GetOptionsFromArray);
use Data::Dumper;
use File::Temp qw/ tempfile tempdir /;

sub core::image_proc {
    my $params = shift;
    my $file_in_vec = shift;
    my $file_in_bmp = shift;

    return $file_in_bmp if (!defined $params || $params =~ /^\s*$/);

    my $r;
    if (eval("\$r = `convert`")) {
        if ($r =~ /ImageMagick/sg) {
            my $suffix = $file_in_bmp;
            $suffix =~ s/^.+\./\./g;
            my ($fh,$file_out) = tempfile (SUFFIX=>$suffix);
            close $fh;
            my $cmd = "convert $params $file_in_vec $file_out";
            print $cmd,"\n";
            system $cmd;
            return $file_out;
        }
    }
    
    return $file_in_bmp;
}


1;

