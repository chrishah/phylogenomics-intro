#!/bin/bash

cat $1 | perl -ne 'chomp; $h=$_; $s=<>; chomp($s); $check=$s; $check=~s/-//g; if (length($check) > 0){print "$h\n$s\n"}'
