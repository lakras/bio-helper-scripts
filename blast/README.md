# A Short Guide to Running BLAST

The contents of this file are based on [this excellent tutorial](https://github.com/ncbi/blast_plus_docs#section-2---a-step-by-step-guide-using-the-blast-docker-image), the help and advice of labmates, and my own experience.

## Contents
- [Helpful Links](#helpful-links)
- [Starting up a VM](#starting-up-a-vm)
- [Helpful Docker Commands](#helpful-docker-commands)
- [Preparing Query](#preparing-query)
- [Making Custom Databases](#making-custom-databases)
- [Downloading Databases](#downloading-databases)
- [Running BLAST](#running-blast)
- [Downloading Large Output Files](#downloading-large-output-files)


## Helpful Links
### Misc:
- excellent tutorial: https://github.com/ncbi/blast_plus_docs#section-2---a-step-by-step-guide-using-the-blast-docker-image
- transferring files: https://cloud.google.com/compute/docs/instances/transfer-files
- FAQs: https://support.nlm.nih.gov/knowledgebase/category/?id=CAT-01239
- book, including limiting search by taxonomy: https://www.ncbi.nlm.nih.gov/books/NBK546209/
- BLAST to BLAST+ command line: http://www.vicbioinformatics.com/documents/Quick_Start_Guide_BLAST_to_BLAST+.pdf

### On formatting blast output:
- https://www.biostars.org/p/88944/
- https://sites.google.com/site/wiki4metagenomics/tools/blast/blastn-output-format-6

### On word size and word size defaults:
- https://www.researchgate.net/post/Why_does_BLASTX_run_slow_How_can_I_speed_up_BLASTX
- https://en.wikipedia.org/wiki/Sensitivity_and_specificity
- https://www.arabidopsis.org/Blast/BLASToptions.jsp
- http://www.metagenomics.wiki/tools/blast/default-word-size
- https://bioinformatics.tugraz.at/phytometasyn/docs/blast_parameters.html
- https://www.ncbi.nlm.nih.gov/books/NBK279668/
- https://www.ncbi.nlm.nih.gov/books/NBK279684/table/appendices.T.blastx_application_options/

## Starting up a VM
Create a Google Cloud Virtual Machine (go to [cloud.google.com](https://cloud.google.com/), click Console at top right, click the hamburger menu at top left, and then Compute Engine, VM instances, and CREATE INSTANCE):
- location closest to you
- n2-highmem-16
- change boot disk to a 500GB Ubuntu 20.04 LTS

The first time after making the VM, run these commands:
```
# Run these commands to install Docker and add non-root users to run Docker
sudo snap install docker
sudo apt update
sudo apt install -y docker.io
sudo usermod -aG docker $USER
exit
# exit and SSH back in for changes to take effect
```
```
docker run hello-world
# should see "Hello from Docker!"

# make and populate directories
cd ; mkdir -p blastdb queries fasta results blastdb_custom
```

Any other time, get it warmed up and updated by running:
```
docker run --rm ncbi/blast update_blastdb.pl --showall pretty --source gcp
```

## Helpful Docker Commands
- `docker ps -a`: Displays a list of containers
- `docker rm $(docker ps -q -f status=exited)`: Removes all exited containers, if you have at least 1 exited container
- `docker rm <CONTAINER_ID>`: Removes a container
- `docker images`: Displays a list of images
- `docker rmi <REPOSITORY (IMAGE_NAME)>`: Removes an image

## Preparing Query

```
# move query to its directory
mv *fasta $HOME/queries/.

# make sure queries are all there
ls -al $HOME/queries
```

## Making Custom Databases
Replace any occurrence of `[something]` with your own content.

Make blastx database:
```
docker run --rm \
    -v $HOME/blastdb_custom:/blast/blastdb_custom:rw \
    -v $HOME/fasta:/blast/fasta:ro \
    -w /blast/blastdb_custom \
    ncbi/blast \
    makeblastdb -in /blast/fasta/[PROTEIN_SEQUENCES].fasta -dbtype prot \
    -parse_seqids -out [my-protein-database] -title "[my protein database]" \
    -taxid [NNNNNN] -blastdb_version 5
```

Make blastn database:
```
docker run --rm \
    -v $HOME/blastdb_custom:/blast/blastdb_custom:rw \
    -v $HOME/fasta:/blast/fasta:ro \
    -w /blast/blastdb_custom \
    ncbi/blast \
    makeblastdb -in /blast/fasta/[NUCLEOTIDE_SEQUENCES].fasta -dbtype nucl \
    -parse_seqids -out [my-nucleotide-database] -title "[my nucleotide database]" \
    -taxid [NNNNNN] -blastdb_version 5
```

Display the accessions, sequence length, and common name of the sequences in the databases:
```
docker run --rm \
    -v $HOME/blastdb:/blast/blastdb:ro \
    -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
    ncbi/blast \
    blastdbcmd -entry all -db [my-database-proteins] -outfmt "%a %l %T"

docker run --rm \
    -v $HOME/blastdb:/blast/blastdb:ro \
    -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
    ncbi/blast \
    blastdbcmd -entry all -db [my-database-nucleotides] -outfmt "%a %l %T"
```

Add names of sequences:
```
# download https://ftp.ncbi.nlm.nih.gov/blast/db/taxdb.tar.gz
# upload to cloud
tar -xf taxdb.tar.gz
mv taxdb.btd blastdb_custom
mv taxdb.bti blastdb_custom
```

## Downloading Databases
Display BLAST databases available on the GCP:
```
docker run --rm ncbi/blast update_blastdb.pl --showall pretty --source gcp
```

Download nt database (takes about 18 minutes):
```
docker run --rm \
  -v $HOME/blastdb:/blast/blastdb:rw \
  -w /blast/blastdb \
  ncbi/blast \
  update_blastdb.pl --source gcp nt &
```

Download nr database (takes about 1 hour).
```
docker run --rm \
  -v $HOME/blastdb:/blast/blastdb:rw \
  -w /blast/blastdb \
  ncbi/blast \
  update_blastdb.pl --source gcp nr &
```

Check database directory size (nt is about 95 GB, nr is about 237 GB):
```
du -sk $HOME/blastdb
du -sh $HOME/blastdb
```

Display database(s) that are now in `$HOME/blastdb`:
```
docker run --rm \
    -v $HOME/blastdb:/blast/blastdb:ro \
    ncbi/blast \
    blastdbcmd -list /blast/blastdb -remove_redundant_dbs
```

## Running BLAST
megablast example:
```
docker run \
  -v $HOME/blastdb:/blast/blastdb:ro -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
  -v $HOME/queries:/blast/queries:ro \
  -v $HOME/results:/blast/results:rw \
  ncbi/blast \
  blastn -task megablast -query /blast/queries/[my_query_file].fasta -db "nt [my-nucleotide-database]" -num_threads 16 \
  -outfmt "6 qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue" \
  -out /blast/results/megablast.[my_file_name].out
```

blastn example:
```
docker run \
  -v $HOME/blastdb:/blast/blastdb:ro -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
  -v $HOME/queries:/blast/queries:ro \
  -v $HOME/results:/blast/results:rw \
  ncbi/blast \
  blastn -task blastn -query /blast/queries/[my_query_file].fasta -db "nt [my-nucleotide-database]" -num_threads 16 \
  -outfmt "6 qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue" \
  -out /blast/results/blastn.[my_file_name].out
```

blastx example:
```
docker run \
  -v $HOME/blastdb:/blast/blastdb:ro -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
  -v $HOME/queries:/blast/queries:ro \
  -v $HOME/results:/blast/results:rw \
  ncbi/blast \
  blastx -task blastx -query /blast/queries/[my_query_file].fasta -db "nr [my-protein-database]" -num_threads 16 \
  -outfmt "6 qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue" \
  -out /blast/results/blastx.[my_file_name].out
```

blastx-fast example:
```
docker run \
  -v $HOME/blastdb:/blast/blastdb:ro -v $HOME/blastdb_custom:/blast/blastdb_custom:ro \
  -v $HOME/queries:/blast/queries:ro \
  -v $HOME/results:/blast/results:rw \
  ncbi/blast \
  blastx -task blastx-fast -query /blast/queries/[my_query_file].fa -db "nr [my-protein-database]" -num_threads 16 \
  -outfmt "6 qseqid sacc stitle staxids sscinames sskingdoms qlen slen length pident qcovs evalue" \
  -out /blast/results/blastx-fast.[my_file_name].out
```

`stdout` and `stderr` will be in `script.out`.
BLAST output will be in `$HOME/results`.

It can be helpful to save your versions of the above commands into a script named with the extension `.sh` (for exampled, [my_script].sh). You can then upload the script to your VM's home directory and run the script:
```
nohup bash [my_script].sh > [my_script_stdout_and_stderr].out &
```

## Downloading Large Output Files
Install `zip`:
```
sudo apt install zip
```
Run zip:
```
cd [MY_DIRECTORY]
zip -r [MY_FILENAME].zip [MY_FILENAME]
```
Download new zip file.
