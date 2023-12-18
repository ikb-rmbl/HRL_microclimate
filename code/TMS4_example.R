####Set up workspace####
project_dir <- "~/code/RMBL_microclimate/" ##must have trailing slash
setwd(project_dir)
source("./code/RMBL_microclim_functions.R")

require(data.table)
require(xts)
require(psych)

####Soil temperature data processing####

##Paths of folders to process (all must be absolute paths)
input_paths_soil <- paste(project_dir,c("/data/tms4_test/tms4"),
                          sep="")

#micro_csv("~/code/RMBL_microclimate/data/Airtemp_2021/field2020/Reading1/JC-C.csv")

##Compiles data into a common format with consistent names.
soil_formatted <- format_micro_csv(input_paths=input_paths_soil,
                                   output_path=paste(project_dir,"/temp/soil",sep=""),
                                   file_prefixes=c("TMS_soil"),
                                   output_metadata_filename="metadata_tms_soil.txt",
                                   data_column=4,overwrite=TRUE)

##Cleans soil temperature data, removing spikes and unphysical values.
clean_meta <- clean_soil_temps(input_path=paste(project_dir,"temp/soil",sep=""),
                 input_metadata_filename="metadata_tms_soil.txt",
                 output_path=paste(project_dir,"output/soil",sep=""),
                 output_metadata_filename="metadata_flags_tms_soil.txt",
                 figure_path=paste(project_dir,"figs/soil",sep=""),
                 guess_tz="UTC",temp_spike_thresh=35,tz_tolerance=30,
                 min_temp_thresh=-40,max_temp_thresh=80,max_temp_hr=24,
                 cf_test_params=c(40,160,20,30),
                 overwrite=TRUE)

snow_summaries <- extract_snow_summaries(input_path=paste(project_dir,"output/soil/clean_unflagged",sep=""),
                                         input_metadata_filename=paste(project_dir,"output/soil/metadata_flags_tms_soil.txt",sep=""),
                                         output_path=paste(project_dir,"output/soil",sep=""),
                                         figure_path=paste(project_dir,"figs/soil",sep=""),
                                         output_metadata_filename="metadata_flags_snow.txt",
                                         range_threshold=1,max_threshold=2,overwrite=TRUE)

merge_meta <- merge_micro_csv(input_path=paste(project_dir,"output/soil/clean_unflagged",sep=""),
                file_metadata_path=paste(project_dir,"output/soil/metadata_flags_tms_soil.txt",sep=""),
                file_metadata_join_column="filestem",
                sensor_metadata_path=paste(project_dir,"data/tms4_test/micromet_locations_2020_wgs84.csv",sep=""),
                sensor_metadata_join_column="sub_site",
                output_path = paste(project_dir,"output/soil/merged_hourly/",sep=""),
                output_metadata_path=paste(project_dir,"output/soil/merged_hourly/tms_metadata.txt",sep=""),
                figure_path=paste(project_dir,"figs/soil/merged_hourly",sep=""),
                hour_begin=as.POSIXct("2019-07-01 00:00 MDT"),
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
                                        start_date=as.Date("2020-07-15"),
                                        end_date=as.Date("2021-07-15"),
                                        add_summer_zero=TRUE,
                                        overwrite=TRUE,
                                        return_data=TRUE)

##Plots time-series to check alignment.
alignment_plot(data_df=soiltemp_data$tmax,
               year_seq=2020:2021,
               min_month="01-01",
               max_month="12-31",
               min_y=-8,max_y=35,
               col_subset="all",
               ID_text=TRUE)

##Paths of folders to process (all must be absolute paths)
input_folders_air <- paste(project_dir,c("data/Airtemp_2021/field2020/Reading1",
                                         "data/Airtemp_2021/field2020/Reading2",
                                         "data/Airtemp_2021/field2020/Reading3",
                                         "data/Airtemp_2021/field2020/Reading4",
                                         "data/Airtemp_2021/field2020/Reading5",
                                         "data/Airtemp_2021/field2021/Reading1",
                                         "data/Airtemp_2021/field2021/Reading2",
                                         "data/Airtemp_2021/field2021/Reading3",
                                         "data/Airtemp_2021/field2021/Reading4",
                                         "data/Airtemp_2021/field2021/Reading5",
                                         "data/Airtemp_2021/Sibold_Air_2019_2020"),
                           sep="")

##Gets files in a common format.
format_micro_csv(input_paths=input_folders_air,
                 output_path=paste(project_dir,"temp/air",sep=""),
                 file_prefixes=c("HOBO_air","HOBO_air","HOBO_air","HOBO_air",
                                 "HOBO_air","HOBO_air","HOBO_air","HOBO_air",
                                 "HOBO_air","HOBO_air","HOBO_air"),
                 output_metadata_filename="metadata_air.txt",overwrite=TRUE)

##Remove spikes and unphysical values.
clean_air_temps(input_path=paste(project_dir,"temp/air",sep=""),
                input_metadata_filename="metadata_air.txt",
                output_path=paste(project_dir,"output/air",sep=""),
                output_metadata_filename="metadata_flags_air.txt",
                figure_path=paste(project_dir,"figs/air",sep=""),
                guess_tz="Etc/GMT-7",temp_spike_thresh=45,
                min_temp_thresh=-40,max_temp_thresh=50,max_temp_hr=14,
                cf_test_params=c(40,100,-5,20),
                overwrite=TRUE)

##Merges time-series for known sensor locations.
airtemp_meta <- merge_micro_csv(input_path=paste(project_dir,"output/air/clean_unflagged",sep=""),
                    file_metadata_path=paste(project_dir,"output/air/metadata_flags_air.txt",sep=""),
                    file_metadata_join_column="filestem",
                    sensor_metadata_path=paste(project_dir,"data/Airtemp_2021/micromet_locations_2021_wgs84.csv",sep=""),
                    sensor_metadata_join_column="air_sensor_name",
                    output_path = paste(project_dir,"output/air/merged_hourly/",sep=""),
                    output_metadata_path=paste(project_dir,"output/air/merged_hourly/metadata.txt",sep=""),
                    figure_path=paste(project_dir,"figs/air/merged_hourly",sep=""),
                    hour_begin=as.POSIXct("2019-07-01 00:00 MDT"),
                    hour_end=as.POSIXct("2021-11-02 00:00 MDT"),
                    tzone="Etc/GMT-7",
                    interp_gap_max=6,
                    overwrite=TRUE)

summarise_airtemp_daily(input_path=paste(project_dir,"output/air/merged_hourly",sep=""),
                        output_path=paste(project_dir,"output/air/summarised_daily",sep=""),
                        overwrite=TRUE,
                        trim=TRUE)

airtemp_data <- compile_airtemp_daily(input_path=paste(project_dir,"output/air/summarised_daily",sep=""),
                                      output_file_tavg=paste(project_dir,"output/air/RMBL_Sibold_merged_daily_2019_2021_tavg.csv",sep=""),
                                      output_file_tmin=paste(project_dir,"output/air/RMBL_Sibold_merged_daily_2019_2021_tmin.csv",sep=""),
                                      output_file_tmax=paste(project_dir,"output/air/RMBL_Sibold_merged_daily_2019_2021_tmax.csv",sep=""),
                                      start_date=as.Date("2019-07-01"),
                                      end_date=as.Date("2021-10-31"),
                                      overwrite=TRUE,
                                      return_data=TRUE)

##Plots time-series to check alignment.
alignment_plot(data_df=airtemp_data$tmin,
               year_seq=2019:2021,
               min_month="01-01",
               max_month="12-31",
               min_y=-30,max_y=35,
               col_subset="all",
               ID_text=TRUE)
