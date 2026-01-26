setwd("/Users/dbarshis/dansstuff/Research/EnvironmentalData/Spotter/30365R-1695-Fagatele")

library(tidyverse)
library(RColorBrewer)
library(plyr)
library(dplyr)
library(lubridate)
library(zoo)

mypalette<-c("red","yellow","blue")

SensorDepths<-c("5m","10.5m","35m")

TempData<-read.csv("SPOT-30365R_2022-12-11_2023-05-17_download-sensor-data.csv", stringsAsFactors = F)

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

#calculate mean, max, min and for every 20min
TempData_20min <- TempData %>% 
  group_by(utc_timestamp = floor_date(utc_timestamp, "20 minutes"), sensor_position) %>%
  dplyr::summarize(twentymin_mean = mean(value, na.rm=TRUE), twentymin_max = max(value, na.rm=TRUE), twentymin_min = min(value, na.rm=TRUE))

#TempData_20min$range<-TempData_20min$twentymin_max-TempData_20min$twentymin_min

#TempData_hourly <- TempData %>% 
#  group_by(utc_timestamp = floor_date(utc_timestamp, "hour"), sensor_position) %>%
#  dplyr::summarize(hourly_mean = mean(value, na.rm=TRUE), hourly_max = max(value, na.rm=TRUE), hourly_min = min(value, na.rm=TRUE))

#TempData_hourly$range<-TempData_hourly$hourly_max-TempData_hourly$hourly_min

###########################################################################
################ Calculating recent/heatwave metrics ######################
###########################################################################
Download_Date<-as.Date("2023-05-17") #the most recent data in the data

#American Samoa MMM = 28.9°C
MMM<-28.9

#Approach 1 - using 20min data

#Calculate Hotspots, then convert HSs < 1 to Zeros
TempData_20min$Hotspots<-TempData_20min$twentymin_mean-MMM
TempData_20min$Hotspots<-ifelse(TempData_20min$Hotspots<1,0,TempData_20min$Hotspots)

#Calculate sum of DHDs using a window of 12 days (864 20min increments)

#Shallow
TempData_20min_Shallow<-subset(TempData_20min, sensor_position == 1)
TempData_20min_Shallow$DHD<-c(rep(0,863),rollapply(TempData_20min_Shallow$Hotspots,864,sum))

#Mid
TempData_20min_mid<-subset(TempData_20min, sensor_position == 2)
TempData_20min_mid$DHD<-c(rep(0,863),rollapply(TempData_20min_mid$Hotspots,864,sum))

#Deep
TempData_20min_deep<-subset(TempData_20min, sensor_position == 3)
TempData_20min_deep$DHD<-c(rep(0,863),rollapply(TempData_20min_deep$Hotspots,864,sum))

#Shallow
TempData_shallow_hourly<-subset(TempData_hourly, sensor_position == 1)
TempData_shallow_hourly$DHH<-c(rep(0,23),rollapply(TempData_shallow_hourly$hourly_Hotspots,24,sum))

#Mid
TempData_mid_hourly<-subset(TempData_hourly, sensor_position == 2)
TempData_mid_hourly$DHH<-c(rep(0,23),rollapply(TempData_mid_hourly$hourly_Hotspots,24,sum))

#Deep
TempData_deep_hourly<-subset(TempData_hourly, sensor_position == 3)
TempData_deep_hourly$DHH<-c(rep(0,23),rollapply(TempData_deep_hourly$hourly_Hotspots,24,sum))

MeanHourlyData<-data.frame(group_by(TempData_hourly, sensor_position) %>%
                            summarize(
                              "MeanHourlyRange"=mean(range),
                              "MinHourlyRange"=min(range),
                              "MaxHourlyRange"=max(range),
                              "MeanHourlyMean"=mean(hourly_mean),
                              "MinHourlyMin"=min(hourly_min),
                              "MaxHourlyMax"=max(hourly_max),
                            ))

####Plotting####
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
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)

dev.off()

####plot of Temp SST & DHW####

pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHW for each year under SST, extend y axis to leave room for DHW
par(new=T)
plot(TempData_shallow_hourly$utc_timestamp,TempData_shallow_hourly$DHH,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_mid_hourly$utc_timestamp,TempData_mid_hourly$DHH,type="l",lty=5, col="yellow", lwd=3)
points(TempData_deep_hourly$utc_timestamp,TempData_deep_hourly$DHH,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHH (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()

jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW_black.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHW for each year under SST, extend y axis to leave room for DHW
par(new=T)
plot(TempData_shallow_hourly$utc_timestamp,TempData_shallow_hourly$DHH,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_mid_hourly$utc_timestamp,TempData_mid_hourly$DHH,type="l",lty=5, col="yellow", lwd=3)
points(TempData_deep_hourly$utc_timestamp,TempData_deep_hourly$DHH,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHH (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()


pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW_white.pdf"),11,7)
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=29.9)
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n')
#plot DHW for each year under SST, extend y axis to leave room for DHW
par(new=T)
plot(TempData_shallow_hourly$utc_timestamp,TempData_shallow_hourly$DHH,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20))
points(TempData_mid_hourly$utc_timestamp,TempData_mid_hourly$DHH,type="l",lty=5, col="yellow", lwd=3)
points(TempData_deep_hourly$utc_timestamp,TempData_deep_hourly$DHH,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1)
mtext("DHH (°C day)",cex=1,side=4,line=3)
dev.off()

jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW_white.jpg"), width=14, height=7, units="in", res=300)
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Spotter Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(27,30), col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=29.9)
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n')
#plot DHW for each year under SST, extend y axis to leave room for DHW
par(new=T)
plot(TempData_shallow_hourly$utc_timestamp,TempData_shallow_hourly$DHH,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20))
points(TempData_mid_hourly$utc_timestamp,TempData_mid_hourly$DHH,type="l",lty=5, col="yellow", lwd=3)
points(TempData_deep_hourly$utc_timestamp,TempData_deep_hourly$DHH,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1)
mtext("DHH (°C day)",cex=1,side=4,line=3)
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
