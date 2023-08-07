#!/usr/bin/env python

# By Dan Barshis

import sys, os, argparse

def main():
	#to parse command line
	usage = "usage: %prog [options]"
	p = argparse.ArgumentParser(usage)

	#Input/output files
#	p.add_argument('-i', '--infilelist', nargs='+', help='*.txt for all results files to parse')
	p.add_argument('-t', '--timebreaks', help='Tab delimited file with filename	resiprostart(Minutes from start [usually 0])	photostarttime(Minutes from start)')

	#General
	args = p.parse_args()
	filecount=0
	timefiles=open(args.timebreaks, 'r')
	linecount=0
	for line in timefiles:
		linecount+=1
		if linecount>1: #to skip header line
			infos=line.rstrip().split('\t')
			filename=infos[0]
			respirostart=int(infos[1])*60
			photostart=int(infos[2])*60
			filecount+=1
			infile = open(filename, 'r') #need to write to work with CRLF EOL characters
			samplename = filename[:-4]
			respirout = open('%s_resp.txt'%(samplename), 'w')
			photoout = open('%s_photo.txt'%(samplename), 'w')
			linecount = 0
			towrite=0 #this is to skip the first lines before the header
			for line in infile:
				linecount+=1
				if line.startswith('Date\tTime'):
					line=line.rstrip()
					header='Date\tTime_HH:MM:SS\tTime_sec\tCh1_O2_%s\tCh2_O2_%s\tCh3_O2_%s\tCh4_O2_%s\tCh1_Temp\tCh2_Temp\tCh3_Temp\tCh4_Temp' %(infos[3],infos[4],infos[5],infos[6])
					towrite=1
					respirout.write('%s\n'%(header))
					photoout.write('%s\n'%(header))
					continue
				if towrite==1:
					cols=line.rstrip().split('\t')
					if float(cols[2])>=respirostart and float(cols[2])<photostart:
						respirout.write('%s\t%s\n'%('\t'.join(cols[0:3]),'\t'.join(cols[4:12])))
					if float(cols[2])>=photostart:
						photoout.write('%s\t%s\n'%('\t'.join(cols[0:3]),'\t'.join(cols[4:12])))
			respirout.close()
			photoout.close()

if __name__ == '__main__':
	main()