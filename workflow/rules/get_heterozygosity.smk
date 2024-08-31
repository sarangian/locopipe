# This rule calls a two-step process in ANGSD. It first uses "doSaf" method to outputs 4 filetypes listed in 
# the "ext" for each sample across all chromosomes. It then runs the "realSFS" sub-module with the newly generated 
# .saf.idx file to estimate the site frequency spectrum (SFS), which is outputted in the .sfs file. 
# The global estimate of heterozygosity for each sample can be easily calculated from the SFS according to this webpage:
# http://www.popgen.dk/angsd/index.php/Heterozygosity.
rule get_heterozygosity:
    input:
        ref = REFERENCE,
        fai = REFERENCE + ".fai",
        bam = lambda wildcards: BAM_DICT[wildcards.id],
        site_list = "{basedir}/angsd/get_depth_global/combined.site_list",
        site_list_idx = "{basedir}/angsd/get_depth_global/combined.site_list.idx",
        chr_list = BASEDIR + "/docs/chr_list.txt",
    output:
        dosaf = expand("{{basedir}}/angsd/heterozygosity/{{id}}.{ext}", ext = ["saf.pos.gz", "saf.idx", "saf.gz", "arg"]),
        realsfs = "{basedir}/angsd/heterozygosity/{id}.sfs",
        done =touch("{basedir}/angsd/heterozygosity/{id}.done")
    params:
        outdir = "{basedir}/angsd/heterozygosity",
        gl_model = config["global"]["gl_model"],
        minq = config["get_heterozygosity"]["minq"],
        minmapq = config["get_heterozygosity"]["minmapq"],
        dosaf_extra = config["get_heterozygosity"]["dosaf_extra"],
        ref_type = config["global"]["ref_type"],
        realsfs_extra = config["get_heterozygosity"]["realsfs_extra"],
    threads: config["get_heterozygosity"]["threads"]
    log: 
        dosaf = "{basedir}/angsd/heterozygosity/dosaf_{id}.log",
        realsfs = "{basedir}/angsd/heterozygosity/realsfs_{id}.log"
    shell:
        '''
        mkdir -p {params.outdir}
        cd {params.outdir}
        
        ## Get saf file
        angsd \
        -i {input.bam} -anc {input.ref} -ref {input.ref} \
        -out {params.outdir}/{wildcards.id} \
        -doSaf 1 -GL {params.gl_model} \
        -P {threads} \
        -minQ {params.minq} -minmapq {params.minmapq} -sites {input.site_list}  -rf {input.chr_list} \
        -remove_bads 1 -only_proper_pairs 1 \
        {params.dosaf_extra} &> {log.dosaf}
        
        ## Get SFS from saf
        realSFS \
        {params.outdir}/{wildcards.id}.saf.idx \
        -cores {threads} \
        -fold {params.ref_type} \
        {params.realsfs_extra} > {output.realsfs} 2> {log.realsfs}
        '''

rule plot_heterozygosity:
    input:
        done=expand("{{basedir}}/angsd/heterozygosity/{id}.done", id=ALL_SAMPLES),
    output:
        plot="{basedir}/figures/heterozygosity/heterozygosity.png",
        done=touch("{basedir}/figures/heterozygosity/heterozygosity.done"),
    params:
        indir="{basedir}/angsd/heterozygosity",
        outdir="{basedir}/figures/heterozygosity",
        sample_table_path="{basedir}/docs/" + config["global"]["sample_table"],
        color_by=config["get_heterozygosity"]["color_by"],
        rscript=config["global"]["scriptdir"] + "/plot_heterozygosity.R",
    threads: 1
    log: "{basedir}/angsd/heterozygosity/plot_heterozygosity.log"
   
    shell:
        '''
        mkdir -p {params.outdir}
        Rscript --vanilla {params.rscript} {params.indir} {params.outdir} {params.sample_table_path} {params.color_by} &> {log}
        '''
