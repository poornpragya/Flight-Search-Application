#!/usr/bin/awk -f
# Author : Poorn Pragya
# Author : Vinayak Pawar
#haltDuration.awk
# This awk script a support script that generates a temporary file in sorted order of connection layover time

{
    i++;

    # Represents first line of trip block i.e. tripID
    if(i==1)
        tripID=$0;

    # Represents second line of trip block i.e Price
    else if(i==2) {
        FS=",";
        next;
    }

    # Represents end of one way trip
    else if ($0 ~ /^###/) {
        printf ("%s,%d,",tripID,HaltTime);
        ForwardHaltTime=HaltTime;
        HaltTime=0;
        flag=1;
    }

    # Represents end of two way trip
    else if($0 ~ /^$/) {
        i=0;
        FS=" ";
        if(flag==1) {
            printf ("%d,%d\n",HaltTime,ForwardHaltTime+HaltTime);
            flag=0
        }
        else {
            printf("%s,%d,%d,%d\n",tripID,HaltTime,HaltTime,HaltTime);
        }
        HaltTime=0;
    }

    else {
        HaltTime=HaltTime+$3;
    }
}



