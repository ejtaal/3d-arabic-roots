#!/bin/bash

pushd $(dirname $0)

# This script requires the mabhath-data repository:
SOURCEDIR="../mabhath-data/Perseus-Tufts/in"
CSV_FILE="./LL_3d_roots.csv"

# http://localhost:8082/mr/#conf=aa,ll=29
cat "$SOURCEDIR"/*.txt \
| egrep 'type="root|<itype' \
| perl -p -e '
s/^\s+//;
s/(Q|R)\.\s/\1\./g;
' \
| grep itype | sort | uniq -c \
| cat > stats-all-root-types.txt

cat "$SOURCEDIR"/*.txt \
| egrep 'type="root|<itype' \
| perl -p -e '
s/^\s+//;
s/(Q|R)\.\s/\1\./g;
' \
| cat > grep-roots-itypes.txt

## Debug
#cat "$SOURCEDIR"/*.txt \
#| egrep 'type="root|<itype' \
#| grep -v 'type="root" part="N"' \
#| grep -v 'alphabetical letter' \
#| perl -p -e '
#s/^\s+//;
#s/(Q|R)\.\s/\1\./g;
#s/^.*?\sn="(.*?)"\stype.*/\n,\1,/g;
#s/<itype>//g;
#s/<\/itype>.*$/,/g;
##chomp($_) unless($_ =~ /^,/);
#' \
#| cat
#
#exit 5


echo "Root,Length,No. of forms,List of forms" \
| tee $CSV_FILE

# Now produce CSV
# filter out single letter entries
cat "$SOURCEDIR"/*.txt \
| egrep 'type="root|<itype' \
| grep -v 'type="root" part="N"' \
| grep -v 'alphabetical letter' \
| perl -p -e '
s/^\s+//;
s/(Q|R)\.\s/\1\./g;
s/^.*?\sn="(.*?)"\stype.*/\n,\1,/g;
s/<itype>//g;
s/<\/itype>.*$/,/g;
chomp($_) unless($_ =~ /^,/);
' \
| perl -pe '
s/^,//;
s/,$//;
' \
| grep , \
| perl -Mutf8 -MEncode::Arabic::Buckwalter -p -e '
# Add no. of conjugations/forms found for this root
s/: or, accord. to some, tqw//;
s/, or, accord. to some, qf\*//;
s/Quasi\s+//;
s/:?\s?(and|or) ...//;
s/:?\s?(and|or) ...//;

s#[\(\) \taoi]##g;
#s#A^#____#g;
s#A\^#آ#g;
s#\^##g;
s#\$E\.#\$E#;
s#nyAj#nyj#;

$count = (tr/,//);
s/,/,$count,/;
$comma_index = index ($_, ",");
s/,/,$comma_index,/;
s#^([^,]+)#{ encode "utf8", decode "buckwalter", $1; }#gei;

#my ( $root ) = $_ =~ m/^([^,]+)/;
#Encode::_utf8_on($root);
#
#$l1 = substr( $root, 1, 1);
#print "l1 = [" . $l1 . "]";
#, root = " . $root;
#s/ (and|or) ...//;
#s/ (and|or) ...//;
' \
| grep , \
| sort -u \
| tee -a $CSV_FILE
#| cat

ls -l $CSV_FILE



:||{
	
#| perl -pe '
#| perl -pe '
#	chomp($_) unless($_ =~ /^,/);
#' \
#| perl -e '
#	undef $/; 
#	$_=<>;
#	s/(\d),\n/AAAAAAAA,/g;
#	print
#	' \
	#| egrep --color=always 'type="root|<itype'
	:
}

exit 9
BOOKSDIR=books/
OUTDIR=$SOURCEDIR/text/

PARSER=./parse-dictionary.pl

if [ -n "$*" ]; then
	books="$BOOKSDIR/$1"
else
	books=$BOOKSDIR/*
fi

for dir in $books; do
	if [ ! -d "$dir" ]; then continue; fi

	echo "==>> Processing '$dir' ..."
	book=$(basename "$dir")

	entryfile=$dir/entry.txt
	filter=$dir/filter.pl
	ignorefile=$dir/ignore.txt
	bookname=$(grep -h -m 1 book: $entryfile | awk '{ print $3 }')
	#outdir="$SOURCEDIR/$book/out"
	outdir="$OUTDIR/$bookname"
	debugdir="/tmp/debug/$book"
	debugdir="$SOURCEDIR/$book/debug"
	debugtxt="$debugdir/debug.txt"

	mkdir -p "$outdir" $debugdir
	
	for i in "$SOURCEDIR/$book/in"/*.doc; do
		if [ ! -f "$i" ]; then continue; fi
		
		converted="${i%%.doc}.abiword.txt"
		echo -en "\t$i -> $converted ... "
		
		### Converting doc -> txt using catdoc 
		#converted="${i%%.doc}.catdoc.txt"
		# Double the indentation since it's unicode
		#catdoc -m 144 "$i" > "$converted" 
		#catdoc -w "$i" > "$converted" 
		
		### Converting doc -> txt using AbiWord
		if [ -f "$converted" ]; then
			echo -n "(abiword cached) "
		else
			abiword --to=txt -o "$converted" "$i"
			echo -n "abiword done. "
		fi

		### Converting doc -> txt using OpenOffice
#		converted="${i%%.doc}.soffice.txt
#		if [ -f "$converted" ]; then
#			echo -n "(soffice cached) "
#		else
#			echo	soffice --headless --convert-to txt:text --outdir "$dir" "$i"
#			soffice_output="${i%%.doc}.txt"
#			mv -vf "$soffice_output" "$converted"
#			echo -n "soffice done. "
#		fi
		echo conversions done.
	done
		
	time pv "$SOURCEDIR/$book/in"/*.txt | \
		perl -Mutf8 -MEncode::Arabic::Buckwalter -p $filter | \
		tee $debugdir/filter-debug.txt | \
		$PARSER $ignorefile	$entryfile $outdir $bookname > $debugtxt

		#perl -C -Mutf8 -MEncode::Arabic::Buckwalter -p $filter | \
	grep    "^e " $debugtxt          > $debugdir/entries.txt
	grep    "^E " $debugtxt          > $debugdir/double-entries.txt
	grep    "^e ([^01234]" $debugtxt > $debugdir/long-entries.txt
	grep    "^i " $debugtxt          > $debugdir/ignored.txt
	grep    "^s " $debugtxt      | tee $debugdir/stats.txt
		
done

./gather-indexes.sh

popd
