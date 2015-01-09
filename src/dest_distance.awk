#!/usr/bin/awk -f
# Author : Poorn Pragya
# Author : Vinayak Pawar
# dest_distance.awk
# This awk script is a support script used that computes the airports in the vicinity of Destination airports

BEGIN {
	filename="dest.txt.2"
	getline thisAirport < filename
	getline thisLatitude < filename
	getline thisLongitude < filename
	
}

{ 
	distance = sqrt(($2-thisLatitude)^2 + ($3 - thisLongitude)^2)
	if(distance < 0.5) {
		print $1
	}
}
