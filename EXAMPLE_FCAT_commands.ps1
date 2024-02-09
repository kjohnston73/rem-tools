# 27Dec2023, D. Schmidt
# This is like FCAT_ssh_commands.ps1 but it runs clojure locally without requiring SSH.
# There are two steps:
# 1. Edit the values of the variables in the block directly below.
# 2. Uncomment the lines in each FCAT section of the following block. Run each section after the preceeding section is finished.

##################################
# Edit these variables as needed #
##################################
# This is the file path to the runway repo
$runway_dir = "C:\git\runway"

# This is the file path to the folder this .ps1 file is in
$script_dir = "C:\Users\kjohnston\Documents\runway_ps1"

# This is your project code, needs to be formatted as <PC>_<abbreviated project name>_<V#>
$project_code = "FA019_Kodama_V8"

# This is the full file path to the aoi shapefile. Aoi is the minimum bounding envelope around a 15 km buffer of the treatment area
# If you are running an REM project, set the aoi_file to be the same shapefile as the tx_file - FCAT will make the correct AOI for you
$aoi_file = "/mnt/share/rem-inputs/ThreeCreeks_UTM11N.shp"

# This is the full file path to the treatment shapefile. 
$tx_file = "/mnt/share/rem-inputs/ThreeCreeks_UTM11N.shp"

# This is the distance (m) to buffer the tx_file by to create the AOI
# Always set to 15000 for an REM project
$buffer_m = 15000

# true/flase to include dead trees in the FCAT project. 
# This is set to "true" for all REM projects.
$include_dead_trees = "true"

# this is the name of your global kcp file *Note: this is not the file path, just the file name with extension
$global_kcp = "global_generic.kcp"

# This is the name of you regen kcp file. * Again, note this is not the file path, just the file name with extension
$regen_kcp = "Regen_FA019.kcp"

# These are binary operators (0/1) for whether or not to execute certain components of the FCAT process. 
# All three should be set to "1" for an REM project. 
$exec_wildfires = 1
$exec_project = 1
$exec_baseline = 1

# This is the start year (typically the current year) for your project
$start_year = 2024

# This is the end year for FVS simulations, for REM projects this is always the start year + 45 years
$fvs_end_year = 2069

# This is the end year for gridfire simulations, for REM projects this is always the start year + 40 years
$end_year = 2064

# This is the number of simulations gridfire runs
# For an REM project this value should be the larger between (10,000) and the (AOI acres/50)
$num_simulations = 10000

# This is the average annual burn probability you computed for your 15km buffered project area
$ABP = 0.00968

# This is a value for the NOX calculations
# Always "0" for REM projects
$NOX = 0

# These are volumes of merchantable timber removed in each fvs time step
# All should be set to "0" for REM projects.
$net_merch_removed_ts1 = 0
$net_merch_removed_ts2 = 0
$net_merch_removed_ts3 = 0
$net_merch_removed_ts4 = 0
$net_merch_removed_ts5 = 0
$net_merch_removed_ts6 = 0
$net_merch_removed_ts7 = 0
$net_merch_removed_ts8 = 0
$net_merch_removed_ts9 = 0

# This is the response host IP for BlueJay, you only need to change this if you are running from a VM other than BlueJay
$response_ip = "10.1.30.113"

# This is the response port for logging progress back to the powershell
# A port can only be used by 1 person for 1 command at a time.
# If you are running multiple projects and want to log/track both in the powershell then you need to use a separate port for each command you run.
# Assigned ports per user:
# Kayla: 5100-5110
# Liz: 5200 - 5210
# Jarrett: 5300 - 5310
# Other: 5900 - 5910
$response_port = 5100

# This cd into the runway directory you defined above
cd $runway_dir

#########################################################################
# Uncomment these commands as needed; they should not need to be edited #
# Each step can be run on 1 of 2 host VM, uncomment only 1 $host_ip     #
# variable for each step                                                #
#########################################################################
##### 1. FCAT-fvs (FVS set-up) #####
## currawong host IP
#$host_ip = "10.1.30.142"
## grouse host IP
#$host_ip = "10.1.30.120"
#$port = 1337
## command with logging
#$fvs_cmd = -join(' {"""scriptArgs""": {"""cell-size""": 30, """project-code""": """', $project_code, '""", """aoi-file""": """', $aoi_file, '""", """treatment-file""": """', $tx_file, '""", """buffer""": ', $buffer_m, ', """include-dead-trees""": ', $include_dead_trees, ', """global-kcp""": """', $global_kcp, '""", """regen-kcp""": """', $regen_kcp, '"""}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$fvs_cmd = -join(' {"""scriptArgs""": {"""cell-size""": 30, """project-code""": """', $project_code, '""", """aoi-file""": """', $aoi_file, '""", """treatment-file""": """', $tx_file, '""", """buffer""": ', $buffer_m, ', """include-dead-trees""": ', $include_dead_trees, ', """global-kcp""": """', $global_kcp, '""", """regen-kcp""": """', $regen_kcp, '"""}, """jobId""": 1}')
#echo $fvs_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $fvs_cmd

##### 2. FCAT-rfvs (execute FVS) ####
## currawong host IP
#$host_ip = "10.1.30.142"
## grouse host IP
#$host_ip = "10.1.30.120"
#$port = 1338
## command with logging
#$rfvs_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $fvs_end_year, ', """exec-wildfires""": ', $exec_wildfires, ', """exec-project""": ', $exec_project, ', """exec-baseline""": ', $exec_baseline, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$rfvs_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $fvs_end_year, ', """exec-wildfires""": ', $exec_wildfires, ', """exec-project""": ', $exec_project, ', """exec-baseline""": ', $exec_baseline, '}, """jobId""": 1}')
#echo $rfvs_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $rfvs_cmd

#### 3a. FCAT-gridfire 1 (GF fuels) ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1337
## command with logging
#$gridfire1_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$gridfire1_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1}')
#echo $gridfire1_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $gridfire1_cmd

#### 3b. FCAT-gridfire 2 (GF inputs) ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1338
## command with logging
#$gridfire2_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$gridfire2_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1}')
#echo $gridfire2_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $gridfire2_cmd

#### 3c. FCAT-gridfire 3 (execute GF) ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1339
## command with logging
#$gridfire3_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, ', """num-simulations""": ', $num_simulations, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$gridfire3_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, ', """num-simulations""": ', $num_simulations, '}, """jobId""": 1}')
#echo $gridfire3_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $gridfire3_cmd

#### 3d. FCAT-gridfire 4 (GF outputs) ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1340
## command with logging
#$gridfire4_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$gridfire4_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, '}, """jobId""": 1}')
#echo $gridfire4_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $gridfire4_cmd

#### 4. FCAT-carbon ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1343
## command with logging
#$process_carbon_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """area-factor""": 0.2224}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$process_carbon_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """area-factor""": 0.2224}, """jobId""": 1}')
#echo $process_carbon_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $process_carbon_cmd

#### 5. FCAT-FOFEM ####
## currawong host IP
#$host_ip = "10.1.30.142"
## grouse host IP
#$host_ip = "10.1.30.120"
#$port = 47165
#$stands_acres_csv = "/mnt/share/rem/$project_code/carbon/stands_acres.csv"
#$fvs_out_db = "/mnt/share/rem/$project_code/fvs/runs/FVSOut.db"
## command with logging
#$fofem_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, ', """stands-acres-csv""": """', $stands_acres_csv, '""", """fvs-out-db""": """', $fvs_out_db, '"""}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$fofem_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """start-year""": ', $start_year, ', """end-year""": ', $end_year, ', """stands-acres-csv""": """', $stands_acres_csv, '""", """fvs-out-db""": """', $fvs_out_db, '"""}, """jobId""": 1}')
#echo $fofem_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $fofem_cmd

#### 6. FCAT-delayed regeneration ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1342
## command with logging
#$delayed_regen_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """projects""": """Project"""}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$delayed_regen_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """projects""": """Project"""}, """jobId""": 1}')
#echo $delayed_regen_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $delayed_regen_cmd

#### 7. FCAT-quant ####
## chickadee IP
#$host_ip = "10.1.30.139"
## goose IP
#$host_ip = "10.1.30.121"
#$port = 1344
## command with logging
#$quant_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """abp""": ', $abp, ', """nox""": ', $nox, ', """start-year""": ', $start_year, ', """net-merch-removed-ts1""": ', $net_merch_removed_ts1, ', """net-merch-removed-ts2""": ', $net_merch_removed_ts2, ', """net-merch-removed-ts3""": ', $net_merch_removed_ts3, ', """net-merch-removed-ts4""": ', $net_merch_removed_ts4 , ', """net-merch-removed-ts5""": ', $net_merch_removed_ts5, ', """net-merch-removed-ts6""": ', $net_merch_removed_ts6, ', """net-merch-removed-ts7""": ', $net_merch_removed_ts7, ', """net-merch-removed-ts8""": ', $net_merch_removed_ts8, ', """net-merch-removed-ts9""": ', $net_merch_removed_ts9, '}, """jobId""": 1, """responseHost""": """', $response_ip, '""", """responsePort""": ', $response_port, '}')
## command without logging
#$quant_cmd = -join(' {"""scriptArgs""": {"""project-code""": """', $project_code, '""", """abp""": ', $abp, ', """nox""": ', $nox, ', """start-year""": ', $start_year, ', """net-merch-removed-ts1""": ', $net_merch_removed_ts1, ', """net-merch-removed-ts2""": ', $net_merch_removed_ts2, ', """net-merch-removed-ts3""": ', $net_merch_removed_ts3, ', """net-merch-removed-ts4""": ', $net_merch_removed_ts4 , ', """net-merch-removed-ts5""": ', $net_merch_removed_ts5, ', """net-merch-removed-ts6""": ', $net_merch_removed_ts6, ', """net-merch-removed-ts7""": ', $net_merch_removed_ts7, ', """net-merch-removed-ts8""": ', $net_merch_removed_ts8, ', """net-merch-removed-ts9""": ', $net_merch_removed_ts9, '}, """jobId""": 1}')
#echo $quant_cmd
#clojure -M:default-ssl-opts:run -h $host_ip -p $port $quant_cmd

# Just for convenience; ignore or delete this if not using
cd $script_dir