#StatArchive.R      
# Peyman Taeb // v0.2 // 20180712

# This script computes the mean and median of the predicted setup
# (gefs.setup.recent) from setup.RData file, and stores them in 
# an archived file along with the calculated setup using wind obs.
# The archived stats should be the same ensemble mean and median
# as demonstrated in the plot (red and blue lines).
#
library(reshape2)
library(xlsx) 
# functions ----------------------------------------------------------------
# given a data frame of ensemble data, add ens average, max, min, and median
addEnsStats <- function(df.ens, cols = 2:22) {
    df.ens$avg <- rowMeans(df.ens[cols], na.rm = FALSE)
    df.ens$min <- apply(df.ens[cols], 1, min)
    df.ens$max <- apply(df.ens[cols], 1, max)
    df.ens$med <- apply(df.ens[cols], 1, median)
    return(df.ens)
}


# Loading the setup.RData file gefs.setup.recent to calculate the stats
load(paste(getwd(), '/data/setup.RData', sep = ''))  
# Remove the missing rows in gefs.setup
#gefs.setup.1 <- gefs.setup.1[4:44,]
#gefs.setup.2 <- gefs.setup.2[4:44,]
#gefs.setup.3 <- gefs.setup.3[4:44,]
gefs.setup.recent <- gefs.setup.recent[4:44,]
# Observation     
asos.setup <- asos.setup[asos.setup$roundvalid >= gefs.setup.1$validtime[1],]
# Prediction
gefs.setup.recent.melt <- melt(gefs.setup.recent, id.vars = 'validtime')
#gefs.setup.1 <- addEnsStats(gefs.setup.1)
#gefs.setup.2 <- addEnsStats(gefs.setup.2)
#gefs.setup.3 <- addEnsStats(gefs.setup.3)
gefs.setup.recent <- addEnsStats(gefs.setup.recent)
#
# Getting time and put it in the 1st column of the archived file
stat.recent <- gefs.setup.recent[,1, drop=FALSE]
# Renaming the name of the time column to Date/Time"
# asos.setup uses roundvalid, setup.recent uses validtime
colnames(stat.recent)[colnames(stat.recent)=="validtime"] <- "Data/Time"
colnames(asos.setup)[colnames(asos.setup)=="roundvalid"] <- "Data/Time"
# some other renameing
colnames(asos.setup)[colnames(asos.setup)=="setup"] <- "Obs setup"
colnames(asos.setup)[colnames(asos.setup)=="wspd"] <- "Obs wspd"
colnames(asos.setup)[colnames(asos.setup)=="wdir"] <- "Obs wdir"
# Calculating mean and median and appending to the 2nd and 3rd columns
stat.recent$ensemble_avg <- gefs.setup.recent[,23]
stat.recent$ensemble_min <- gefs.setup.recent[,24]
stat.recent$ensemble_max <- gefs.setup.recent[,25]
stat.recent$ensemble_med <- gefs.setup.recent[,26]
# reading the current cycle number                                       
fileName <- "/home/ptaeb/wind-setup/current.run"        
conn <- file(fileName,open="r")                                        
linn <-readLines(conn)                                                  
run <- print(linn[1])                                                   
close(conn)                                                            
# Naming the archive file 
currentDate <- Sys.Date()
fileNameOF <- paste("data/Stats",currentDate,"-cycle",run,".csv",sep="")
ForeObs <- merge(stat.recent, asos.setup, all= TRUE, by=c("Data/Time"))
write.csv(ForeObs, file = fileNameOF)
#
