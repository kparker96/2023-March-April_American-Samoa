setwd("/Users/dbarshis/dansstuff/Research/EnvironmentalData/Spotter/30365R-1695-Fagatele")

library(tidyverse)
library(RColorBrewer)
library(plyr)
library(dplyr)
library(lubridate)
library(zoo)

mypalette<-c("red","yellow","blue")

SensorDepths<-c("5m","10.5m","40m")

TempData<-read.csv("SPOT-30365R_2022-12-11_2024-05-04_download-sensor-data.csv", stringsAsFactors = F)

TempData<-separate(TempData, utc_timestamp, c("Date","Time"), "T", remove=F)
TempData$Time<-gsub(".000Z", "", TempData$Time)

TempData$utc_timestamp<-as_datetime(TempData$utc_timestamp)
TempData$DateTime<-strptime(paste(TempData$Date, TempData$Time, " "), format = "%Y-%m-%d %H:%M:%S", tz="GMT")

min(TempData$DateTime)
max(TempData$DateTime)
tickpos<-seq(as.POSIXct(min(TempData$DateTime)),as.POSIXct(max(TempData$DateTime)),by="1 day")

TempData$Day<-format(TempData$DateTime,"%D")
TempData$value[TempData$value==0]<-NA
TempData$value[TempData$value<23]<-NA
TempData$value[TempData$value>40]<-NA

summary(TempData[TempData$sensor_position==1,"value"])
summary(TempData[TempData$sensor_position==2,"value"])
summary(TempData[TempData$sensor_position==3,"value"])

#calculate mean, max, min daily range (group by day first to extract daily max and min, then daily range)
TempData_daily <- TempData %>% 
  mutate(utc_timestamp = as.Date(utc_timestamp)) %>%
  group_by(utc_timestamp, sensor_position) %>%
  dplyr::summarize(Daily_mean = mean(value, na.rm=TRUE), Daily_max = max(value, na.rm=TRUE), Daily_min = min(value, na.rm=TRUE))

TempData_daily$range<-TempData_daily$Daily_max-TempData_daily$Daily_min
TempData_daily$utc_timestamp<-as.POSIXct(TempData_daily$utc_timestamp)
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

#American Samoa MMM = 28.9°C
MMM<-28.9

####Degree Heating Weeks using daily data####
TempData_daily$Hotspots<-TempData_daily$Daily_mean-MMM
TempData_daily$Hotspots<-ifelse(TempData_daily$Hotspots<1,0,TempData_daily$Hotspots)

TempData_daily_shal<-as.data.frame(TempData_daily %>%
                                     filter(sensor_position==1))
TempData_daily_mid<-as.data.frame(TempData_daily %>%
                                    filter(sensor_position==2))

#DHW = the accumulation of HotSpots at that location over a rolling 12-week time period,84 is no of days
TempData_daily_shal$DHW<-c(rep(0,83),rollapply(TempData_daily_shal$Hotspots,84,sum))/7
TempData_daily_mid$DHW<-c(rep(0,83),rollapply(TempData_daily_mid$Hotspots,84,sum))/7

####Degree Heating Days using 20min data####

#Calculate Hotspots, then convert HSs < 1 to Zeros
TempData_20min$Hotspots<-TempData_20min$twentymin_mean-MMM
TempData_20min$Hotspots<-ifelse(TempData_20min$Hotspots<1,0,TempData_20min$Hotspots)

#Calculate sum of DHDs using a window of 12 days (864 20min increments)

#Shallow
TempData_20min_shallow<-subset(TempData_20min, sensor_position == 1)
TempData_20min_shallow$DHD<-c(rep(0,863),rollapply(TempData_20min_shallow$Hotspots,864,sum))/72

#Mid
TempData_20min_mid<-subset(TempData_20min, sensor_position == 2)
TempData_20min_mid$DHD<-c(rep(0,863),rollapply(TempData_20min_mid$Hotspots,864,sum))/72

#Deep
TempData_20min_deep<-subset(TempData_20min, sensor_position == 3)
TempData_20min_deep$DHD<-c(rep(0,863),rollapply(TempData_20min_deep$Hotspots,864,sum))/72

####Plotting####
SiteName="Fagatele"

pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SpotterTempData_black.pdf"),14,7)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
Site=Sytes[i]
points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, lwd=1, col="white")
legend("topright", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
dev.off()


jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SpotterTempData_black.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2,ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2,col=mypalette[i])
}
abline(h=MMM+1, lwd=1, col="white")
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
dev.off()

####plot of Temp SST & DHW####
pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHW_black.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHW for each sensor under SST, extend y axis to leave room for DHW
par(new=T)
plot(TempData_daily_shal$utc_timestamp,TempData_daily_shal$DHW,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,10), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_daily_mid$utc_timestamp,TempData_daily_mid$DHW,type="l",lty=5, col="yellow", lwd=3)
#points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHW (°C week)",cex=1,side=4,line=3 ,col="white")
dev.off()

####plot of Temp SST & DHD####

pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_black.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,25), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()

jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_black.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()


pdf(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_white.pdf"),11,7)
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1)
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n')
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20))
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1)
mtext("DHD (°C day)",cex=1,side=4,line=3)
dev.off()

jpeg(paste0(min(TempData$Date),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_white.jpg"), width=14, height=7, units="in", res=300)
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1)
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n')
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20))
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1)
mtext("DHD (°C day)",cex=1,side=4,line=3)
dev.off()

####Custom dates####
StartDate="2023-06-11"
EndDate="2023-08-04"
pdf(paste0(StartDate,"_to_",EndDate,"_",SiteName,"_SST_vs_DHD_black.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n', xlim=as.POSIXct(c(StartDate, EndDate)), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,25), xlim=as.POSIXct(c(StartDate, EndDate)), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()

pdf(paste0(StartDate,"_to_",EndDate,"_",SiteName,"_SST_vs_DHW_black.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n', xlim=as.POSIXct(c(StartDate, EndDate)), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_daily_shal$utc_timestamp,TempData_daily_shal$DHW,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,10), xlim=as.POSIXct(c(StartDate, EndDate)), col.axis="white", col.main="white",col.lab="white", fg="white")
points(TempData_daily_mid$utc_timestamp,TempData_daily_mid$DHW,type="l",lty=5, col="yellow", lwd=3)
#points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHW (°C week)",cex=1,side=4,line=3 ,col="white")
dev.off()


pdf(paste0(StartDate,"_to_",EndDate,"_",SiteName,"_SpotterTempData.pdf"),14,7)
par(bg="black")
Sytes=c(1,2,3)
Site=Sytes[1]
YLims=c(25,30)
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(StartDate, EndDate)), ylim=YLims, col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
legend("topright", c("5m", "16m", "40m"), lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
dev.off()
# 
# sum(TempData$value==0)
# sum(filter(TempData, sensor_position==1)$value==0)
# sum(filter(TempData, sensor_position==2)$value==0)
# sum(filter(TempData, sensor_position==3)$value==0)
# 

####Daily boxplots####
StartDate="2023-06-11"
EndDate="2023-08-04"
as.POSIXct(c(StartDate, EndDate))

CustomDaily<-TempData_daily[TempData_daily$utc_timestamp>as.POSIXct(StartDate)&TempData_daily$utc_timestamp<as.POSIXct(EndDate),]
summary(CustomDaily)
aggregate(Daily_mean ~ sensor_position, data=CustomDaily, summary)
aggregate(range ~ sensor_position, data=CustomDaily, summary)

t.test(CustomDaily[CustomDaily$sensor_position==3,"Daily_mean"], CustomDaily[CustomDaily$sensor_position==1,"Daily_mean"], alternative="less")
t.test(CustomDaily[CustomDaily$sensor_position==3,"range"], CustomDaily[CustomDaily$sensor_position==1,"range"], alternative="greater")
CustomDailyDeepShallow <- CustomDaily[CustomDaily$sensor_position==1|CustomDaily$sensor_position==3,]
Shallow="2m"
Deep="37m"

pdf("FagateleDailyBoxplots.pdf",14, 7)
par(mfrow=c(1,2), bg="black")
boxplot(range~sensor_position, data=CustomDailyDeepShallow, main = "Daily Temperature Range °C", col.main="white",cex.main=2,xlab = "Depth", ylab = "Temperature °C",notch=T, col="dodgerblue",col.axis="white", col.lab="white", fg="white", border="white", cex.lab=1.45,cex.axis=2, names=c(Shallow, Deep))
axis(side = 1,col="white", labels=F)
axis(side = 2, col="white", labels=F)
boxplot(Daily_mean~sensor_position, data=CustomDailyDeepShallow, main = "Daily Temperature Mean °C", col.main="white", cex.main=2,xlab = "Depth", ylab = "Temperature °C",notch=T, col="dodgerblue",col.axis="white", col.lab="white", fg="white", border="white",cex.lab=1.45,cex.axis=2, names=c(Shallow, Deep))
axis(side = 1,col="white", labels=F)
axis(side = 2, col="white", labels=F)
dev.off()

####Adding full year####
FagateleDeep<-read.delim("Fagatele_Deep_ODU_clean.txt")
FagateleDeep$DateTime<-strptime(FagateleDeep$DateTime, format="%m/%d/%y %I:%M:%S %p")
FagateleDeep$Day<-format(FagateleDeep$DateTime,"%D")
FagateleDeepdaily<-data.frame("DayRange"=tapply(FagateleDeep$Fagatele_Deep_ODU, FagateleDeep$Day, function(x) range(x)[2]-range(x)[1]),"DayMin"=tapply(FagateleDeep$Fagatele_Deep_ODU, FagateleDeep$Day, min),"DayMax"=tapply(FagateleDeep$Fagatele_Deep_ODU, FagateleDeep$Day, max), "DayMean"=tapply(FagateleDeep$Fagatele_Deep_ODU, FagateleDeep$Day, mean))
summary(FagateleDeepdaily)

FagateleShallow<-read.delim("Fagatele_Shallow_ODU_clean.txt")
FagateleShallow$DateTime<-strptime(FagateleShallow$DateTime, format="%m/%d/%y %I:%M:%S %p")
FagateleShallow$Day<-format(FagateleShallow$DateTime,"%D")
FagateleShallowdaily<-data.frame("DayRange"=tapply(FagateleShallow$Fagatele_Shallow_ODU, FagateleShallow$Day, function(x) range(x)[2]-range(x)[1]),"DayMin"=tapply(FagateleShallow$Fagatele_Shallow_ODU, FagateleShallow$Day, min),"DayMax"=tapply(FagateleShallow$Fagatele_Shallow_ODU, FagateleShallow$Day, max), "DayMean"=tapply(FagateleShallow$Fagatele_Shallow_ODU, FagateleShallow$Day, mean))
summary(FagateleShallowdaily)

####MergingHobo and Spotter Data####
ShallowDailyMerged<-cbind("Date"=row.names(FagateleShallowdaily), FagateleShallowdaily)
names(ShallowDailyMerged)
names(TempData_daily)
TempData_daily_shallow<-TempData_daily %>%
  filter(sensor_position==1)
TempData_daily_shallow<-cbind("Date"=TempData_daily_shallow$utc_timestamp, 
                                      "DayRange"=TempData_daily_shallow$range,
                                      "DayMin"=TempData_daily_shallow$Daily_min,
                                      "DayMax"=TempData_daily_shallow$Daily_max,
                                      "DayMean"=TempData_daily_shallow$Daily_mean)
ShallowDailyMerged<-rbind(ShallowDailyMerged, TempData_daily_shallow)

DeepDailyMerged<-cbind("Date"=row.names(FagateleDeepdaily), FagateleDeepdaily)
names(DeepDailyMerged)
names(TempData_daily)
TempData_daily_Deep<-TempData_daily %>%
  filter(sensor_position==3)
TempData_daily_Deep<-cbind("Date"=TempData_daily_Deep$utc_timestamp, 
                              "DayRange"=TempData_daily_Deep$range,
                              "DayMin"=TempData_daily_Deep$Daily_min,
                              "DayMax"=TempData_daily_Deep$Daily_max,
                              "DayMean"=TempData_daily_Deep$Daily_mean)
DeepDailyMerged<-rbind(DeepDailyMerged, TempData_daily_Deep)

summary(DeepDailyMerged)
summary(ShallowDailyMerged)

t.test(DeepDailyMerged$DayMean, ShallowDailyMerged$DayMean, alternative="less")
t.test(DeepDailyMerged$DayRange, ShallowDailyMerged$DayRange, alternative="greater")

AllDailysMerge<-cbind(ShallowDailyMerged,"Depth"="05m")
AllDailysMerge<-rbind(AllDailysMerge,cbind(DeepDailyMerged,"Depth"="40m"))	

pdf("FagateleDailyBoxplots.pdf",14, 7)
par(mfrow=c(1,2), bg="black")
boxplot(DayRange~Depth, data=AllDailysMerge, main = "Daily Temperature Range °C", col.main="white",cex.main=2,xlab = "Depth", ylab = "Temperature °C",notch=T, col="dodgerblue",col.axis="white", col.lab="white", fg="white", border="white", cex.lab=1.45,cex.axis=2)
axis(side = 1,col="white", labels=F)
axis(side = 2, col="white", labels=F)
boxplot(DayMean~Depth, data=AllDailysMerge, main = "Daily Temperature Mean °C", col.main="white", cex.main=2,xlab = "Depth", ylab = "Temperature °C",notch=T, col="dodgerblue",col.axis="white", col.lab="white", fg="white", border="white",cex.lab=1.45,cex.axis=2)
axis(side = 1,col="white", labels=F)
axis(side = 2, col="white", labels=F)
dev.off()

#calculate mean, max, min and for every 20min
FagateleDeep_20min <- FagateleDeep %>% 
  group_by(DateTime = floor_date(DateTime, "20 minutes")) %>%
  dplyr::summarize(twentymin_mean = mean(Fagatele_Deep_ODU, na.rm=TRUE), twentymin_max = max(Fagatele_Deep_ODU, na.rm=TRUE), twentymin_min = min(Fagatele_Deep_ODU, na.rm=TRUE))

#Calculate Hotspots, then convert HSs < 1 to Zeros
FagateleDeep_20min$Hotspots<-FagateleDeep_20min$twentymin_mean-MMM
FagateleDeep_20min$Hotspots<-ifelse(FagateleDeep_20min$Hotspots<1,0,FagateleDeep_20min$Hotspots)

####Calculate sum of DHDs using a window of 12 days (864 20min increments)####

#Deep
FagateleDeep_20min$DHD<-c(rep(0,863),rollapply(FagateleDeep_20min$Hotspots,864,sum))/72

FagateleShallow_20min <- FagateleShallow %>% 
  group_by(DateTime = floor_date(DateTime, "20 minutes")) %>%
  dplyr::summarize(twentymin_mean = mean(Fagatele_Shallow_ODU, na.rm=TRUE), twentymin_max = max(Fagatele_Shallow_ODU, na.rm=TRUE), twentymin_min = min(Fagatele_Shallow_ODU, na.rm=TRUE))

#Calculate Hotspots, then convert HSs < 1 to Zeros
FagateleShallow_20min$Hotspots<-FagateleShallow_20min$twentymin_mean-MMM
FagateleShallow_20min$Hotspots<-ifelse(FagateleShallow_20min$Hotspots<1,0,FagateleShallow_20min$Hotspots)

#Calculate sum of DHDs using a window of 12 days (864 20min increments)

#Shallow
FagateleShallow_20min$DHD<-c(rep(0,863),rollapply(FagateleShallow_20min$Hotspots,864,sum))/72

min(FagateleDeep_20min$DateTime)
max(TempData$DateTime)
tickpos<-seq(as.POSIXct(min(FagateleDeep_20min$DateTime)),as.POSIXct(max(TempData$DateTime)),by="1 day")

####plot of Temp SST & DHW####

pdf(paste0(min(FagateleDeep_20min$DateTime),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_black_alldata.pdf"),11,7)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow$DateTime,FagateleShallow$Fagatele_Shallow_ODU, type="l", lwd=2, col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
points(FagateleDeep$DateTime,FagateleDeep$Fagatele_Deep_ODU, type="l", lwd=2, col=mypalette[3])
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20), xlim=as.POSIXct(c(min(tickpos), max(tickpos))), col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow_20min$DateTime,FagateleShallow_20min$DHD,type="l",lty=5, col="red", lwd=3)
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
points(FagateleDeep_20min$DateTime,FagateleDeep_20min$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()

jpeg(paste0(min(FagateleDeep_20min$DateTime),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_black_alldata.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,2,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow$DateTime,FagateleShallow$Fagatele_Shallow_ODU, type="l", lwd=2, col=mypalette[1])
for(i in 2:length(Sytes)){
  Site=Sytes[i]
  points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
}
points(FagateleDeep$DateTime,FagateleDeep$Fagatele_Deep_ODU, type="l", lwd=2, col=mypalette[3])
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths, lty=1, lwd=3, col=mypalette, bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',ylim=c(0.5,20), xlim=as.POSIXct(c(min(tickpos), max(tickpos))), col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow_20min$DateTime,FagateleShallow_20min$DHD,type="l",lty=5, col="red", lwd=3)
points(TempData_20min_mid$utc_timestamp,TempData_20min_mid$DHD,type="l",lty=5, col="yellow", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
points(FagateleDeep_20min$DateTime,FagateleDeep_20min$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=1, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=1,side=4,line=3 ,col="white")
dev.off()

jpeg(paste0(min(FagateleDeep_20min$DateTime),"_to_",max(TempData$Date),"_",SiteName,"_SST_vs_DHD_black_alldata_forppt.jpg"), width=14, height=7, units="in", res=300)
par(bg="black")
par(mar=c(5,5,3,5))
#plot SST for each sensor
Sytes=c(1,3)
Site=Sytes[1]
plot(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, ylab="Water Temp °C", xlab="Date", main=paste0(SiteName," Temperature Data"),cex.main=2,cex.lab=2, cex.axis=2, xaxt='n',xlim=as.POSIXct(c(min(tickpos), max(tickpos))), ylim=c(25,31.5), col=mypalette[1],col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow$DateTime,FagateleShallow$Fagatele_Shallow_ODU, type="l", lwd=2, col=mypalette[1])
Site=Sytes[2]
points(filter(TempData, sensor_position==Site)$DateTime,filter(TempData, sensor_position==Site)$value, type="l", lwd=2, col=mypalette[i])
points(FagateleDeep$DateTime,FagateleDeep$Fagatele_Deep_ODU, type="l", lwd=2, col=mypalette[3])
abline(h=MMM+1, col="white")
axis.POSIXct(side=1, at=tickpos, format="%Y-%b-%d",col="white", col.axis="white",cex.axis=1)
legend("bottomleft", SensorDepths[c(1,3)], lty=1, lwd=3, col=mypalette[c(1,3)], bty='n', text.col="white")
#plot DHD for each sensor under SST, extend y axis to leave room for DHD
par(new=T)
plot(TempData_20min_shallow$utc_timestamp,TempData_20min_shallow$DHD,type="l",lty=5, col="red", lwd=3, xaxt='n', xlab='',yaxt='n', ylab='',xlim=as.POSIXct(c(min(tickpos), max(tickpos))),ylim=c(0.5,20), col.axis="white", col.main="white",col.lab="white", fg="white")
points(FagateleShallow_20min$DateTime,FagateleShallow_20min$DHD,type="l",lty=5, col="red", lwd=3)
points(TempData_20min_deep$utc_timestamp,TempData_20min_deep$DHD,type="l",lty=5, col="blue", lwd=3)
points(FagateleDeep_20min$DateTime,FagateleDeep_20min$DHD,type="l",lty=5, col="blue", lwd=3)
axis(side=4, cex.axis=2, col.axis="white", col.main="white",col.lab="white", fg="white")
mtext("DHD (°C day)",cex=2,side=4,line=3 ,col="white")
dev.off()