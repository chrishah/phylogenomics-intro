#!/bin/bash

searchdir=$1
minlength=$2
mincount=$3
minboot=$4

for fasta in $(find $searchdir -name 'ALICUT_*' | grep -v "best_model" | grep -v "reduced" | grep ".fasta$")
do
	count=$(cat $fasta | grep ">" | wc -l)
	length=$(head -n 2 $fasta | tail -n 1 | wc | perl -ne 'chomp; @a=split(" "); print "$a[-1]\n"')
	BUSCO=$(echo "$fasta" | perl -ne 'chomp; @a=split("\/"); @b=split("_",$a[-1]); $b[1] =~ s/\..*//; print "$b[-1]\n"')
	tree=$(find $searchdir -name "RAxML_bipartitionsBranchLabels.$BUSCO*")
	if [ -z $tree ]; then continue; fi
	avg_boot=$(cat $tree | perl -ne 'chomp; @a=split(/\[/); for (@a){if ($_ =~ /]/){$_ =~ s/\].*//; $ab=$ab+$_; $count++}}; if (eof()){print sprintf("%.3f", $ab/$count)."\n"}')
	
        echo -en "$fasta\t$count\t$length\t$avg_boot"
        if [ "$count" -gt "$mincount" ] && [ "$length" -ge "$minlength" ]
        then
		temp=$(echo $avg_boot | sed 's/\.//')
		if [ "$(echo -e "$avg_boot\t$minboot" | perl -ne 'chomp; @a=split("\t"); if ($a[0] >= $a[1]){print "1"}else{print "0"}')" -ne 0 ]
		then
                	echo -e "\tpass"
                	new=$(echo -e "$fasta" | perl -ne 'chomp; @a=split("/"); $a[-1] =~ s/fasta/fas/; print "$a[-1]\n"')
                	cp $fasta $new
		else
			echo -e "\tfilter bootstrap"
		fi
        else
                echo -e "\tfilter length"
        fi
done

