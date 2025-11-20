# Respirometry Data Collection and Analysis Pipeline  

**Author:** Katie Parker  

---  

This directory contains the analysis pipeline for respirometry data collected on a PreSens Oxy-10 mini.

---
raw data example:  
	
	4/2/2023/9:36 AM SW ver:OXY10v3_33
	Header Ch-1
	Description: Deep_Extra_01
	IDENTIFICATION
	PHIboard number   : v1231473
	PM number         : 00000000
	Serial number     : S DLK 0001 000022   
	MUX channel       : ON - 01
	
	PARAMETERS
	Signal LED current: 050
	Ref LED current   : 076
	Ref LED amplitude : 98678
	Frequency         : 006
	Sending interval  : 0001
	Averaging         : 3
	Internal temp     : 20.0 C
	
	SYSTEM SETTINGS
	APL function      : ON
	Temp compensation : OFF
	Analog out        : OFF
	RS232 echo        : OFF
	Oxygen unit       : %a.s.
	
	CALIBRATION
	Sensor type       : 2
	0%a.s.phase 1     : 58.45 at 029.0°C amp 030300
	100.00%a.s.phase 2: 26.34 at 029.0°C amp 015300
	Date   (ddmmyy)   : 270313
	Pressure (mBar)   : 1013
	
	FIRMWARE
	Code 3.016 (IAP)  : 08/20/04, 09:50:56
	Xilinx built      : 01/05/04 (MM/DD/YY)
	
	Pressure [hPa]: 1013
	Date/dd:mm:yy;Time/hh:mm:ss;Logtime/min;Oxy/% air sat.;Phase/°;Amp;Temp/°C
	4/2/2023;9:36:34 AM;0.00;83.150;28.280;11409.000;29.000
	4/2/2023;9:36:36 AM;0.02;83.040;28.300;11400.000;29.000
	4/2/2023;9:36:44 AM;0.16;83.000;28.300;11402.000;29.000
	4/2/2023;9:36:59 AM;0.41;82.270;28.400;11410.000;29.000
	4/2/2023;9:37:14 AM;0.66;82.610;28.350;11398.000;29.000
	4/2/2023;9:37:29 AM;0.91;82.140;28.420;11413.000;29.000
	4/2/2023;9:37:44 AM;1.16;82.240;28.400;11438.000;29.000
	4/2/2023;9:37:59 AM;1.41;81.960;28.440;11428.000;29.000
	...

Running the OxyFileClean\_and\_HeaderChange.py script to clean up raw data files 

	## Cleaning up raw PreSens files for analysis in R using OxyFileClean\_and\_HeaderChange.py  script  
	
	#!/usr/bin/env python
	
	Usage = '''
	Usage:
		OxyFileClean_and_HeaderChange.py HeaderLine.txt Infiles
	'''
	
	#####
	# This update to the SuperOxyCalc_djb.py script takes each input .txt file from the Oxy
	# and spits out a 'cleaned' version that includes the raw oxygen values corrected for the
	# calculations that are done by the original PreSens_cracked.xlsx spreadsheet
	# This script also changes the header line to the desired format for R import
	
	Debug=False
	
	import os
	import sys
	import time
	import fileinput
	from math import *
	
	StartTime = time.time()
	
	
	def TimeConvert(TimeString):
		# Function to convert time string to 24-hour format
		if "PM" in TimeString:
			TimeList = TimeString.split("/")[0].split(":")
			if TimeList[0] == '12':
				MilTime = '%s' % (":".join(TimeList))
			else:
				MilTime = '%s:%s:%s' % (12 + int(TimeList[0]), TimeList[1], TimeList[2])
		else:
			if "AM" in TimeString:
				TimeList = TimeString.split("/")[0].split(":")
				if TimeList[0] == '12':
					MilTime = '0:%s' % (":".join(TimeList[1:]))
				else:
					if TimeList[0] in range(1, 9):
						MilTime = '0%s' % (":".join(TimeList))
					else:
						MilTime = TimeString.split("/")[0]
		return MilTime
	
	
	def OxyCalcPt1(Phase, Temp):
		# Function to calculate oxygen values
		Salin = float('35') #change this for different salinity
		Phase = float(Phase) #phase from datarow column 5 (python 4) E19 for first row
		Cal0 = float(60.62) #$B$6 from presense xcel sheet CHANGE FOR NEW SPOTS
		Cal100 = float(27.68) #$B$7 from presense xcel sheet CHANGE FOR NEW SPOTS
		AirPres = float(1013) #$B$8 from presense xcel sheet CHANGE FOR NEW SPOTS
		F1const = float(0.808)  #$B$11 from presense xcel sheet
		DelPhiK = float(-0.08255) #$B$12 from presense xcel sheet
		DelKsvK = float(0.000492) #$B$13 from presense xcel sheet
		Mconst = float(29.87) #$B$14 from presense xcel sheet
		Temp = float(Temp) #temp from datarow column 7 (python 6) G19 for first row
		T0Temp = float(20) #$E$6 from presense xcel sheet CHANGE FOR NEW SPOTS
		T100Temp = float(20) #$E$7 from presense xcel sheet CHANGE FOR NEW SPOTS
		KsvT100 = float(0.0514271) #$H$11 from presense xcel sheet
	
	
		PercAirSat = (-((tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*(KsvT100+(DelKsvK*(Temp-T100Temp)))+(tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*1/Mconst*(KsvT100+(DelKsvK*(Temp-T100Temp)))-F1const*1/Mconst*(KsvT100+(DelKsvK*(Temp-T100Temp)))-(KsvT100+(DelKsvK*(Temp-T100Temp)))+F1const*(KsvT100+(DelKsvK*(Temp-T100Temp))))+(sqrt((pow(((tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*(KsvT100+(DelKsvK*(Temp-T100Temp)))+(tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*1/Mconst*(KsvT100+(DelKsvK*(Temp-T100Temp)))-F1const*1/Mconst*(KsvT100+(DelKsvK*(Temp-T100Temp)))-(KsvT100+(DelKsvK*(Temp-T100Temp)))+F1const*(KsvT100+(DelKsvK*(Temp-T100Temp)))),2))-4*((tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*1/Mconst*pow((KsvT100+(DelKsvK*(Temp-T100Temp))),2))*((tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))-1))))/(2*((tan(Phase*pi/180))/(tan((Cal0+(DelPhiK*(Temp-T0Temp)))*pi/180))*1/Mconst*pow((KsvT100+(DelKsvK*(Temp-T100Temp))),2)))
		PercO2 = PercAirSat*20.95/100
		P02HpA = (AirPres-exp(52.57-6690.9/(273.15+Temp)-4.681*log(273.15+Temp)))*PercAirSat/100*0.2095
		P02Torr = P02HpA/1.33322
		CO2MgL = ((AirPres-exp(52.57-6690.9/(273.15+Temp)-4.681*log(273.15+Temp)))/1013)*PercAirSat/100*0.2095*(48.998-1.335*Temp+0.02755*pow(Temp,2)-0.000322*pow(Temp,3)+0.000001598*pow(Temp,4))*32/22.414
		CO2umolL = CO2MgL*31.25
		Sheet1Data = ['%.6f'%PercAirSat, '%.7f'%PercO2, '%.6f'%P02HpA, '%.6f'%P02Torr, '%.8f'%CO2MgL, '%.6f'%CO2umolL]
		
		Chlorin = (Salin-0.03)/1.805
		FinalCO2MgL = ((AirPres-exp(52.57-6690.9/(273.15+Temp)-4.681*log(273.15+Temp)))/1013)*PercAirSat/100*0.2095*((49-1.335*Temp+0.02759*pow(Temp,2)-0.0003235*pow(Temp,3)+0.000001614*pow(Temp,4))-(Chlorin*(5.516*pow(10,-1)-1.759*pow(10,-2)*Temp+2.253*pow(10,-4)*pow(Temp,2)-2.654*pow(10,-7)*pow(Temp,3)+5.363*pow(10,-8)*pow(Temp,4))))*32/22.414
		FinalCO2umolL = FinalCO2MgL*31.25
		Sheet2FinalData = ['%.0f'%Salin,'%.7f'%Chlorin, '%.8f'%FinalCO2MgL, '%.6f'%FinalCO2umolL]
		return Sheet1Data, Sheet2FinalData
	
	
	def change_header(directory):
		# List all .txt files in the directory
		file_list = [file for file in os.listdir(directory) if file.endswith(".txt")]
	
		# Check if any .txt files exist in the directory
		if not file_list:
			print("No .txt files found in the directory.")
			return
	
		# Process each .txt file
		for file in file_list:
			file_path = os.path.join(directory, file)
	
			# Read the contents of the file
			with fileinput.input(files=file_path, inplace=True) as infile:
				for line in infile:
					if fileinput.isfirstline():
						# Modify the header line
						header = "Genotype\tTime\tLogtime\tOxy_air_sat\tPhase\tAmp\tTempC\tair_sat\tpercent_oxygen\tpO2\tpO2_Torr\tcO2\tcO2_umol\tSalinity\tchlorinity\tSalCorcO2\tSalCorcO2_umol\n"
						print(header, end="")
					else:
						print(line, end="")
	
			print(f"Header changed for file: {file}")
	
		print("Header change complete.")
	
	
	if __name__ == "__main__":
		if len(sys.argv) < 3:
			print(Usage)
		else:
			InFileList = sys.argv[2:]
			InDelim = ";"
			FileCount = 0
			OutList = []
			HeaderFile = open(sys.argv[1], 'r')
			HeaderLineCount = 0
	
			# Read the header lines
			for HeaderLine in HeaderFile:
				HeaderLineCount += 1
				if HeaderLineCount == 1:
					Header = HeaderLine.rstrip()
				if HeaderLineCount == 2:
					OxyCalcHeader = HeaderLine.rstrip()
	
			if Debug:
				print(Header)
	
			# Process each input file
			for InFile in InFileList:
				FileCount += 1
				LineCount = 0
				FileToClean = open(InFile, 'r')
				CleanedOut = open('%s_cleaned.txt' % (os.path.splitext(InFile)[0]), 'w')
				StartParsing = 0
	
				# Process each line in the input file
				for Line in FileToClean:
					LineCount += 1
					if LineCount == 2:
						ChamberID = Line.rstrip().split(" ")[1].split('-')[1]
						if Debug:
							print(ChamberID)
					if Line.startswith(Header[0:10]):
						if Debug:
							print(Line.rstrip())
							print('%s_cleaned.txt' % (os.path.splitext(sys.argv[1])[0]))
	
						# Write the updated header line to the cleaned output file
						CleanedOut.write('Chamber\t%s\t%s\n' % ("\t".join(Line.rstrip().split(InDelim)[1:]), OxyCalcHeader))
						StartParsing = LineCount
	
					if StartParsing != 0 and LineCount > StartParsing:
						try:
							Cols = Line.rstrip().split(";")
							int(Cols[0].split("/")[0])
							CleanedOut.write('%s\t%s\t%s' % (ChamberID, TimeConvert(Cols[1]), "\t".join(Cols[2:])))
							Calcd, FinalCalcd = OxyCalcPt1(Cols[4], Cols[6])
							CleanedOut.write('\t%s\t%s\n' % ("\t".join(Calcd), "\t".join(FinalCalcd)))
						except ValueError:
							StartParsing = LineCount
	
				FileToClean.close()
				CleanedOut.close()
	
			HeaderFile.close()
			print("Processed %d files." % FileCount)
			print("Time Elapsed: %f" % (time.time() - StartTime))
	
			# Call the function to change headers for all .txt files in the directory
			change_header(os.path.dirname(os.path.abspath(InFileList[0])))

Output file example:

	Genotype	Time	Logtime	Oxy_air_sat	Phase	Amp	TempC	air_sat	percent_oxygen	pO2	pO2_Torr	cO2	cO2_umol	Salinity	chlorinity	SalCorcO2	SalCorcO2_umol
	1	9:36:34 AM	0.00	83.150	28.280	11409.000	29.000	81.491099	17.0723853	166.087020	124.575854	6.25674036	195.523136	35	19.3739612	5.06907230	158.408509
	1	9:36:36 AM	0.02	83.040	28.300	11400.000	29.000	81.340716	17.0408800	165.780524	124.345963	6.24519421	195.162319	35	19.3739612	5.05971786	158.116183
	1	9:36:44 AM	0.16	83.000	28.300	11402.000	29.000	81.340716	17.0408800	165.780524	124.345963	6.24519421	195.162319	35	19.3739612	5.05971786	158.116183
	1	9:36:59 AM	0.41	82.270	28.400	11410.000	29.000	80.593864	16.8844146	164.258366	123.204247	6.18785227	193.370384	35	19.3739612	5.01326069	156.664397
	1	9:37:14 AM	0.66	82.610	28.350	11398.000	29.000	80.966239	16.9624270	165.017302	123.773497	6.21644252	194.263829	35	19.3739612	5.03642387	157.388246
	1	9:37:29 AM	0.91	82.140	28.420	11413.000	29.000	80.445500	16.8533322	163.955984	122.977441	6.17646112	193.014410	35	19.3739612	5.00403183	156.375995
	1	9:37:44 AM	1.16	82.240	28.400	11438.000	29.000	80.593864	16.8844146	164.258366	123.204247	6.18785227	193.370384	35	19.3739612	5.01326069	156.664397
	1	9:37:59 AM	1.41	81.960	28.440	11428.000	29.000	80.297469	16.8223197	163.654281	122.751145	6.16509553	192.659235	35	19.3739612	4.99482369	156.088240
	 
	
