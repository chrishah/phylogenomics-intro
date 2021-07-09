#!/bin/bash


ID=$1
threads=$2
basedir="$(realpath $3)"


ingroup=$(pwd)/ingroup.txt
outgroup=$(pwd)/outgroup.txt

bin=$(dirname $(realpath $0))

echo -e "\n###\nprocessing ID: $ID"
if [ ! -d "$ID" ]
then
	mkdir $ID
fi

cd $ID
#get sequences
bash $bin/fetch_seqs.sh $ID $basedir $ingroup $outgroup

#alignment
#echo -e "\n[$(date)]\tLoading cluster's singularity modules"
#module load go/1.11 singularity/3.4.1

echo -e "\n[$(date)]\tAignment with clustalo"
cmd="clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/clustalo-docker:1.2.4 \

docker run --rm -v $(pwd):/in -w /in chrishah/clustalo-docker:1.2.4 clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads

#aliscore and alicut
echo -e "\n[$(date)]\tEvaluating (Aliscore) and trimming alignment (ALICUT)"
#cd $ID
cmd="Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/alicut-aliscore-docker:2.31 \

docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log

cmd="ALICUT.pl -s &> alicut.log"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/alicut-aliscore-docker:2.31 \
docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 ALICUT.pl -s &> alicut.log

#find best model for RAxml
echo -e "\n[$(date)]\tFinding best model for RAxML"
mkdir find_best_model
cd find_best_model
cp ../ALICUT_$ID.clustalo.aln.fasta .
cmd="ProteinModelSelection.pl ALICUT_$ID.clustalo.aln.fasta"
echo -e "[Running .. ] $cmd"
#singularity exec -B /cl_tmp/hahnc docker://chrishah/raxml-docker:8.2.12 \

docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 $cmd > $ID.bestmodel
cd ..

#run RAxML
echo -e "\n[$(date)]\tRunning RAxML"
RAxMLmodel=$(cat find_best_model/$ID.bestmodel | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
bs=100
cmd="raxml -f a -T $threads -m PROTGAMMA$RAxMLmodel -p 12345 -x 12345 -# $bs -s ALICUT_$ID.clustalo.aln.fasta -n $ID.clustalo.aln.ALICUT.$RAxMLmodel &> raxml.log"
echo -e "[Running .. ] $cmd"

#singularity exec -B /cl_tmp/hahnc docker://chrishah/raxml-docker:8.2.12 \
docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 $cmd


echo -e "\n[$(date)]\tDone! \n"
#cd ..



