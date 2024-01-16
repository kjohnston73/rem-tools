# install.packages(c("dbplyr", "RSQLite"))
library(ggplot2) # for figures
library(dplyr) # for df manipulation
library(dbplyr) # for db handling
library(RSQLite) # for db connection

setwd("C:/Users/kayla/Documents/SIG-GIS/REM/Projects/AlderSprings")

fvsData <- dbConnect(SQLite(), 'FVSOut.db') # connects db to an R object

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


