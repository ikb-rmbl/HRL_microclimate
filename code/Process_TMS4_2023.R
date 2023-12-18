####Set up workspace####
project_dir <- "/Users/ian/Library/CloudStorage/OneDrive-RMBL/Documents - Research - Spatial Ecology/General/SpatialEcologyShared/Projects/RMBL_microclimate/" ##must have trailing slash
setwd(project_dir)
source("./code/RMBL_microclim_functions.R")

require(data.table)
require(xts)
require(psych)

####Soil temperature data processing####

##Paths of folders to process (all must be absolute paths)
input_paths_soil <- paste(project_dir,c("/data/Data2023/TMS4_2023"),
                          sep="")

#micro_csv("~/code/RMBL_microclimate/data/tms4_test/tms4_latest_2022/data_94199701_2022_10_13_0.csv")

##Compiles data into a common format with consistent names.
soil_formatted <- format_micro_csv(input_paths=input_paths_soil,
                                   output_path=paste(project_dir,"/temp/soil2023/",sep=""),
                                   file_prefixes=c("TMS_soil"),
                                   output_metadata_filename="metadata_tms_soil_2023.txt",
                                   data_column=4,overwrite=TRUE)

##Auto-QC soil temperature data, flagging spikes and unphysical values, and attempting to correct for time zone problems.
qc_meta_soil <- qc_soil_temps(input_path=paste(project_dir,"temp/soil2023",sep=""),
                 input_metadata_filename="metadata_tms_soil_2023.txt",
                 output_path=paste(project_dir,"output/soil2023",sep=""),
                 output_metadata_filename="metadata_flags_tms_soil_2023.txt",
                 figure_path=paste(project_dir,"figs/soil2023",sep=""),
                 guess_tz="UTC",
                 temp_spike_thresh=18,
                 tz_tolerance=30,
                 min_temp_thresh=-20,
                 max_temp_thresh=40,
                 max_temp_hr=24,
                 cf_test_params=c(40,160,20,30),
                 overwrite=TRUE)

##IMPORTANT: Manual step of flagging suspect data. Examine the output figures from the processing step above and identify unflagged problems. Open qc'd files in Excel and add flags where necessary.

##Remove flags in downstream processing.
clean_meta_soil <- clean_micro_csv(input_path=paste(project_dir,"output/soil2023/qc_flagged",sep=""),
                                   output_path=paste(project_dir,"output/soil2023/qc_cleaned",sep=""),
                                   figure_path=paste(project_dir,"figs/soil2023",sep=""),
                                   remove_flagged=c("B","S","A","L","O"),
                                   overwrite=TRUE)


#snow_summaries <- extract_snow_summaries(input_path=paste(project_dir,"output/soil2022/clean_unflagged",sep=""),
#                                         input_metadata_filename=paste(project_dir,"output/soil2022/metadata_flags_tms_soil_2022.txt",sep=""),
#                                         output_path=paste(project_dir,"output/soil2022",sep=""),
#                                         figure_path=paste(project_dir,"figs/soil2022",sep=""),
#                                         output_metadata_filename="metadata_flags_snow_2022.txt",
#                                         range_threshold=1,max_threshold=2,overwrite=TRUE)
#setwd(project_dir)
merge_meta <- merge_micro_csv(input_path=paste(project_dir,"output/soil2023/qc_cleaned",sep=""),
                file_metadata_path=paste(project_dir,"output/soil2023/metadata_flags_tms_soil_2023.txt",sep=""),
                file_metadata_join_column="filestem",
                sensor_metadata_path=paste(project_dir,"data/Data2023/micromet_locations_2023_wgs84.csv",sep=""),
                sensor_metadata_join_column="soil_sensor_name",
                sensor_metadata_site_column = "site_name",
                merge_by_site=TRUE,
                output_path = paste(project_dir,"output/soil2023/merged_hourly/",sep=""),
                output_metadata_path=paste(project_dir,"output/soil2023/merged_hourly/tms_metadata_2023.txt",sep=""),
                figure_path=paste(project_dir,"figs/soil2023/merged_hourly",sep=""),
                hour_begin=as.POSIXct("2019-10-01 00:00 MDT"),
                hour_end=as.POSIXct("2023-10-01 00:00 MDT"),
                tzone="America/Denver",
                interp_gap_max=8,
                overwrite=TRUE)

summarise_soiltemp_daily(input_path=paste(project_dir,"output/soil2023/merged_hourly",sep=""),
                         output_path=paste(project_dir,"output/soil2023/summarised_daily",sep=""),
                         snow_range_thresh=2,
                         snow_maxt_thresh=2,
                         overwrite=TRUE)

##Merges all daily measurements into a single file. Takes files formatted by summarise_soil_daily.
soiltemp_data <- compile_soiltemp_daily(input_path=paste(project_dir,"output/soil2023/summarised_daily",sep=""),
                                        output_file_snow=paste(project_dir,"output/soil2023/merged_daily_tms_snow_2022_2023.csv",sep=""),
                                        output_file_tmin=paste(project_dir,"output/soil2023/merged_daily_tms_smin_2022_2023.csv",sep=""),
                                        output_file_tmax=paste(project_dir,"output/soil2023/merged_daily_tms_smax_2022_2023.csv",sep=""),
                                        start_date=as.Date("2022-07-15"),
                                        end_date=as.Date("2023-08-15"),
                                        add_summer_zero=TRUE,
                                        overwrite=TRUE,
                                        return_data=TRUE)

##Plots time-series to check alignment.
setwd(project_dir)
pdf("./plots/alignment_plot_soil_tmax_2022.pdf",width=12,height=14)
alignment_plot(data_df=soiltemp_data$tmax,
               year_seq=2020:2022,
               min_month="1-01",
               max_month="12-31",
               min_y=-8,max_y=35,
               col_subset="all",
               ID_text=FALSE)
dev.off()


pdf("./plots/alignment_plot_soil_tmin_2022.pdf",width=12,height=14)
alignment_plot(data_df=soiltemp_data$tmin,
               year_seq=2020:2022,
               min_month="1-01",
               max_month="12-31",
               min_y=-15,max_y=20,
               col_subset="all",
               ID_text=FALSE)
dev.off()

pdf("./plots/alignment_plot_soil_snow_2022.pdf",width=12,height=14)
alignment_plot(data_df=soiltemp_data$snow,
               year_seq=2020:2022,
               min_month="1-01",
               max_month="12-31",
               min_y=0,max_y=1,
               col_subset="all",
               ID_text=FALSE)
dev.off()