#!/bin/bash

ID=$1
basedir=$2
ingroup=$3
outgroup=$4

echo -n "" > $ID.fasta
for out in $(cat $ingroup $outgroup)
do
	
	echo -ne "ID: $ID - sample: $out - "
	if [ -s "$(grep -P "$out" <(find $basedir -name "single_copy*"))/$ID.faa" ]
	then
		echo -e "FOUND"
		echo -e ">$out" >> $ID.fasta
		cat $(grep -P "$out" <(find $basedir -name "single_copy*"))/$ID.faa | tail -n 1 >> $ID.fasta
	else
		echo -e "MISSING"
#		echo -e ">$out\n-" >> $ID.fasta
	fi
done

