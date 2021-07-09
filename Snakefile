rule all:
    input:
        expand("per_gene/{BUSCO}/{BUSCO}.raxml.done", BUSCO=config["files"].split(" ")),
	"post-filtering-concat/FcC_supermatrix.fas",
	"phylogenomic-ML/RAxML_bipartitions.final"
        
rule get_seqs:
    input:
        ingroup = config["ingroup"],
        outgroup = config["outgroup"]
    params:
        script = "./scripts/fetch_seqs.sh",
        prefix = "{BUSCO}",
        dir = config["dir"]
    singularity:
        "docker://chrishah/ncbi-blast:v2.6.0"
    threads: 2
    log:
        stdout = "per_gene/{BUSCO}/get_seqs.stdout.txt",
        stderr = "per_gene/{BUSCO}/get_seqs.stderr.txt"
    output:
        "per_gene/{BUSCO}/{BUSCO}.ingroup.fasta"
    shell:
        """
	basedir=$(pwd)
        cd per_gene/{params.prefix}
        
        bash $basedir/{params.script} {params.prefix} {params.dir} {input.ingroup} {input.outgroup} 1> ../../{log.stdout} 2> ../../{log.stderr}
	mv {params.prefix}.fasta $basedir/{output}
        """
rule get_outgroups:
    input: 
        rules.get_seqs.output
    params:
        script = "./scripts/download_outgroups.sh",
        prefix = "{BUSCO}",
	taxids = config["taxids"]
    log:
        stdout = "per_gene/{BUSCO}/get_outgroups.stdout.txt",
        stderr = "per_gene/{BUSCO}/get_outgroups.stderr.txt"
    output:
        orthodb = "per_gene/{BUSCO}/{BUSCO}.orthodb.fasta",
        outgroup = "per_gene/{BUSCO}/{BUSCO}.outgroup.fasta"
    shell:
        """
        #download fastas from Orhtodb for BUSCO id
        for i in {{1..5}}
        do
             wget "http://www.orthodb.org/fasta?query={params.prefix}&level=33208" -O {output.orthodb} 1> {log.stdout} 2> {log.stderr} && break || echo -e "try again ($i)" && sleep 15
        done

	#This is quick an dirty for now and just takes the first protein if there is more than one for an outgroup taxon
        bash {params.script} {params.taxids} {output.orthodb} > {output.outgroup}
        """

rule join_groups:
    input:
        rules.get_seqs.output,
        rules.get_outgroups.output.outgroup
    params:
        prefix = "{BUSCO}"
    output:
        "per_gene/{BUSCO}/{BUSCO}.fasta"
    shell:
        """
        cat {input[0]} {input[1]} > {output}
        """
       
rule MSA:
    input:
        rules.join_groups.output
    output:
        "per_gene/{BUSCO}/{BUSCO}.clustalo.fasta"
    singularity:
        "docker://chrishah/clustalo-docker:1.2.4"
    threads: 2
    log:
        stdout = "per_gene/{BUSCO}/MSA.stdout.txt",
        stderr = "per_gene/{BUSCO}/MSA.stderr.txt"
    shell:
        """
        clustalo -i {input} -o {output} --threads={threads} 1> {log.stdout} 2> {log.stderr}
        """
        
rule score_and_cut:
    input:
        rules.MSA.output
    params:
        prefix = "{BUSCO}"
    output:
        "per_gene/{BUSCO}/ALICUT_{BUSCO}.clustalo.fasta"
    threads: 2
    singularity:
        "docker://chrishah/alicut-aliscore-docker:2.31"
    shell:
        """
        cd per_gene/{params.prefix}
        Aliscore.pl -N -r 200000000000000000 -i ../../{input} &> aliscore.log
        ALICUT.pl -s &> alicut.log
        """

rule remove_empty:
    input:
         rules.score_and_cut.output
    params:
         script = "./scripts/remove_empty.sh"
    output:
         "per_gene/{BUSCO}/empty_check.done"
    shell:
         """
         if [ "$(cat {input} | grep -v ">" | sed 's/-//g' | grep "^$" | wc -l)" -gt 0 ]
         then
              cp {input} {input}.backup
              bash {params.script} {input}.backup > {input}
         fi
         touch {output}
         """
        
rule find_best_model:
    input:
        rules.score_and_cut.output,
        rules.remove_empty.output
    params:
        prefix = "{BUSCO}"
    output:
        "per_gene/{BUSCO}/{BUSCO}.best_model"
    threads: 2
    singularity:
        "docker://chrishah/raxml-docker:8.2.12"
    log:
        stderr = "per_gene/{BUSCO}/find_best_model.stderr.txt"
    shell:
        """
        cd per_gene/{params.prefix}
        if [ ! -d find_best_model ]
        then
            mkdir find_best_model
        fi
        cd find_best_model
        ln -s ../../../{input[0]} {params.prefix}.fasta
        ProteinModelSelection.pl {params.prefix}.fasta 1> ../../../{output} 2> ../../../{log.stderr}
        """
        
rule infer_single_ML:
    input:
        rules.find_best_model.output,
        rules.score_and_cut.output
    params:
        prefix = "{BUSCO}",
        bs = 100,
	mincount = "5"
    output:
        "per_gene/{BUSCO}/{BUSCO}.raxml.done"
    threads: 2
    singularity:
        "docker://chrishah/raxml-docker:8.2.12"
    shadow: "shallow"
    log:
        stdout = "per_gene/{BUSCO}/infer_single_ML.stdout.txt",
        stderr = "per_gene/{BUSCO}/infer_single_ML.stderr.txt"
    shell:
        """
        cd per_gene/{params.prefix}
	count=$(cat ../../{input[1]} | grep ">" | wc -l)
	if [ "$count" -gt {params.mincount} ]
        then
		RAxMLmodel=$(cat ../../{input[0]} | grep "Best" | cut -d ":" -f 2 | tr -d '[:space:]')
                if [ "$(ls -1 | grep "^RAxML" | wc -l)" -ne 0 ]
		then
			rm RAxML*
		fi
        	raxml -f a -T {threads} -m PROTGAMMA$RAxMLmodel \
        	-p 12345 -x 12345 -# {params.bs} \
        	-s ../../{input[1]} -n {params.prefix}.clustalo.aln.ALICUT.$RAxMLmodel \
		1> ../../{log.stdout} 2> ../../{log.stderr}
	else
		echo "fasta file {input[1]} contains fewer than {params.mincount} sequences - skipped" > ../../{log.stdout}
		touch raxml.skipped
	fi
        touch ../../{output}
        """

rule post_filter:
    input:
        expand("per_gene/{BUSCO}/{BUSCO}.raxml.done", BUSCO=config["files"].split(" "))
    params:
        script = "./scripts/post-filter.sh",
	minlen = "100",
	mincount = "5",
	minboot = "60"
    singularity:
        "docker://chrishah/ncbi-blast:v2.6.0"
    output:
        "post-filtering-concat/post_filter.ok"
    log:
        stdout = "post-filtering-concat/post_filter.stdout.txt",
        stderr = "post-filtering-concat/post_filter.stderr.txt"
    shell:
        """
	basedir=$(pwd)
        cd post-filtering-concat
        
        bash $basedir/{params.script} ../per_gene/ {params.minlen} {params.mincount} {params.minboot} 1> ../{log.stdout} 2> ../{log.stderr}

	touch ../{output}
        """

rule concat:
    input:
        rules.post_filter.output
    singularity:
        "docker://chrishah/fasconcat-g:1.04"
    output:
        "post-filtering-concat/FcC_supermatrix.fas"
    log:
        stdout = "post-filtering-concat/concat.stdout.txt",
	stderr = "post-filtering-concat/concat.stderr.txt"
    shell:
        """
	cd post-filtering-concat

	FASconCAT-G.pl -a -a -s 1> ../{log.stdout} 2> ../{log.stderr}
	"""

rule infer_supermatrix_ML:
    input:
        fasta = rules.concat.output
    params:
        script = "./scripts/create_partitions.sh"
    singularity:
        "docker://chrishah/raxml-docker:8.2.12"
    threads: 4
    log:
        stdout = "phylogenomic-ML/infer_supermatrix_ML.stdout.txt",
        stderr = "phylogenomic-ML/infer_supermatrix_ML.stderr.txt"
    output:
        partitions = "phylogenomic-ML/partitions.txt",
        tree = "phylogenomic-ML/RAxML_bipartitions.final"
    shell:
        """
	basedir=$(pwd)
	cd phylogenomic-ML

	bash $basedir/{params.script} ../post-filtering-concat 1> ../{output.partitions} 2> partitions.err

	file=(RAxML*)
	if [ -f "$file" ]
	then
		rm RAxML*
	fi
	raxml -f a -T {threads} -m PROTGAMMAWAG -p 12345 -q ../{output.partitions} -x 12345 -# 100 -s ../{input.fasta} -n final 1> ../{log.stdout} 2> ../{log.stderr}
        """
