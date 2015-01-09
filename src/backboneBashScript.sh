#! /bin/bash
# Author : Poorn Pragya
# Author : Vinayak Pawar
# Backbone_bash_Script.sh
# This is the basic backbone shell script and interacts with end user and call other supporting scripts

chmod 755 *

# This fucntion is converts the time in HH:MM format to mins
function timeToMin {
    depfrom=$1

    local deparray=(`echo $depfrom | tr ":" "\n"`)
    local depmins=`expr ${deparray[0]} \* 60`
    local depmins=`expr $depmins + ${deparray[1]}`
    echo "$depmins"
}

# Removing all temp files if already present
rm -f "LUT_AIRPORT.txt"
rm -f "LUT_CITY.txt"
rm -f "LUT_AIRCRAFT.txt"
rm -f "LUT_CARRIER.txt"
rm -f "Flight_Details.txt"
rm -f "request.json"
rm -f "response.json"

# Taking user input
echo
echo "1.One Way"
echo "2.Round Trip"
read -p "Please choose:" CH
read -p "Adult Count: " ADULT_COUNT
read -p "Refundable(true/false): " REFUNDABLE
read -p "Origin Code: " ORIGIN
read -p "Destination Code: " DEST
read -p "Number of Solution limit: " SOL
read -p "Departure Date(YYYY-MM-DD): " DDATE

if [ $CH -eq 2 ]; then
    read -p "Return Date(YYYY-MM-DD):" RDATE
fi


# Creating the JSON request file "request.json" based on user input
if [ $CH -eq 1 ]; then
    echo -ne "{\n\"request\": {\n\"passengers\": {\n\"adultCount\": $ADULT_COUNT\n},\n\"slice\": [\n{\n\"origin\": \"$ORIGIN\",\n\"destination\": \"$DEST\",\n\"date\": \"$DDATE\"\n}\n],\n\"solutions\": $SOL,\n\"refundable\": $REFUNDABLE\n}\n}" > request.json
elif [ $CH -eq 2 ]; then
    echo -ne "{\n\"request\": {\n\"passengers\": {\n\"adultCount\": $ADULT_COUNT\n},\n\"slice\": [\n{\n\"origin\": \"$ORIGIN\",\n\"destination\": \"$DEST\",\n\"date\": \"$DDATE\"\n},\n{\n\"origin\": \"$DEST\",\n\"destination\": \"$ORIGIN\",\n\"date\": \"$RDATE\"\n}\n],\n\"solutions\": $SOL,\n\"refundable\": $REFUNDABLE\n}\n}" > request.json
fi

# Quering QPX server using the request.json file and storing the response in response.json file.
# Note: The Google Flights QPX Express API requires to provide the Client API key in the request and need to be replaced if expired
curl -sd @$PWD/request.json --header "Content-Type: application/json" https://www.googleapis.com/qpxExpress/v1/trips/search?key=AIzaSyBEb4QVgQekDE_zV9fs9tVoOJbvcKWopfA > response.json

# Checking the validity of response
grep error response.json > /dev/null
if [ $? -ne 1 ]; then
    echo "Input invalid"
    rm -f "LUT_AIRPORT.txt"
    rm -f "LUT_CITY.txt"
    rm -f "LUT_AIRCRAFT.txt"
    rm -f "LUT_CARRIER.txt"
    rm -f "Flight_Details.txt"
    rm -f "request.json"
    rm -f "response.json"
    exit
fi

# Calling the Response_Processing.pl script to parse the response
./Response_Processing.pl

# Menu Driven options
while true
do

# Displaying options
    echo
    echo
    echo "Display options--->"
    echo "1. Ascending order of trip price"
    echo "2. Ascending order of layover time at airport"
    echo "3. Flights within Price Range"
    echo "4. Flights within Upper limit of layover time in minutes"
    echo "5. Flights within specified arrival and departure time"
    echo "6. Check Vicinity Airports"
    echo "7. Exit"
    read -p "Choose an option above:" CHOICE

    # Displaying trips in ascending order of price
    if [ $CHOICE -eq 1 ]; then
        # Storing all tripIDs sorted by Price in Sorted_Price.$$
        awk '{i++; if(i==1) print $0; if($0 ~ /^$/) i=0; }' Flight_Details.txt > sorted_Price.$$
        # Reading each trip id from above created temp file and extracting trip block from flight details and calling displayTrip.awk script to display the report
        while read line
        do
            sed -n "/^$line\$/,/^$/p" Flight_Details.txt > display.tmp.txt
            ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
            rm -f display.tmp.txt
        done < sorted_Price.$$
        rm -f sorted_Price.$$
    fi

    # Displaying Trips in ascending order of connection layover time
    if [ $CHOICE -eq 2 ]; then
        # Storing all tripIDs sorted by layover time in Sorted_Halt_Duration.$$
        ./haltDuration.awk Flight_Details.txt| sort -t"," -nk4 > sorted_Halt_Duration.$$
        # Reading each trip id from above created temp file and extracting trip block from flight details and calling displayTrip.awk script to display the report
        while read line
        do
            trip_id=`echo $line | cut -d"," -f1`
            sed -n "/^$trip_id\$/,/^$/p" Flight_Details.txt > display.tmp.txt
            ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
            rm -f display.tmp.txt
        done < sorted_Halt_Duration.$$
        rm -f sorted_Halt_Duration.$$
    fi

    # Displaying Trips based on price range in ascending order of price
    if [ $CHOICE -eq 3 ]; then

        # Extracing the price of cheapest trip
        MIN=`sed -n '/^TripId:1$/,/^$/p' Flight_Details.txt | sed -n '2p'| tr -dc [^0-9.]+`
        echo "Min Price Flight available= $MIN"
        read -p "Enter Price Upper limit: " UPPER
        # valdating if upper limit entered by user
        if [ $UPPER -le $MIN ]; then
            echo " Upper price limit cannot be less than minimum price flight trip"
            continue
        fi

        # Extracting Trip Ids in ascending order based on price and within the upper limit of price and calling dispalyTrip.awk
        awk '{i++; if(i==1) print $0; if($0 ~ /^$/) i=0; }' Flight_Details.txt > sorted_Price.$$
        while read line
        do
            CURR=`sed -n "/^$line\$/,/^$/p" Flight_Details.txt | sed -n '2p' | tr -dc [^0-9.]+`
            if [ `echo $CURR'<'$UPPER | bc -l` -eq 1 ]; then
                sed -n "/^$line\$/,/^$/p" Flight_Details.txt > display.tmp.txt
                ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
                rm -f display.tmp.txt
            fi
        done < sorted_Price.$$
        rm -f sorted_Price.$$
    fi

    # Displaying Trips based on layover upper limit in ascending order of in sorted orde of layover time
    if [ $CHOICE -eq 4 ]; then
        read -p "Enter layover Upper limit (in minutes): " UPPER
        ./haltDuration.awk Flight_Details.txt| sort -t"," -nk4 > sorted_Halt_Duration.$$
        while read line
        do
            trip_id=`echo $line | cut -d"," -f1`
            halt_Time=`echo $line | cut -d"," -f4`
            if [ $halt_Time -le $UPPER ];then
                sed -n "/^$trip_id\$/,/^$/p" Flight_Details.txt > display.tmp.txt
                ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
                rm -f display.tmp.txt
            fi
        done < sorted_Halt_Duration.$$
        rm -f sorted_Halt_Duration.$$
    fi

    # Displaying all Trips based between departure time range and arrival time range
    if [ $CHOICE -eq 5 ]; then

        echo "Enter Departure Time Range at Origin"
        read -p "Departure Time From(HH:MM): " DFrom
        read -p "Departure Time To(HH:MM): " DTo

         #Converting Time to min
        DFrom_min=$(timeToMin $DFrom)
        DTo_min=$(timeToMin $DTo)

        # Validating User Input
        if [ $DFrom_min -gt $DTo_min ]; then
            echo "invalid Input"
            continue
        fi

        echo "Enter Arrival Time Range at Destination"
        read -p "Arrival Time From(HH:MM): " AFrom
        read -p "Arrival Time To(HH:MM): " ATo

        #Converting Time to min
        AFrom_min=$(timeToMin $AFrom)
        ATo_min=$(timeToMin $ATo)

        # Validating User Input
        if [ $AFrom_min -gt $ATo_min ]; then
            echo "invalid Input"
            continue
        fi

        # Getting the list of all tri IDs and displaying all trips which fall within specified time range
        awk '{i++; if(i==1) print $0; if($0 ~ /^$/) i=0; }' Flight_Details.txt > TempData.$$
        while read line
        do
            sed -n "/^$line\$/,/^$/p" Flight_Details.txt > display.tmp.txt
            if [ $CH -eq 1 ]; then
                Dep_Flight=`sed -n '3p' display.tmp.txt`
                Arr_Flight=`cat display.tmp.txt | tail -2 | head -1`
                Dep_Flight_Time_min=`echo $Dep_Flight | cut -d"," -f13`
                Arr_Flight_Time_min=`echo $Arr_Flight | cut -d"," -f12`
                if [ $Dep_Flight_Time_min -ge $DFrom_min -a $Dep_Flight_Time_min -le $DTo_min -a $Arr_Flight_Time_min -ge $AFrom_min -a $Arr_Flight_Time_min -le $ATo_min ]; then
                    ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
                fi

            fi

            if [ $CH -eq 2 ]; then
                one_Dep_Flight=`sed -n '3p' display.tmp.txt`
                one_Arr_Flight=`cat display.tmp.txt | sed -n "/^$line\$/,/^###/p" | tail -2 | head -1`
                two_Dep_Flight=`cat display.tmp.txt | sed -n "/^###/,/^$/p" | head -2 | tail -1`
                two_Arr_Flight=`cat display.tmp.txt | tail -2 | head -1`

                one_Dep_Flight_Time_min=`echo $one_Dep_Flight | cut -d"," -f13`
                one_Arr_Flight_Time_min=`echo $one_Arr_Flight | cut -d"," -f12`
                two_Dep_Flight_Time_min=`echo $two_Dep_Flight | cut -d"," -f13`
                two_Arr_Flight_Time_min=`echo $two_Arr_Flight | cut -d"," -f12`

                if [ $one_Dep_Flight_Time_min -ge $DFrom_min -a $one_Dep_Flight_Time_min -le $DTo_min -a $one_Arr_Flight_Time_min -ge $AFrom_min -a $one_Arr_Flight_Time_min -le $ATo_min -a  $two_Dep_Flight_Time_min -ge $DFrom_min -a $two_Dep_Flight_Time_min -le $DTo_min -a $two_Arr_Flight_Time_min -ge $AFrom_min -a $two_Arr_Flight_Time_min -le $ATo_min ]; then
                    ./displayTrip.awk -v ori=$ORIGIN -v des=$DEST display.tmp.txt
                fi

            fi
        rm -f display.tmp.txt
        done < TempData.$$
        rm -f TempData.$$
    fi

    # Displaying all nearby airports in vicinity of source and destination airports
    if [ $CHOICE -eq 6 ]; then


        ./airports.awk airports.dat > airports.dat.1

        cat airports.dat.1 | grep $ORIGIN > source.txt.1
        cat source.txt.1 | awk 'BEGIN { OFS="\n" } { print $1, $2, $3 }' > source.txt.2

        cat airports.dat.1 | grep $DEST > dest.txt.1
        cat dest.txt.1 | awk 'BEGIN { OFS="\n" } { print $1, $2, $3 }' > dest.txt.2

        ./src_distance.awk airports.dat.1 > src_prox_temp.txt
        ./dest_distance.awk airports.dat.1 > dest_prox_temp.txt

        echo "You can also search trips with following nearby airports as source"
        while read line1
        do
            cat airports.dat | grep "\"$line1\"" | awk 'BEGIN { FS="," } { print $5,$3 }' | sed 's/\"//g'
        done < src_prox_temp.txt


        echo
        echo "You can also search trips with following nearby airports as destination"
        while read line1
        do
            cat airports.dat | grep "\"$line1\"" | awk 'BEGIN { FS="," } { print $5,$3 }' | sed 's/\"//g'
        done < dest_prox_temp.txt

        rm -f dest.txt.1 source.txt.1 airports.dat.1 source.txt.2 dest.txt.2 src_prox_temp.txt dest_prox_temp.txt
    fi

    # Cleaup and exit option 
    if [ $CHOICE -eq 7 ]; then
        rm -f "LUT_AIRPORT.txt"
        rm -f "LUT_CITY.txt"
        rm -f "LUT_AIRCRAFT.txt"
        rm -f "LUT_CARRIER.txt"
        rm -f "Flight_Details.txt"
        rm -f "request.json"
        rm -f "response.json"
        exit 1;
    fi

done




