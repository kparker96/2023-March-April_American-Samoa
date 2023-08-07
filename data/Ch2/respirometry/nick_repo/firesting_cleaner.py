#!/usr/bin/env python

# By Dan Barshis

import sys, os, argparse

def main():
	#to parse command line
	usage = "usage: %prog [options]"
	p = argparse.ArgumentParser(usage)

	#Input/output files
	p.add_argument('-i', '--infilelist', nargs='+', help='*.txt for all results files to parse')

	#General
	args = p.parse_args()
	filecount=0
	for file in args.infilelist:
		filecount+=1
		infile = open(file, 'r') #need to write to work with CRLF EOL characters
		outfile = open('%s_cleaned.txt'%(file[:-4]),'w')
		linecount = 0
		towrite=0 #this is to skip the first lines before the header
		for line in infile:
			linecount+=1
			if line.startswith('Date\tTime'):
				line=line.rstrip()
				header='Date\tTime_HH:MM:SS\tTime_sec\tCh1_O2\tCh2_O2\tCh3_O2\tCh4_O2\tCh1_Temp\tCh2_Temp\tCh3_Temp\tCh4_Temp'
				outfile.write('%s\n'%(header))
				towrite=1
				continue
			if towrite==1:
				cols=line.rstrip().split('\t')
				outfile.write('%s\t%s\n'%('\t'.join(cols[0:3]),'\t'.join(cols[4:12])))
		outfile.close()

if __name__ == '__main__':
	main()