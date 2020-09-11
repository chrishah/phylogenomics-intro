#!/bin/bash

dir=$1

for line in $(cat $dir/FcC_info.xls | grep "ALICUT" | cut -f 1-3 | sed 's/\t/|/g')
do
	id=$(echo -e "$line" | cut -d "|" -f 1 | sed 's/ALICUT_//' | sed 's/.clustalo.*//')
	model=$(cat $(find ../per_gene/ -name "$id.best_model") | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
	echo -e "$model, $id = $(echo -e "$line" | cut -d "|" -f 2,3 | sed 's/|/-/')"
done
