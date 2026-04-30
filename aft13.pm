#!/usr/bin/perl

package AFT;

=head1 NAME

AFT - Anti Fake Tool Version 1.3

=head1 SYNOPSIS	

	require AFT;
	use AFT;
	AFT::aft_processor('Vorname','Nachname','PLZ','Ort','Straße','Hausnummer');
	
=head1 COPYRIGHT

copyright 2003 by Frank Schwellinger

                  76138 Karlsruhe
                  Germany
                  
                  E-Mail:     nummer_eins@web.de


=head1 DESCRIPTION

AFT-Fakenames 1.3 is a program to detect slight variations in writing names or adresses. It does
so by taking a postal adress and returning a hashstring. Various kinds of adress manipulations will
result in the same hashstring.
It is  specially designed for Germany.
It can be used mainly in the field of Internet Game Development to automatically recognize multiple participants.
It is able of detecting a wide range of different types of name and adress variations and it takes into account that
mail delivery might work, even if there occur errors in village names, ZIP-codes or street names.
Two Examples :
    aft_processor('[\(d ö t t l ä f f)\) "m o r i t z" "M. D." /karl/ ','zu Händen su. Fami1¡e acc. BrØfesšor Dr.dr.ing.schmïeeeeeddthttdtdt junior abg.','3 5l-45','   hahn0fer 43','Aleksandra-Kwallen Str. Nummer', '61-b');
and aft_processor(an "zu Händen M.B.A." sc. //mister "5/Ç/h/m/í/+/†"// dØcktor','karll mqritz Ðetle\/',' D3-5l-4S',' -|-|ann over-','Al€×andra Qualemstrassê', 'Nr.6l');
will both evaluate to the same hashvalue: 314-61-dedlcy-zchnid-gyalcnzdrazc-hancycr 
Whereas
    AFT::aft_processor('Frank','Kabel','76666','Karlsruhe','Karlstraße', '777');
and AFT::aft_processor('Franz','Kabel','76666','Karlsruhe','Karlstraße', '777');
will evaluate to different hashvalues.

 AFT-Fakenames 1.3 produces a hashvalue depending on its input.
 Same Hashvalues on different inputs mean they represent the same person, which only tries to write
 its name and/or adress in different ways in order to participate more than once in a web based game,
 contest, survey, voting etc. It turns out, that usually there are more than 100.000 different ways
 to apply barely distinguishable variations to names and adresses. Same Hashvalues means same persons
 but be aware that currently this will only hold as long as the switches are not changed. So choose your approriate
 settings for all the control variables, before you use AFT-Fakenames 1.3 in practice and then don't touch them
 any more. Never try to change order of processing! Changing order, would probably produce nonsense.
 They only way to configure aft-Fakenames 1.3 properly is by setting the control variables or calling the
 function allow_countries with the desired arguments.
 
=head1 Limitations

 The current version is not able to map two strings with two swapped consecutive characters 
 onto the same hash value. If this would be the case, then every permutation of a string would result in
 the same hashvalue, because arbirtarily often swapping characters would not change the hash value. Due to
 similar reasons, it is currently impossible to detect, if one string differs from an other one by just
 one additional or just one missing letter. There are control variables that allow to change the process
 of similarity detection. Currently they are set to recommended values. In the current version there is no API
 to change these values. Values have to be assigned manually in the source code of this modul.

  
= head1 Changes since last version of AFT

This new version 1.3 of AFT is able to detect attempts to spread spaces between the single characters of an input string,
like  'b  e  r  t  a     s  i  e  g  l  i  n  d  e' ,  or like
 'h   a  n   s       o    l a    f'

It will also detect and remove attempts to put strings in parentheses, braces or brackets, or to quote strings with
" + - / \ - ~ and many other special characters. AFT 1.3 even handles correctly multiple quotings like
'/+++"martin"+++/' and the same with parentheses, braces or brackets '(((uwe]]]' and recursive quotings like
'** /martin/ /uwe/ / --olaf-- +egon+ / **'  and the same thing with parentheses '{( ( martin ) ( uwe ) ) henry }'

Moreover AFT1.3 will handle names written like 's!o!n!j!a' 

With Version 1.3 AFT will recognize Umlaute like "u or "A. AFT will know if a double quote character is used to build
an Umlaut or if it works as a quotation character.

This new options work perfectly together with all the other recognition capabilaties, known from earlier versions
of AFT. so '//mister "5/Ç/h/m/í/+/†"//' is no challenge for AFT1.3

In case that some user finds an unknown way to bring AFT1.3 into trouble, AFT1.3 will return an 'invalid' hash string.
AFT1.3 will check its output before returning it. if the hash value does look suspect in some way, AFT1.3 will
not accept the input.

Due to complexity problems, the option of handling distributed ZIP-Codes has been temporarily removed from
AFT1.3

for the moment all the new capabilities of AFT1.3, except the new recognition facility for Umlaute,
are always working. They can't be turned off. With the next version of AFT, they can be switched 
like all the other options.

=cut 

require Exporter;
@ISA = qw(Exporter);
@Export = (aft_processor);

local $TRUE = 1;
local $FALSE = 0;

local $Zero = 0;
local $One = 1;
local $Two = 2;
local $Four = 4;
local $Five = 5;
local $Nine = 9;
local $MagicZIP = '99999';
local $Result = 'invalid';
local $ZIPLength ;

local $ErS = '(.{4,}[^aeiouy])er';
local $vn, $nn, $plz, $ort, $str, $hn, @vnc, @nnc;
local $ZIPCharacters = '[\)\(\dOlZSGBg\-]';
local %CountrySigns = ( Germany => D, Austria => A, Switzerland => CH );
local %CountryZIPLength = ( D => $Five, A => $Four, CH => $Four);
local %ListOfAllowedCountries = ( D => $FALSE, A => $FALSE, CH => $FALSE );


# Switches to Control the behavior of AFT-Fakenames 1.2----------------------------------------------------------
# preset values are recommended

local $DefaultCountry = 'Germany';


$ZIPReductionLevel = 2; # discarding the last digits of ZIP-code; a value of 0 turns this option off!

$SwappedCharactersDetection = 0; # feature unavailable - its impossible to implement this feature with hash values.
			         # some future version of aft might provide this option when comparing 2 given
				 # adresses directly
                                 
$PhoneticCheck = $TRUE; # maps similar sounding strings to the same hashvalue when $TRUE

$OpticalCheck = $TRUE; # maps similar looking strings to the same hashvalue when $TRUE

$DiphtongReconstruction = $TRUE; # Destroyed Diphtongs will be estimated. Diphtong Reconstruction will however
                                 # not work if OpticalCheck is turned off

$TitelCheck = $TRUE; # disregards most common salutations and academic titles when $TRUE

$RemoveAbrevationsInNames = $TRUE; # When True, removes everything in first name and last name that ends with '.'

$FirstNameLastNameSwapCheck = $TRUE; # Swapping First and Last Name in Input will be detectet when $TRUE

$OrderOfFirstNamesCheck = $TRUE; # Using multiple First names in different orders will be detectet when $TRUE

$DenyNameAbrevations = $FALSE; # When TRUE, and Abrevations of Names are used then a hash value of 'invalid' will be returned
			       # titles and salutations will not be affected by this option
			       # $Titelcheck must be TRUE to use this option

$DenyAnythingThatLooksLikeTitleSalutationOrAbrevationInName = $FALSE; # When True and any kind of title,
								      # salutation or abrevation in first
								      # or last name is detectetd, 'invalid'
								      # will be returned. This is the most
								      # restrictive option concerning titles
								      # and abrevations. If turned on, it
								      # will override all other options
								      # concerning titels or abrev. in names

$DenyDigitsInNames = $FALSE; # When turned on, any digit that occurs in first or last name will cause a
			     # return value of 'invalid'. This option should be used, while 
			     # $DigitAlphabeticSubstitutionCheck is not available.

$DenySpecialCharactersInNames = $FALSE; # When turned on, any special character except ' . - _ digits and white
				       # space characters will cause a return value of 'invalid'. This option 
				       # should be used, while $SpecialCharacterSubstitutionCheck
				       # is not available.
			       
$StreetNameAbrevationsCheck = $TRUE; # When TRUE Abrevations of Streetnames will be detectet

$DigitAlphabeticSubstitutionCheck = $TRUE; # Detects attempts to replace alphabetic characters by 
					   # similar looking digits, when true

$AlphabeticDigitSubstitutionCheck = $TRUE; # Detects attempts to replace digits by similar looking alphabetic
					  # characters, when true

$SpecialCharacterSubstitutionCheck = $TRUE; # Detects attempts to replace alphabetic characters by similar 
														  # looking special characters or combinations of them. When TRUE
														  # this option overrides $DenySpecialCharactersInNames
														  	
$StrongTitleCheck = $TRUE; # When TRUE, titles are also detected, if they are misspelled. same rules apply
									# then to title checking as for name checking, when FALSE, only to lower case
									# normalization will be applied to titles

$ForceZIPOnDigitError = $FALSE; # when True and no Zip-code detectet, then some magic numer is assumed as ZIPcode
		    # when False, a missing Zip-code will cause return of 'invalid' without further adress processing
		    # if there are not exactly the number of digits of a valid ZIP-code of the corresponding country found, 
		    # then no Zipcode is detectet. If $AlphabeticDigitSubstitutionCheck is True, then digit counting starts 
		    # after substitution of alphabetic characters by similar looking digits.
		    
$ForceZIPOnCountryError = $FALSE; # when True and a ZIP-Code from a country that is not allowed will be detected
											 # then a magic number will be returned, when FALSE in this case an 'invalid'-
											 # hashvalue will be returned, processing will be terminated.
		    
$DistributedZIPCodeCheck = $FALSE; # Detects, when some Portion of the ZIP-Code has been transfered to the city name
											 # $plz = 'D -345';  $ort = '12 blabla'; is eqivalent to
											 # $plz = '34Sl2'; $ort = 'blabla'; or
											 # $plz = ''; $ort = 'D 3 4 5 1 2 blabla';
											
allow_countrys(Austria,Switzerland); # Adresses from these countrys will be accepted unless their ZIP-Codes have wrong
												 # number of digits. This function call accepts an arbitrary number of
												 # arguments

$PushCountryCode = $FALSE; # When TRUE, a CountryCode (A for Austria, D for Germany, CH for Switzerland) will be
									# added to the Hashstring. The Countrycode will be taken from the ZIPCode, if no
									# Countrycode is given, D will be taken by default.
									
$SupressEnding_er = $TRUE; # When TRUE, word endings 'er' will be discarded in street names last names and first names

$ResolveAccents = $TRUE; # When TRUE, "u will be transformed to ü  etc.								 	
#--------------------------------------------------------------------------------------------------------------------

# some initial code:
#determine code of default country
local $Country = $CountrySigns{$DefaultCountry};
#-------------------------------------------------------------------------------------------
local $ActualCountry = $Country;
#allow the default country
$ListOfAllowedCountries{$Country} = $TRUE;
#-------------------------------------------------------------------------------------------
#determine the default ZIPCode length of the DefaultCountry
$ZIPLength = $CountryZIPLength{$Country};
#-------------------------------------------------------------------------------------------
#determine minimum ZIP-Code length
$MinZIPLength = $ZIPLength;
local $zl;
foreach $zl (values %CountryZIPLength){
	if ($zl < $MinZIPLength) {
		$MinZIPLength = $zl;
	}
}
# -----------------------------------------------------------------------------------------
#build the reduced array with the signs of all allowed countries except the default country
@AllAllowedCountriesExceptDefaultCountry = ();
local $cl;
foreach $cl (keys %ListOfAllowedCountries){
	if ( $ListOfAllowedCountries{$cl} && ($cl ne $Country) ) {
		push @AllAllowedCountriesExceptDefaultCountry , $cl;
	}
}
# -----------------------------------------------------------------------------------------
#building a pattern matching string for later separating of country sign from ZIP-Code
local $CountryFromZIPStrippingAllowed = '^\s*(';
foreach (@AllAllowedCountriesExceptDefaultCountry) { # the actually allowed countries
	$CountryFromZIPStrippingAllowed .=('|' . $_);
}
$CountryFromZIPStrippingAllowed .= ')\s*-?\s*(.*)$';
#remove the first pipe-character after opening bracket
$CountryFromZIPStrippingAllowed =~ s/\(\|/(/g;
#---------------------------------------------------------------------------------------
#building another pattern matching string for later separating of country sign from ZIP-Code
local $CountryFromZIPStrippingAll = '^\s*(';
foreach (keys %ListOfAllowedCountries) { # all countries from the list of available countries
	if ( $_ ne $Country) {
		$CountryFromZIPStrippingAll .=('|' . $_);
	}
}
$CountryFromZIPStrippingAll .= ')\s*-?\s*(.*)$';
#remove the first pipe-character after opening bracket
$CountryFromZIPStrippingAll =~ s/\(\|/(/g;

#---------------------------------------------------------------------------------------
print aft_processor('moritz karl egon','Hr. pr0f. dr. Kniettelsmayer','D-6 1 4 5-5',' 5ie9en 23','Kwallenstr. 66-b');
print "\n";
print aft_processor('+++Herr+++  K N i t t e 1 s m c i e r  jun"uor dr.  J~u~n~i~o~r','karll mqritz eG0N','D61458',' Sigên','Qualemstrasse Nr.66');
print "\n";

print aft_processor('[\(d ö t t l ä f f)\) "m o r i t z" "M. D." /karl/ ','zu Händen su. Fami1¡e acc. BrØfesšor Dr.dr.ing.schmïeeeeeddthttdtdt junior abg.','3 5l-45','   hahn0fer 43','Aleksandra-Kwallen Str. Nummer', '61-b');
print "\n";

print aft_processor('an "zu Händen M.B.A." sc. //mister "5/Ç/h/m/í/+/†"// dØcktor','karll mqritz Ðetle\/',' D3-5l-4S',' -|-|ann over-','Al€×"andra Qualemstrassê', 'Nr.6l');
print "\n";
#---------------------------------------------------------------------------------------
sub allow_countrys {
	foreach (@_){
		$ListOfAllowedCountries{$CountrySigns{$_}} = $TRUE;
	}	
} # end allow_country ----------------------------------------------------------------------------------------------

sub string_concentrator1{
my $temp = $_[0];
return $temp;
}

sub string_concentrator {
	my $temp = $_[0];
	my $keep2;
	my $found = $TRUE;
	my $splitterstring = '[\s\_\+\*\-\,;~\\\/%!\|]';
	#my $splitterstring = '[\s]';
	my @splitfield = split (/$splitterstring/, $temp); 
	while ((5*($#splitfield+1) > length($temp)) && $found) {
		$found = $FALSE;
		if ($temp =~ /([a-zA-ZäöüÄÖÜß0-9])($splitterstring)([a-zA-ZäöüÄÖÜß0-9])((\2([a-zA-ZäöüÄÖÜß0-9]))+)/) {
			$keep2 = $2; 
			$found = $TRUE;
			$keep2 = quotemeta($keep2);
			$temp =~ s/([^$keep2])$keep2([^$keep2])$keep2?/$1$2/g; 
			$temp =~ s/([^$keep2])$keep2([^$keep2]$keep2)/$1$2/g;
			@splitfield = split (/$splitterstring/, $temp); 
		}
		if ($temp =~ /($splitterstring)\1/) {
			$keep2 = $1;
			$found = $TRUE;
			$temp =~ s/($keep2)($keep2)/$1/g;
			$temp =~ s/^([^$keep2])($keep2)/$1/g;
			$temp =~ s/($keep2)([^$keep2])$/$2/g;
		}
		@splitfield = split (/$splitterstring/, $temp); 
	}
	# just to remove single spaces
	#$temp =~ s/(\S)\s{1,1}(\S)/$1$2/g;
	$temp =~ s/§+/ /g;
	return $temp;
}

sub parentheses_level_analyzer {
	my $tempb = $_[0];
	my $k, $l;
	my $ParenthesesCount = '@';
	my $tempbscan;
	$ParenthesesLevel='';
	for ($k=$Zero; $k<length($tempb); $k++) {
		$l = substr($tempb,$k,1);
		if ( $l eq '(' ) {
			$ParenthesesCount = chr(1+ord($ParenthesesCount));
			$ParenthesesLevel .= $ParenthesesCount;
		}
		else {
			if ( $l eq ')') {
				$ParenthesesLevel .= $ParenthesesCount;
				$ParenthesesCount = chr(ord($ParenthesesCount)-1);
			}
			else { 
				if ( ($l eq ' ') || ($1 eq '\t')) {
					$ParenthesesLevel .= $Nine;
				}
				else { # some ordinary character
					$ParenthesesLevel .= $Zero;
				}
			}
		}			
	}	
	return $ParenthesesLevel;
} # end parentheses_level_analyzer ------------------------------------------------------------------


sub strip_off_quotes {
	my $temp = $_[0];
	$temp = ' ' . $temp . ' ';
	my $tempb = $temp; # a second temp-variable for parentheses removement
	my $ParenthesesLevel; # keeps information about perentheses-nesting-level according to $tempb
	my $changed = $TRUE;
	my $keeptemp, $keeptempb;
	my $no_t = $TRUE; # do not replace '+' by 't'
	if ($SpecialCharacterSubstitutionCheck) {
		$temp = special($temp,$no_t);
	}
	#building search pattern for Umlaute, more to come with special character check
	my $subpattern = '"u|u"|"U|U"|"o|o"|"O|O"|"a|a"|"A|A"';
	if ($OpticalCheck) {
		$subpattern .= '|"ü|ü"|"Ü|Ü"|"ö|ö"|"Ö|Ö"|"ä|ä"|"Ä|Ä"|"\@|\@"|"c|c"|"C|C"|"q|q"|"v|v"|"V|V"|"y|y"|"Y|y"';
	}
	if ($DigitAlphabeticSubstitutionCheck) {
		$subpattern .= '|"0|0"';
	}
		
	while ($changed) {
		$keeptemp = $temp;
		$keeptempb = $tempb;
		$changed = $FALSE;
		$temp =~ s/(.*\s)(\+|-|\*|#|\.|\,|;|~|\\|\/|%|!|\|)([^\2]+)\2(\s.*)/$1 $3 $4/g;

		$temp =~ s/(.*\s)"(([^"]+)|(([^"]+)($subpattern)([^"]+)))"(\s.*)/$1$2$8/g;
		
		if ( $temp ne $keeptemp) {
			$changed = $TRUE;
		}
		# check parentheses
		$tempb = $temp;
		# translate braces and brackets into parentheses
		$tempb =~ tr/{[]}/(())/;

		# building parentheses-nesting-level-information
		$ParenthesesLevel = parentheses_level_analyzer($tempb);

		# continue according to parentheses-nesting-level-information
		
		# case number one, only one pair of parentheses of top level exists.
		# and no text can be found outside this pair, then delete this pair and
		# all surrounding portions of the string. Then rescan parentheses structure.
		if ( $ParenthesesLevel =~ /^9*A[^A]+A9*$/) {
			$tempb =~ s/^\s*\((.*)\)\s*$/$1/g;
			$ParenthesesLevel = parentheses_level_analyzer($tempb);
			$changed = $TRUE;			
		}
		
		
		#case number two, only one pair of of parentheses of top level exists.
		# text can be found left or right outside these parentheses.
		# then remove superfluid blanks from the text. the outer parentheses 
		# can be replaced by many blanks all inner parenthesis will be
		#replaced by a single blank. remove superfluid blanks inside the parentheses
		#if ( $ParenthesesLevel =~ /^[09]*A[^A]+A[09]*$/) {
		if ( $ParenthesesLevel =~ /^[09]*A.+A[09]*$/) {
			$tempb =~ /^([^\(]*)\((.*)\)([^\)]*)$/g;
			$tempbscan = '';
			for (my $m = $Zero; $m < length($tempb); $m++) {
				my $tstr = substr($ParenthesesLevel,$m,1);
				if ( $tstr eq '0') {
					$tempbscan .= substr($tempb,$m,1);
				}
				if ( ($tstr ge 'A') && ($tstr le 'Z') ) {
					#$tempbscan .= ' 'x(3*(ord('Z')-ord($tstr)));
					$tempbscan .= '§';
				}
				if ( $tstr eq 'A' ) {
					$tempbscan .= ' 'x(3*(ord('Z')-ord($tstr)));
				}
				if ($tstr eq '9') {
					$tempbscan .= ' ';
				}
			}
			$tempb = $tempbscan;
			$changed = $TRUE;
		}
		
		
		#case number three, more than one pair of top level parentheses exists.
		# equivalent to case number 2
		
		if ( $tempb ne $keeptempb) {
			$changed = $TRUE;
		}
		$temp = $tempb;
	}
	$temp =~ s/^\s+(.*)\s+$/$1/g;
	
	return $temp;
} # end strip_off_quotes -------------------------------------------------------------------------------------------


sub resolve_accents { # this is subject to country specific changes, now only german rules apply
	my $temp = $_[0];
		$temp =~ s/(.*)"[aA]/$1ä/g;
		$temp =~ s/(.*)"[oO]/$1ö/g;
		$temp =~ s/(.*)"[uU]/$1ü/g;
	if ($OpticalCheck) { 
		$temp =~ s/(.*)"[\@äÄ]/$1ä/g;
		$temp =~ s/(.*)"[cCqöÖ]/$1ö/g;
		$temp =~ s/(.*)"[vVYyüÜ]/$1ü/g;
	}
	if ($DigitAlphabeticSubstitutionCheck) {
		$temp =~ s/(.*)"[0]/$1ö/g;
	}
		$temp =~ s/(.*)[aA]"/$1ä/g;
		$temp =~ s/(.*)[oO]"/$1ö/g;
		$temp =~ s/(.*)[uU]"/$1ü/g;
	if ($OpticalCheck) { 
		$temp =~ s/(.*)[\@äÄ]"/$1ä/g;
		$temp =~ s/(.*)[cCqöÖ]"/$1ö/g;
		$temp =~ s/(.*)[vVYyüÜ]"/$1ü/g;
	}
	if ($DigitAlphabeticSubstitutionCheck) {
		$temp =~ s/(.*)[0]"/$1ö/g;
	}	
	return $temp;
	
} # end ResolveAccents ---------------------------------------------------------------------------------------


sub special {
	my $temp = $_[0];
	if (!$_[1]) {
		$temp =~ s/\+/t/g;
	}
	$temp =~ tr/€ƒ†Š@Ÿ¡¢£¤µ¶ÇÐÑ×ñ/eftSaYicLouqCDNxn/;
	$temp =~ tr/š$¥©ªç/sSYoac/;
	$temp =~ tr/§°Ý‹/SoYc/;
	$temp =~ tr/º/o/;
	$temp =~ s/À|Á|Â|Ã|Å/A/g;
	$temp =~ s/È|É|Ê|Ë/E/g;
	$temp =~ s/Ì|Í|Î|Ï/I/g;
	$temp =~ s/Ò|Ó|Ô|Õ|Ø/O/g;
	$temp =~ s/Ù|Ú|Û/U/g;
	$temp =~ s/à|á|â|ã|å/a/g;
	$temp =~ s/è|é|ê|ë/e/g;
	$temp =~ s/¡|ì|í|î|ï/i/g;
	$temp =~ s/ð|ò|ó|ô|õ|ø/o/g;
	$temp =~ s/ù|ù|ú|û/u/g;
	$temp =~ s/ý|ÿ/y/g;
	$temp =~ s/\|\\\|/N/g;
	$temp =~ s/\|\\\/\|/M/g;	
	$temp =~ s/\\\/\\\//W/g;	
	$temp =~ s/\/\\/A/g;
	$temp =~ s/\\\//V/g;	
	$temp =~ s/\|-\|/H/g;
	$temp =~ s/\(\)/O/g;	
	
	return $temp;
}

sub remove_titles {
	my $temp = $_[0]; # name
	my $uu = $_[1]; # title
	my $i;
	my @hold;
	my $build;
	if ($StrongTitleCheck) {
		# detect titles in names, even if titels are misspelled eg. 'provesor', 'Docktor' etc.
		# the rules of misspelling detection of names are also applied to titles
	
		# split the name by blank as seperator
		my @tempName = split(/\s+/,$temp);
		
		# normalize the title
		$uu = lc($uu);
		
		$uu = strip_off_quotes($uu);
		if ($ResolveAccents) {
			$uu = resolve_accents($uu);
		}
		if ($OpticalCheck && $DiphtongReconstruction) {
			$uu = diphtong($uu);
		}			
		if ($PhoneticCheck) {
			$uu = phonetic($uu);
		}
		if ($OpticalCheck) {
			$uu = optical($uu);
		}		


		# normalize each name component and compare it with normalized title component
		foreach $i (@tempName) {
			$build = $i;
			$build = lc($build);
			$build =~ tr/ÄÖÜ/äöü/;
			$build = strip_off_quotes($build);
			if ($ResolveAccents) {
				$build = resolve_accents($build);
			}			
			if ($OpticalCheck && $DiphtongReconstruction) {
				$build = diphtong($build);
			}			
			if ($PhoneticCheck) {
				$build = phonetic($build);
			}
			if ($OpticalCheck) {
				$build = optical($build);
			}


			if ($uu ne $build) {
				push @hold, $i;
			}
		}
		$temp = join ' ', @hold;
	}
	else {
		$temp =~ s/^\s*$uu(\s+.*)$/$1/ig;
		$temp =~ s/^(.*)\s*$uu\s*$/$1/ig;
		$temp =~ s/(.*\s+)$uu(\s+.*)/$1$2/ig;
		$temp =~ s/^\s*(.*)$/$1/g;
	}	

	return $temp;
} # end remove_titles-------------------------------------------------------------------------------

sub remove_titles2 {
	my $temp = $_[0];
	my $uu = $_[1];
	
	$temp =~ s/^\s*$uu(\s+.*)$/$1/ig;
	$temp =~ s/^(.*)\s*$uu\s*$/$1/ig;
	$temp =~ s/(.*\s+)$uu(\s+.*)/$1$2/ig;
	$temp =~ s/^\s*(.*)$/$1/g;	
	
	return $temp;	
} # end remove_titles2---------------------------------------------------------------------------------

sub remove_abrevatedTitles {
	my $temp = $_[0];
	my $uu = $_[1];
	$temp =~ s/^\s*$uu(\s*.*)$/$1/ig;
	$temp =~ s/^(.*)\s*$uu\s*$/$1/ig;
	$temp =~ s/(.*\s+)$uu(\s+.*)/$1$2/ig;
	$temp =~ s/^\s*(.*)$/$1/g;	
	
	return $temp;	
} # end remove_abrevatedTitles-------------------------------------------------------------------------------

sub alphadig {
	my $temp = $_[0];
	$temp =~ tr/OlZSGBg/0125689/;
	
	return $temp;
} # end alphadig ------------------------------------------------------------------------------------ 

sub alphadig_for_distributed_ZIPCodes { # this function is obsolete --------------------------------
													 # however it will be called from 'dead' code, so do not remove it
	my $temp = $_[0];
	
	$temp =~ s/O([\d\s\-])/0$1/g;
	$temp =~ s/l([\d\s\-])/1$1/g;
	$temp =~ s/Z([\d\s\-])/2$1/g;
	$temp =~ s/S([\d\s\-])/5$1/g;
	$temp =~ s/G([\d\s\-])/6$1/g;
	$temp =~ s/B([\d\s\-])/8$1/g;
	$temp =~ s/g([\d\s\-])/9$1/g;

	
	return $temp;
} # end alphadig_for_distributed_ZIPCodes-------------------------------------------------------------

sub digialph_for_distributed_ZIPCodes {  # this function is obsolete -----------------------------
													 # however it will be called from 'dead' code, so do not remove it
	my $temp = $_[0];
	
	$temp =~ s/(\s+|[^\d\s\-])0([^\d\s\-])/$1O$2/g;
	$temp =~ s/(\s+|[^\d\s\-])1([^\d\s\-])/$1l$2/g;
	$temp =~ s/(\s+|[^\d\s\-])2([^\d\s\-])/$1z$2/g;
	$temp =~ s/(\s+|[^\d\s\-])3([^\d\s\-])/$1ß$2/g;
	$temp =~ s/(\s+|[^\d\s\-])4([^\d\s\-])/$1q$2/g;
	$temp =~ s/(\s+|[^\d\s\-])5([^\d\s\-])/$1s$2/g;
	$temp =~ s/(\s+|[^\d\s\-])6([^\d\s\-])/$1G$2/g;
	$temp =~ s/(\s+|[^\d\s\-])8([^\d\s\-])/$1B$2/g;
	$temp =~ s/(\s+|[^\d\s\-])9([^\d\s\-])/$1Og$2/g;

	
	return $temp;
} # end digialph_for_distributed_ZIPCodes------------------------------------------------------------- 

sub digialph {
	my $temp = $_[0];
	$temp =~ tr/123456890/lzßqsGBgo/;
	
	return $temp;
} # end digialph -------------------------------------------------------------------------------------


sub remabrev {
	my $tempa = $_[0];
	my $tempr = $tempa;
	# first try to remove quotation of abrevations
	$tempr =~ s/^\s*(([^\.\s]+\s+)*)[^\.\s]+\.\s*(.*)$/$1$3/ig;
	while ( $tempa ne $tempr) {
		$tempa = $tempr;
		$tempr =~ s/^\s*(([^\.\s]+\s+)*)[^\.\s]+\.\s*(.*)$/$1$3/ig;
	}

	return $tempr;
} # end remabrev --------------------------------------------------------------------------------------

sub diphtong {
	my $temp = $_[0];
	$temp =~ s/ci|ej|cj/ei/g;
	$temp =~ s/eü|ey|cu/eu/g;	
	$temp =~ s/aj/ai/g;
	$temp =~ s/aü/au/g;
	$temp =~ s/äü|äy/äu/g;
	$temp =~ s/oü/u/g;
	
	return $temp;
} # end diphtong -------------------------------------------------------------------------------------

sub er_ending_reconstruction {  #### NOT YET USED  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
		my $temp = $_[0];
		$temp =~ s/(.*)cr\s*$/$1er/g;
		
		return $temp;
} # end er_ending_reconstruction ---------------------------------------------------------------------

sub phonetic {
	my $temp = $_[0];
	$temp =~ s/scht/st/g;
	$temp =~ s/ck/k/g;
	$temp =~ s/vv/w/g;
	$temp =~ s/ph/f/g;
	$temp =~ s/([^c])h/$1/g;
	$temp =~ s/([dt]+h*[dt]*)+/d/g;
	$temp =~ s/[pb]+/b/g;
	$temp =~ s/([gk]+h*[gk]*)+/g/g;			
	$temp =~ s/(.)\1+/$1/g;
	$temp =~ s/ey|ej|ai|ay|aj/ei/g;
	$temp =~ s/äu/eu/g;
	$temp =~ s/ou/u/g;
	$temp =~ s/[äö]/e/g;
	$temp =~ s/ü|y/i/g;
	$temp =~ s/([^aeiou]i)e/$1/g;
	$temp =~ s/tz|ts/z/g;
	$temp =~ s/c(a|o)/k$1/g;
	$temp =~ s/c([^h])/z$1/g;	
	$temp =~ s/qu/kw/g;
	$temp =~ s/x/ks/g;
	$temp =~ s/w|f/v/g;
	$temp =~ tr/ptkß/bdgs/;
	
	return $temp;
} # end phonetic --------------------------------------------------------------------------------------

sub optical {
	my $temp = $_[0];
	$temp =~ s/o|ö|p/c/g;
	$temp =~ s/q([^u])/c$1/g;
	$temp =~ s/u|ü|v/y/g;
	$temp =~ tr/jmst/inzf/;
	$temp =~ s/([^=])e/$1c/g;
	$temp =~ s/ä/a/g;
	
	return $temp;	
} # end optical ----------------------------------------------------------------------------------------

sub remove_ending_er {
	my $temp = $_[0];	
		$temp =~ s/$ErS\s*$/$1/g;
		
	return $temp;	
} # end  remove_ending_er ------------------------------------------------------------------------------



sub aft_processor {
	# extract variables from arguments--------------------
	$vn = $_[0];
	$nn = $_[1];
	$plz = $_[2];
	$ort = $_[3];
	$str = $_[4];
	$hn = $_[5];
	

	strip_off_quotes($ort);

	strip_off_quotes($str);

	if ($ResolveAccents) {
		$ort = resolve_accents($ort);
		$str = resolve_accents($str);							
	}
	
	# necessary for some special character detections
	quotemeta($vn);
	quotemeta($nn);
	quotemeta($ort);
	quotemeta($str);
	$Country = $CountrySigns{$DefaultCountry};
	$ActualCountry = $Country;
	$ZIPLength = $CountryZIPLength{$Country};
	# initialize most commen titels and salutations
	my @titles = ("Herr", "Frau", "Familie", "Fräulein","Doktor", "Professor",
						 "sc", "Mister", "Missis", "lady", "madam", "sir", "monsieur", "madame", "Monsigneur", 
	                "Mlle", "Mademoiselle", "Jnr", "jun", "Jr", "Junior", "MBA", "Ms", "Mistress", "MSc", "monsignore", "professore", 
	                "sig", "signore", "sig.a", "signora", "sig.na", "signorina", "Dn", "Don", "D.a", "Dona", "Sa", "Sra", "Senora", "sen", "Senior", "Sr.ta",
	                "Srta", "Senorita", "gospodin", "gospodina", "gosp", "Van", "De", "La", "Du", "z.Hd", "an", "Herrn");
	
	# initialize most commen titels and salutations with two words
	my @titles2 = ( "zu Händen", "zu Hd", "z. Hd", "z. Händen", "zu Händ");

	# initialize most commen titels and salutations, abrevated ones only. this splitting improves efficiency and recognition 
	my @abrevatedTitles = ("Hr.", "Fr.", "Fa.", "Frl.",  "Dr.", "Doktor", "Dipl.", "Prof.", "ing.", "inf.", "inform.", "pol.", "jur.", "h.c.", "h. c.", "habil.",
	                "agr.", "disc.", "forest.", "utr.", "med.", "dent.", "vet.", "oec.", "publ.", "öc.", "troph.", "paed.", "päd.", "pharm.", "phil.", "nat.", "rer.", "hort.", 
	                "mont.", "techn.", "sc", "math.", "theol.", "Mr.", "Mrs.", "M.",  "Mgr.", 
	                 "jnr.", "jun.", "junr.", "jr.", "M.B.A.", "ms.", "msc.", "mons.", 
	                "sig.", "sig.a", "sig.na", "D.", "Dn.", "D.a",  "Sa.", "Sra.", "sen.", "Sr.ta",
	                "Srta.", "gosp.", "zu Hd.", "z. Hd.", "z.Hd.", "zu Händ.");



	
#  Z I P    C O D E    P R O C E S S I N G ***************************************************************
#  -------------------------------------------------------------------------------------------------------	
	# prepare ZIP-Code, cutting of the end------------------
	if ($AlphabeticDigitSubstitutionCheck) {
	$plz = alphadig($plz);
	}

	# there must be at most $ZIPLength digits within ZIP otherwise adress is invalid
	# in case that Adresses form other countries are valid appropriate number of digits
	# will be accepted, if there is a leading sign of another alloewd country

	# this code will be executed if a non-Default-Country CountryCode is given -----------------------
	if($#AllAllowedCountriesExceptDefaultCountry+1  > 0 && $plz =~ /$CountryFromZIPStrippingAll/){
		$ActualCountry = $1; 
		$ZIPLength = $CountryZIPLength{$ActualCountry};
		$plz = $2;

		if ( !$ListOfAllowedCountries{$ActualCountry} ) {
			if ($ForceZIPOnCountryError) {
				$plz = $MagicZIP;
			}
			else {
				return $Result . '- Teilnahme aus diesem Land nicht erlaubt';
			}	
		}
	}

	# checking if ZIP-Code has too many digits --------------------------------------------------------
	$ZIPPlus1 = $ZIPLength + $One;	
	# eventually strip of leading Defaultcountry sign
	#$plz =~ s/^\s*$DefaultCountry\s*-?\s*(.*)$/$1/i;
	$plz =~ s/^\s*$Country\s*-?\s*(.*)$/$1/i;
	if ($plz =~ /^(.*\d){$ZIPPlus1}/) {
		if ($ForceZIPOnDigitError) {
			$plz = $MagicZIP;
		}
		else {
			return $Result . '- zu viele Ziffern in der Postleitzahl';
		}
	}

	
	my $heal = $FALSE; # $heal will become true, if there exists a correct distributed ZIP-code			
	# there must be at least $ZIPLength digits within ZIP otherwise adress is invalid
	

	if ($plz =~ /^(.*\d){$ZIPLength}.*$/) {

		# remove all other characters, extract the digits only		
		my $ZIPDigitsPattern = '^.*';
		for (my $li = $One; $li < $ZIPLength; $li++) {
			$ZIPDigitsPattern .= '(\d).*';
		}
		$ZIPDigitsPattern .= '(\d).*' . '$';
		$plz =~ s/$ZIPDigitsPattern/$1$2$3$4$5$6$7$8/g; # assuming there will be never more than 8 digit ZIPCodes anywhere

		# cut of last digits
		if (!$DistributedZIPCodeCheck) {
			$plz = substr($plz,0,5-$ZIPReductionLevel);
			#remove trailing digits from city
			$ort =~ s/^(.*)\s+(\d|\s|-)*$/$1/g;

			if ($AlphabeticDigitSubstitutionCheck) {
				$ort = digialph($ort);
			}
		}
		# heal will be true and only changed by distributed plz
		$heal = $TRUE;
	}

#		if($DistributedZIPCodeCheck) {   ####################  currently this option will not be supported
#
#			my $plzh = $plz;
#
#			$plzh =~ s/\D//ig; #remove everything but digits
#
#			my $plzc = length($plzh); #number of digits in the $plz portion of the ZIP-code
#
#			my $plzo = $ZIPLength - $plzc; # number of digits of ZIP-Code expected in the $ort field
#			my $orth = $ort;
#			my $orth3 = $orth;
#			# currently slightly restricted, better results later with city names
#			if($plzo){
#				$orth =~ s/^([^BE-HJ-NP-RT-Za-km-zäöüÄÖÜ]*)(\s+[A-Za-zäöüÄÖÜ\|-]+([^\s]+)(\s+\d+)?\s*)$/$1/;
#				$ort = $2;
#			}
#
#			$ort = $2;
#
#			if ($SpecialCharacterSubstitutionCheck) {
#				$orth3 = special($orth3);
#			}
#
#			# currently slightly restricted, better results later with city names
#			if($plzo){			
#				#$orth3 =~ s/^([^BE-HJ-NP-RT-Za-km-zäöüÄÖÜ€ƒ†Š@Ÿ¡¢£¤µ¶ÇÐÑ×ñš$¥©ªç§°Ý‹ºÀÁÂÃÅÈÉÊËÌÍÎÏÒÓÔÕØÙÚÛàáâãåèéêë¡ìíîïðòóôõøùùúû]*)//; 
#				#$ort = $orth3;	
#			}
#			#$ort = $orth3;
#			
#	#for the moment this is wrong !!!!!!!!!!!!
#	#this can be done only with cityname lists
#	#		if ($AlphabeticDigitSubstitutionCheck) {
#	#			$orth = alphadig_for_distributed_ZIPCodes($orth); #replace characters by digits,when necessary
#	#		}
#       #this is the substitution for the wrong code above
#			#if ($AlphabeticDigitSubstitutionCheck && $ZIPLength != $CountryZIPLength{$ActualCountry}) {
#			#	$orth = alphadig($orth); #replace characters by digits,when necessary
#			#}
#			
#			my $orth2 = $orth;
#			$orth =~ s/\D//ig; #remove everything but digits
#
#			my $ortc = length($orth); #number of digits in the $ort portion of the ZIP-code
#			
#			if ($plzc == $Zero) { # in this case not only the complete ZIP-Code resides in the $ort field
#										 # also a possible Country symbol could there be found
#				# check for a country symbol in $ort
#
#								# this pattern should be created dynamically, some day !!!
#								$orth2 =~ s/^(\s*)(A|D|CH)(\-|\s*)(.*)$/$2/g;
#				
#				# determine country and zipcode-length
#				if ( $orth2 eq "A" || $orth2 eq "CH") { # this should also be done in a more generic way
#					$ActualCountry = $orth2;
#					$ZIPLength = $CountryZIPLength{$ActualCountry};
#				}
#				
#				# check if country is allowed
#				if (!$ListOfAllowedCountries{$ActualCountry}) {
#				#if (($Country eq "A" && !$AllowAustria) || ($Country eq "CH" && !$AllowSwitzerland)) {
#					if ($ForceZIPOnCountryError) {
#						$plz = $MagicZIP;
#					}
#					else {
#					return $Result . ' - Teilnahme aus diesem Land nicht erlaubt.';
#					}
#				}						 
#			}
#			$plz = $plzh . $orth; # this is the zipcode taken from $plz and $ort
#			
#			$heal = (($ortc + $plzc) == $ZIPLength); #does distributed ZIP-Code has right length?
#
#			$plz = substr($plz,0,5-$ZIPReductionLevel);	
#					 
#		}
		
		if (!$heal){ 
			if ($ForceZIPOnDigitError) {
				$plz = $MagicZIP;
			}
			else {
				return $Result . ' - Postleitzahl hat falsche Anzahl an Ziffern';
			}
		}	

#  Z I P    C O D E    P R O C E S S I N G finished-------------------------------------------------------




#  N A M E   P R O C E S S I N G *************************************************************************
#  -------------------------------------------------------------------------------------------------------	
	# replace special characters
	if ($SpecialCharacterSubstitutionCheck) {
		$vn = strip_off_quotes($vn); 
		$nn = strip_off_quotes($nn);
		$vn = string_concentrator($vn); 
		$nn = string_concentrator($nn);
		$vn = special($vn);
		$nn = special($nn);
	}

	# return 'invalid' when digits occur in names and this option is turned on
	if ($DenyDigitsInNames) {
		if ($nn =~ /\d/) {
			return $Result . ' - Ziffern im Nachnamen nicht erlaubt.';
		}
		if ($vn =~ /\d/) {
			return $Result . ' - Ziffern im Vornamen nicht erlaubt.';
		}		
	}

	# return 'invalid' when special characters occur in names and this option is turned on
	if ($DenySpecialCharactersInNames) {
		if ($nn =~ /[^a-zA-ZäöüÄÖÜß\s\d\._']|-/) {
			return $Result . ' - Sonderzeichen im Nachnamen nicht erlaubt.';
		}
		if ($vn =~ /[^a-zA-ZäöüÄÖÜß\s\d\._']|-/) {
			return $Result . ' - Sonderzeichen im Vornamen nicht erlaubt.';
		}		
	}

	# return 'invalid' when anything like titles salutations or abreviations occur in names
	# and this option is turned on
	if($DenyAnythingThatLooksLikeTitleSalutationOrAbrevationInName) {
		if ($nn =~ /^(.*).+\.(\s.*)$/) {
			return $Result . ' - Abkürzungen, Anreden, Titel im Nachnamen nicht erlaubt.';
		}
		if ($vn =~ /^(.*).+\.(\s.*)$/) {
			return $Result . ' - Abkürzungen, Anreden, Titel im Vornamen nicht erlaubt.';
		}
		foreach (@titles){
			if ($nn =~ /^(.*)$_(\s.*)$/) {
				return $Result . ' - Abkürzungen, Anreden, Titel im Nachnamen nicht erlaubt.';
			}
			if ($vn =~ /^(.*)$_(\s.*)$/) {
				return $Result . ' - Abkürzungen, Anreden, Titel im Vornamen nicht erlaubt.';
			}
		}		
	}
 	
	# elimination of titles, if desired ---------------------
	if ($TitelCheck) {

		if ($DigitAlphabeticSubstitutionCheck) {
			$nn = digialph($nn);
			$vn = digialph($vn);
		}

	
		foreach $uu (@titles){

			# process last name
			$nn = remove_titles($nn,$uu);

			# process first name
			$vn = remove_titles($vn,$uu);	
	
		}
		
		foreach $uu (@titles2){
			$nn = remove_titles2($nn,$uu);
			$nn = strip_off_quotes($nn);
			$vn = remove_titles2($vn,$uu);
			$vn = strip_off_quotes($vn);			
		}
		
		if (!$RemoveAbrevationsInNames) { # only then remove abrevated titles, don't make the same work twice!
			foreach $uu (@abrevatedTitles) {
				$nn = remove_abrevatedTitles($nn,$uu);
				$nn = strip_off_quotes($nn);
				$vn = remove_abrevatedTitles($vn,$uu);
				$vn = strip_off_quotes($vn);
			}
		}
	}

	# return 'invalid' if abrevitions in names are used and this option is turned on
	if ($DenyNameAbrevations && $TitelCheck) {
		if ($nn =~ /^(.*).+\.(\s.*)$/) {
			return $Result . ' - Abkürzungen im Nachnamen nicht erlaubt.';
		}
		if ($vn =~ /^(.*).+\.(\s.*)$/) {
			return $Result . ' - Abkürzungen im Vornamen nicht erlaubt.';
		}
	}


	# elimination of all abrevations in names -------------
	# in some parts this is redundant with title elimination
	if ($RemoveAbrevationsInNames) {
		$nn = remabrev($nn);
		$vn = remabrev($vn);		
	}
	
	# eliminate some double-name fake possibility
	$nn =~ s/_/-/g;
	$vn =~ s/_/-/g;	
		
	# eliminate all kinds of special characters except '-' from names
	# this is necessary as long as digit or special character substitution check is not implemented
        # double names like däubler-gmelin however will be preserved
	#$nn =~ s/[^a-zA-ZäÄöÖüÜß\s\-]//g;
	#$vn =~ s/[^a-zA-ZäÄöÖüÜß\s\-]//g;
			
	# special lowercase reduction of names
	# all characters will be transformed to lower case but some characters must be
	# distinguished if they were originally lower or upper case
	#first make a copy of names
	my $vnco = $vn;
	my $nnco = $nn;
	
	# now work with the copy
	$nnco =~ tr/A-ZÖÄÜ/a-zöäü/;
	$vnco =~ tr/A-ZÖÄÜ/a-zöäü/;
	
	if ($OrderOfFirstNamesCheck) {	
		# splitting names and their copies by blank as seperator
		
		$nnco =~ s/^\s*(.*)$/$1/g;

		my @lncoms = split(/\s+/,$nnco);
		my @fncoms = split(/\s+/,$vnco);
		# here strip off qotes before sorting
		for ( my $k = 0; $k <= $#fncoms; $k++) {
			$fncoms[$k] = strip_off_quotes($fncoms[$k]);
			if ($ResolveAccents) {

				$fncoms[$k] = resolve_accents($fncoms[$k]);

			}
		}
		for ( my $k = 0; $k <= $#lncoms; $k++) {
			$lncoms[$k] = strip_off_quotes($lncoms[$k]);
			if ($ResolveAccents) {
				$lncoms[$k] = resolve_accents($lncoms[$k]);
			}
		}
		
		
		# sorting the copies lexically and keep only the first of each names
		@lncoms = sort(@lncoms);
		@fncoms = sort(@fncoms);
		$nnco = $lncoms[0];
		$vnco = $fncoms[0];
	}	
	
	if ($FirstNameLastNameSwapCheck) {			
		# eventually swap first name and last name for normalizition purposes according to their lexical order
		# this eliminates possibility for the user to generate second identity
		# by swapping first and last name himself
	
		my @NameOrder = ($nnco,$vnco);
		@NameOrder = sort (@NameOrder);
		$nnco = $NameOrder[0];
		$vnco = $NameOrder[1];
	}

	# now that you got the result on lower cased names
	# restore original names and perform special lower case transformation

	$vn = strip_off_quotes($vn);
	$vn = strip_off_quotes($vn);
	if ($ResolveAccents) {
			$vn = resolve_accents($vn);
			$nn = resolve_accents($nn);
	}	
	
	# preparing step
	$nn =~ tr/ÄÖÜ/äöü/;
	$vn =~ tr/ÄÖÜ/äöü/;
	

	if ($nn =~ /$nnco/ig) {
		$nn = $&;
		$vn =~ /$vnco/ig;
		$vn = $&;
	}
	else {
		$nn =~ /$vnco/ig;
		$nn = $&;
		$vn =~ /$nnco/ig;
		$vn = $&;
	}
	($vn,$nn) = sort($vn,$nn);
	
	if ($SupressEnding_er) {
		$vn = remove_ending_er($vn);
		$nn = remove_ending_er($nn);
	}
	
	# here, after sorting lexically, do the lower case normalization
	$nn =~ s/D/=d/g;
	$vn =~ s/D/=d/g;
	$nn =~ s/E/=e/g;
	$vn =~ s/E/=e/g;
	$nn =~ tr/A-Z/a-z/;
	$vn =~ tr/A-Z/a-z/;	

# N A M E   P R O C E S S I N G finished------------------------------------------------------------------	
	


#  S T R E E T   P R O C E S S I N G *********************************************************************
#  -------------------------------------------------------------------------------------------------------

	# replace special characters
	if ($SpecialCharacterSubstitutionCheck) {
		$str = strip_off_quotes($str);
		$str = string_concentrator($str);
		$str = special($str);
	}
	
	# eliminate 'nr.' if it occurs
	$str =~ s/no\.|nummer|nr\.//ig;
	
	# eliminate all digit sequences
	$str =~ s/(.*)\s+(\d*)\s*(.*)/$1$3/g;
	
	# eliminate special characters from street name
	$str =~ s/_/-/g;
	$str =~ s/[^a-zA-ZäÄöÖüÜß\s\-\.]//g;
	
	# make street name lower case	
	$str =~ s/D/=d/g;
	$str =~ s/E/=e/g;
	$str =~ tr/A-ZÖÄÜ/a-zöäü/;
	
	# normalize most common endings of street names

	if ($SupressEnding_er) {
		$str =~ s/$ErS\s*(s|st|str|stra|stras|strass)\..*$/$1straße/g;
		$str =~ s/$ErS\s*(strasse|straße).*$/$1straße/g;
		$str =~ s/$ErS\s*(w\.|weg).*$/$1weg/g;
		$str =~ s/$ErS\s*(p\.).*$/$1platz/g;
		$str =~ s/$ErS\s*(pl\.|platz).*$/$1platz/g;
		$str =~ s/$ErS\s*(a|al|all)\..*$/$1allee/g;
		$str =~ s/$ErS\s*(allee).*$/$1allee/g;
	}

	$str =~ s/(.*)(s|st|str|stra|stras|strass)\..*$/$1straße/g;
	$str =~ s/(.*)strasse.*$/$1straße/g;
	$str =~ s/(.*)w\..*$/$1weg/g;
	$str =~ s/(.*)p\..*$/$1platz/g;
	$str =~ s/(.*)pl\..*$/$1platz/g;
	$str =~ s/(.*)(a|al|all)\..*$/$1allee/g;

	
	# final normalization step
	$str =~ s/\-//g;
	$str =~ s/\s//g;	
# S T R E E T    P R O C E S S I N G finished-------------------------------------------------------------


# H O U S E    N U M B E R    P R O C E S S I N G ********************************************************
	# replace alphabetic characters by similar looking digits, where approbriate
	if ($AlphabeticDigitSubstitutionCheck) {
	$hn =~ tr/lSO/150/;
	}
 
	# eliminate everything thats no digit
	$hn =~ s/\D//ig;
	
# H O U S E    N U M B E R    P R O C E S S I N G finished------------------------------------------------


#  C I T Y   P R O C E S S I N G *************************************************************************
#  -------------------------------------------------------------------------------------------------------
	# replace special characters
	if ($SpecialCharacterSubstitutionCheck) {
		$ort = special($ort);
	}
	# eliminate digits and special characters from city name
	$ort =~ s/[^a-zA-Z01-9äÄöÖüÜß\s]//g;
	# make city name lower case
	$ort =~ tr/A-ZÖÄÜ/a-zöäü/;
	# remove trailing numbers
	$ort =~ s/^(.*)\s+\d*$/$1/g;
	# remove leading numbers
	$ort =~ s/^\s*\d*(.*)$/$1/g;
	# remove white space characters
	$ort =~ s/\s//g;
	
#  C I T Y   P R O C E S S I N G finished-----------------------------------------------------------------



#  D I G I T S   T O   A L P H A B E T I C A L   C H A R A C T E R S   R E S U B S T I T U T I O N *******
	if ($DigitAlphabeticSubstitutionCheck) {
		$vn = digialph($vn);	
		$nn = digialph($nn);
		$ort = digialph($ort);
		$str = digialph($str);
	}
#  D I G I T S   T O   A L P H A B E T I C A L   C H A R A C T E R S   R E S U B S T I T U T I O N finished


#  D I P H T O N G   R E V E R S E   E S T I M A T I O N *************************************************
	if ($OpticalCheck && $DiphtongReconstruction) {
		$vn = diphtong($vn);	
		$nn = diphtong($nn);
		$ort = diphtong($ort);
		$str = diphtong($str);
	}
#  D I P H T O N G   R E V E R S E   E S T I M A T I O N finished -----------------------------------------



#  S O M E   P H O N E T I C   N O R M A L I Z A Z I O N S ************************************************
	if ($PhoneticCheck) {
		$vn = phonetic($vn);	
		$nn = phonetic($nn);
		$ort = phonetic($ort);
		$str = phonetic($str);
	}
#  S O M E   P H O N E T I C   N O R M A L I Z A Z I O N S finished ---------------------------------------



#  S O M E   O P T I C A L   N O R M A L I Z A Z I O N S ***************************************************
	if ($OpticalCheck) {
		$vn = optical($vn);	
		$nn = optical($nn);
		$ort = optical($ort);
		$str = optical($str);
	}
#  S O M E   O P T I C A L   N O R M A L I Z A Z I O N S finished ------------------------------------------


#  C L E A N   U P *****************************************************************************************
	$vn =~ s/=//g;	
	$nn =~ s/=//g;
	$ort =~ s/=//g;
	$str =~ s/=//g;
#  C L E A N   U P finished --------------------------------------------------------------------------------

# C H E C K I N G   R E S U L T S    S O   F A R **********************************************************
#  --------------------------------------------------------------------------------------------------------

if ( ($vn =~ /[^a-zA-ZäöüÄÖÜß\-]/) or (length($vn) < $Two)) {
	$Result .= ' - dies ist kein gültiger Name.';
	return $Result;
}

if ( ($nn =~ /[^a-zA-ZäöüÄÖÜß\-]/) or (length($nn) < $Two)) {
	$Result .= ' - dies ist kein gültiger Name.';
	return $Result;
}

if ( ($str =~ /[^a-zA-ZäöüÄÖÜß\-]/) or (length($str) < $Two)) {
	$Result .= ' - dies ist keine gültige Straße.';
	return $Result;
}

if ( ($ort =~ /[^a-zA-ZäöüÄÖÜß\-]/) or (length($ort) < $Two)) {
	$Result .= ' - dies ist kein gültiger Ort.';
	return $Result;
}
	
#  B U I L D I N G   R E T U R N   V A L U E   O F   A F T P R O C E S S O R ******************************
#  --------------------------------------------------------------------------------------------------------

my $Result='';

if ($PushCountryCode) {
	$Result .= $ActualCountry . '-';
}

$Result .= $plz . '-' . $hn . '-' . $vn . '-' . $nn . '-' . $str . '-' . $ort;

return $Result;
} # end aft-processor
1;
