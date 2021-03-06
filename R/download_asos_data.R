# download_asos_data.R
# Bryan Holman || v0.1 || 20170502

# This R script downloads KMLB ASOS wind data to match GEFS ensemble data from
# the previous day's 18 UTC run for bias correction/calibration purposes.


# libraries ---------------------------------------------------------------

library(riem) # access to ASOS data through iowa state
library(lubridate) # awesome date handling
library(xts) # also awesome date handling
# library(WindVerification) # wind data handling

# functions ---------------------------------------------------------------

# function to turn wspd and wdir into a vector of u and v components
getuv <- function(wspd, wdir) {
    
    # If either wspd or wdir are missing, we cannot do the calculation!
    if (is.na(wspd) | is.na(wdir)) {return(c(NA, NA))}
    
    # calculate u and v
    u <- -1 * wspd * sin(0.01745329251 * wdir) # 0.01745329251 is pi / 180
    v <- -1 * wspd * cos(0.01745329251 * wdir)
    
    # round off floating point errors
    if (u < 0.0001 & u > -0.0001) {u <- 0}
    if (v < 0.0001 & v > -0.0001) {v <- 0}
    
    return(c(u, v))
}

# paths for /tmp and /util
tmp.path <- paste(getwd(), '/tmp', sep = '')
data.path <- paste(getwd(), '/data', sep = '')
util.path <- paste(getwd(), '/util', sep = '')

# load gefs_all.csv
df.all <- read.csv(paste(data.path, '/', 'gefs_all.csv', sep = ''), 
                   header = TRUE, stringsAsFactors = FALSE)
df.all$runtime <- as.POSIXct(df.all$runtime, tz = 'UTC')
df.all$validtime <- as.POSIXct(df.all$validtime, tz = 'UTC')

# determine what timeframe we need to look at for KMLB ASOS data
times.needs.kmlb <- df.all$validtime[is.na(df.all$kmlb.u)]

# get KMLB ASOS data for this time frame
df.kmlb <- riem_measures(station = "MLB", 
                         date_start = format(times.needs.kmlb[1], '%Y-%m-%d'), 
                         date_end = format(Sys.Date() + days(4), '%Y-%m-%d'))

# Only keep the hourly updates, which happen to be the only observations with
# MSLP
df.kmlb <- df.kmlb[!is.na(df.kmlb$mslp),]

# round valid times to nearest quarter hour, n is in seconds
df.kmlb$roundvalid <- as.POSIXct(align.time(df.kmlb$valid, n=60*15))

# convert wind speed from knots to m/s
df.kmlb$wspd <- df.kmlb$sknt * 0.51444

# get u and v
uv <- mapply(getuv, df.kmlb$wspd, df.kmlb$drct)
df.kmlb$u <- uv[1,]
df.kmlb$v <- uv[2,]

# A loop can't be the best way to do this, but it will work for now!
for (datetime in times.needs.kmlb) {
    if (datetime %in% df.kmlb$roundvalid) {
        df.all[df.all$validtime == datetime, c('kmlb.u', 'kmlb.v')] <- 
            df.kmlb[df.kmlb$roundvalid == datetime, c('u', 'v')]   
    }
}

# now save df.all
write.csv(df.all, file = paste(data.path, '/gefs_all.csv', sep = ''), 
          row.names = FALSE)
