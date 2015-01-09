#!/usr/bin/awk -f
# Author : Poorn Pragya
# Author : Vinayak Pawar
# airports.awk
# This awk script is a support script used to fetch airport id along with longitude and latitude values from airport.dat LUT file

BEGIN {
	FS=",";
}
{
	airport_id = $5
	latitude = $7
	longitude = $8
	
	#for blank balues of FAA codes, put BLANK value for FAA	
	gsub(/^\"\"$/, "BLANK", airport_id)    	

	#remove double quotes
	gsub("\"", "", airport_id)
	
	if(airport_id != "BLANK") {
		printf("%s %.3f %.3f\n", airport_id, latitude, longitude)
	}
}
