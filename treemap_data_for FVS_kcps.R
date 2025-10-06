# Author: Kayla Johnston, kjohnston@sig-gis.com
# Date: 12/27/2023

# R script for deriving data from TreeMap2016 for use in FCAT, REM

# To use this script in it's entirety you'll need the following downloaded on your machine:
#     * A project shapefile
#     * The TreeMap2016 dataset
#     * The species code crosswalk csv (located in the same folder as this script)

# For REM projects you can use this script to derive:
#     * A list of western US tree species present in the project AOI for use in the species group keyword
#     * A list of 6 most abundant species over 12.0" DBH for use in the regen kcp file

# Additional functionality of this script that may be useful depending on treatment specs, or for non-REM projects
#     * A project TreeInit for use in FVS
#     * A list of forest types in the project AOI
#     * Snags/stand and average snags/acre in the project AOI, and proportion snags/acre to cut to achieve desired snags/acre

# ***This document is a working draft. If there is something you need summarized 
# from TreeMap that is not currently included in this script please submit a 
# request to Kayla by email or MM or (if you write your own addition) a pull 
# request on the git hub repo. ***

################################################################################
# Set up your workspace
# set working directory
setwd("C:/Users/kayla/Documents/SIG-GIS/REM")
# load libraries for handling shapefiles and rasters in R
library(terra) # for handling spatial data
library(foreign) # for reading in database files (and other data file types)
library(dplyr) # for data manipulation


################################################################################
# Read in files used in this script
# project shapefile
aoi <- vect("Projects/SaveTheRedwoods/FA023_GMC/FA023_GMC_10N_final.shp")
# TreeMap2016 raster
treemap <- rast("TreeMap2016/Data/TreeMap2016.tif")
comp_rast <- rast("Projects/TM_dist_tx_wf_NC510.tif")
# TreeMap2016 RAT
treemap_rat <- read.dbf("TreeMap2016/Data/TreeMap2016.tif.vat.dbf")
comp_rast <- rast("Projects/TM_dist_tx_wf_NC510.tif")
# Master tree list for all of TreeMap2016
all_trees = read.csv(file = "TreeMap2016/Data/TreeMap2016_tree_table.csv", colClasses = c("character", "character"))
# western variants spcd xwalk csv 
# this currently includes only the spcd listed in the main FVS documentation
# plan to update to include more western US species as time permits
spcd_xwalk = read.csv(file = "rem-tools/spcd_xwalk.csv")

################################################################################
# Reproject shapefile to match crs of TreeMap raster
# aoi shapefile projection
# crs(aoi)
# treemap projection
# crs(treemap)
aoi <- project(aoi, treemap) 
comp_aoi <- project(aoi, comp_rast) 

################################################################################
# Trim TreeMap raster down to just the project AOI
treemap_AOI <- crop(treemap, aoi, mask=TRUE) # crop & mask TreeMap to the AOI
comp_aoiv2 <- crop(comp_rast, comp_aoi, mask=TRUE) # crop & mask comp_rast to the AOI

################################################################################
# Get raster stand ID values
library(tidyr)
crsfvs_standIDs <- values(comp_aoiv2) # retrieves raster pixel values as vector
fvs_standIDs <- as.list(fvs_standIDs[!is.na(fvs_standIDs)]) # removes NA - the areas masked out
unq_fvs_standIDs <- unique(fvs_standIDs) # returns only unique project stand values
unq_fvs_standIDsv2 <- as.data.frame(unique(fvs_standIDs))
unq_fvs_stands <- pivot_longer(unq_fvs_standIDsv2, cols = everything(), values_to = "raster_standID")
write.csv(unq_fvs_stands, "Projects/comp_raster_fvs_standIDs.csv", row.names = FALSE)

################################################################################
# Get list of stands within project area
project_stands <- values(treemap_AOI) # retrieves raster pixel values as vector
project_stands <- as.list(project_stands[!is.na(project_stands)]) # removes NA - the areas masked out
unq_project_stands <- unique(project_stands) # returns only unique project stand values
stand_count <- as.data.frame(table(unlist(project_stands))) # returns a count by project stand ID
stand_count <- stand_count %>% rename(tm_id = Var1) # rename column header 'Var1' to 'tm_id'

################################################################################
# Compute number of live trees by species
unq_treelist <- all_trees[all_trees$tm_id %in% stand_count$tm_id,] # extract treelist for each unique stand ID
unq_treelist$TPA <- as.numeric(unq_treelist$TPA_UNADJ) # make a numeric type TPA column
unq_treelist <- unq_treelist %>% mutate(TPA = ifelse(is.na(TPA), 1, TPA)) # replace NA TPA values with 1
unq_treelist$TPP <- (unq_treelist$TPA/4046.86)*900 # compute trees per pixel (TPP) from TPA
unq_treelist <- merge(unq_treelist, stand_count, by = "tm_id") # merge count of stands with treelist
unq_treelist$projectTrees <- unq_treelist$TPP*unq_treelist$Freq # compute number of trees for each record within the project
live_treelist = subset(unq_treelist, STATUSCD == 1) # subsets treelist to only live trees
live_treecount_by_spp <- live_treelist %>% # summarizes data by count/species
  group_by(SPCD) %>%
  summarise( 
    count=sum(projectTrees))

# Extract top 49 species of softwoods and hardwoods - 50 is the limit for species group keyword in FVS, 
# extracting top 49 allows user to include OS or OH in the keyword
tpa_by_spp <- merge(live_treecount_by_spp, spcd_xwalk, by = "SPCD") # merges with western variants species code crosswalk, 
                                                         # note this drops any species not in the crosswalk
prjt_hard = subset(tpa_by_spp, Wood == 'H') # subset hardwoods
prjt_soft = subset(tpa_by_spp, Wood == 'S') # subset softwoods

top_49_hw <- prjt_hard %>%
  arrange(desc(count)) %>%
  slice(1:49) 

top_49_sw <- prjt_soft %>%
  arrange(desc(count)) %>%
  slice(1:49) 

noquote(top_49_sw$code) # print the softwood codes
noquote(top_49_hw$code) # print the hardwood codes
## ********** REMEMBER TO INCLUDE OS (other softwood) and OH (other hardwood) ************************* 
## ********** in your kcp to account for TreeMap assigned species that do not *************************
## ********** exist in the FVS variant for the project                        *************************

# OPTIONAL - save project tree list as csv
# write.csv(all_prjt_trees, file = "Projects/GSLC/fvs_inits/marin_biomass_tree_list.csv", row.names = F)

################################################################################
# Get top 6 species over 12" DBH for use in regen kcp
live_treelist$diam <- as.numeric(live_treelist$DIA) # creates a numeric type of DBH values
live_treelist_gte12 <- live_treelist[which(live_treelist$diam >= 12.0),] # subset live trees to only those GTE 12.0" DBH
treecount_by_spp_gte12 <- live_treelist_gte12 %>%
  group_by(SPCD) %>%
  summarise( 
    count=sum(projectTrees)) # count trees by species
count_by_spp <- merge(treecount_by_spp_gte12, spcd_xwalk, by = "SPCD")  # merge with species code crosswalk
top_6_regen_species <- count_by_spp %>%
  arrange(desc(count)) %>%
  slice(1:6) # returns df of most abundant 6 species over 12.0" DBH

################################################################################


################################################################################


################################################################################






#########
# Other things you can do with this script but that are not necessary for most REM projects
#########

################################################################################
# Compute average snags/acre and proportion to cut to meet desired snags/acre - for projects with snag retention specs
# dead_treelist = subset(unq_treelist, STATUSCD == 2) # subsets treelist to only dead trees (snags)
# tpa_snags_by_stand <- dead_treelist %>%
#   group_by(tm_id) %>%
#   summarise( 
#     snag_TPA=sum(TPA)) # counts trees/stand by tm_id & TPA
# avg_snags_per_acre <- mean(tpa_snags_by_stand$snag_TPA) # converts snags/stand to snags/acre
# desired_snags_per_acre <- 10 # How many snags/acre need to be left after thinning
# proportion_available_to_cut <- 1 - (desired_snags_per_acre/avg_snags_per_acre) # compute proportion of snags/acre available to cut
# proportion_available_to_cut # print/return proportion of snags/acre available to cut

################################################################################
# # Create full tree list for project area - this can take several minutes for large or diverse treatment areas
# all_prjt_trees <- all_trees[0,] # creates empty df with the same column headers from the 'all_trees' df
# for (i in project_stands) {
#   all_prjt_trees <- rbind(all_prjt_trees, all_trees[all_trees$tm_id %in% project_stands[i],])
# } # fills the 'all_prjt_trees' df with all tree records in the project area

################################################################################
# # get forest types and save to csv file
# # retrieve data from TreeMap RAT that corresponds to project stands
# prjt_forest_type <- treemap_rat[treemap_rat$Value %in% project_stands,]
# # retrieve df of unique forest types within project AOI 
# unq_forest_type = as.data.frame(unique(prjt_forest_type$FldTypName))
# # rename project forest type column header
# colnames(unq_forest_type)[1] <- "prjt_forest_type"
# # OPTIONAL - write csv of project forest types for use else where
# write.csv(unq_forest_type, file = "Projects/GSLC/fvs_inits/prjt_forest_types.csv", row.names = F)