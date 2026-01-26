setwd("/Users/danbarshis/dansstuff/Research/EnvironmentalData/Spotter/30365R-1695-Fagatele")

library(tidyverse)
library(RColorBrewer)
library(plyr)
library(dplyr)
library(lubridate)

mypalette<-c("red","yellow","blue")

SensorDepths<-c("6m","14.5m","39.5m")

TempData<-read.csv("SPOT-30365R_2022-12-10_2023-02-19_download-sensor-data.csv", stringsAsFactors = F)

TempData<-separate(TempData, utc_timestamp, c("Date","Time"), "T", remove=F)
TempData$Time<-gsub(".000Z", "", TempData$Time)

TempData$DateTime<-strptime(paste(TempData$Date, TempData$Time, " "), format = "%Y-%m-%d %H:%M:%S", tz="GMT")
TempData$utc_timestamp<-as_datetime(TempData$utc_timestamp)

min(TempData$DateTime)
max(TempData$DateTime)
tickpos<-seq(as.POSIXct(min(TempData$DateTime)),as.POSIXct(max(TempData$DateTime)),by="1 day")

TempData$Day<-format(TempData$DateTime,"%D")

#calculate mean, max, min daily range (group by day first to extract daily max and min, then daily range)
TempData_daily <- TempData %>% 
  mutate(utc_timestamp = as.Date(utc_timestamp)) %>%
  group_by(utc_timestamp, sensor_position) %>%
  dplyr::summarize(Daily_mean = mean(value, na.rm=TRUE), Daily_max = max(value, na.rm=TRUE), Daily_min = min(value, na.rm=TRUE))

TempData_daily$range<-TempData_daily$Daily_max-TempData_daily$Daily_min

TempData_daily_range_mean<-ddply(TempData_daily, .(sensor_position), summarize, Daily_range_mean=mean(range))
TempData_daily_range_max<-ddply(TempData_daily, .(sensor_position), summarize, Daily_range_max=max(range))
TempData_daily_range_min<-ddply(TempData_daily, .(sensor_position), summarize, Daily_range_min=min(range))

#calculate mean, max, min and hourly range
TempData_hourly <- TempData %>% 
  group_by(utc_timestamp = floor_date(utc_timestamp, "hour"), sensor_position) %>%
  dplyr::summarize(hourly_mean = mean(value, na.rm=TRUE), hourly_max = max(value, na.rm=TRUE), hourly_min = min(value, na.rm=TRUE))

TempData_hourly$range<-TempData_hourly$hourly_max-TempData_hourly$hourly_min

###########################################################################
################ Calculating recent/heatwave metrics ######################
###########################################################################
Download_Date<-as.Date("2023-02-17") #the most recent data in the data

#American Samoa MMM = 28.9°C
MMM<-28.9

#Approach 1 - using daily data

#Calculate Hotspots, then convert HSs < 1 to Zeros
TempData_daily$Daily_Hotspots<-TempData_daily$Daily_mean-MMM
TempData_daily$Daily_Hotspots<-ifelse(TempData_daily$Daily_Hotspots<1,0,TempData_daily$Daily_Hotspots)
#Calculate sum of DHDs across different time ranges - 12, 28, 84 days (removing day of download values to avoid using less than full day's data)

TempData_daily_Shallow<-subset(TempData_daily, sensor_position == 1)
TempData_daily_Shallow_DHD12<-sum(subset(TempData_daily_Shallow$Daily_Hotspots,(Download_Date-13)<TempData_daily_Shallow$utc_timestamp&TempData_daily_Shallow$utc_timestamp<=Download_Date-1))
TempData_daily_Shallow_DHD28<-sum(subset(TempData_daily_Shallow$Daily_Hotspots,(Download_Date-29)<TempData_daily_Shallow$utc_timestamp&TempData_daily_Shallow$utc_timestamp<=Download_Date-1))
TempData_daily_Shallow_DHD84<-sum(subset(TempData_daily_Shallow$Daily_Hotspots,(Download_Date-85)<TempData_daily_Shallow$utc_timestamp&TempData_daily_Shallow$utc_timestamp<=Download_Date-1))

TempData_daily_mid<-subset(TempData_daily, sensor_position == 2)
TempData_daily_mid_DHD12<-sum(subset(TempData_daily_mid$Daily_Hotspots,(Download_Date-13)<TempData_daily_mid$utc_timestamp&TempData_daily_mid$utc_timestamp<=Download_Date-1))
TempData_daily_mid_DHD28<-sum(subset(TempData_daily_mid$Daily_Hotspots,(Download_Date-29)<TempData_daily_mid$utc_timestamp&TempData_daily_mid$utc_timestamp<=Download_Date-1))
TempData_daily_mid_DHD84<-sum(subset(TempData_daily_mid$Daily_Hotspots,(Download_Date-85)<TempData_daily_mid$utc_timestamp&TempData_daily_mid$utc_timestamp<=Download_Date-1))

TempData_daily_deep<-subset(TempData_daily, sensor_position == 3)
TempData_daily_deep_DHD12<-sum(subset(TempData_daily_deep$Daily_Hotspots,(Download_Date-13)<TempData_daily_deep$utc_timestamp&TempData_daily_deep$utc_timestamp<=Download_Date-1))
TempData_daily_deep_DHD28<-sum(subset(TempData_daily_deep$Daily_Hotspots,(Download_Date-29)<TempData_daily_deep$utc_timestamp&TempData_daily_deep$utc_timestamp<=Download_Date-1))
TempData_daily_deep_DHD84<-sum(subset(TempData_daily_deep$Daily_Hotspots,(Download_Date-85)<TempData_daily_deep$utc_timestamp&TempData_daily_deep$utc_timestamp<=Download_Date-1))

#Approach 2 - using hourly data

#Calculate Hotspots, then convert HSs < 1 to Zeros
TempData_hourly$hourly_Hotspots<-TempData_hourly$hourly_mean-MMM
TempData_hourly$hourly_Hotspots<-ifelse(TempData_hourly$hourly_Hotspots<1,0,TempData_hourly$hourly_Hotspots)

#Calculate sum of DHDs across different time ranges - 12, 28, 84 days

#Shallow
TempData_shallow_hourly<-subset(TempData_hourly, sensor_position == 1)
TempData_shallow_hourly_DHD12<-sum(subset(TempData_shallow_hourly$hourly_Hotspots,(Download_Date-13)<TempData_shallow_hourly$utc_timestamp&TempData_shallow_hourly$utc_timestamp<=Download_Date-1))
TempData_shallow_hourly_DHD28<-sum(subset(TempData_shallow_hourly$hourly_Hotspots,(Download_Date-29)<TempData_shallow_hourly$utc_timestamp&TempData_shallow_hourly$utc_timestamp<=Download_Date-1))
TempData_shallow_hourly_DHD84<-sum(subset(TempData_shallow_hourly$hourly_Hotspots,(Download_Date-85)<TempData_shallow_hourly$utc_timestamp&TempData_shallow_hourly$utc_timestamp<=Download_Date-1))

#Mid
TempData_mid_hourly<-subset(TempData_hourly, sensor_position == 2)
TempData_mid_hourly_DHD12<-sum(subset(TempData_mid_hourly$hourly_Hotspots,(Download_Date-13)<TempData_mid_hourly$utc_timestamp&TempData_mid_hourly$utc_timestamp<=Download_Date-1))
TempData_mid_hourly_DHD28<-sum(subset(TempData_mid_hourly$hourly_Hotspots,(Download_Date-29)<TempData_mid_hourly$utc_timestamp&TempData_mid_hourly$utc_timestamp<=Download_Date-1))
TempData_mid_hourly_DHD84<-sum(subset(TempData_mid_hourly$hourly_Hotspots,(Download_Date-85)<TempData_mid_hourly$utc_timestamp&TempData_mid_hourly$utc_timestamp<=Download_Date-1))

#Deep
TempData_deep_hourly<-subset(TempData_hourly, sensor_position == 3)
TempData_deep_hourly_DHD12<-sum(subset(TempData_deep_hourly$hourly_Hotspots,(Download_Date-13)<TempData_deep_hourly$utc_timestamp&TempData_deep_hourly$utc_timestamp<=Download_Date-1))
TempData_deep_hourly_DHD28<-sum(subset(TempData_deep_hourly$hourly_Hotspots,(Download_Date-29)<TempData_deep_hourly$utc_timestamp&TempData_deep_hourly$utc_timestamp<=Download_Date-1))
TempData_deep_hourly_DHD84<-sum(subset(TempData_deep_hourly$hourly_Hotspots,(Download_Date-85)<TempData_deep_hourly$utc_timestamp&TempData_deep_hourly$utc_timestamp<=Download_Date-1))

#Organise DHDs
DHD12<-c(TempData_shallow_hourly_DHD12,TempData_mid_hourly_DHD12,TempData_deep_hourly_DHD12)
DHD28<-c(TempData_shallow_hourly_DHD28,TempData_mid_hourly_DHD28,TempData_deep_hourly_DHD28)
DHD84<-c(TempData_shallow_hourly_DHD84,TempData_mid_hourly_DHD84,TempData_deep_hourly_DHD84)

Full_hourly_DHDs<-data.frame(DHD12,DHD28,DHD84)

MeanData<-data.frame(group_by(TempData_daily, sensor_position) %>%
  summarize(
    "MeanDailyRange"=mean(range),
    "MinDailyRange"=min(range),
    "MaxDailyRange"=max(range),
    "MeanDailyMean"=mean(Daily_mean),
    "MinDayMin"=min(Daily_min),
    "MaxDayMax"=max(Daily_max),
      ))

SiteName="Fagatele"

pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SpotterTempData.pdf"),14,7)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
Site=Sytes[i]
points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
legend("topright", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
dev.off()


jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SpotterTempData.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2,ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2,col=mypalette[i])
}
legend("topright", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)

dev.off()

####plot of Temp SST & DHW####

pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW.pdf"),11,7)
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=29.9)
#axis(1,at=dat$date,tick=F,labels=format(as.Date(dat$date), "%b"))
#plot DHW for each year under SST, extend y axis to leave room for DHW
par(new=T)
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
axis(side=4, cex.axis=1.5)
mtext("DHW (°C week)",cex=1.5,side=4,line=3)
dev.off()


#Custom dates
StartDate="2022-07-08"
EndDate="2022-08-18"
pdf(paste0(StartDate,"_to_",EndDate,"_",SiteName,"_SpotterTempData.pdf"),14,7)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
YLims=c(27,30)
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(StartDate, EndDate)), ylim=YLims, col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
legend("topright", c("5m", "16m", "40m"), lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
dev.off()

sum(TempData$value==0)
sum(filter(TempData, sensor_position==1)$value==0)
sum(filter(TempData, sensor_position==2)$value==0)
sum(filter(TempData, sensor_position==3)$value==0)
