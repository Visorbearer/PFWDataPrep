# Install these packages if you don't have them already
install.packages("dplyr")
install.packages("data.table")
install.packages("tidyr")
install.packages("lubridate")

# Load packages
library(dplyr)
library(data.table)
library(tidyr)
library(lubridate)

# Replace "directory path" with your actual working directory path
setwd("directory path")

# Define the file paths for all PFW data you've downloaded
#this will typically come in batches of years, e.g. "PFW_all_2011_2015_May2024_Public.csv"
files <- list(
#  Put file paths here as a list separated by commas
)

# Load files into a list of data one at a time to prevent memory overflow
#We're  doing it like this because the files can be pretty big, so loading them all at once can lag and/or crash your PC
data_list <- list()
for (file in files) {
  data <- fread(file)
  data_list <- append(data_list, list(data))
  rm(data)
  gc()
}

# Now we can identify the specific regions we want to focus on for our study
#These are listed as subnational code, e.g. c("US-OR", "US-WA", "US-ID")
regions <- c(#list here, you can bring the parenthesis back to this line after or just leave it on the next
  )

#SUBNATIONAL1_CODE is the state/province level identifier for PFW data
filter_by_region <- function(df, regions) {
  df %>% filter(SUBNATIONAL1_CODE %in% regions)
}

filtered_data_list <- list()
for (df in data_list) {
  filtered_df <- filter_by_region(df, regions)
  filtered_data_list <- append(filtered_data_list, list(filtered_df))
  rm(df)
  gc()
}

#Now you should only have data for your selected regions. Always best to double-check before proceeding, though
# Check the number of rows to ensure filtering worked correctly;number should be less than the original combined dataset had
for (i in 1:length(filtered_data_list)) {
  print(paste("Rows in filtered data frame", i, ":", nrow(filtered_data_list[[i]])))
}

rm(data_list)
gc()

# Combine all dataframes into one
combined_data <- bind_rows(filtered_data_list)

#Now you have all your data, filtered by location, in one place.

#Next, you can filter by year, if you want
#Just plug in whatever years you don't want to include at the end in YYYY format
combined_data <- combined_data %>% filter(Year != YYYY)

rm(filtered_data_list)
gc()

# Save the combined data as a CSV for backup
write.csv(combined_data, "combined_PFW_data.csv", row.names = FALSE)

# Extract unique SUB_ID values and all associated columns
unique_checklists <- combined_data %>% distinct(SUB_ID, .keep_all = TRUE)

# Create a dataframe for zero-filling, which will turn no detections into zeros
#for SPECIES_CODE, find the identifer that matches your study species. For example, Lesser Goldfinch is "lesgol" in the PFW data.
zero_filled_data <- unique_checklists %>%
  mutate(SPECIES_CODE = "######", HOW_MANY = 0)

combined_data <- combined_data %>%
  right_join(zero_filled_data, by = c("SUB_ID", "SPECIES_CODE"))

rm(zero_filled_data, unique_checklists)
gc()

# Filter the data to keep only observations of target species
#again, plug in the corresponding species code here
target_data <- combined_data %>% filter(SPECIES_CODE == "######")

# Remove rows where PLUS_CODE is 1, but keep rows with NA
# We do this to remove unreliable counts that might underestimate the actual number of birds seen; more on that in the PFW Data Dictionary
target_data <- target_data %>% filter(is.na(PLUS_CODE) | PLUS_CODE != 1)

# Verify there are no remaining rows with a PLUS_CODE of 1
remaining_plus_code_1 <- target_data %>% filter(PLUS_CODE == 1)
print(nrow(remaining_plus_code_1))

# Optionally, print the remaining rows to inspect them
print(remaining_plus_code_1)

#Since effort is an important part of detection, we want to remove any NAs from our data if they happen to occur
#check for NAs on effort values
num_na_effort <- sum(is.na(target_data$EFFORT_HRS_ATLEAST))
print(num_na_effort)

target_data <- target_data %>%
  filter(!is.na(EFFORT_HRS_ATLEAST))

# Calculate the number of half-days observed
target_data <- target_data %>%
  mutate(
    half_days_observed = rowSums(select(., DAY1_AM, DAY1_PM, DAY2_AM, DAY2_PM) == 1, na.rm = TRUE)
  )

# Bin the numeric values into the specified categories
target_data <- target_data %>%
  mutate(
    EFFORT_HRS_BINNED = cut(EFFORT_HRS_ATLEAST,
                            breaks = c(-Inf, 1, 4, 8, Inf),
                            labels = c("< 1", "1 to 4", "4 to 8", "> 8"),
                            right = FALSE)
  )

# Calculate mean and standard error for each effort bin
effort_summary <- target_data %>%
  group_by(EFFORT_HRS_BINNED) %>%
  summarise(
    mean_birds = mean(HOW_MANY, na.rm = TRUE),
    se_birds = sd(HOW_MANY, na.rm = TRUE) / sqrt(n())
  )
# Ensure the levels of EFFORT_HRS_BINNED are ordered correctly
effort_summary$EFFORT_HRS_BINNED <- factor(effort_summary$EFFORT_HRS_BINNED, levels = c("< 1", "1 to 4", "4 to 8", "> 8"))

# Remove invalid records
#This is to avoid any unconfirmed observations, which are typically unlikely and may skew subsequent modeling
target_data <- target_data %>%
  filter(VALID != 0)

# Save this dataset
write.csv(target_data, "CleanedPFWData.csv", row.names = FALSE)

#At this point, you'll want to attach whatever variables you're testing to your data.
#There are a variety of ways to do this, like through R or external GIS software.
#The code you'll need to run here will therefore depend on what you're testing.
#Luckily, most databases will also provide explanations on how to do this step.
#After you've merged all your data into one file, you can return to this code.
#In the following line, you'll want the imported .csv file to be one with all of your covariate values attached to the CleanedPFWData.csv you created earlier.
PFW_data <- read.csv("############.csv")

#Get  a list of the unique LOCs
#This will tell us how many unique sites there are, rather than unique checklists
sites <-unique(PFW_data$LOC_ID)
#make it a data frame
sites <-data.frame(sites)
#and name this column
colnames(sites) <- "LOC_ID"

#now merge the corrected data with the sites we know we want
raw_sites <- merge(PFW_data, sites, by.x="LOC_ID", by.y="LOC_ID")

#
#Now, if we want, we can also limit the observations by month
#This can be especially helpful if you want a certain part of winter exclusively for your analysis
#The following code selects for December through March, but you can have it select for whatever months you'd like
raw_sites_dates <- raw_sites[which(raw_sites$Month==12|raw_sites$Month==1|raw_sites$Month==2 | raw_sites$Month==3),]

write.table(raw_sites_dates, "RawSitesPruned.csv", sep=",",row.names=FALSE)

####The next steps help set up for unmarked modeling.
#While we won't get into the modeling code here, we will prepare our data for that modeling format.
#If you're doing a different kind of modeling, you may need to revise some of this code to accommodate.

# Add Julian Date
raw_sites_dates$Julian_date <- yday(raw_sites_dates$Date)

#Create a Unique Identifier for Each Survey Instance
raw_sites_dates <- raw_sites_dates %>%
  group_by(LOC_ID, Year) %>%
  mutate(survey_instance = row_number()) %>%
  ungroup()

# create a wide data table for occupancy
occupancy_wide <- raw_sites_dates %>%
  select(LOC_ID, Year, survey_instance, presence_absence) %>%
  unite("survey", c("survey_instance", "Year"), sep = "_") %>%
  spread(key = survey, value = presence_absence, fill = NA)
write.csv(occupancy_wide, "occu.csv", row.names = FALSE)
occu <- occupancy_wide

# create a wide data table for Julian date
julian_wide <- raw_sites_dates %>%
  select(LOC_ID, Year, survey_instance, Julian_date) %>%
  unite("survey", c("survey_instance", "Year"), sep = "_") %>%
  spread(key = survey, value = Julian_date, fill = NA)
write.csv(julian_wide, "julian.csv", row.names = FALSE)

# create a wide data table for effort
effort_wide <- raw_sites_dates %>%
  select(LOC_ID, Year, survey_instance, EFFORT_HRS_ATLEAST) %>%
  unite("survey", c("survey_instance", "Year"), sep = "_") %>%
  spread(key = survey, value = EFFORT_HRS_ATLEAST, fill = NA)
write.csv(effort_wide, "effort.csv", row.names = FALSE)


#Bind site covariates from full data
site_cov <- merge(occu, raw_sites_dates, by.x="LOC_ID", by.y="LOC_ID")

#Establish site covariate list
#this will vary depending on what you're testing
#it will look something like c("ppt","tmean","HousingDensity") and so on to include all of your covariates
site_cov <- site_cov[,c(######
                        )]
site_cov<-data.table(site_cov)

# Calculate mean for numeric columns and retain first value for character columns
site_cov_mean <- site_cov[, c(lapply(.SD, mean, na.rm = TRUE), 
                              .(range = first(range), SUBNATIONAL1_CODE = first(SUBNATIONAL1_CODE))), 
                          by = LOC_ID, 
                          .SDcols = c(#List of covariates here again
                            )]

write.table(site_cov_mean, "site_cov.csv", sep=",",row.names=FALSE)

#And now you're ready to start your modeling! Enjoy!
