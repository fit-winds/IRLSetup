#StatArchive.R      
# Peyman Taeb // v0.2 // 20180705

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
# Calculating mean and median and appending to the 2nd and 3rd columns
stat.recent$avg <- gefs.setup.recent[,23]
stat.recent$min <- gefs.setup.recent[,24]
stat.recent$max <- gefs.setup.recent[,25]
stat.recent$med <- gefs.setup.recent[,26]
# Naming the archive file 
currentDate <- Sys.Date()
fileName <- paste("data/stat",currentDate,".xlsx",sep="")
# Writing an archived file in xlsx format
write.xlsx(stat.recent, file = fileName,sheetName="forecast.recent",
        col.names=TRUE, row.names=TRUE, append=FALSE)
write.xlsx(asos.setup, file = fileName,sheetName="observed.setup",
        col.names=TRUE, row.names=TRUE, append=TRUE)
#
