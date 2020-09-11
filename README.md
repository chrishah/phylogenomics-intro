# phylogenomics-intro
Phylogenomics tutorial based on BUSCO genes

***Disclaimer***
To follow the demo and make the most of it, it helps if you have some basic skills with running software tools and manipulating files using the Unix shell command line. It assumes you have Docker installed on your computer (tested with Docker version 18.09.7, build 2d0083d; on Ubuntu 18.04).

## Introduction

We will be reconstructing the phylogenetic relationships of some parasitic flatworms based on previously published whole genome data. The list of species we will be including in the analyses, and the URL for the data download can be found in this <a href="https://github.com/chrishah/phylogenomics/blob/master/data/samples.csv" title="Sample table" target="_blank">table</a>.

All software used in the demo is deposited as Docker images on <a href="https://hub.docker.com/" title="Dockerhub" target="_blank">Dockerhub</a> (see <a href="https://github.com/chrishah/phylogenomics/blob/master/data/software.csv" title="software table" target="_blank">here</a>) and all data is freely and publicly available.

The workflow we will demonstrate is as follows:
- Download genomes / transcriptomes from Genbank
- Identifying complete BUSCO genes in each of the transcriptomes/genomes
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

## Why parasitic flatworms are an interesting system for phylogenomics (in a nutshell)

The phylogenetic relationships between the three major groups of parasitic flatworms, Flukes (Trematoda), Monogenea (traditionally Monophistocotylea and Polyophistocotylea), and Tapeworms (Cestoda), remain controversial. The figure below shows the three main competing hypotheses, that were published over the years. Phylogenomics might give new (hopefully more conclusive) insights, but particularly the Monogenea are rather underrepresented when it comes to genomic resources. We are currently working on changing that.

![Competing Hypotheses](data/competing_hypotheses_opist.jpg)

chrishah/busco-docker:v3.1.0 augustus --species=help

