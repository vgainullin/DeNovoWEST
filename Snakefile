import json
import sys
import os
import datetime
import tempfile
import glob

from DeNovoWEST.submit_DNE_test_pergene import load_dnms_print

with open("config.json") as fh:
	rc = json.load(fh)

current_date = datetime.date.today()
today_info = '{0}_{1:02d}_{2:02d}'.format(current_date.year, current_date.month, current_date.day)



# This doesnt seem to work with SLURM
#temp_dir = tempfile.mkdtemp(dir=rc['outpath'])
temp_dir = os.path.join(rc['outpath'],'temp1')

os.makedirs(temp_dir, exist_ok=True)

# Step 1: load all DNMs and print temporary files per gene


dnm_genes, nfiles = load_dnms_print(rc['denovospath'], temp_dir, rc['ngenesperfile'])

sys.stderr.write('There are {0} genes with DNMs\n'.format(len(dnm_genes.keys())))

PATHS = glob.glob(temp_dir+"/*.txt")

NAMES = [os.path.basename(x) for x in PATHS]
COMMAND = f"python DeNovoWEST/DNE_test.py --weightdic {rc['weightspath']} --nmales {rc['nmale']} --nfemales {rc['nfemale']}  --rates {rc['ratespath']}"

# add pvalcap
if rc['pvalcap'] != 1.0:
	COMMAND = COMMAND + ' --pvalcap {0}'.format(rc['pvalcap'])


rule all:
	input:
		expand(temp_dir+"/missense/{name}.out", name=NAMES),
		expand(temp_dir+"/all/{name}.out", name=NAMES),


rule make_missense:
	input:
		 temp_dir+"/{name}"
	output:
		variants=temp_dir+"/missense/{name}.out"
	shell:
		COMMAND + f" --denovos {temp_dir}/{{wildcards.name}} --output {rc['outpath']}/missense/{{wildcards.name}}.out"

rule make_all:
	input:
		 temp_dir+"/{name}"
	output:
		variants=temp_dir+"/all/{name}.out"
	shell:
		COMMAND + f"  --denovos {temp_dir}/{{wildcards.name}} --output {rc['outpath']}/all/{{wildcards.name}}.out"