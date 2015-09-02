Tools to post-process NEXUS files (and some other related stuff)
================================

Renaming of sequences within NEXUS files
-------------

The tool can be given a nexus file and a file that gives a mapping from sequence
names (as found in the input file) to the names that should be used in the
generated NEXUS files. The first word (without spaces) in each line is
interpreted as the input name and the rest as the output name.

For instance, the following command

~~~
nexus --rename input.nex names.nds
~~~

will generate a file called `input.renamed.nex` which is the input nexus files
with the specified renaming applied

Addition of traits into NEXUS files
-------------

The tool can generate a bunch of NEXUS files post processed with the addition of
trait and/or geotag blocks. It must be given a nexus file and a configuration
file. Additionally, two other files must be provided:

 - a CSV file containing some trait information. One column in this file contains the sequence names as found in the input NEXUS file. The first line of the CSV file must contain the column names.
 - a file that gives a mapping from sequence names (as found in the input file) to the names that should be used in the generated NEXUS files. The first word (without spaces) in each line is interpreted as the input name and the rest as the output name.

The configuration file points to these two as well as to other information.
Example:

~~~ yaml
traits_file: path_to_csv_file.csv
name_mappings_file: path_to_name_mapping_file.nds

# Name of the column containing the sequence names in the input NEXUS file
key: arb name
# Column containing the decimal latitude (optional)
lat: lat decimal
# Column containing the decimal longitude (optional)
lon: lon decimal
# If lat/lon is provided, the number of clusters that popart should use to classify the sequences geographically
ncluters: 5
# The trait columns
traits:
 - habitat
~~~

The tool is then called with this configuration file and the NEXUS file

~~~
nexus input.nex postprocess.config
~~~

it will create a directory called like the input file, but without the extension
(here `input`). In this directory will be created one nexus file and one CSV
file per trait. The csv file contains the trait matrix (as stored in the nexus
file). If geotags are provided, one nexus file with a geotags block and one CSV
file are generated as well.

~~~
input/geotags.nex
input/geotags.csv
input/habitat.nex
input/habitat.csv
~~~

If a trait is unknown for a sequence, set the corresponding cell to ? in the CSV file

