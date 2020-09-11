#!/bin/bash

cat $1 | sed 's/)/)\n/g' | perl -ne 'chomp; $f=$_; if ($_ =~ /\[/){$f =~ s/.*\[//; $f =~ s/,.*//; $_ =~ s/\[.*\]//; $tree.="$f$_"}else{$tree.=$f} if (eof()){print "$tree\n"}'

