# install.packages(c("dbplyr", "RSQLite"))
library(ggplot2) # for figures
library(dplyr) # for df manipulation
library(dbplyr) # for db handling
library(RSQLite) # for db connection
library(tidyr)
library(terra)

################################################################################
setwd("C:/Users/kayla/Documents/SIG-GIS/REM/Projects/Sugarloaf_PC505/V2")
################################################################################
fvsData <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object
################################################################################
fvs_compute <- tbl(fvsData, 'FVS_Compute')
fvs_compute_df <- as.data.frame(fvs_compute)
################################################################################
#fvs_compute_df <- fvs_compute_df %>% separate(StandID, c('stand', 'variant', 'num1', 'treated', 'num3')) #splits the FCAT ID into treemapID, variant + location code, past disturbance code, treated code, past wf code
fvs_compute_df2 <- subset(fvs_compute_df, Year == 2024) # subsets to year 2024 (the year of treatment)
fvs_treated <- subset(fvs_compute_df2, BEFORE_C > 0) # subsets to only the records with a pre-thin CC
#fvs_treated <- unite(fvs_treated, "StandID", c('stand', 'variant', 'num1', 'treated', 'num3'), sep = "_") # unplits the FCAT ID
################################################################################
standid_table <- read.csv(file = "standids_table.csv") # read in standID xwalk
colnames(standid_table) <- c('varloc', 'FCATID', 'StandID') # update column names for xwalk
fvs_treated_ids <- merge(fvs_treated, standid_table, by = 'StandID') # merges db with xwalk
################################################################################
#fvs_treated_ids$perc_change <- (fvs_treated_ids$POST_CC - fvs_treated_ids$BEFORE_C)/fvs_treated_ids$POST_CC # computes percent change
fvs_treated_ids$change_pts <- fvs_treated_ids$POST_CC - fvs_treated_ids$BEFORE_C # computes change in percentage points

# fvs_treated_ids$tx <- ifelse(fvs_treated_ids$BEFORE_C < 40, 1, 0)
# fvs_treated_ids$tx <- ifelse(fvs_treated_ids$BEFORE_C >= 40 & fvs_treated_ids$POST_CC < 40, 2, fvs_treated_ids$tx)
# fvs_treated_ids$tx <- ifelse(fvs_treated_ids$POST_CC >= 40 & fvs_treated_ids$perc_change < -0.2, 3, fvs_treated_ids$tx)
# fvs_treated_ids$tx <- ifelse(fvs_treated_ids$BEFORE_C >= 40 & fvs_treated_ids$POST_CC >= 40 & 
#                                fvs_treated_ids$perc_change > -0.2, 4, fvs_treated_ids$tx)
# table(fvs_treated_ids$tx)

fvs_treated_ids$tx2 <- ifelse(fvs_treated_ids$BEFORE_C < 40, 1, 0)
fvs_treated_ids$tx2 <- ifelse(fvs_treated_ids$BEFORE_C >= 40 & fvs_treated_ids$POST_CC < 40, 3, fvs_treated_ids$tx)
fvs_treated_ids$tx2 <- ifelse(fvs_treated_ids$POST_CC >= 40 & fvs_treated_ids$change_pts > 20, 3, fvs_treated_ids$tx)
fvs_treated_ids$tx2 <- ifelse(fvs_treated_ids$BEFORE_C >= 40 & fvs_treated_ids$POST_CC >= 40 & 
                               fvs_treated_ids$change_pts <= 20, 2, fvs_treated_ids$tx)
table(fvs_treated_ids$tx2)

fvs_matrix <- fvs_treated_ids[,c(19,21)]
fvs_matrix <- as.matrix(fvs_matrix)
################################################################################
fcat_rast <- rast("TM_dist_tx_wf_WS513.tif")
fcat_rast_tx <- classify(fcat_rast, rcl = fvs_matrix, others=NA)
fcat_line_tx <- as.lines(fcat_rast_tx)
fcat_poly_tx <- as.polygons(fcat_rast_tx)
plot(fcat_rast_tx)
plot(fcat_poly_tx)
################################################################################
aoi <- vect("../sugarloaf_FBburn_hazardhaul/sugarloaf_FBburn_hazardhaul.shp")
aoi <- project(aoi, fcat_poly_tx) 
test <- split(aoi, fcat_line_tx)
fcat_og_hybrid <- cover(test, fcat_poly_tx)
plot(test)
plot(fcat_og_hybrid)
################################################################################
#writeVector(test, filename = 'fcat_tx', filetype = "ESRI Shapefile")
writeVector(fcat_og_hybrid, filename = 'fcat_og_hybrid', filetype = "ESRI Shapefile")
################################################################################


################################################################################
fvs_treated_ids_df <- fvs_treated_ids %>% separate(StandID, c('stand', 'variant', 'num1', 'treated', 'num3'))
treelist <- read.csv(file = "C:/Users/kayla/Documents/SIG-GIS/REM/TreeMap2016/Data/TreeMap2016_tree_table.csv", colClasses = c("character", "character"))
fvs_treated_ids_df <- fvs_treated_ids_df %>% rename(tm_id = stand)
unq_treelist <- treelist[treelist$tm_id %in% fvs_treated_ids_df$tm_id,]
stand_tx <- fvs_treated_ids_df[,c(1,25)]
unq_trees_tx <- merge(unq_treelist, stand_tx, by = "tm_id")
spcd_xwalk = read.csv(file = "C:/Users/kayla/Documents/SIG-GIS/REM/rem-tools/spcd_xwalk.csv")
unq_trees_tx <- merge(unq_trees_tx, spcd_xwalk, by = "SPCD") 
################################################################################
unq_trees_tx$dbh <- as.numeric(unq_trees_tx$DIA)
unq_trees_tx$class <- ifelse(unq_trees_tx$dbh <= 10, 1, 0)
unq_trees_tx$class <- ifelse(unq_trees_tx$dbh > 10 & unq_trees_tx$dbh <= 12 & unq_trees_tx$Wood == 'H', 2, unq_trees_tx$class)
unq_trees_tx$live <- as.numeric(unq_trees_tx$STATUSCD)
unq_trees_tx <- subset(unq_trees_tx, live == 1)
unq_trees_tx$class <- ifelse(unq_trees_tx$dbh > 10 & unq_trees_tx$dbh <= 20 & unq_trees_tx$Wood == 'S', 3, unq_trees_tx$class)
unq_trees_tx$class <- ifelse(unq_trees_tx$class == 0, 4, unq_trees_tx$class)
################################################################################
table(unq_trees_tx$class)
unq_trees_tx <- subset(unq_trees_tx, tx == 2 | tx == 3)
unq_trees_tx$TPA <- as.numeric(unq_trees_tx$TPA_UNADJ)
tpa_csc_tx <- unq_trees_tx %>%
  group_by(tm_id, class) %>%
  summarise( 
    count=sum(TPA))
tpa_csc_tx <- merge(tpa_csc_tx, stand_tx, by = "tm_id")
avgtpa_csc_tx <- tpa_csc_tx %>%
  group_by(class, tx) %>%
  summarise( 
    avg=mean(count))







# dbGetQuery(fvsData, 'SELECT * FROM FVS_TreeInit')

fvs_cases <- tbl(fvsData, 'FVS_cases') # returns the FVS_cases as a tbl object
fvs_cases_df <- as.data.frame(fvs_cases) # converts tbl object to a df object

fvs_summary2 <- tbl(fvsData, 'FVS_Summary2')
fvs_summary2_df <- as.data.frame(fvs_summary2)

fvs_fuels <- tbl(fvsData, 'FVS_Fuels')
fvs_fuels_df <- as.data.frame(fvs_fuels)

fvs_acre <- tbl(fvsData, 'stands_acres')
fvs_acre_df <- as.data.frame(fvs_acre)
fvs_acre_df$area_ac <- as.numeric(fvs_acre_df$area_ac)



# merge cases to fuels and summary df
fvs_sum_case <- merge(fvs_summary2_df, fvs_cases_df, by = c("CaseID", "StandID"))
fvs_sum <- merge(fvs_sum_case, fvs_acre_df, by = "StandID")

fvs_fuels_case<- merge(fvs_fuels_df, fvs_cases_df, by = c("CaseID", "StandID"))
fvs_fuels <- merge(fvs_fuels_case, fvs_acre_df, by = "StandID")

# subset to baseline & project NOWF
fvs_sum_nowf <- subset(fvs_sum, MgmtID == 'NOWF')
fvs_fuels_nowf <- subset(fvs_fuels, MgmtID == 'NOWF')

years_list <- c(2016,2021,2023,2028,2033,2038,2043,2048,2053,2058,2063,2068)

sum_fvs <- function (df, years){
  for (i in years) {
    if (exists("output") == 'FALSE') {
      Matrix <- matrix(nrow = 0, ncol = 6)
      output <- data.frame(matrix = Matrix)
      out_names <- c('Run', 'Year', 'TPA', 'SDI', 'BA', 'QMD')
      colnames(output) <- out_names
    } 
    base <- subset(fvs_sum_nowf, Year == i & RunTitle == 'Baseline')
    prj <- subset(fvs_sum_nowf, Year == i & RunTitle == 'Project')
    #
    total_base_ac <- sum(base$area_ac)
    total_prj_ac <- sum(prj$area_ac)
    #
    base$wgt_ac <- base$area_ac/total_base_ac
    prj$wgt_ac <- prj$area_ac/total_prj_ac
    #
    Matrix1 <- matrix(nrow = 1, ncol = 6)
    out_col <- c('Run', 'Year', 'TPA', 'SDI', 'BA', 'QMD')
    #
    tempoutput1 <- data.frame(matrix = Matrix1)
    tempoutput2 <- data.frame(matrix = Matrix1)
    #
    colnames(tempoutput1) <- out_col
    colnames(tempoutput2) <- out_col
    #
    tempoutput1$Run <- "Baseline"
    tempoutput1$Year <- i
    tempoutput1$TPA <- weighted.mean(base$Tpa, base$wgt_ac)
    tempoutput1$SDI <- weighted.mean(base$SDI, base$wgt_ac)
    tempoutput1$BA <- weighted.mean(base$BA, base$wgt_ac)
    tempoutput1$QMD <- weighted.mean(base$QMD, base$wgt_ac)
    #
    tempoutput2$Run <- "Project"
    tempoutput2$Year <- i
    tempoutput2$TPA <- weighted.mean(prj$Tpa, prj$wgt_ac)
    tempoutput2$SDI <- weighted.mean(prj$SDI, prj$wgt_ac)
    tempoutput2$BA <- weighted.mean(prj$BA, prj$wgt_ac)
    tempoutput2$QMD <- weighted.mean(prj$QMD, prj$wgt_ac)
    #
    output <- rbind(output, tempoutput1)
    output <- rbind(output, tempoutput2)
  }
  return(output)
}

test <- sum_fvs(fvs_sum_nowf, years_list)  
  

#fuels
#potfire













# fvsData_df$BA <- (pi*((fvsData_df$DIAMETER)^2))/576 # computes BA of each tree
# 
# fvsData_df$BA_total <- (fvsData_df$BA*fvsData_df$TREE_COUNT)
# 
# fvsData_BA <- fvsData_df %>%
#   group_by(STAND_CN) %>%
#   summarise(BA_sum = sum(BA_total)) # sums total BA for each stand
# 
# fvsData_BA$BA_perAcre <- fvsData_BA$BA_sum/0.222395 # converts total BA/stand to an estimate of BA/acre
# 
# avg_BA_perAcre <- fvsData_BA %>%
#   summarise( 
#     n=n(),
#     mean=mean(BA_perAcre),
#     sd=sd(BA_perAcre)
#   ) %>%
#   mutate( se=sd/sqrt(n))  %>%
#   mutate( ic=se * qt((1-0.05)/2 + .5, n-1)) # computes mean, SE, SD for BA/acre
# 
# fvsData_stems <- fvsData_df %>%
#   group_by(STAND_CN) %>%
#   summarise(stems_sum = sum(TREE_COUNT))
# 
# avg_stems_perAcre <- fvsData_stems %>%
#   summarise( 
#     n=n(),
#     mean=mean(stems_sum),
#     sd=sd(stems_sum)
#   ) %>%
#   mutate( se=sd/sqrt(n))  %>%
#   mutate( ic=se * qt((1-0.05)/2 + .5, n-1)) # computes mean, SE, SD for BA/acre
# 
# min(fvsData_BA$BA_perAcre) # minimum value BA/acre
# max(fvsData_BA$BA_perAcre) # maximum value BA/acre
# median(fvsData_BA$BA_perAcre) # median value BA/acre
# 
# ggplot(fvsData_BA, aes(BA_perAcre)) +       # ggplot2 histogram with manual bins
#   geom_histogram(binwidth = 60)   
# 
# test <- which(fvsData_BA$BA_perAcre <= 100) # grab stands with BA <= X
# length(test) # return number of stands with BA <= X




