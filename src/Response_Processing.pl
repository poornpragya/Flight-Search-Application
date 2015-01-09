#! /usr/bin/perl -w
# Author: Poorn Pragya
# Author: Vinayak Pawar
# Response_Processing.pl
# This perl script is a support script which reads the Json response file from QPX Express and generates LUT and Flight_Details temp files, thus parsing and extracting relevent data  

use JSON;
use strict;
use warnings;

# Function to lookup key value pair on LUT files
sub getValue {
    my $file = $_[0];
    my $name = $_[1];
    my $value;
    open(FILE, "<$file") or die "Unable to open: $file\n";
    while(<FILE>) {
        if(grep(/$name/, $_)) {
            my @ffield = split /,/;
            $value = $ffield[1];
            chomp($value);
        }
    }
    close(FILE);
    return $value;
}

# Function to convert time in standard format
sub timeAndDate {
    my $str = $_[0];
    my @words = split /T/, $str;
    my $date = $words[0];
    my @Time = split /[+-]/, $words[1];
    my @sep = split /:/, $Time[0];
    my $mins = ($sep[0]*60)+$sep[1];
    return ($date . " " . $Time[0], $mins);
}

# reading the contents of file response.json created by backbone bash script and storing in perl scalar for decoding
my $dir=`pwd`;
chomp($dir);
my $responseData="$dir"."/"."response.json";
open(DATA, "<$responseData") or die "Couldn't open file file.txt, $!";
my $json_data="";
while(<DATA>){
    $json_data .=$_;
}
close DATA;

# using JSON module to decode the response of Google Flight QPX API into perl format
my $json_obj = new JSON;
my $perl_data = $json_obj->decode($json_data);

# Creating lookup tables with code and thier names

open (AIRPORT,">>LUT_AIRPORT.txt")or die "Couldn't open file file.txt, $!";
foreach my $data (@{$perl_data->{'trips'}->{'data'}->{'airport'}} ) {
    print AIRPORT "$data->{'code'},$data->{'city'},$data->{'name'}\n";
}
close AIRPORT;

open (CITY,">>LUT_CITY.txt")or die "Couldn't open file file.txt, $!";
foreach my $data (@{$perl_data->{'trips'}->{'data'}->{'city'}} ) {
    print CITY "$data->{'code'},$data->{'name'}\n";
}
close CITY;

open (AIRCRAFT,">>LUT_AIRCRAFT.txt")or die "Couldn't open file file.txt, $!";
foreach my $data (@{$perl_data->{'trips'}->{'data'}->{'aircraft'}} ) {
    print AIRCRAFT "$data->{'code'},$data->{'name'}\n";
}
close AIRCRAFT;

open (CARRIER,">>LUT_CARRIER.txt")or die "Couldn't open file file.txt, $!";
foreach my $data (@{$perl_data->{'trips'}->{'data'}->{'carrier'}} ) {
    print CARRIER "$data->{'code'},$data->{'name'}\n";
}
close CARRIER;

# reading the contents of $Perl_Data and storing relevent data in temp file Flight_Details.txt for future use.
my $TripID; # TripId is a system generated key to represent each trip
open (OUT,">>Flight_Details.txt")or die "Couldn't open file file.txt, $!";

#Parsing the Json file
foreach my $x (@{$perl_data->{trips}->{tripOption}}) {
    $TripID++;
    print OUT "TripId:$TripID\n";
    my $saleTotal=$x->{'saleTotal'};
    print OUT "$saleTotal". "\n";
    my @slices=$x->{'slice'};
    my $slice_count=0;
    foreach my $slice (@slices) {
        
        foreach my $y (@{$slice}) {
            my @segments=$y->{'segment'};
            
            foreach my $z (@segments) {
                my $segment_counter=0;
                
                foreach my $segment (@{$z}) {
                    my $segment_cabin=$segment->{'cabin'};
                    my $segment_connectionDuration=0;
                    
                    if($segment_counter!=scalar @{$z}-1) {
                    
                        $segment_connectionDuration=$segment->{'connectionDuration'};
    
                    }
                    my $flight_carrier=$segment->{'flight'}->{'carrier'};
                    my $flight_number=$segment->{'flight'}->{'number'};
                    my $airline_name=getValue("LUT_CARRIER.txt",$segment->{'flight'}->{'carrier'});
                    
                    foreach my $leg (@{$segment->{'leg'}}) {
                        my $leg_aircraft=$leg->{'aircraft'}."(".getValue("LUT_AIRCRAFT.txt",$leg->{'aircraft'}).")";
                        my $leg_arrivalTime=$leg->{'arrivalTime'};
                        my $leg_departureTime=$leg->{'departureTime'};
                        my @Arrival_Time=timeAndDate($leg_arrivalTime);
                        my @Departure_Time=timeAndDate($leg_departureTime);
                        my $leg_origin=$leg->{'origin'}."(".getValue("LUT_CITY.txt",getValue("LUT_AIRPORT.txt",$leg->{'origin'})).")";
                        my $leg_destination=$leg->{'destination'}."(".getValue("LUT_CITY.txt",getValue("LUT_AIRPORT.txt",$leg->{'destination'})).")";;
                        my $leg_duration=$leg->{'duration'};
                        print OUT "$flight_carrier,$flight_number,$segment_connectionDuration,$segment_cabin,$leg_aircraft,$Arrival_Time[0],$Departure_Time[0],$leg_origin,$leg_destination,$leg_duration,$airline_name,$Arrival_Time[1],$Departure_Time[1]". "\n";
                    
                    }
                    $segment_counter++;
                    
                }
                
            }
            if($slice_count!=scalar @{$slice}-1) {
                print OUT "###\n";
            }
            $slice_count++;
        }
       
    }
    print OUT "\n";
    
}
close OUT;











