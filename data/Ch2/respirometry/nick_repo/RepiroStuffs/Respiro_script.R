### USING RespR to analyse P+R data - Sept. 2019, NRE+DJB script ###
#Eilat version
#To initially DL respR - not yet in CRAN repository
#install.packages("devtools")
#devtools::install_github("januarharianto/respR")

library(respR)

####                            ####
##### Import and organise data #####
####                            ####

setwd("/Users/nicolasevensen/Documents/ODU_Post-doc/2019-01_Eilat/RepiroStuffs")
filelist<-read.delim("./filelist_check.txt")
paste(filelist[1,1])

####Quick loop to make plots to inspect data
for (Data_row in 1:nrow(filelist)) {
  data<-read.delim(paste0("./cleaned/",filelist[Data_row,1]), na.strings = '---')
  data<-data[,3:7]
  Channel<-c("Ch1","Ch2","Ch3","Ch4")
  for (Column in 1:4)
  {
    pdf(paste0('./check_plots/',filelist[Data_row,Channel[Column]],".pdf"))
    inspect(data[,c(1,Column+1)])
    dev.off()
  }
}
  
  ####Main rate calling loop
  Master_resp<-read.table(text="",col.names=c("Sample_name","intercept_b0","rate_b1","rsq",
                                              "row","endrow","time","endtime","oxy","endoxy","rowlength","timelength","rate_twopoint"))
  Master_photo<-read.table(text="",col.names=c("Sample_name","intercept_b0","rate_b1","rsq",
                                               "row","endrow","time","endtime","oxy","endoxy","rowlength","timelength","rate_twopoint"))
  filelist<-read.delim("./filelist.txt")
  paste(filelist[1,4])
  
  for (Data_row in 1:nrow(filelist)){
    Filename<-filelist[Data_row,1]
    data<- read.delim(paste0("./cleaned/",Filename), na.strings = '---')
    data<-data[,3:7]
    Channel<-c("Ch1","Ch2","Ch3","Ch4")
    RespS<-c("Ch1RS","Ch2RS","Ch3RS","Ch4RS")
    RespE<-c("Ch1RE","Ch2RE","Ch3RE","Ch4RE")
    PhotoS<-c("Ch1PS","Ch2PS","Ch3PS","Ch4PS")
    PhotoE<-c("Ch1PE","Ch2PE","Ch3PE","Ch4PE")
    for (Column in 1:4)
    {
      Sample_name<-filelist[Data_row,Channel[Column]]
      #Respiration calculations
      Resp<-calc_rate(data[,c(1,Column+1)], from = filelist[Data_row,RespS[Column]], to = filelist[Data_row,RespE[Column]], by = "time", plot = TRUE)
      pdf(paste0('./full_plots/',filelist[Data_row,Channel[Column]],"_Resp.pdf"))
      plot(Resp)
      dev.off()
      #Respiration rates
      Resp$summary
      routput<- cbind("Sample_name"=Sample_name,Resp$summary)
      Master_resp<-rbind(Master_resp,routput)
      
      #Photosynthesis calculations
      Photo<-calc_rate(data[,c(1,Column+1)], from = filelist[Data_row,PhotoS[Column]], to = filelist[Data_row,PhotoE[Column]], by = "time", plot = TRUE)
      pdf(paste0('./full_plots/',filelist[Data_row,Channel[Column]],"_Photo.pdf"))
      plot(Photo)
      dev.off()
      #Respiration rates
      Photo$summary
      poutput<- cbind("Sample_name"=Sample_name,Photo$summary)
      Master_photo<-rbind(Master_photo,poutput)
      
    }
  }
  
  write.csv(Master_photo,'Master_photo.csv')
  write.csv(Master_resp,'Master_resp.csv')
  
  ######################################################################
  ######################################################################
  #### OLD CODE - one by one
  ######################################################################
  ######################################################################
  
  data<- read.delim("./data/cleaned", na.strings = '---')
  View(data) #Very important to have "na.strings = '---'" as any of the faulty "---" readings will otherwise convert that column to a factor
  inspect(data) #Plots the 4 columns - helpful to visualise data to make sure cut offs are correct
  
  data1<-read.delim("2019_08_09_TPC_Por_36.5_5-8_cleaned.txt", na.strings = '---')
  data1.1<-data1[,c(3,5)]
  inspect(data1.1)
  
  ####                                        ####
  ##### use .bg to calculate background rate #####
  ####                                       ####
  Control1<-calc_rate.bg(data, time = 1 , oxygen = 2)
  print(Control1)
  
  ####                                                                                               ####
  ##### Create separate dataframes for each sample, then calculate sample resp/photosynthesis rates #####
  ####                                                                                               ####
  
  ### Sample 1 - i.e., Ex1
  Sample1<-data[,c(1,3)]
  plot(Sample1)
  
  Resp1<-calc_rate(Sample1, from = 120, to = 2000, by = "time", plot = TRUE)
  #started at 1 min/60 sec in case the beginning is glitchy, then use mins from filelist to define end
  print(Resp1)
  summary(Resp1)
  plot(Resp1)
  
  Photo1<-calc_rate(Sample1, from = (42*60), to = 4500, by = "time", plot = TRUE)
  #started at 5 mins after lights went on, then used plot to define the end
  print(Photo1)
  summary(Photo1)
  plot(Photo1)
  
  ### Sample 2 - i.e., Ex2
  Sample2<-data[,c(1,4)]
  plot(Sample2)
  
  Resp2<-calc_rate(Sample2, from = 60, to = (37*60), by = "time", plot = TRUE)
  print(Resp2)
  summary(Resp2)
  plot(Resp2)
  
  Photo2<-calc_rate(Sample2, from = (42*60), to = 4000, by = "time", plot = TRUE)
  print(Photo2)
  summary(Photo2)
  plot(Photo2)
  
  ### Sample 3 - i.e., Ex3
  Sample3<-data[,c(1,5)]
  plot(Sample3)
  
  Resp3<-calc_rate(Sample3, from = 60, to = (37*60), by = "time", plot = TRUE)
  print(Resp3)
  summary(Resp3)
  plot(Resp3)
  
  Photo3<-calc_rate(Sample3, from = (45*60), to = 5000, by = "time", plot = TRUE) #visually adjusted start and end times based on plot
  print(Photo3)
  summary(Photo3)
  plot(Photo3)
  
  ####                                                                    ####
  ##### Adjust for background rate and convert rates with chamber volume #####
  ####                                                                    ####
  
  a.rate1 <- adjust_rate(0.000988204715303361, 0)
  print(a.rate1)
  convert_rate(a.rate1, 
               o2.unit = "ml/L",
               time.unit = "sec",S=40, t=22,
               output.unit = "umol/h", 
               volume =0.079470) #Then need to standardise to cm2 and to specific chamber volume to get umol/cm2/hour once we have SA measurements from TubeyTimTamPamScanMan
  