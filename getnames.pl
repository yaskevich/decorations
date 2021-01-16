#!/usr/bin/perl
use strict;
use warnings;
use 5.013; 
use utf8;
use Switch;
use Mojo::UserAgent;
use Data::Dump qw(dump);
use Unicode::Collate;
binmode(STDOUT, ":unix:utf8");

use Text::CSV;
my $csv = Text::CSV->new({  binary => 1  });
 
my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";
 
my $sum = 0;
my $error;


# reply
# quality
# type - person, nontrad name, institution def or other

open my $fh, "<:encoding(utf8)", $file or die "Could not open '$file' $!\n";
open my $log, ">:encoding(utf8)", "error.txt" or die "Could not open log $!\n";

my %names_stat	= ();

my $f = 0;
my $m = 0;

### ====================================================
print <<'HTML'; 
 <!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="description" content="bookmarks">
    <meta name="author" content="Alex Yaskevich">
    <title>Нармалізацыя імёнаў</title>
    <link rel="shortcut icon" href="favicon.ico" />
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />

    <script src="jquery-1.10.2.min.js" type="text/javascript"></script>
    <script src="jquery.tablesorter.js" type="text/javascript"></script>
	<script src="new.js" type="text/javascript"></script>
	<link rel="stylesheet" href="./blue/style.css" type="text/css" media="print, projection, screen" />
	
	
	<style media="screen" type="text/css">
	body {
	 background-color: lightyellow;
	 .bad {
		background-color:red;
		color: yellow;
	 }
	}

</style>
	
    
  </head>
  <body>
    <div id="wrapper">
	<!--
      <div id="header">
        <h1>Нармалізацыя імёнаў</h1>
      </div>
	  -->
      <div id="main">
   
        <div id="stacks" style="float:left;"></div>
        <div id="article">
          <div class="ui-widget">
                <table id="myTable" class="tablesorter" style="max-width:95%;margin-left:2%;"> 
				<thead> 
				<tr>
					<th>№№</th> 
					<th>Res</th> 
					<th>Last Name</th> 
					<th>First Name</th> 
					<th>Middle Name</th> 
					<th width="200px;">In text</th> 
					<th>In text(2)</th> 
				</tr> 
				</thead> 
				<tbody> 
				<!--
				<tr> 
					<td>Smith</td> 
					<td>John</td> 
					<td>John</td> 
					<td>jsmith@gmail.com</td> 
					<td>$50.00</td> 
				</tr> 
				-->
				
HTML
### ====================================================
my $iter=0;
my $ers=0;
my $dummy=<$fh>;   # skip first line 
while (my $line = <$fh>) {
	$error = '';
	chomp $line;
	if ($csv->parse($line) ) {
		$iter++;
		my @fields = $csv->fields();
		my $nameline = $fields[0];
		my $what = $fields[1];
		$what =~ s/^[\–\s]{1,2}//;

		$nameline =~ tr/Ii/Іі/;
		$nameline =~ tr/Ι/І/; # 	Дзедука Валерыя Ιванавіча →  GREEK CAPITAL LETTER IOTA
		$nameline =~ tr/M/М/;
		$nameline =~ tr/CcAaOoPpXxBHK/СсАаОоРрХхВНК/;
		
		# to-do DO replacemnet in all fields!!!
		
		# say $log $fields[0] if $fields[0] ne $nameline;
		
		my @names = split(" " , $nameline);
		
		if (@names != 3) {
			$error = "Not a name! → ".$nameline;
		} else {
			my @props = ();
			my $f_name;
			my $m_name;
			my $l_name = $names[0];
			my @names_stemmed = @names;
			my @names_stem_char;
			foreach my $i (0..2) { $names_stem_char[$i] = chop $names_stemmed[$i]; }

			if (($names_stem_char[1] eq "а" || $names_stem_char[1] eq "я") &&  $names_stem_char[2] eq "а") {
				my $sfx = '';
				if ($names_stem_char[1] eq "я") { #Генадзя Генадзія Мікалая Аляксея
					$sfx = substr($names_stemmed[1], -1) =~ m/[ыіаеэоую]/ ? "й" : "ь";
				}
				$f_name = $names_stemmed[1].$sfx;
				$m_name = $names_stemmed[2];
				@props = ("m", "acc");
			} elsif ($names_stem_char[1] eq "у" &&  $names_stem_char[2] eq "а") { # Данілу Віктаравіча
				say $log "!=Даніл: ".$names_stemmed[1] unless $names_stemmed[1] eq "Даніл"; 
				$f_name = $names_stemmed[1]."а";
				$m_name = $names_stemmed[2];
				@props = ("m", "acc");
			} elsif ($names_stem_char[1] eq "ю" &&  $names_stem_char[2] eq "а") { # Ілью Алегавіча
				say $log "!=Іль: ".$names_stemmed[1]."|" unless $names_stemmed[1] eq "Іль"; 
				$f_name = $names_stemmed[1]."я";
				$m_name = $names_stemmed[2];
				@props = ("m", "acc");
			} elsif ($names_stem_char[1] eq "е" &&  $names_stem_char[2] eq "е") { # Таццяне Мікалаеўне
				$f_name = $names_stemmed[1]."а";
				$m_name = $names_stemmed[2]."а";
				@props = ("f", "dat");
			} elsif ($names_stem_char[1] eq "ы" &&  $names_stem_char[2] eq "е") { # Тамары Барысаўне
				$f_name = $names_stemmed[1]."а";
				$m_name = $names_stemmed[2]."а";
				@props = ("f", "dat");
			} elsif (($names_stem_char[1] eq "у" || $names_stem_char[1] eq "ю") &&  $names_stem_char[2] eq "у") { 
				if ($names_stemmed[2] =~ /віч/) { # Канстанціну Анатольевічу, # Генадзію Генадзьевічу
					# $f_name = $names_stemmed[1].sprintf($names_stem_char[1] eq "ю" ? "й" : "");
					my $sfx = '';
					if ($names_stem_char[1] eq "ю") { #Генадзя Генадзія Мікалая Аляксея
					$sfx = substr($names_stemmed[1], -1) =~ m/[ыіаеэоую]/ ? "й" : "ь";
					}
					$f_name = $names_stemmed[1].$sfx;
					$m_name = $names_stemmed[2];
					@props = ("m", "dat");
				} else { # Ірыну Валер’еўну
					$f_name = $names_stemmed[1].sprintf($names_stem_char[1] eq "ю" ? "я" : "а");
					$m_name = $names_stemmed[2]."а";
					@props = ("f", "acc");
				}
			} elsif ($names_stem_char[1] eq "ў"  &&  $names_stem_char[2] eq "у") { # Любоў Раманаўну
				say $log "???" unless $names_stemmed[1] eq "Любо"; 
				$f_name = $names_stemmed[1]."ў";
				$m_name = $names_stemmed[2]."а";
				@props = ("f", "acc");
				
			} elsif ($names_stem_char[1] eq "і" &&  $names_stem_char[2] eq "е") { # Дар’і Уладзіміраўне
				$f_name = $names_stemmed[1]."я";
				$m_name = $names_stemmed[2]."а";
				@props = ("f", "dat");
			}
			# elsif($names[2] =~ /іча$/){
			# } elsif($names[2] =~ /ічу$/){
			# } elsif($names[2] =~ /ўне$/){
			# } elsif($names[2] =~ /ўну$/){
			# }
			else
			{
				$error = $names_stem_char[0]." | ".$names_stem_char[1]." | ".$names_stem_char[2]."\t".$nameline;
			}
			push2stat (@props, $f_name, $m_name, $l_name, $nameline, $what, $iter) unless $error;
			
			# say $props[0]." ".props[1];
		}
	
#########################
	# warn $error if $error;
	if ($error) {
		if ($fields[0]  ~~ [qr/[уЎўу]станов/, qr/прадпрыемства/, qr/таварыства/, qr/«.*»/]){
			say '<tr><td>'.$iter.'</td><td class="bad" style="background-color: orange;color:yellow;font-weight:bold;">ORG'.'</td><td>'.'</td><td>'.'</td><td>'.'</td><td>'.$fields[0].'</td><td>'.$what.'</td></tr>' 
		} else {
			$ers++;
			say '<tr><td>'.$iter.'</td><td class="bad" style="background-color: red;color:white;font-weight:bold;">NO'.'</td><td>?'.'</td><td>'.'?</td><td>?'.'</td><td>'.$fields[0].'</td><td>'.$what.'</td></tr>' 
		}
		
	}
	
#########################	
	
	
	} else { # if not parsed
	  say "Line could not be parsed: $line\n";
	}
  $sum ++;
}
# print "$sum\n"; #### !!! out qty

 # dump(%names_stat);
 
 
 
for (
sort 
{ $names_stat{'m'}{$b} <=> $names_stat{'m'}{$a} } 
# http://www.perl.com/pub/2011/08/whats-wrong-with-sort-and-how-to-fix-it.html
# Unicode::Collate::->new->sort(
keys $names_stat{'m'}
# )
){
	# printf "%-8s %s\n", $_,$names_stat{'m'}{$_}; #### !!! out freq
}
for (
sort 
{ $names_stat{'f'}{$b} <=> $names_stat{'f'}{$a} } 
keys $names_stat{'f'}){
	# printf "%-8s %s\n", $_,$names_stat{'f'}{$_}; #### !!! out freq
}


sub push2stat {
	my ($gender, $case, $name1, $name2, $name3, $line, $profession, $idnum)  = @_;
	# say $name1." ".$name2." | ". $line;
	my $new = $name3;
	my $nom = 0;
	
	# check double letters
	# points for pattern matching
	
	if ($gender eq "f" and $case eq "acc"){
		if (substr ($name3, -1) eq "у") {
			chop $new;
			$new .= "а";
			$nom = 1;
		}  elsif (substr ($name3, -4) eq "скую"){
			substr ($new, -2) = "ая";
			$nom = 1;
		} elsif (substr ($name3, -2) eq "ую") { # Нужную 
			substr ($new, -2) = "ая";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "ю") {
			chop $new;
			$new .= "я";
			$nom = 1;
		}
		# elsif (substr ($name3, -1) eq "о") { # нескланяльныя
			# $nom = 1;
		# } elsif (substr ($name3, -1) =~ /[йьчрк]/) { # Валанцей Гузень Мацкевіч Качур
			# $nom = 1;
		# }
		else {
			$nom = 1; # ўсё астатняя - нескланяльнае
		}
		$f++;
	} elsif ($gender eq "f" and $case eq "dat") {
		if (substr ($name3, -3) eq "вай") { # Сакаловай Осіпавай
			chop $new;
			$nom = 1;
		}  elsif (substr ($name3, -4) eq "скай"){
			chop $new;
			$new .= "я";
			$nom = 1;
		}  elsif (substr ($name3, -3) eq "най"){ # Булыгінай
			chop $new;
			$nom = 1;
		} elsif (substr ($name3, -3) eq "ной"){ # Барадзіной
			substr ($new, -2) = "а";
			$nom = 1;
		} elsif ($name3 =~ m/[ао]й$/){ # што заўгодна, панізіць бал праўдападабенства
			substr ($new, -2) = "а";
			$nom = 1;
		} elsif ($name3 =~ m/[аэео]віч$/){ # нескланяльныя Радцэвіч, Адашкевіч
			# даць бал
			$nom = 1;
		} elsif (substr ($name3, -3) eq "нка"){ # Семчанка
			# даць бал
			$nom = 1;
		} 
		$f++;
	}
	
	
	if ($gender eq "m" and $case eq "acc"){
		if (substr ($name3, -3) eq "ага"){
			my $sfx = substr ($name3, -4, 1) =~ m/[гкх]/ ? "і" : "ы";
			substr ($new, -3) = $sfx;
			$nom = 1;
		} elsif (substr ($name3, -2) eq "ва") {
			substr ($new, -2) = "ў";
			$nom = 1;
		} elsif (substr ($name3, -4) eq "віча") {
			chop $new;
			$nom = 1;
		} elsif (substr ($name3, -3) eq "нка") {
			# my $begin = $name3, 0, -3;
			substr($new, -2) = substr($name3, -4,1) eq "я" ? "ок" : "ак";  # need more powerfull euristics Шыянка # if 4 eq е - русіфікацыя 	Шкіленак	Шкіленка
			$nom = 1;
		}  elsif (substr ($name3, -3) eq "нца") {
			substr ($new, -2) = "ец";
			$nom = 1;
		} elsif (substr ($name3, -3) eq "ўца") {
			substr ($new, -3) = "вец";
			$nom = 1;
		} elsif (substr ($name3, -2) =~ m/[ў'’]я/) {
			substr ($new, -2) = "ей";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "а") {
			chop $new;
			$nom = 1;
		} elsif (substr ($name3, -1) eq "я") { # Таўгеня Казея
			chop $new;
			$new .= $new =~ m/[ыіаеэоую]$/ ? "й" : "ь"; # але праблемы з пераносам націску - Караль
			$nom = 1;
		} elsif (substr ($name3, -1) eq "я") {
			chop $new;
			$new .= "ь";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "у") { # Куліпу
			chop $new;
			$new .= "а";
			$nom = 1;
		}  elsif (substr ($name3, -1) eq "ю") { # 
			chop $new;
			$new .= "я";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "о") { # нескланяльныя
			$nom = 1;
		} else {
			$nom = 1; # ўсё астатняя - нескланяльнае
		}
		# $new .= ".NOM" if $nom == 1;
		$m++;
	} elsif($gender eq "m" and $case eq "dat"){
		if (substr ($name3, -3) eq "аму"){
			my $sfx = substr ($name3, -4, 1) eq "к" ? "і" : "ы";
			substr ($new, -3) = $sfx;
			$nom = 1;
		}  elsif (substr ($name3, -3) eq "нку") {
			substr ($new, -1) = "а";
			$nom = 1;
		} elsif (substr ($name3, -2) eq "ву") { # Летаву
			substr ($new, -2) = "ў";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "у") { # Гальцу Міхалевічу
			chop $new;
			$nom = 1;
		} elsif (substr ($name3, -2) eq "це") { # Свіце !!! rare!
			substr ($new, -2) = "та";
			$nom = 1;
		} elsif (substr ($name3, -3) eq "дзе") { # Свобадзе !!! rare!
			substr ($new, -3) = "да";
			$nom = 1;
		} elsif (substr ($name3, -1) eq "ю") { # Каралю Нягрэю Горбелю
			chop $new;
			$new .= $new =~ m/[ыіаеэоую]$/ ? "й" : "ь"; # але праблемы з пераносам націску - Караль
			$nom = 1;
		} elsif (substr ($name3, -1) eq "і") { # m dat Кавалені ???
			chop $new;
			$new .= "я";
			$nom = 1;
		} 
		$m++;
		
	}
	
	
	
	
	if ($gender eq 'm' and substr($name1, -2) eq 'ав'){
		substr($name1, -1)  = 'ў';
	}
	if ($gender eq 'm'){
		switch ($name1) {
			case "Льв"		{ $name1 = "Леў"}
			case "Паўл"		{ $name1 = "Павел"}
			case "Пятр"		{ $name1 = "Пётр"}
			case "Валер’ян"		{ $name1 = "Валяр’ян"}
		}	
	}
	if ($gender eq 'f'){
		switch ($name1) {
			case "Вольза"		{ $name1 = "Вольга"}
		}	
	}
	
	unless ($nom == 1){
		# print "!!!!" ;
		# say $gender." ".$case." ".$new;
	} else {
		# say $line. "|\t$new $name1 $name2";
		# say $line. "\n$new $name1 $name2\n"; ### !!!
		
		say '<tr><td>'.$idnum.'</td><td>OK'.'</td><td>'.$new.'</td><td>'.$name1.'</td><td>'.$name2.'</td><td>'.$line.'</td><td>'.$profession.'</td></tr>';
	}
	
	
	if (exists $names_stat{$gender}{$name1} ) {
		$names_stat{$gender}{$name1}++;
	} else {
		$names_stat{$gender}{$name1} = 1;
	}

}


# say $m;
# say $f;



print <<'HTML2'; 
</tbody> 
				</table> 
          </div>
        </div>
      </div>
      <div id="footer">
        <span>© 2015</span> 
    </div>
    </div>
  </body>
</html>
HTML2

warn $ers;