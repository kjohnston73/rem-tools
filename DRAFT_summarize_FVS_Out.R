library(dplyr) # for df manipulation
# library(dbplyr) # for db handling
library(RSQLite) # for db connection
library(tidyr)

################################################################################
# Set the working directory
setwd("C:/Users/kayla/Documents/SIG-GIS/REM/Projects/Sugarloaf_PC505/V12")
################################################################################
# Connect to FVSOut.db and read/convert the compute and summary2 table as df
fvsData <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object
fvs_compute <- tbl(fvsData, 'FVS_Compute') # converts to R table object
fvs_compute_df <- as.data.frame(fvs_compute) # converts to R df object
fvs_sum2 <- tbl(fvsData, 'FVS_Summary2') # converts to R table object
fvs_sum2_df <- as.data.frame(fvs_sum2) # converts to R df object
################################################################################
# # Connect to FVSOut.db and read/convert the compute and CASES table as df
fvsCases <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object
fvs_cases <- tbl(fvsCases, 'FVS_Cases') # converts to R table object
fvs_cases_df <- as.data.frame(fvs_cases) # converts to R df object
fvs_cases_df1 <- fvs_cases_df[,c(1,4,5)]
# table(fvs_cases_df1$MgmtID)
################################################################################
# Read in the stands_acres csv, merge with the FVS_Compute df, then subset to the 
# desired years
stand_ac <- read.csv('stands_acres.csv')
fvs_comp_df <- merge(fvs_compute_df, stand_ac, by = 'StandID')
fvs_comp_df1 <- subset(fvs_compute_df, Year == 2024 | Year == 2034)
################################################################################
# Connect to the FVS_Data.db and read/convert the StandInit table as df
fvsInit <- dbConnect(SQLite(), 'FVS_Data.db') # connects db to an R object
standInit <- tbl(fvsInit, 'FVS_StandInit') # converts to R table object
standInit_df <- as.data.frame(standInit) # converts to R df object
table(standInit_df$GROUPS)
################################################################################
# Subset the stand init df to the standID and Group, merge with the FVS_compute df
standInit_df2 <- standInit_df[,c(2,5)]
standInit_df3 <- standInit_df2 %>% separate(STAND_ID, c('stand', 'variant', 'num1', 'treated', 'num3'))
standInit_df4 <- unite(standInit_df3, "StandID", c('stand', 'variant', 'num1', 'treated', 'num3'), sep = "_") # unplits the FCAT ID
fvs_comp_df2 <- merge(fvs_comp_df1, standInit_df4, by = "StandID")
table(fvs_comp_df2$GROUPS)
################################################################################
# Get rid of the baseline (non-project) stands
fvs_comp_df2$project <- ifelse(fvs_comp_df2$GROUPS == 'All_Stands Baseline', 'no', 'yes')
fvs_comp_df3 <- subset(fvs_comp_df2, project == 'yes')
################################################################################
# merge with fvs_cases and subset to the NOWF records
fvs_comp_df4 <- merge(fvs_comp_df3, fvs_cases_df1, by = 'CaseID')
fvs_comp_df5 <- subset(fvs_comp_df4, MgmtID == 'NOWF')
################################################################################
# same steps but on fvs_summary
fvs_sum2_df1 <- subset(fvs_sum2_df, Year == 2024 | Year == 2034)
fvs_sum2_df2 <- fvs_sum2_df1[,c(1,2,3,4,6,8,9,12)]
fvs_sum2_df22 <- merge(fvs_sum2_df2, standInit_df4, by = "StandID")
fvs_sum2_df22$project <- ifelse(fvs_sum2_df22$GROUPS == 'All_Stands Baseline', 'no', 'yes')
fvs_sum2_df32 <- subset(fvs_sum2_df22, project == 'yes')

fvs_sum2_df3 <- merge(fvs_sum2_df32, fvs_cases_df1, by = 'CaseID')
fvs_sum2_df4 <- subset(fvs_sum2_df3, MgmtID == 'NOWF')
fvs_sum2_df5 <- subset(fvs_sum2_df4, RmvCode == '0' | RmvCode == '2')
################################################################################
# Compute averages
fvs_sum2_df5$tx_type <- ifelse(fvs_sum2_df5$GROUPS == 'All_Stands Baseline Project PC505_snag_burn', 'snagsburn', 'fbburn')
burn_tpa <- fvs_sum2_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    TPA=mean(Tpa))

burn_tpa<- unite(burn_tpa, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_ba <- fvs_sum2_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    BA=mean(BA))

burn_ba<- unite(burn_ba, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_sdi <- fvs_sum2_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    SDI=mean(SDI))

burn_sdi<- unite(burn_sdi, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_qmd <- fvs_sum2_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    QMD=mean(QMD))

burn_qmd<- unite(burn_qmd, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

fvs_comp_df5$tx_type <- ifelse(fvs_comp_df5$GROUPS == 'All_Stands Baseline Project PC505_snag_burn', 'snagsburn', 'fbburn')
burn_fl <- fvs_comp_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    FL=mean(SEV_FL))

burn_fl<- unite(burn_fl, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_cc <- fvs_comp_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CC=mean(CC))

burn_cc<- unite(burn_cc, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_cbh <- fvs_comp_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CBH=mean(CBH))

burn_cbh<- unite(burn_cbh, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

burn_cbd <- fvs_comp_df5 %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CBD=mean(CBD))

burn_cbd<- unite(burn_cbd, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")


################################################################################
# Set the working directory
setwd("C:/Users/kayla/Documents/SIG-GIS/REM/Projects/Sugarloaf_PC505/V13")
################################################################################
# Connect to FVSOut.db and read/convert the compute and summary2 table as df
fvsData_a <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object
fvs_compute_a <- tbl(fvsData_a, 'FVS_Compute') # converts to R table object
fvs_compute_df_a <- as.data.frame(fvs_compute_a) # converts to R df object
fvs_sum2_a <- tbl(fvsData_a, 'FVS_Summary2') # converts to R table object
fvs_sum2_df_a <- as.data.frame(fvs_sum2_a) # converts to R df object
################################################################################
# # Connect to FVSOut.db and read/convert the compute and CASES table as df
fvsCases_a <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object
fvs_cases_a <- tbl(fvsCases_a, 'FVS_Cases') # converts to R table object
fvs_cases_df_a <- as.data.frame(fvs_cases_a) # converts to R df object
fvs_cases_df1_a <- fvs_cases_df_a[,c(1,4,5)]
# table(fvs_cases_df1$MgmtID)
################################################################################
# Read in the stands_acres csv, merge with the FVS_Compute df, then subset to the 
# desired years
stand_ac_a <- read.csv('stands_acres.csv')
fvs_comp_df_a <- merge(fvs_compute_df_a, stand_ac_a, by = 'StandID')
fvs_comp_df1_a <- subset(fvs_compute_df_a, Year == 2024 | Year == 2034)
################################################################################
# Connect to the FVS_Data.db and read/convert the StandInit table as df
fvsInit_a <- dbConnect(SQLite(), 'FVS_Data.db') # connects db to an R object
standInit_a <- tbl(fvsInit_a, 'FVS_StandInit') # converts to R table object
standInit_df_a <- as.data.frame(standInit_a) # converts to R df object
table(standInit_df_a$GROUPS)
################################################################################
# Subset the stand init df to the standID and Group, merge with the FVS_compute df
standInit_df2_a <- standInit_df_a[,c(2,5)]
standInit_df3_a <- standInit_df2_a %>% separate(STAND_ID, c('stand', 'variant', 'num1', 'treated', 'num3'))
standInit_df4_a <- unite(standInit_df3_a, "StandID", c('stand', 'variant', 'num1', 'treated', 'num3'), sep = "_") # unplits the FCAT ID
fvs_comp_df2_a <- merge(fvs_comp_df1_a, standInit_df4_a, by = "StandID")
table(fvs_comp_df2_a$GROUPS)
################################################################################
# Get rid of the baseline (non-project) stands
fvs_comp_df2_a$project <- ifelse(fvs_comp_df2_a$GROUPS == 'All_Stands Baseline', 'no', 'yes')
fvs_comp_df3_a <- subset(fvs_comp_df2_a, project == 'yes')
################################################################################
# merge with fvs_cases and subset to the NOWF records
fvs_comp_df4_a <- merge(fvs_comp_df3_a, fvs_cases_df1_a, by = 'CaseID')
fvs_comp_df5_a <- subset(fvs_comp_df4_a, MgmtID == 'NOWF')
################################################################################
# same steps but on fvs_summary
fvs_sum2_df1_a <- subset(fvs_sum2_df_a, Year == 2024 | Year == 2034)
fvs_sum2_df2_a <- fvs_sum2_df1_a[,c(1,2,3,4,6,8,9,12)]
fvs_sum2_df22_a <- merge(fvs_sum2_df2_a, standInit_df4_a, by = "StandID")
fvs_sum2_df22_a$project <- ifelse(fvs_sum2_df22_a$GROUPS == 'All_Stands Baseline', 'no', 'yes')
fvs_sum2_df32_a <- subset(fvs_sum2_df22_a, project == 'yes')

fvs_sum2_df3_a <- merge(fvs_sum2_df32_a, fvs_cases_df1_a, by = 'CaseID')
fvs_sum2_df4_a <- subset(fvs_sum2_df3_a, MgmtID == 'NOWF')
fvs_sum2_df5_a <- subset(fvs_sum2_df4_a, RmvCode == '0' | RmvCode == '2')
################################################################################
# Compute averages
fvs_sum2_df5_a$tx_type <- ifelse(fvs_sum2_df5_a$GROUPS == 'All_Stands Baseline Project PC505_snag_haul', 'snagshaul', 'fb')
noburn_tpa <- fvs_sum2_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    TPA=mean(Tpa))

noburn_tpa<- unite(noburn_tpa, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_ba <- fvs_sum2_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    BA=mean(BA))

noburn_ba<- unite(noburn_ba, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_sdi <- fvs_sum2_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    SDI=mean(SDI))

noburn_sdi<- unite(noburn_sdi, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_qmd <- fvs_sum2_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    QMD=mean(QMD))

noburn_qmd<- unite(noburn_qmd, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

fvs_comp_df5_a$tx_type <- ifelse(fvs_comp_df5_a$GROUPS == 'All_Stands Baseline Project PC505_snag_haul', 'snagshaul', 'fb')
noburn_fl <- fvs_comp_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    FL=mean(SEV_FL))

noburn_fl<- unite(noburn_fl, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_cc <- fvs_comp_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CC=mean(CC))

noburn_cc<- unite(noburn_cc, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_cbh <- fvs_comp_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CBH=mean(CBH))

noburn_cbh<- unite(noburn_cbh, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

noburn_cbd <- fvs_comp_df5_a %>%
  group_by(Year, RunTitle, tx_type) %>%
  summarise( 
    CBD=mean(CBD))

noburn_cbd<- unite(noburn_cbd, "tx_scen_year", c('tx_type', 'RunTitle', 'Year'), sep = "_")

final_out <- merge(burn_tpa, burn_sdi, by = 'tx_scen_year')
final_out <- merge(final_out, burn_qmd, by = 'tx_scen_year')
final_out <- merge(final_out, burn_cc, by = 'tx_scen_year')
final_out <- merge(final_out, burn_cbh, by = 'tx_scen_year')
final_out <- merge(final_out, burn_cbd, by = 'tx_scen_year')
final_out <- merge(final_out, burn_ba, by = 'tx_scen_year')
final_out <- merge(final_out, burn_fl, by = 'tx_scen_year')

temp_out <- merge(noburn_tpa, noburn_sdi, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_qmd, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_cc, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_cbh, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_cbd, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_ba, by = 'tx_scen_year')
temp_out <- merge(temp_out, noburn_fl, by = 'tx_scen_year')

final_out_export <- rbind(final_out, temp_out)
final_out_export <- subset(final_out_export, tx_scen_year!= 'fb_Baseline (1)_2024')
final_out_export <- subset(final_out_export, tx_scen_year!= 'fb_Baseline (1)_2034')
final_out_export <- subset(final_out_export, tx_scen_year!= 'snagshaul_Baseline (1)_2024')
final_out_export <- subset(final_out_export, tx_scen_year!= 'snagshaul_Baseline (1)_2034')
final_out_export <- final_out_export %>% separate(tx_scen_year, c('tx', 'scenario', 'year1', 'year2'))
final_out_export$year2 <- ifelse(final_out_export$year1 == '1', final_out_export$year2, final_out_export$year1)
final_out_export <- final_out_export[,-c(3)]
colnames(final_out_export)[3] <- "Year"

write.csv(final_out_export, file = "PC505_SL_final_outputs.csv", row.names = F)
