####Set up workspace####
project_dir <- "~/code/HRL_microclimate/" ##must have trailing slash
setwd(project_dir)
source("./code/HRL_microclim_functions.R")

require(data.table)
require(xts)
require(psych)

####Soil temperature data processing####

##Paths of folders to process (all must be absolute paths)
input_paths_soil <- paste(project_dir,c("./data/tms4_test/tms4"),
                          sep="")

##Compiles data into a common format with consistent names.
soil_formatted <- format_micro_csv(input_paths=input_paths_soil,
                                   output_path=paste(project_dir,"temp/soil",sep=""),
                                   file_prefixes=c("TMS_soil"),
                                   output_metadata_filename="metadata_tms_soil.txt",
                                   data_column=4,overwrite=TRUE)

##Cleans soil temperature data, removing spikes and unphysical values.
clean_soil_temps(input_path=paste(project_dir,"temp/soil",sep=""),
                 input_metadata_filename="metadata_tms_soil.txt",
                 output_path=paste(project_dir,"output/soil",sep=""),
                 output_metadata_filename="metadata_flags_tms_soil.txt",
                 figure_path=paste(project_dir,"figs/soil",sep=""),
                 guess_tz="UTC",temp_spike_thresh=20,
                 min_temp_thresh=-30,max_temp_thresh=60,max_temp_hr=17,
                 cf_test_params=c(40,160,20,30),
                 overwrite=TRUE)

merge_meta <- merge_micro_csv(input_path=paste(project_dir,"output/soil/clean_unflagged",sep=""),
                file_metadata_path=paste(project_dir,"output/soil/metadata_flags_tms_soil.txt",sep=""),
                file_metadata_join_column="filestem",
                sensor_metadata_path=paste(project_dir,"data/tms4_test/micromet_locations_2020_wgs84.csv",sep=""),
                sensor_metadata_join_column="sub_site",
                output_path = paste(project_dir,"output/soil/merged_hourly/",sep=""),
                output_metadata_path=paste(project_dir,"output/soil/merged_hourly/tms_metadata.txt",sep=""),
                figure_path=paste(project_dir,"figs/soil/merged_hourly",sep=""),
                hour_begin=as.POSIXct("2020-07-01 00:00 MDT"),
                hour_end=as.POSIXct("2021-10-01 00:00 MDT"),
                tzone="America/Denver",
                interp_gap_max=8,
                overwrite=TRUE)

summarise_soiltemp_daily(input_path=paste(project_dir,"output/soil/merged_hourly",sep=""),
                         output_path=paste(project_dir,"output/soil/summarised_daily",sep=""),
                         snow_range_thresh=1,
                         snow_maxt_thresh=2,
                         overwrite=TRUE)

##Merges all daily measurements into a single file. Takes files formatted by summarise_soil_daily.
soiltemp_data <- compile_soiltemp_daily(input_path=paste(project_dir,"output/soil/summarised_daily",sep=""),
                                        output_file_snow=paste(project_dir,"output/soil/merged_daily_tms_snow.csv",sep=""),
                                        output_file_tmin=paste(project_dir,"output/soil/merged_daily_tms_smin.csv",sep=""),
                                        output_file_tmax=paste(project_dir,"output/soil/merged_daily_tms_smax.csv",sep=""),
                                        start_date=as.Date("2020-07-01"),
                                        end_date=as.Date("2021-09-15"),
                                        add_summer_zero=TRUE,
                                        overwrite=TRUE,
                                        return_data=TRUE)

##Plots time-series to check alignment.
alignment_plot(data_df=soiltemp_data$tmin,
               year_seq=2020:2021,
               min_month="01-01",
               max_month="12-31",
               min_y=-20,max_y=20,
               col_subset="all",
               ID_text=FALSE)