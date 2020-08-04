USERNAME="ptaeb2014@my.fit.edu"
cycle=`cat current.run`
todaydate=`date '+%Y%m%d'`
mail -s "IRL setup calculated on GEFS cycle $todaydate-$cycle and uploaded to https://github.com/fit-winds/IRLSetup" -a ~/IRLsetup/IRLSetup/docs/img/raw_setup.png  $USERNAME <<- EOF
