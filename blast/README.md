The contents of this file are based on [this excellent tutorial](https://github.com/ncbi/blast_plus_docs#section-2---a-step-by-step-guide-using-the-blast-docker-image), the help and advice of labmates, and my own experience.

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
Create a Google Cloud Virtual Machine:
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

docker run hello-world
# should see "Hello from Docker!"
```

Any other time, run:
```
docker run --rm ncbi/blast update_blastdb.pl --showall pretty --source gcp
```

## Docker Commands
- `docker ps -a`: Displays a list of containers
- `docker rm $(docker ps -q -f status=exited)`: Removes all exited containers, if you have at least 1 exited container
- `docker rm <CONTAINER_ID>`: Removes a container
- `docker images`: Displays a list of images
- `docker rmi <REPOSITORY (IMAGE_NAME)>`: Removes an image
