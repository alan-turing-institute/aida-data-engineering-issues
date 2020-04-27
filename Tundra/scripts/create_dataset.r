# Tundra Trait AIDA wrangling challenge

# Create the dataset for analysis

# Giovanni Colavizza <gcolavizza@turing.ac.uk>
# June 2018

# tidy data analysis 
library(plyr)
library(dplyr)
# read tidy data
library(readr)

# LOAD DATA
load("../datasets/data_clean/TTT_cleaned_dataset.RData")

# Filter dataset according to paper draft (See analyses, intraspecific trait variation)
nrow(ttt.save)
filtered_dataset <- ttt.save[(!is.na(ttt.save$Latitude)) & (!is.na(ttt.save$Longitude)) & (!is.na(ttt.save$Year)),] # keep only existing Lat and Long with a year
nrow(filtered_dataset)

# Keep only species represented in more than 4 sites
filtered_dataset <- filtered_dataset %>%
  group_by(AccSpeciesName) %>%
  mutate(unique_sites = n_distinct(SiteName))
filtered_dataset <- filtered_dataset[filtered_dataset$unique_sites > 3,] # only species present in 4 or more distinct sites
nrow(filtered_dataset)

# Get site information, trim by number of observations (> 10)
filtered_dataset$lat_trimmed = round(filtered_dataset$Latitude,digits=2)
filtered_dataset$log_trimmed = round(filtered_dataset$Longitude,digits=2)
sites <- filtered_dataset[,c("lat_trimmed","log_trimmed","SiteName")]
sites <- sites %>% group_by(SiteName,lat_trimmed,log_trimmed) %>% filter(n()>10) #summarise(freq=sum(!is.na(SiteName)))
rounding <- function(a) round(a,digits = 2)
sites <- na.omit(unique(cbind(sites[3], lapply(sites[1:2], rounding))[,1:3]))
sites <- sites[order(sites$SiteName),]

# Create grid with site indexes
index_pos <- function(n,cnt=90){ # 90 for latitude, 180 for longitude
  dec_part = n%%1
  int_part = floor(n)
  incr = 1
  if (dec_part >= 0.5) {incr = 2}
  return((int_part+cnt)*2+incr)
}
sites$lat_index = index_pos(sites$lat_trimmed)
sites$log_index = index_pos(sites$log_trimmed,180)
# join with data frame
filtered_dataset <- merge(filtered_dataset, sites, by=c("SiteName","lat_trimmed","log_trimmed"))
# drop not needed columns, unique and reset index
sites <- sites[,-c(2,3)]
sites <- unique(sites)
rownames(sites) <- NULL
sites["index"] <- c(1:nrow(sites))
filtered_dataset <- merge(filtered_dataset, sites, by=c("SiteName","lat_index","log_index"))

ref_month = 7 # July, or 1 for January, etc.

## Change commented line to use precipitation rather than temperature data
# data_folder <- "dataset/401_PRE_monthly_1950_2015" # precipitation data
# data_folder <- "datasets/401_TMP_monthly_1950_2015" # temperature data
data_folder <- "../datasets/CRU/datasets/401_TMP_monthly_1950_2015" # temperature data
# load time series for mean temperatures (1950-2015)
l <- 2017-1950
# create matrix for time series
ts <- matrix(, nrow = nrow(sites), ncol = l)

myFiles <- list.files(data_folder, pattern = "*.csv") #all files starting with Climate_
myFiles <- sort(myFiles)
# then read them in, for instance through
for (filename in myFiles) {
  year <- as.numeric(substring(filename,nchar(filename)-11,nchar(filename)-8))
  month <- as.numeric(substring(filename,nchar(filename)-7,nchar(filename)-6))
  if (month == ref_month){
    data = read.csv(paste(data_folder, filename, sep = "/"), header = FALSE, skip=45)
    for (row in 1:nrow(sites)) {
      long_i <- sites[row,"log_index"]
      lat_i <- sites[row,"lat_index"]
      if (data[[long_i+1]][[lat_i]] > -1000){ # note that -10000 is the not observed value for this dataset...
        ts[row,year-1949] <- data[[long_i+1]][[lat_i]]}
    }
  }
}

nrow(filtered_dataset)
filtered_dataset.tmp <- NA
# add information to the data frame
for (row in 1:nrow(filtered_dataset)) {
  year_index <- filtered_dataset[row,"Year"]-1949
  if (year_index >= 0 && year_index <= ncol(ts)){
    filtered_dataset[row,"tmp"] <- ts[filtered_dataset[row,"index"],year_index]
  }
}
# drop tmp NA
nrow(filtered_dataset)
filtered_dataset <- filtered_dataset[!is.na(filtered_dataset$tmp),]
nrow(filtered_dataset)
# mean-center by species
filtered_dataset <- ddply(filtered_dataset, c("AccSpeciesName"), transform, tmp.centered = scale(tmp, center = TRUE, scale = FALSE))
# drop species without sufficient temperature span (irrelevant if before or after centering!)
max_tmp = max(ts, na.rm = TRUE)
min_tmp = min(ts, na.rm = TRUE)
tmp_range = (max_tmp - min_tmp)/10
filtered_dataset <- filtered_dataset %>%
  group_by(AccSpeciesName) %>%
  mutate(tmp_range = max(tmp, na.rm = TRUE)-min(tmp, na.rm = TRUE))
filtered_dataset <- filtered_dataset[filtered_dataset$tmp_range>=tmp_range,]
nrow(filtered_dataset) # Note this final dataset is slightly more aggressivley trimmed than in the paper!

## Save a copy for use in the next step
save(filtered_dataset, file = "../datasets/data_clean/filtered_dataset.RData")
