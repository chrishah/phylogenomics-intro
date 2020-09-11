#!/bin/bash

t=$1
B=$2

for line in $(cat $t | sed 's/\t/|/'); do taxid=$(echo -e "$line" | cut -d "|" -f 1); sp=$(echo -e "$line" | cut -d "|" -f 2); grep ">$taxid\_" -A 1 $B | head -n 2 | sed "s/^>.*/>$sp/"; done
