#!/usr/bin/awk -f
# Author : Poorn Pragya
# Author : Vinayak Pawar
# displayTrip.awk
# This awk script a support script used to display the trip block in flight details in desired format

{   i++;

    # Represents first line of trip block i.e. tripID
    if(i==1) {
      printf("\n");
        next;
    }

    # Represents second line of trip block i.e Price
    else if(i==2) {
        printf("Price : %s\n",$0);
        printf("\n%-35s %-7s %-35s %-20s %-20s %-20s %-20s %s\n\n","AIRLINE","FLIGHT","AIRCRAFT","ORIGIN","DEPARTURE","DESTINATION","ARRIVAL","DURATION");
        FS=",";
        next;
    }

    # Represents end of one way trip
    else if ($0 ~ /^###/) {
        printf("\n");
    }

    # Represents end of two way trip
    else if($0 ~ /^$/) {
        printf("\n");
        printf("\n");
        printf("\n");
        i=0;
        next;
    }

    # Represents the data contents and displays on console
    else {
        hours = int($10/60);
        minutes = $10%60;
        printf("%-35s %-2s-%-4s %-35s %-20s %-20s %-20s %-20s %s hours %s minutes\n",$11,$1,$2,$5,$8,$7,$9,$6,hours,minutes);
        if($3 != 0) {
            hours = int($3/60);
            minutes = $3%60;
            printf("Connection Time: %s hours %s minutes\n",hours,minutes);
        }
    }
}


