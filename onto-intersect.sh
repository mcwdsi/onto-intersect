echo "Input file #1: $1"
echo "Input file #2: $2"

# Get the basenames of the input files. Otherwise having a path in the names causes errors later.
f1=$(basename $1)
f2=$(basename $2)

# Future enhancement: strip off the extensions from f1 and f2

# Convert the input files to OWL functional notation. We are assuming they're in some other format to start, typically RDF/XML
robot convert -i $1 --format ofn -o $f1.ofn
robot convert -i $2 --format ofn -o $f2.ofn

# Filter the ofn files for the declaration sections and sort them. We sort first because we are going to later find what's in common.
grep "^Declaration" $f1.ofn | sort > $f1-declarations-sorted.txt
grep "^Declaration" $f2.ofn | sort > $f2-declarations-sorted.txt

# Get the common declarations between the two files. Note that we are assuming they use the same prefixes. A future enhancement could relax this assumption.
# Note that because we're using declarations, if the two files declare a particular IRI to be different things (e.g. class vs. object property), we will not include it.
comm -12 $f1-declarations-sorted.txt $f2-declarations-sorted.txt > $f1-$f2-intersection-declarations.tsv

# Now filter the Declaration sections down to just CURIES and then pass that into sed twice, once to erase the obo: prefix, and once to replace the colon with an underscore.
#  Note that here, too, we assume a particular prefix, and a future extension could relax that assumption.
egrep -o "(obo\:[A-Z]+_[0-9]+)" $f1-$f2-intersection-declarations.tsv | sed s/obo:// | sed s/_/:/ > $f1-$f2-intersection-curies.txt

# Now that we have just the CURIEs from the in-common Declaration section, we use robot extract, using the CURIEs file as a filter file
# And we extract first from the first input file
robot extract --method Subset --term-file $f1-$f2-intersection-curies.txt --input $1 --output $f1-$f2-intersection-from-$f1.owl
# And then extract second from the second input file. Note that the two extracts are not guaranteed to be the same, given annotations and hierarchy / taxonomy
robot extract --method Subset --term-file $f1-$f2-intersection-curies.txt --input $2 --output $f1-$f2-intersection-from-$f2.owl

echo "The in-common extract from $1 is in $f1-$f2-intersection-from-$f1.owl"
echo "The in-common extract from $2 is in $f1-$f2-intersection-from-$f2.owl"
echo "Finished."
