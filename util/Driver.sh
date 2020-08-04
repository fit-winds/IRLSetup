#!/bin/bash
# Author:
# Peyman Taeb
########################################

# Log file
STARTDATETIME=`date +'%Y-%h-%d-T%H:%M'`
SYSLOG=`pwd`/irlSetup-${STARTDATETIME}.log

# Detecting loop
for (( ; ; )); do
    today_date=`date '+%Y%m%d'`             

    # removing previous index.htms
    rm index.html*

    # Getting the index.html                 
    wget http://www.ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.$today_date/

    # Getting the existing cycles using a combination
    # of text processing commands
    cat index.html | grep -a "href" | cut -d'"' -f2 | sed '1d' > current.cycles

    # to delete the old.cycles file of yesterday
    # and create a new empty, for use at 00 cycle
    line_current=`wc -l current.cycles | cut -d' ' -f1`
    line_old=`wc -l old.cycles | cut -d' ' -f1`

    # if [ $line_old > $line_current ]; then == wrong relational operator for numeric comparison
    if [ $line_old -gt $line_current ]; then
       rm old.cycles
       touch old.cycles
    fi   
    
    current_cycles=`cat current.cycles`
    old_cycles=`cat old.cycles`
    echo "`date +'%Y-%h-%d-T%H:%M'` (INFO): Current cycles: $current_cycles, old cycles: $old_cycles" >> ${SYSLOG} 2>&1

    # Checking if it has been changed compared to old.cycle
    # We want the last uploaded cycle
    # If the system can't catch one cyle,
    # there will be two cycles in the diff file,
    # We want the last one!
    diff_cycle=$(diff current.cycles old.cycles  | tail -1 |  cut -d'<' -f2 |  cut -d' ' -f2 | cut -d'/' -f1)

    if [ ! -z "$diff_cycle" ]; then  

       echo $diff_cycle  > current.run 
       echo "`date +'%Y-%h-%d-T%H:%M'` (INFO): New cycle has been detected for $today_date-$diff_cycle" >> ${SYSLOG} 2>&1
       cp current.cycles old.cycles 
       echo "`date +'%Y-%h-%d-T%H:%M'` (INFO): Waiting 1 hour for all data to get updated" >> ${SYSLOG} 2>&1

       # wait for all files to get uploaded
#       sleep 5400  
       
       # Download data/perform calculation
       cd IRLSetup/
       Rscript R/download_gefs_data.R  
       Rscript R/download_asos_data.R    
       Rscript R/calculate_irl_setup.R 
       Rscript R/csv.StatArchive.R     

       # Add current time and cycle to index.md
       header_time=`date '+%Y-%m-%d'`
       cycle=`cat ../current.run`
       current_time_cycle=$header_time' '$cycle"Z"
       sed -i "s/%CURRENTTIMECYCLE%/${current_time_cycle}/g"  docs/index.md
       # PT June 2019 ------------------------------------------------------------------------------
       # Stats CSV file and plots will be archived all in data/
       # I did not edit the R codes to reflect these changes as
       # I was afraid this would make the program unstable.
       # Desired changes in archiving are handled by the following 
       # sections 
       # Moving the csv file to the folder (monthly ordered)
       yy=`echo ${today_date} | cut -c1-4`
       mm=`echo ${today_date} | cut -c5-6`       
       mkdir data/${yy}
       mkdir data/${yy}/${mm}
       mkdir data/${yy}/${mm}/CSV
       # August 3, 2020: Below commented to avoid taking too much space on local and repo
       #mkdir data/${yy}/${mm}/plots
       mv data/Stat*                     data/${yy}/${mm}/CSV/         # COMMIT 2
       mv data/gefs_"${today_date}".csv  data/${yy}/${mm}/CSV/         # COMMIT 3

       # Archiving raw plots
       # August 3, 2020: Below commented to avoid taking too much space on local and repo
       # cp docs/img/raw_setup.png  data/${yy}/${mm}/plots/setup_"${today_date}${diff_cycle}".png  #WILL BE COMMITTED by Forecast update
       
       # PT finish -------------------------------------------------------------------------------- 
       
       # Github bussiness
       git remote add origin https://github.com/fit-winds/IRLSetup.git
       git config credential.helper store

       # adding new forecast results to git and push them
       # Using a combination of -a and -m, only modified and newly
       # created files are committed.
       git commit -a -m "Forecast Update ${today_date}${diff_cycle}"
       git push origin master
        
       # I don't know why the stat file & the plot are not pushed along with latest forecast
       # Committing stat file separately!
       # Getting the name of the latest stat file
       # latestStat=`ls -lt data/ | head -2 | awk '{print $9}'` aborted: place an space in the begining
       latestStat=`ls -t data/${yy}/${mm}/CSV/ | head -1 `
       # git pull --rebase
       # git reset --mixed origin/master
       git add data/${yy}/${mm}/CSV/$latestStat
       git commit -m "Archive ${today_date}${diff_cycle}"
       git push origin master
       
       # git pull --rebase
       # git reset --mixed origin/master
       #git add data/${yy}/${mm}/plots/setup_"${today_date}${diff_cycle}".png
       #git commit -m "Archive ${today_date}${diff_cycle}"
       #git push origin master
 
       cd -
 
       # Sending email notifying user that setup calculated and uploaded
       ./sendEmail.sh
    else 
       echo "`date +'%Y-%h-%d-T%H:%M'` (INFO): new cycle not detected, will check in 5 min ... " >> ${SYSLOG} 2>&1
    fi
    #
    sleep 300      # sleep 5 min before checking again
done
