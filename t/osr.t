use strict;
use warnings;
use File::Share ':all';
use Test::More qw(no_plan);
BEGIN { use_ok('Geo::GDAL') };

{
    my $datadir = dist_file('Geo-GDAL', 'gdal-datadir');
    if ($datadir && open(my $fh, "<", $datadir)) {
        $datadir = <$fh>;
        chomp($datadir);
        close $fh;
        Geo::GDAL::PushFinderLocation($datadir);
    }
}

my $srs1 = Geo::OSR::SpatialReference->new(EPSG=>2936);
my $srs2 = Geo::OSR::SpatialReference->new(Text=>$srs1->AsText);

ok($srs1->ExportToProj4 eq $srs2->ExportToProj4, "new EPSG, Text, Proj4");

my $src = Geo::OSR::SpatialReference->new(EPSG => 2392);
my $dst = Geo::OSR::SpatialReference->new(EPSG => 2393);
ok(($src and $dst), "new Geo::OSR::SpatialReference");

eval {
    Geo::OSR::CoordinateTransformation->new($src, $dst);
};

SKIP: {
    skip "libproj probably not installed: $@", 3 if $@;
    my ($t1, $t2);
    eval {
	$t1 = Geo::OSR::CoordinateTransformation->new($src, $dst);
	$t2 = Geo::OSR::CoordinateTransformation->new($dst, $src);
    };
    ok($t1 && $t2, "new Geo::OSR::CoordinateTransformation $@");

    my @points = ([2492055.205, 6830493.772],
		  [2492065.205, 6830483.772],
		  [2492075.205, 6830483.772]);

    my $p1 = $points[0][0];

    my @polygon = ([[2492055.205, 6830483.772],
		    [2492075.205, 6830483.772],
		    [2492075.205, 6830493.772],
		    [2492055.205, 6830483.772]]);

    my $p2 = $polygon[0][0][0];
    
    $t1->TransformPoints(\@points);
    $t1->TransformPoints(\@polygon);

    $t2->TransformPoints(\@points);
    $t2->TransformPoints(\@polygon);

    ok(int($p1) == int($points[0][0]), "from EPSG 2392 to 2393 and back in line"); 
    ok(int($p2) == int($polygon[0][0][0]), "from EPSG 2392 to 2393 and back in polygon"); 
    
}

