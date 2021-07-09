# phylogenomics-intro
Phylogenomics tutorial based on BUSCO genes

***Disclaimer***
To follow the demo and make the most of it, it helps if you have some basic skills with running software tools and manipulating files using the Unix shell command line. It assumes you have Docker installed on your computer (tested with Docker version 18.09.7, build 2d0083d; on Ubuntu 18.04).

## Introduction

We will be reconstructing the phylogenetic relationships of some parasitic flatworms based on previously published whole genome data. The list of species we will be including in the analyses, and the URL for the data download can be found in this <a href="https://github.com/chrishah/phylogenomics-intro/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited as Docker images on <a href="https://hub.docker.com/" title="Dockerhub" target="_blank">Dockerhub</a> (see <a href="https://github.com/chrishah/phylogenomics-intro/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available.

The workflow we will demonstrate is as follows:
- Download genomes from Genbank
- Identifying complete BUSCO genes in each of the genomes
- pre-filtering of orthology/BUSCO groups
- For each BUSCO group:
  - build alignment
  - trim alignment
  - identify model of protein evolution
  - infer phylogenetic tree (ML)
- post-filter orthology groups
- construct supermatrix from individual gene alignments
- infer phylogenomic tree with paritions corresponding to the original gene alignments using ML
- map internode certainty (IC) onto the phylogenomic tree

### Why parasitic flatworms are an interesting system for phylogenomics (in a nutshell)

The phylogenetic relationships between the three major groups of parasitic flatworms, Flukes (Trematoda), Monogenea (traditionally Monopisthocotylea and Polyopisthocotylea), and Tapeworms (Cestoda), remain controversial. The figure below shows the three main competing hypotheses, that were published over the years. Phylogenomics might give new (hopefully conclusive) insights, but particularly the Monogenea are rather underrepresented when it comes to genomic resources. We are currently working on changing that.

![Competing Hypotheses](data/competing_hypotheses_opist.jpg)

### Let's begin

Before you get going I suggest you download this repository, so have all scripts that you'll need. Ideally you'd do it through `git`.
```bash
(user@host)-$ git clone https://github.com/chrishah/phylogenomics-intro.git
```

Then move into the newly cloned directory, and get ready.
```bash
(user@host)-$ cd phylogenomics-intro
```

__1.) Download data from Genbank__

What's the first species of parasitic flatworm that pops into your head? _Schistosoma mansoni_ perhaps? Let's see if someone has already attempted to sequence its genome. 
NCBI Genbank is usually a good place to start. Surf to the [webpage](https://www.ncbi.nlm.nih.gov/genome/) and have a look. And indeed we are [lucky](https://www.ncbi.nlm.nih.gov/genome/?term=Schistosoma+mansoni).  

Let's get it downloaded. Note that the `(user@host)-$` part of the code below just mimics a command line prompt. This will look differently on each computer. The command you actually need to exectue is the part after that, so only, e.g. `mkdir assemblies`:
```bash
#First make a directory and enter it
(user@host)-$ mkdir Schistosoma_mansoni
(user@host)-$ cd Schistosoma_mansoni

#use the wget program to download the genome
(user@host)-$ wget https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/237/925/GCF_000237925.1_ASM23792v2/GCF_000237925.1_ASM23792v2_genomic.fna.gz

#decompress for future use
(user@host)-$ gunzip GCF_000237925.1_ASM23792v2_genomic.fna.gz

#leave the directory for now
(user@host)-$ cd ..
```
We have compiled a list of published genomes that we will be including in our analyses [here](https://github.com/chrishah/phylogenomics-intro/blob/master/data/samples.csv). Ideally we should download them all. You can do one by one or use your scripting skills to get them all in one go. 

Make sure that you download each into a separate directory that should be named according to the binomial (connected with underscores, rather than spaces) - see example for _S. mansoni_ above.

__2.) Run BUSCO on each assembly__

First we'll need to download an appropriate reference dataset for BUSCO - pick and choose on their <a href="https://busco-archive.ezlab.org/v3/" title="BUSCO v3" target="_blank">webpage</a>. We go for 'metazoa odb9'.

***Attention***
> If you're doing this session as part of a course, pause here for a second and only do the download if it's necessary. The BUSCO reference set will likely be provided to participants so that it's not downloaded separately by each.

Below you see how you'd download the dataset. 

```bash
(user@host)-$ wget https://busco-archive.ezlab.org/v3/datasets/metazoa_odb9.tar.gz
```
I comes compressed, so we need to decompress:
```bash
(user@host)-$ tar xvfz metazoa_odb9.tar.gz
```

Now we want to run BUSCO to identify the set of core genes in our genome. This will take a little while for each assembly, depending on the computational resources you have available. I'll start with one to give you an example. I suggest you copy paste and hit enter for now, while it is running we will talk about some details of the command.

First, make sure you know where your database is, either downloaded yourself or provided somewhere on the server, and save the location into a variable `mydb`.

```bash
(user@host)-$ mydb=$(pwd)/metazoa_odb9 #if downloaded yourself as above
(user@host)-$ mydb=/home/ubuntu/Share/Day5/metazoa_odb9 #e.g. if provided on a server
```

Now, move to your species' directory and run BUSCO - __if running on a server, please use the second command__.
```bash
(user@host)-$ cd Schistosoma_mansoni

#### if running locally
(user@host)-$ docker run --rm \
-v $(pwd):/in -w /in \
-v $mydb:$mydb \
chrishah/busco-docker:v3.1.0 \
run_BUSCO.py \
--in ./GCF_000237925.1_ASM23792v2_genomic.fna \
--out S_mansoni \
-l $mydb \
--mode genome -c 4 -f \
-sp schistosoma --augustus_parameters='--progress=true'

#### if running on a server, we enter the container
#### start busco, and
#### detach with a key combination
(user@host)-$ docker run --rm \
-v $(pwd):/in -w /in \
-v $mydb:$mydb \
--name $USER-busco -e DB=$mydb -it \
chrishah/busco-docker:v3.1.0 

root@c528f3385b9d:/in# run_BUSCO.py \
--in ./GCF_000237925.1_ASM23792v2_genomic.fna \
--out S_mansoni \
-l $DB \
--mode genome -c 4 -f \
-sp schistosoma --augustus_parameters='--progress=true' &> busco.log

## Then you can detach from the container by pressing 'CTRL-P + CTRL-Q'
## it will keep running in the background until it's done
## you can check what busco is doing by looking into the busco.log file

```

Here's some more details, as promised:
If you're new to the command line the above probably looks a bit confusing. What you have here is one long command that is wrapped across several lines to make it a bit more readable. You notice that each line ends with a `\` - this tells the shell that the command is not done and will continue in the next line. You could write everything in one line. BUSCO calls a number of other software tools that would all need to be installed on your system. In order to avoid that we use a Docker container, that has everything included. So, we tell the program `docker` to `run` a container `chrishah/busco-docker:v3.1.0` and within it we call the program `run_BUSCO.py`. We have a few other options to specify for BUSCO which I will come to soon, but that's the bare minimum - give it a try.
```bash
(user@host)-$ docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py
ERROR	The parameter '--in' was not provided. Please add it in the config file or provide it through the command line
```
We get and error and it tells us that we have not provided a certain parameter. The question is which parameters are available. Command line programs usually have an option to show you which parameters are available to the user. This __help__ can in most be cases be called by adding a `-h` flag to the software call. There can be variations around that: sometimes it's `--help`, sometimes it's `-help`, but something like that exists for almost every command line program,s o this is a very important thing to take home from this exercise. Give it a try. 
```bash
(user@host)-$ docker run chrishah/busco-docker:v3.1.0 run_BUSCO.py -h
usage: python BUSCO.py -i [SEQUENCE_FILE] -l [LINEAGE] -o [OUTPUT_NAME] -m [MODE] [OTHER OPTIONS]

Welcome to BUSCO 3.1.0: the Benchmarking Universal Single-Copy Ortholog assessment tool.
For more detailed usage information, please review the README file provided with this distribution and the BUSCO user guide.

optional arguments:
  -i FASTA FILE, --in FASTA FILE
                        Input sequence file in FASTA format. Can be an assembled genome or transcriptome (DNA), or protein sequences from an annotated gene set.
  -c N, --cpu N         Specify the number (N=integer) of threads/cores to use.
  -o OUTPUT, --out OUTPUT
                        Give your analysis run a recognisable short name. Output folders and files will be labelled with this name. WARNING: do not provide a path
  -e N, --evalue N      E-value cutoff for BLAST searches. Allowed formats, 0.001 or 1e-03 (Default: 1e-03)
  -m MODE, --mode MODE  Specify which BUSCO analysis mode to run.
                        There are three valid modes:
                        - geno or genome, for genome assemblies (DNA)
                        - tran or transcriptome, for transcriptome assemblies (DNA)
                        - prot or proteins, for annotated gene sets (protein)
  -l LINEAGE, --lineage_path LINEAGE
                        Specify location of the BUSCO lineage data to be used.
                        Visit http://busco.ezlab.org for available lineages.
  -f, --force           Force rewriting of existing files. Must be used when output files with the provided name already exist.
  -r, --restart         Restart an uncompleted run. Not available for the protein mode
  -sp SPECIES, --species SPECIES
                        Name of existing Augustus species gene finding parameters. See Augustus documentation for available options.
  --augustus_parameters AUGUSTUS_PARAMETERS
                        Additional parameters for the fine-tuning of Augustus run. For the species, do not use this option.
                        Use single quotes as follow: '--param1=1 --param2=2', see Augustus documentation for available options.
  -t PATH, --tmp_path PATH
                        Where to store temporary files (Default: ./tmp/)
  --limit REGION_LIMIT  How many candidate regions (contig or transcript) to consider per BUSCO (default: 3)
  --long                Optimization mode Augustus self-training (Default: Off) adds considerably to the run time, but can improve results for some non-model organisms
  -q, --quiet           Disable the info logs, displays only errors
  -z, --tarzip          Tarzip the output folders likely to contain thousands of files
  --blast_single_core   Force tblastn to run on a single core and ignore the --cpu argument for this step only. Useful if inconsistencies when using multiple threads are noticed
  -v, --version         Show this version and exit
  -h, --help            Show this help message and exit
```

Now for the extra Docker parameters: 
 - `--rm`: each time you run a docker container it will be stored on your system, which after a while eats up quite a bit of space, so this option tells docker to remove the container after it's finished for good.
 - `-v`: This specifies so-called mount points, i.e. the locations where the docker container and your local computer are connected. I've actually specified three of them in the above command. For example `-v $(pwd):/in` tells docker to connect the present working directory on my computer (this will be returned by a command call $(pwd)) and a place in the container called `/in`. Then I also mount the place where the assemblies and the BUSCO genes that we've just downloaded are located into specific places in the container which I will point BUSCO to later on.
 - `-w`: specifies the working directory in the container where the command will be exectued - I'll make it `/in` - remember that `/in` is connected to my present working directory, so essentially the programm will run and write all output to my present working directory.
BTW, docker has a help function too:
```bash
#For the main docker program
(user@host)-$ docker --help
#For the run subprogram
(user@host)-$ docker run --help
```
Then I specify a number of parameters for BUSCO (you can double check with the information from the `-h` above), like:
 - the input fasta file, via `--in`
 - where the output should be written, via `--out`
 - where it can find the BUSCO set I have downloaded, via `-l`
 - that I am giving it a genome, via `-mode genome` (`transcriptome` is also possible her)
 - that I want to use 4 CPUs, via `-c 4`
 - that I want it to force overwrite any existing data, in case I ran it before in the same place, via `-f`
 - and finally a few parameters for one of the gene predictors BUSCO uses, it's called `augustus`

`augustus` comes pre-trained for some oranisms and it happens to contain a training set for schisosoma. If you want to know which other options you might have - the following command gives you a list of all species that augustus is trained for - ideally you would pick a species that is as closely related to your target as possible.

```bash
(user@host)-$ docker run --rm chrishah/busco-docker:v3.1.0 augustus --species=help
```

Now, let's have a look at BUSCO's output. If you followed the steps above BUSCO will have created lots of files for your genome. Let's move to there and list the files:
```bash
(user@host)-$ cd Schistosoma_mansoni/run_S_mansoni/
(user@host)-$ ls -1
blast_output
full_table_S_mansoni.tsv
hmmer_output
missing_busco_list_S_mansoni.tsv
short_summary_S_mansoni.txt
translated_proteins
``` 

Usually the most interesting for people is the content of the short summary, which gives an indication of how complete your genome/transcriptome is.
```bash
(user@host)-$ cat short_summary_S_mansoni.txt
# BUSCO version is: 3.1.0
# The lineage dataset is: metazoa_odb9 (Creation date: 2016-02-13, number of species: 65, number of BUSCOs: 978)
# To reproduce this run: python /usr/bin/run_BUSCO.py -i GCF_000237925.1_ASM23792v2_genomic.fna -o S_mansoni -l ./metazoa_odb9/ -m genome -c 4 -sp schistosoma --augustus_parameters '--progress=true'
#
# Summarized benchmarking in BUSCO notation for file GCF_000237925.1_ASM23792v2_genomic.fna
 
# BUSCO was run in mode: genome

        C:74.0%[S:72.7%,D:1.3%],F:5.4%,M:20.6%,n:978

        724     Complete BUSCOs (C)
        711     Complete and single-copy BUSCOs (S)
        13      Complete and duplicated BUSCOs (D)
        53      Fragmented BUSCOs (F)
        201     Missing BUSCOs (M)
        978     Total BUSCO groups searched
```

We're also interested in which BUSCO genes it actually found. Note that I am only showing the first 20 lines of the file below - it actually has 1000+ lines.
```bash
(user@host)-$ head -n 20 full_table_S_mansoni.tsv
# BUSCO version is: 3.1.0 
# The lineage dataset is: metazoa_odb9 (Creation date: 2016-02-13, number of species: 65, number of BUSCOs: 978)
# To reproduce this run: python /usr/bin/run_BUSCO.py -i GCF_000237925.1_ASM23792v2_genomic.fna -o S_mansoni -l metazoa_odb9/ -m genome -c 4 -sp schistosoma --augustus_parameters '--progress=true'
#
# Busco id	Status	Sequence	Score	Length
EOG091G00AH     Complete        NW_017386051.1  601331  626781  450.4   578
EOG091G00CM     Missing
EOG091G00GM     Complete        NW_017386081.1  59875   121529  1103.9  962
EOG091G00GQ     Complete        NC_031495.1     28396966        28418315        553.1   675
EOG091G00L0     Fragmented      NC_031497.1     12261511        12270432        96.0    156
EOG091G00MA     Complete        NC_031497.1     18716664        18724151        165.0   397
EOG091G00MI     Complete        NC_031498.1     11122844        11133860        186.1   204
EOG091G00Q0     Complete        NC_031495.1     34828944        34843567        1679.4  969
EOG091G00QT     Duplicated      NC_031497.1     14803536        14817948        255.3   374
EOG091G00QT     Duplicated      NC_031497.1     14821726        14851065        230.3   409
EOG091G00UD     Complete        NC_031495.1     54350454        54389664        1115.6  794
EOG091G00VZ     Complete        NC_031495.1     43353623        43366175        331.6   250
EOG091G00Z3     Complete        NC_031495.1     21812828        21829893        848.9   769
```
You get the status for all BUSCO genes, wheter they were found complete, duplicated etc., on which sequence in your assembly it was found, how good the match was, length, etc.

__3.) Prefiltering of BUSCO groups__

Now, assuming that we ran BUSCO across a number of genomes, we're going to select us a bunch of BUSCO genes to be included in our analyses. Let's get and overview.

We'd want for example to identify all genes that are not missing data for more than one sample. I have grouped my species into ingroup taxa (the focal group) and outgroup taxa and I've written them to files accordingly. Note that for all of the below to work the names need to fit with the names you gave during the BUSCO run and the download.
```bash
(user@host)-$ cat ingroup.txt 
Clonorchis_sinensis
Echinococcus_multilocularis
Fasciola_gigantica
Gyrodactylus_bullatarudis
Hymenolepis_diminuta
Protopolystoma_xenopodis
Schistosoma_mansoni
Taenia_solium
Kapentagyrus_tanganicanus
Dictyocotyle_coeliaca
Diclidophora_denticulata
Eudiplozoon_nipponicum

(user@host)-$ cat outgroup.txt 
Dugesia_japonica
Schmidtea_mediterranea
```

Let's start by looking at a random gene, say `EOG091G11IM`. You can try to do it manually, i.e. go through all the full tables, search for the gene id and take a note of what the status was. For a 1000 genes that's a bit tedious so I wrote a script to do that: `evaluate.py`. It's in the `scripts/` directory of this repository - go [here](https://github.com/chrishah/phylogenomics-intro/blob/master/scripts/evaluate.py), if you're interested in the code.

You can execute it like so:
```bash
(user@host)-$ ./scripts/evaluate.py
usage: evaluate.py [-h] -i IN_LIST [--max_mis_in INT] -o OUT_LIST
                   [--max_mis_out INT] [--max_avg INT] [--max_med INT] -f
                   TABLES [TABLES ...] [-B [IDs [IDs ...]]] [--outfile FILE]
```
Or, like this, if you want some more info:
```bash
(user@host)-$ ./scripts/evaluate.py -h
usage: evaluate.py [-h] -i IN_LIST [--max_mis_in INT] -o OUT_LIST
                   [--max_mis_out INT] [--max_avg INT] [--max_med INT] -f
                   TABLES [TABLES ...] [-B [IDs [IDs ...]]] [--outfile FILE]

Pre-filter BUSCO sets for phylogenomic analyses

optional arguments:
  -h, --help            show this help message and exit
  -i IN_LIST, --in_list IN_LIST
                        path to text file containing the list of ingroup taxa
  --max_mis_in INT      maximum number of samples without data in the ingroup,
                        default: 0, i.e. all samples have data
  -o OUT_LIST, --out_list OUT_LIST
                        path to text file containing the list of outgroup taxa
  --max_mis_out INT     maximum number of samples without data in the
                        outgroup, default: 0, i.e. all samples have data
  --max_avg INT         maximum average number of paralog
  --max_med INT         maximum median number of paralogs
  -f TABLES [TABLES ...], --files TABLES [TABLES ...]
                        full BUSCO results tables that should be evaluated
                        (space delimited), e.g. -f table1 table2 table3
  -B [IDs [IDs ...]], --BUSCOs [IDs [IDs ...]]
                        list of BUSCO IDs to be evaluated, e.g. -B EOG090X0IQO
                        EOG090X0GLS
  --outfile FILE        name of outputfile to write results to

```

Let's try it for our BUSCO `EOG091G11IM` across a bunch of BUSCO results. We can stitch together the command by following the info from the help (not showing the output here). Note that I specify tables I have deposited as backup data in the repo, for demonstration. If you actually ran BUSCO yourselve according to the instructions above, you should adjust the paths, to e.g. `./Schistosoma_mansoni/full_table_S_mansoni.tsv` and so forth.
```bash
(user@host)-$ ./scripts/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 2 --max_mis_out 1 \
--max_avg 1 --max_med 1 \
-B EOG091G11IM \
-f /home/ubuntu/Share/Day5/BUSCO_runs/Taenia_solium/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Schistosoma_mansoni/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Echinococcus_multilocularis/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Hymenolepis_diminuta/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Fasciola_gigantica/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Dictyocotyle_coeliaca/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Kapentagyrus_tanganicanus/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Protopolystoma_xenopodis/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Eudiplozoon_nipponicum/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Clonorchis_sinensis/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Dugesia_japonica/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Schmidtea_mediterranea/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Gyrodactylus_bullatarudis/run_busco/full_table_busco.tsv \
/home/ubuntu/Share/Day5/BUSCO_runs/Diclidophora_denticulata/run_busco/full_table_busco.tsv
```

This BUSCO passes our filter criteria. No more than one sample missing for either the in- or the outgroup, average number of paralogs per sample <= 2 and median number of paralogs is <= 2 , as well. Great.
With some 'bash-magic' I don't even need to manually list all the tables (not showing the output here) - again, I am just pointing to my backup tables here, if you actually ran all of the above you'd need to adjust this part - `-f $(find /home/ubuntu/Share/Day5/BUSCO_runs/ -name "full_table*")` - to point somewhere else.
```bash
(user@host)-$ ./scripts/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 2 --max_mis_out 1 \
--max_avg 2 --max_med 2 \
-B EOG091G11IM \
-f $(find /home/ubuntu/Share/Day5/BUSCO_runs/ -name "full_table*")
```

And finally, we can run it across all BUSCO genes, by not specifying any partiular BUSCO Id. Note that I have provided the name for an output file that will receive the summary.
```bash
(user@host)-$ ./scripts/evaluate.py \
-i ingroup.txt -o outgroup.txt --max_mis_in 4 --max_mis_out 1 \
--max_avg 1 --max_med 1 \
--outfile summary.tsv \
-f $(find /home/ubuntu/Share/Day5/BUSCO_runs/ -name "full_table*") 
# Ingroup taxa: ['Clonorchis_sinensis', 'Echinococcus_multilocularis', 'Fasciola_gigantica', 'Gyrodactylus_bullatarudis', 'Hymenolepis_diminuta', 'Protopolystoma_xenopodis', 'Schistosoma_mansoni', 'Taenia_solium', 'Kapentagyrus_tanganicanus', 'Dictyocotyle_coeliaca', 'Diclidophora_denticulata', 'Eudiplozoon_nipponicum']
# Outgroup taxa ['Dugesia_japonica', 'Schmidtea_mediterranea']
# tables included: ['/home/classdata/Day5/BUSCO_runs/Taenia_solium/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Schistosoma_mansoni/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Echinococcus_multilocularis/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Hymenolepis_diminuta/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Fasciola_gigantica/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Dictyocotyle_coeliaca/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Kapentagyrus_tanganicanus/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Protopolystoma_xenopodis/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Eudiplozoon_nipponicum/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Clonorchis_sinensis/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Dugesia_japonica/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Schmidtea_mediterranea/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Gyrodactylus_bullatarudis/run_busco/full_table_busco.tsv', '/home/classdata/Day5/BUSCO_runs/Diclidophora_denticulata/run_busco/full_table_busco.tsv']
# maximum number of ingroup samples with missing data: 4
# maximum number of outgroup samples with missing data: 1
# maximum average number of paralogs: 1
# maximum median number of paralogs: 1
#
# found BUSCO table for taxon Taenia_solium -> ingroup
# found BUSCO table for taxon Schistosoma_mansoni -> ingroup
# found BUSCO table for taxon Echinococcus_multilocularis -> ingroup
# found BUSCO table for taxon Hymenolepis_diminuta -> ingroup
# found BUSCO table for taxon Fasciola_gigantica -> ingroup
# found BUSCO table for taxon Dictyocotyle_coeliaca -> ingroup
# found BUSCO table for taxon Kapentagyrus_tanganicanus -> ingroup
# found BUSCO table for taxon Protopolystoma_xenopodis -> ingroup
# found BUSCO table for taxon Eudiplozoon_nipponicum -> ingroup
# found BUSCO table for taxon Clonorchis_sinensis -> ingroup
# found BUSCO table for taxon Dugesia_japonica -> outgroup
# found BUSCO table for taxon Schmidtea_mediterranea -> outgroup
# found BUSCO table for taxon Gyrodactylus_bullatarudis -> ingroup
# found BUSCO table for taxon Diclidophora_denticulata -> ingroup
# Evaluated 894 BUSCOs - 358 (40.04 %) passed

```
__4.) For each BUSCO group__

For each of the BUSCOs that passed we want to:
 - bring together all sequences from all samples in one file
 - do multiple sequence alignment
 - filter the alignment, i.e. remove ambiguous/problematic positions
 - build a phylogenetic tree


Here are all steps for `EOG091G11IM` as an example. I have deposited the intiial fasta file in the data directory.
```bash
(user@host)-$ mkdir per_gene_manual
(user@host)-$ cd per_gene_manual
(user@host)-$ mkdir EOG091G11IM
(user@host)-$ cd EOG091G11IM
(user@host)-$ bash ../../scripts/fetch_seqs.sh EOG091G11IM \
/home/ubuntu/Share/Day5/BUSCO_runs/ ../../ingroup.txt ../../outgroup.txt
```

Now, step by step.
Specify the name of the BUSCO gene and the number of CPU cores to use for analyses in variables so you don't have to type it out every time.
```bash
(user@host)-$ ID=EOG091G11IM
(user@host)-$ threads=2
```

Perform multiple sequence alignment with [clustalo](http://www.clustal.org/omega/).
```bash
(user@host)-$ docker run --rm \
-v $(pwd):/in -w /in \
chrishah/clustalo-docker:1.2.4 \
clustalo -i $ID.fasta -o $ID.clustalo.aln.fasta --threads=$threads --verbose
```

We can then look at the alignment result. There is a number of programs available to do that, e.g. MEGA, Jalview, Aliview, or you can do it online. A link to the upload client for the NCBI Multiple Sequence Alignment Viewer is [here](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) (I suggest to open in new tab). Upload (`EOG091G11IM.clustalo.aln.fasta`), press 'Close' button, and have a look.

What do you think? It's actually quite messy.. 

Let's move on to score and filter the alignment, using [Aliscore](https://www.zfmk.de/en/research/research-centres-and-groups/aliscore) and [Alicut](https://github.com/PatrickKueck/AliCUT) programs. 
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
Aliscore.pl -N -r 200000000000000000 -i $ID.clustalo.aln.fasta &> aliscore.log
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/alicut-aliscore-docker:2.31 \
ALICUT.pl -s &> alicut.log
```
Try open the upload [dialog](https://www.ncbi.nlm.nih.gov/projects/msaviewer/?appname=ncbi_msav&openuploaddialog) for the Alignment viewer in a new tab and upload the new file (`ALICUT_EOG091G11IM.clustalo.aln.fasta`).
What do you think? The algorithm has removed quite a bit of the original alignment, reducing it to only ~100, but these look much better. 

Find best model of evolution for phylogenetic inference (first set up a new directory to keep things organized) using a script from [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/).
```bash
(user@host)-$ mkdir find_best_model
(user@host)-$ cd find_best_model
(user@host)-$ cp ../ALICUT_$ID.clustalo.aln.fasta .

(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
ProteinModelSelection.pl ALICUT_$ID.clustalo.aln.fasta > $ID.bestmodel

(user@host)-$ cd .. #move back to the base directory (if you forget the following will not work, because the location of the files will not fit to the command - happened to me before ;-)
```

Infer phylogenetic tree using [RAxML](https://cme.h-its.org/exelixis/web/software/raxml/). The first line just reads the output from the previous command, i.e. the best model, reformats it and saves it in a variable. 

The RAxML command in a nutshell:
 - `-f a` - use rapid bootstrapping mode (search for the best-scoring ML tree and run bootstrap in one analysis)
 - `-T` - number of CPU threads to use
 - `-m` - model of protein evolution - note that we add in the content of our variable `$RAxMLmodel`
 - `-p 12345` - Specify a random number seed for the parsimony inferences (which give will become the basis for the ML inference, which is much more computationally intensive). The number doesn't affect the result, but it allows you to reproduce your analyses, so run twice with the same seed, should give the exact same tree.
 - `-x 12345` - seed number for rapid bootstrapping. For reproducibility, similar to above.
 - `-# $bs` - number of bootstrap replicates - note that we put the variable `$bs` here that we've defined above
 - `-s` - input fasta file (the filtered alignemnt)
 - `-n` - prefix for output files to be generated

```bash
(user@host)-$ RAxMLmodel=$(cat find_best_model/$ID.bestmodel | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]') #this line reads in the file that countains the output from the best model search, reformats it and saves it to a variable
(user@host)-$ bs=100 #set the number of bootstrap replicates
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
raxml -f a -T $threads -m PROTGAMMA$RAxMLmodel \
-p 12345 -x 12345 -# $bs \
-s ALICUT_$ID.clustalo.aln.fasta -n $ID.clustalo.aln.ALICUT.$RAxMLmodel
```

This runs for a while. RAxML produces a log file (`RAxML_info.EOG091G11IM.clustalo.aln.ALICUT.JTTF`) that we can inspect. Just looking at the last 15 lines with the `tail` command.
```bash
(user@host)-$ tail -n 15 RAxML_info.EOG091G11IM.clustalo.aln.ALICUT.JTTF


Found 1 tree in File /in/RAxML_bestTree.EOG091G11IM.clustalo.aln.ALICUT.JTTF

Program execution info written to /in/RAxML_info.EOG091G11IM.clustalo.aln.ALICUT.JTTF
All 100 bootstrapped trees written to: /in/RAxML_bootstrap.EOG091G11IM.clustalo.aln.ALICUT.JTTF

Best-scoring ML tree written to: /in/RAxML_bestTree.EOG091G11IM.clustalo.aln.ALICUT.JTTF

Best-scoring ML tree with support values written to: /in/RAxML_bipartitions.EOG091G11IM.clustalo.aln.ALICUT.JTTF

Best-scoring ML tree with support values as branch labels written to: /in/RAxML_bipartitionsBranchLabels.EOG091G11IM.clustalo.aln.ALICUT.JTTF

Overall execution time for full ML analysis: 85.772520 secs or 0.023826 hours or 0.000993 days
```

And of course, we get our best scoring Maximum Likelihood tree.
```bash
(user@host)-$ cat RAxML_bipartitions.EOG091G11IM.clustalo.aln.ALICUT.JTTF 
(((Dugesia_japonica:0.04540905387157418566,Schmidtea_mediterranea:0.07848925176084055322)100:1.16715518034492538035,Protopolystoma_xenopodis:0.11079416545156400842)39:0.04487589776655191015,(((Dictyocotyle_coeliaca:0.21647112350310823703,(Kapentagyrus_tanganicanus:0.58585884381059250003,Gyrodactylus_bullatarudis:0.24863115243060615600)68:0.14361691889338459860)75:0.23455875734067299643,(Hymenolepis_diminuta:0.22780085806789415748,(Taenia_solium:0.01804635499578595079,Echinococcus_multilocularis:0.08482638895881837449)98:0.07679331284949014735)99:0.45065101264083423649)16:0.00536417294447177374,(Schistosoma_mansoni:0.22242908934952307365,Clonorchis_sinensis:0.19548372348592255032)97:0.19831350728023106056)38:0.05773372192722324436,Eudiplozoon_nipponicum:0.29043867944508250378);
```
.. in the Newick tree format. There is a bunch of programs that allow you to view and manipulate trees in this format. You can only do it online, for example through [iTOL](https://itol.embl.de/upload.cgi), embl's online tree viewer. There is others, e.g. [ETE3](http://etetoolkit.org/treeview/), [icytree](https://icytree.org/), or [trex](http://www.trex.uqam.ca/index.php?action=newick&project=trex). You can try it out.


__5.) Run the process for multiple genes__

Now, let's say we want to go over this process for each of our 300+ genes that passd our filtering criteria. A script that does all the above steps run for each BUSCO would do it. I've made a very simple one that also fetches the individual genes for each of the BUSCO ids. You could try e.g. the following, which assumes this:
  - you've run the BUSCO analyses for all datasets and they are in directories called like the name of the species in the `/home/ubuntu/Share/BUSCO_runs/` directory, so, e.g.: `/home/ubuntu/Share/BUSCO_runs/Schistosoma_mansoni`
  - the directory where you are running the following contains the files `ingroup.txt` and `outgroup.txt` that list the taxa to be considered ingroup and outgroup, respectively. The taxon names need to correspond to the sample specific directories you ran the BUSCO analysis in. The below runs it for the first 5 BUSCOs that passed our criteria. If you want to run it for all, you'd remove the `head -n 5`.


```bash
(user@host)-$ threads=2
(user@host)-$ for BUSCO in $(cat summary.tsv | grep "pass$" | cut -f 1 | head -n 5)
do
	echo $BUSCO
	./scripts/per_BUSCO.sh $BUSCO $threads /home/ubuntu/Share/BUSCO_runs/
done
```
 
Next step is to concatenate all trimmed alignments into a single supermatrix. Let's do that in a new directory.
```bash
(user@host)-$ mkdir post-filtering-concat
(user@host)-$ cd post-filtering-concat
```

Get the fasta files.
```bash
(user@host)-$ cp ../EOG091G00AH/ALICUT_EOG091G00AH.clustalo.aln.fasta \
../EOG091G00GM/ALICUT_EOG091G00GM.clustalo.aln.fasta \
../EOG091G00GQ/ALICUT_EOG091G00GQ.clustalo.aln.fasta .
```
I've made a simple script that finds the trimmed alignments given our data structure and only keeps alignemnts that are longer than 200 amino acids.
```bash
(user@host)-$ ../../script/post-filter.sh ../../data/checkpoints/per_gene/OTHERS/
```

Now, let's concatenate all files into a single supermatrix using `FASconCAT-g` (see [here](https://www.zfmk.de/en/research/research-centres-and-groups/fasconcat-g)).
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/fasconcat-g:1.04 \
FASconCAT-G.pl -a -a -s > concat.log
#remove the indivdiual alignment files. We don't need them any more.
(user@host)-$ rm *.aln.fas

```

Took a few seconds. We can look at the logfile `concat.log` to get some info about our supermatrix. The info is also there in an excel table `FcC_info.xls`.
```bash
(user@host)-$ cat concat.log
```

Now, we're ready to build our phylogenomic tree. First we need to put two more files in place. I'll do that in a new directory. First, I just copy the supermatrix from the previous step to here. Second, I create a so-called partition file `partitions.txt`, that contains the coordinates of the original genes in the supermatrix and specifies the best model of protein evolution we've determined before. I'll get this info from the output of FASconCAT and our individual gene analyses with some 'bash-magic'.
```bash
(user@host)-$ cd ..
(user@host)-$ mkdir phylogenomic-ML
(user@host)-$ cd phylogenomic-ML

#get supermatrix
(user@host)-$ cp ../post-filtering-concat/FcC_supermatrix.fas .

#create partitions file
(user@host)-$ for line in $(cat ../post-filtering-concat/FcC_info.xls | grep "ALICUT" | cut -f 1-3 | sed 's/\t/|/g')
do
	id=$(echo -e "$line" | cut -d "|" -f 1 | sed 's/ALICUT_//' | sed 's/.clustalo.*//')
	model=$(cat $(find ../ -name "$id.bestmodel") | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
	echo -e "$model, $id = $(echo -e "$line" | cut -d "|" -f 2,3 | sed 's/|/-/')"
done > partitions.txt

```
Have a look at `partitions.txt`.

Run RAxML.
```bash
(user@host)-$ docker run --rm -v $(pwd):/in -w /in chrishah/raxml-docker:8.2.12 \
raxml -f a -T 3 -m PROTGAMMAWAG -p 12345 -q ./partitions.txt -x 12345 -# 100 -s FcC_supermatrix.fas -n super
```

This will run for a few minutes.

I've deposited the final tree under `data/checkpoints/phylogenomics_ML/RAxML_bipartitions.alignment_min6`.

We can inspect it in one of the above mentioned online tree viewers. 



I've deposited the final tree under `data/checkpoints/phylogenomics_ML/RAxML_bipartitions.alignment_min6`.

We can inspect it in one of the above mentioned online tree viewers. 


__5.) Automate the workflow with Snakemake__

A very neat way of handling this kind of thing is [Snakemake](https://snakemake.readthedocs.io/en/stable/).

Remember our `summary.tsv` file from before? Let's move to where this is located.
```bash
(user@host)-$ cd ../../
```

Here, we also have a `Snakefile.txt` (it came with the repository that you downloaded). This file contains the instructions for running a workflow with Snakemake. Let's have a look.

```bash
(user@host)-$ less Snakefile.txt #exit less with 'q'
```

In the Snakefile you'll see 'rules' (that's what individual steps in the analyses are called in the Snakemake world). Some of which should look familiar, because we just ran them manually. Filenames etc. are replaced with variables but other than that..

In addition to the steps we just did manually, the workflow will also create a concatenated alignment - a 'supermatrix' - once all indiviual alignments are finished, and then run `RAxML` a final time on the supermatrix, taking into account the individual best models of protein evolution for each gene that we have identified.

Snakemake is installed on your system. In order run Snakemake you first need to enter a `conda` environment that we've set up. 

```bash
(user@host)-$ conda activate snakemake
(snakemake) (user@host)-$ snakemake -h
```

I have set up the Snakefile so that we have to give some parameters to Snakemake via the command line. You could also do that via a configuration file, but like this I am more flexible.

For time reasons, we only want to run the analyses for the first 20 genes that passed our criteria. Let's get them out of the `summary.tsv` file and into a new file `my_subset.txt`.
```bash
(snakemake) (user@host)-$ cat summary.tsv | grep -P "\tpass" | head -n 20 | cut -f 1 > my_subset.txt
```

```bash
(snakemake) (user@host)-$ snakemake -n -s Snakefile.txt \
--use-singularity --singularity-args "-B $(pwd) -B /home/classdata/Day5/" \
--latency-wait 50 \
-j 4 -p \
--config \
dir=/home/classdata/Day5/BUSCO_runs \
ingroup="$(pwd)/ingroup.txt" outgroup="$(pwd)/outgroup.txt" \
files="$(cat my_subset.txt | tr '\n' ' ' | sed 's/ $//')" \
taxids="$(pwd)/taxids.txt"
```

Now, this was a dry run, and you kind of get an idea what will be happening. No erros, so everything seems to be fine. Shall we try it for real? Rerun, but ommit the `-n` flag this time - this told Snakemake that we only wanted a dry run.

```bash
(snakemake) (user@host)-$ snakemake -n -s Snakefile.txt \
--use-singularity --singularity-args "-B $(pwd) -B /home/classdata/Day5/" \
--latency-wait 50 \
-j 4 -p \
--config \
dir=/home/classdata/Day5/BUSCO_runs \
ingroup="$(pwd)/ingroup.txt" outgroup="$(pwd)/outgroup.txt" \
files="$(cat my_subset.txt | tr '\n' ' ' | sed 's/ $//')" \
taxids="$(pwd)/taxids.txt"
```

Once this is done the final tree is written to `phylogenomics-ML/RAxML_bipartitions.final`. Let's have a look, by pasting it into [iTOL](https://itol.embl.de/upload.cgi). Note that I am displaying a larger tree I have inferred as backup. 
```bash
(snakemake) (user@host)-$ cat data/RAxML_bipartitions.final
(Rodentolepis_nana:0.03684667540504209943,(Hymenolepis_diminuta:0.05365320128818799189,((Mesocestoides_corti:0.11382175458723173267,((((Kapentagyrus_tanganicanus:0.37056695730754030116,((Gyrodactylus_bullatarudis:0.23973499259064837141,Gyrodactylus_salaris:0.26186250827709700584)100:0.33531984156394206709,Dictyocotyle_coeliaca:0.33468595952253094028)78:0.04321815271258070551)100:0.13630735625407652822,((Drosophila_melanogaster:0.49739815989886448921,(Cionia_intestinalis:0.47024946596909422691,(Danio_rerio:0.15906656119182147058,Rattus_norvegicus:0.14256395229098053901)100:0.17546133837449690018)89:0.07534725451188568901)100:0.23686787431138991988,(Schmidtea_mediterranea:0.09265905798734777599,Dugesia_japonica:0.10758755163140210076)100:0.49082413635911525951)100:0.11721256073439016709)99:0.04514198592165186152,(((((Fasciolopsis_buski:0.12314202132856488792,(Fasciola_gigantica:0.14686458395490634143,Fasciola_hepatica:0.04904295105908970664)100:0.04110413255140191180)100:0.02400932038248752842,Echinostoma_caproni:0.12849775075359745613)100:0.09450712362479178619,((Paragonimus_heterotremus:0.07823113191895705865,Paragonimus_westermani:0.07312617177590630124)100:0.10846325959356475921,(Clonorchis_sinensis:0.01770115338741783811,(Opisthorchis_viverrini:0.04817423183688491345,Opisthorchis_felineus:0.04544915068851628631)99:0.00657747865734801054)100:0.12524751424784802412)100:0.04426753715195563127)100:0.06790551400483556266,(Trichobilharzia_regenti:0.12567820298270102053,((Schistosoma_mansoni:0.03653156631204165783,Schistosoma_bovis:0.03990340723740078838)100:0.03657038711521183594,Schistosoma_japonicum:0.10768987330529999902)100:0.03415232070419779026)100:0.13566805310046556321)100:0.10769581211852248537,(Protopolystoma_xenopodis:0.24790699440159275069,(Eudiplozoon_nipponicum:0.27562366428684492714,Diclidophora_denticulata:0.13559800727544354948)100:0.18855942925413535227)100:0.10123952603231373137)79:0.03248939271548581531)100:0.15918341908895150549,(Schistocephalus_solidus:0.05308211462818494819,(Sparganum_proliferum:0.05627350778340294013,Spirometra_erinaceieuropaei:0.02427653023662926582)100:0.04156928305134222068)100:0.14572812698839465728)100:0.10312201304300923355)100:0.04960481839566012463,((Hydatigera_taeniaeformis:0.06995673418424694368,((Taenia_saginata:0.00993938860823944878,Taenia_multiceps:0.01831445652767186433)100:0.01231540977111486058,Taenia_solium:0.02397521754854715914)100:0.02957522174137439119)90:0.01077369939674101620,(Echinococcus_multilocularis:0.01421602883589030003,Echinococcus_canadensis:0.01188040184204420743)100:0.03694741512317966520)100:0.06038755425646366581)100:0.14186474816667632437)100:0.03517208801464582341,Hymenolepis_microstoma:0.03958746079266604878);
```

We can calculate the tree and internode certainties and map them onto our best ML tree.
```bash
#concatenate all individual gene trees that were used in the supermatrix
(snakemake) (user@host)-$ cd phylogenomics-ML
(snakemake) (user@host)-$ cat $(for t in $(cat partitions.txt | cut -d " " -f 2); do ls ../per_gene/$t/RAxML_bipartitions.$t.clustalo.aln.ALICUT*; done) > trees.tre
#calculate tree / internode certainty values and map them on the best ML tree
(snakemake) (user@host)-$ docker run --rm \
-v $(pwd):/in -w /in \
chrishah/raxml-docker:8.2.12 \
raxml -f i -t RAxML_bipartitions.final -z trees.tre -m GTRCAT -n TC
```

The tree comes in an usual format and I have a script that converts it to something that can be interpreted by commonly used tree viewers.
```bash
(snakemake) (user@host)-$ bash ../scripts/convert_tree.sh RAxML_Corrected_Lossless_IC_Score_BranchLabels.TC > reformated.RAxML_Corrected_Lossless_IC_Score_BranchLabels.TC 
```

Let's have a look with [iTOL](https://itol.embl.de/upload.cgi). Note, I am again displaying a tree I have inferred as backup.
```bash
(snakemake) (user@host)-$ cat data/reformated.RAxML_Corrected_Lossless_IC_Score_BranchLabels.TC 
(((Mesocestoides_corti:0.11382175458723173267,((((Kapentagyrus_tanganicanus:0.37056695730754030116,((Gyrodactylus_bullatarudis:0.23973499259064837141,Gyrodactylus_salaris:0.26186250827709700584)0.813:0.33531984156394206709,Dictyocotyle_coeliaca:0.33468595952253094028)0.477:0.04321815271258070551)0.804:0.13630735625407652822,((Drosophila_melanogaster:0.49739815989886448921,(Cionia_intestinalis:0.47024946596909422691,(Danio_rerio:0.15906656119182147058,Rattus_norvegicus:0.14256395229098053901)0.821:0.17546133837449690018)0.561:0.07534725451188568901)0.697:0.23686787431138991988,(Schmidtea_mediterranea:0.09265905798734777599,Dugesia_japonica:0.10758755163140210076)0.703:0.49082413635911525951)0.520:0.11721256073439016709)0.189:0.04514198592165186152,(((((Fasciolopsis_buski:0.12314202132856488792,(Fasciola_gigantica:0.14686458395490634143,Fasciola_hepatica:0.04904295105908970664)0.561:0.04110413255140191180)0.609:0.02400932038248752842,Echinostoma_caproni:0.12849775075359745613)0.206:0.09450712362479178619,((Paragonimus_heterotremus:0.07823113191895705865,Paragonimus_westermani:0.07312617177590630124)0.690:0.10846325959356475921,(Clonorchis_sinensis:0.01770115338741783811,(Opisthorchis_viverrini:0.04817423183688491345,Opisthorchis_felineus:0.04544915068851628631)0.477:0.00657747865734801054)0.841:0.12524751424784802412)0.619:0.04426753715195563127)0.189:0.06790551400483556266,(Trichobilharzia_regenti:0.12567820298270102053,((Schistosoma_mansoni:0.03653156631204165783,Schistosoma_bovis:0.03990340723740078838)0.789:0.03657038711521183594,Schistosoma_japonicum:0.10768987330529999902)0.541:0.03415232070419779026)0.835:0.13566805310046556321)0.817:0.10769581211852248537,(Protopolystoma_xenopodis:0.24790699440159275069,(Eudiplozoon_nipponicum:0.27562366428684492714,Diclidophora_denticulata:0.13559800727544354948)1.000:0.18855942925413535227)0.278:0.10123952603231373137)0.328:0.03248939271548581531)0.838:0.15918341908895150549,(Schistocephalus_solidus:0.05308211462818494819,(Sparganum_proliferum:0.05627350778340294013,Spirometra_erinaceieuropaei:0.02427653023662926582)1.000:0.04156928305134222068)1.000:0.14572812698839465728)0.419:0.10312201304300923355)0.337:0.04960481839566012463,((Hydatigera_taeniaeformis:0.06995673418424694368,((Taenia_saginata:0.00993938860823944878,Taenia_multiceps:0.01831445652767186433)0.598:0.01231540977111486058,Taenia_solium:0.02397521754854715914)0.690:0.02957522174137439119)0.189:0.01077369939674101620,(Echinococcus_multilocularis:0.01421602883589030003,Echinococcus_canadensis:0.01188040184204420743)0.804:0.03694741512317966520)0.481:0.06038755425646366581)0.828:0.14186474816667632437,(Hymenolepis_microstoma:0.03958746079266604878,Rodentolepis_nana:0.03684667540504209943)0.809:0.03517208801464582341,Hymenolepis_diminuta:0.05365320128818799189);
