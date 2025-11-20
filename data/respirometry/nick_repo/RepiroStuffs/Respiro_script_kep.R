### USING RespR to analyse P+R data - Sept. 2019, NRE+DJB script ###
#Eilat version
#To initially DL respR - not yet in CRAN repository
#install.packages("devtools")
#devtools::install_github("januarharianto/respR")

library(respR)

####                            ####
##### Import and organize data #####
####                            ####

# setwd("./data/Ch2/respirometry/nick_repo/RepiroStuffs")
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
  
