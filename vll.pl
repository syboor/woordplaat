#!/usr/bin/perl -wT -I/home/syboore/cgi-resources/perllib

use CGI;
use CGI::Carp qw(fatalsToBrowser);
$CGI::DISABLE_UPLOADS = 1;          # Disable uploads
$CGI::POST_MAX        = 512 * 1024; # limit posts to 512K max
use Parse::PerlConfig;

local $| = 1;      # no buffering
local $/ = "";

my $q = new CGI;

my $lessonprefix = "vll/";

my $kern = $q->param('kern');
my $level = $q->param('level') || "1";
--$level;
my $size = $q->param('size') || $q->cookie('WOORDPLAAT_SIZE') || "";
my $sound = $q->param('sound') || $q->cookie('WOORDPLAAT_SOUND') || "";
my $special = $q->param('special') || "";
my $index = "vll.html";
my $index_adv = "vll_adv.html";
my $file = $q->param('file') || "";
my $mode;

unless ($size eq 'm' or $size eq 's') { $size = 'm'};
unless ($sound eq 'y' or $sound eq 'n') { $sound = 'y'};

my $picprefix;
$picprefix = "400px/" if ($size eq 'm');
$picprefix = "300px/" if ($size eq 's');

my $description;
my $levels;
my $words;
my @sets;

my %licenses_compact = 
    ('ccbysa10' => '<a href="http://creativecommons.org/licenses/by-sa/1.0/" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
	'ccbysa20' => '<a href="http://creativecommons.org/licenses/by-sa/2.0/" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'ccbysabe20' => '<a href="http://creativecommons.org/licenses/by-sa/2.0/be/deed.en_GB" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'ccbysade20' => '<a href="http://creativecommons.org/licenses/by-sa/2.0/de/deed.en" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'ccbysafa20' => '<a href="http://creativecommons.org/licenses/by-sa/2.0/fr/deed.en_GB" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'ccbysa25' => '<a href="http://creativecommons.org/licenses/by-sa/2.5/" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'dual' => '<a href="http://www.gnu.org/licenses/fdl.txt" target="_blank"><img alt="GFDL" src="gfdl.png"/></a><a href="http://creativecommons.org/licenses/by-sa/2.5/" target="_blank"><img alt="CC-BY-SA" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/></a>',
     'ccby20' => '<a href="http://creativecommons.org/licenses/by/2.0/" target="_blank"><img alt="CC-BY" src="cc_icon_attribution_small.png"/></a>',
     'pd' => '<a href="http://creativecommons.org/licenses/publicdomain/" target="blank"><img alt="PD" src="publicdomain.png"/></a>',
     'gfdl' => '<a href="http://www.gnu.org/licenses/fdl.txt" target="_blank"><img alt="GFDL" src="gfdl.png"/></a>',
     );

my %licenses_long = 
    ('ccbysa20' => '<a href="http://creativecommons.org/licenses/by-sa/2.0/" target="_blank"><img alt="" src="cc_icon_sharealike_small.png"/><img alt="" src="cc_icon_attribution_small.png"/> CC Attribution-ShareAlike 2.0</a>',
     'ccby20' => '<a href="http://creativecommons.org/licenses/by/2.0/" target="_blank"><img alt="" src="cc_icon_attribution_small.png"/> CC Attribution 2.0</a>',
     'pd' => '<a href="http://creativecommons.org/licenses/publicdomain/" target="blank"><img alt="" src="publicdomain.png"/> public domain</a>',
     'gfdl' => '<a href="http://www.gnu.org/licenses/fdl.txt" target="_blank"><img alt="" src="gfdl.png"/> GNU Free Documentation License</a>',
     );

if ($kern or $file) {
    print $q->header(-cookie=>[$q->cookie(-name=>'WOORDPLAAT_SIZE',
										  -value=>$size,
										  -expires=>'+1y'),
							   $q->cookie(-name=>'WOORDPLAAT_SOUND',
								   		  -value=>$sound,
										  -expires=>'+1y'),
								],
							   );

	# open the wordlist file and read it into $words
	my $tmp2 = Parse::PerlConfig::parse(File=>"wordlist_eenlett.pl", Taint_Clean=>1, Namespace=>"w");
	$words = $tmp2->{'words'};

    if ($kern) {
		# untaint 'kern': delete anything that's not a digit
		$kern =~ s/[^0-9]//g;

		if ($kern < 1 or $kern > 6) {
			print "No such kern: $kern";
			exit;
		}
	
		# parse kern description file
		my $tmp = Parse::PerlConfig::parse(File=>$lessonprefix . "kern" . $kern, Taint_Clean=>1, Namespace=>"w");
		$levels = $tmp->{'levels'};
	
		# untaint level
		$level =~ s/[^0-9]//g;
		# wrap around (if the kern has levels 0-7, level 8 becomes level 1 etc)
		$level %= @$levels;
	
		# now open the file containing the words for this kern and level and read it
		open(IN, "< $lessonprefix" . $levels->[$level]->{'file'}) or die "Can't find file for level $level, kern $kern: " . $levels->[$level]->{'file'} . "\n";

		$description = <IN>;
	
		# now finally read the words in the lesson file
		while (<IN>) {
			my @w = split;
			push @sets, \@w; 
		}
	} else { # file parameter was used
		$file =~ s/[^0-9_a-z]//g;
		unless (open(IN, "< $lessonprefix" . $file . ".txt")) {
			print "No such file: $file";
			exit;
		}
		$description = <IN>;
		# now finally read the words in the lesson file
		while (<IN>) {
			my @w = split;
			push @sets, \@w; 
		}
	}
	
	unless ($special) {
		# display the page
		$mode = $levels->[$level]->{'mode'} if ($kern);
		$mode = $q->param('mode') if ($file);
		$mode = 'view' unless ($mode eq 'view' or $mode eq 'chooseword' or
								$mode eq 'choosepic');
								
		my $nextf;
		if ($kern) {$nextf = $levels->[$level]->{'nextf'};}
		if ($file) {
			$nextf = 'nextrandom()' if ($q->param('nextf') eq 'random');
			$nextf = 'nextconsec()' if ($q->param('nextf') eq 'consec');
			if ($mode eq 'view' ) {$nextf ||= 'nextconsec()';} else {$nextf ||= 'nextrandom()';}
		}

				
		print $q->start_html(-title => 'Woordplaat', 
				-style => { -src => ['woordplaat.css', 'woordplaat_' . $size . '.css']},
				-script=>[
					{-language=>'Javascript',
					-src=>'soundmanager2.js',},
					{-language=>'Javascript',
					-code=>'var mode = "' . $mode . '"; var sound = "' . $sound . '";',},
					{-language=>'Javascript',
					-src=>'play.js',},
				],
				-onload=> 'start(' . $nextf . ');',
				);
		
		if ($mode eq 'chooseword') {
			print '<div id="question" class="piconly"></div>' . "\n" . 
				'<div id="answerset" class="textonly"></div>' . "\n";
		}
		if ($mode eq 'choosepic') {
			print '<div id="question" class="textonly"></div>' . "\n" . 
				'<div id="answerset" class="piconly"></div>' . "\n";
		}
		if ($mode eq 'view') {
			print '<div id="question"></div>' . "\n" . 
				'<div id="answerset" class="pictext"></div>' . "\n";
		}
	
		printitems();
		displayimagecopyright();
		printcontrol();
	
		print $q->end_html();
		exit;
	}
}
else { # no kern chosen
    print $q->redirect($index);    
    exit;
}

if ($special eq "raw") {
    print $q->start_html(-title => 'Woordplaat');
	if ($kern) {
		print "Kern: $kern<br />";
		print "Modus: " . $levels->[$level]->{'mode'} . "<br />";
		print "Level: ";
		for (0 .. @$levels - 1) {
			if ($_ == $level) {
				print "<b>" . ($level + 1) . "</b> ";
			} else {
				print '<a href="' . url(level=>($_+1)) . '">' . ($_+1) . '</a> ';
			}
		}
	}
	if ($file) {
		print "File: $file";
	}
	print "<br />Beschrijving: " . $description . "<br />";
	print "<br />";
    foreach my $set (@sets) {
	foreach my $w (@$set) {
	    
	    print "$w<br />";
	}
	print "<br />";
    }
    exit;
}

if ($special eq "allwords") {
    print $q->start_html(-title => 'Woordplaat');
    foreach my $w (sort keys %$words) {
	print $words->{$w}->{'text'} . "<br/>";
    }
}

if ($special eq "copyright") {
    print $q->start_html(-title => 'Woordplaat', -style => 'woordplaat.css');
    my %itemsunique;

    foreach my $items (@sets) {
	foreach (@$items) {
	    $itemsunique{$_} = $_;
	}
    }

    print 
	'<p>Alle afbeeldingen zijn eigendom van de resp. auteurs.</p>' .
	'<p>Op deze pagina vindt u van de afbeeldingen die in kern ' . $kern .
	', level ' . ($level + 1) . '</b> gebruikt worden de bron, de auteur, ' .
	'en de licentievoorwaarden.' . "\n" . '<table class="copyright">' .
	'<tr><th>woord</th><th>auteur</th><th>licentie</th><th>bron</th></tr>';

    foreach (sort keys %itemsunique) {
	my $lic = $licenses_long{$words->{$_}->{'license'}} || $words->{$_}->{'license'};
	my $ref = $words->{$_}->{'source'};

	print 
	    '<tr><td>' . $words->{$_}->{'text'} . '</td>' .
	    '<td>' .  $words->{$_}->{'author'} . '</td>' .
	    '<td class="license">' .  $lic . '</td>' .
	    '<td class="source"><a href="' . $ref . '">' . 
	    (length($ref) > 50 ? substr($ref, 0, 50) . '...' : $ref) . '</td>' .
	    '</tr>' . "\n";
    }

    print '</table>' . "\n" . $q->end_html();
	
}

sub printitems {
	print '<div class="items" id="itemset">';

	my $nitem = 0;
	my $nfiller = 0;
	my $setnr = 0;

	foreach my $set (@sets) {
		my @items = @$set;
	
		print '
  <div class="set" id="set:'. $setnr . '">';
	
		foreach my $item (@items) {
			my $filler = 0;
			if ($item =~ /\*/) {
				$filler = 1;
				$item =~ s/\*//g;
			}

			my $lic = $licenses_compact{$words->{$item}->{'license'}} || $words->{$item}->{'license'};
			print '
    <div class="' . ($filler ? 'filler' : 'item') . '" id="' . ($filler ? 'filler:' . $nfiller : 'item:' . $nitem) . '">
      <div class="image">
        <div class="pic" onclick="pictureclicked(' . ($filler ? "&quot;filler&quot;,$nfiller" : "&quot;item&quot;,$nitem") . ')">
          <img alt="" src="' . $picprefix . $words->{$item}->{'file'} . '"/>
        </div>
        <div class="license">' . $lic . '</div>
        <div class="source">' . 
            ($words->{$item}->{'source'} 
            ? '<a href="' .  $words->{$item}->{'source'} . '" target="_blank">bron</a>' 
            : "") . '</div>
      </div>
      <div class="wordtext" onclick="wordclicked(' . ($filler ? "&quot;filler&quot;,$nfiller" : "&quot;item&quot;,$nitem") . ')"><span>' . $words->{$item}->{'text'} . '</span></div>
    </div>';
			
			if ($filler) { ++$nfiller; } else { ++$nitem;}
		}

		++$setnr;
		print '
  </div>';
	}

	print
'   </div>
';	
}

sub printcontrol {
    print 
	'<div id="control">' .
	'<span style="font-size: 20pt">';
	if ($mode eq 'chooseword') {
		print "Klik op het juiste woord</span><br />";
	}
	if ($mode eq 'choosepic') {
		print "Klik op het juiste plaatje</span><br />";
	}
	if ($mode eq 'view') {
		print "Bekijk de woorden</span><br />Gebruik de pijlen om te bladeren";
	}

	print
	'<div id="setnav">' .
	'<span onclick="prevset()" id="prevset"><img alt="&lt;&lt;" src="Back.png"/></span> ' .
	'<span id="curset"></span>' . "/" .
	'<span id="maxset"></span>' .
	' <span onclick="nextset()" id="nextset"><img alt="&gt;&gt;" src="Forward.png"/></span>' .
	'</div>';
	
	if ($kern) {
		print	
		'<p><span style="font-size: 120%">Kern: '. $kern .  
		'</span><br/><a href="' . $index . '">andere kern</a></p>';

		print '<table><tr><td><span style="font-size: 120%">Level: ' . ($level+1) .  '</span></td><td><table><tr><td>';
		if ($level < @$levels - 1) {
			print '<img alt="&gt;&gt;" src="Up.png" border=0 onclick="if (sound == &quot;y&quot;) { soundManager.play(&quot;levelup&quot;);} window.location = &quot;' . $q->url(-relative=>1) . "?kern=$kern&amp;level=" . ($level+2) . '&quot;" />';
		}
		print '</td></tr><tr><td>';
		if ($level > 0) {
			print '<img alt="&gt;&gt;" src="Down.png" border=0 onclick="if (sound == &quot;y&quot;) { soundManager.play(&quot;levelup&quot;);} window.location = &quot;' . $q->url(-relative=>1) . "?kern=$kern&amp;level=" . ($level) . '&quot;" />';
		}
		print '</td></table></td></tr></table><span style="font-size: 80%">Klik op de pijl om naar een ander level te gaan</span></p>';
#	'<p><span style="font-size: 120%">Level: ' . ($level+1) . ' <a href="' . $q->url(-relative=>1) . "?kern=$kern&amp;level=" . ($level+2) . '"><img alt="&gt;&gt;" src="Up.png" border=0/></a></span><br /><span style="font-size: 80%">Klik op de pijl om naar het volgende level te gaan</span></p>';
	}
	
	if ($file) {
		print
		'<p><span style="font-size: 120%">Woordenlijst: '. $file .
		'</span><br /><a href="' . $index_adv . '">andere woordenlijst</a></p>';
	}
	
	print
	'<div id="settings"><p><b>Instellingen</b><br />' . 
	'<span id="setsize">' .
	'Plaatjes: ' .
	($size eq 's' ? "<b>klein</b>" : '<a href="' . url(size=>"s") . '">klein</a>') . " " .
	($size eq 'm' ? "<b>groot</b>" : '<a href="' . url(size=>"m") . '">groot</a>') . " " .
	'</span><br />' .
	'<span id="setsound">' .
	'Geluid: ' .
	($sound eq 'y' ? "<b>aan</b>" : '<a href="' . url(sound=>"y") . '">aan</a>') . " " .
	($sound eq 'n' ? "<b>uit</b>" : '<a href="' . url(sound=>"n") . '">uit</a>') . " " .
	'</span><br /></p></div>';

	print '</div>';
}

sub displayimagecopyright {
    print
	'<div id="copyright">' .
	'<p>Alle afbeeldingen zijn eigendom van de resp. auteurs.' .
	' <a target="blank" href="' . $q->url(relative=>1) . '?kern=' . $kern . '&amp;level=' . $level .
	'&amp;special=copyright">meer informatie over copyright</a></p></div>';

}

sub url {
	my %params = @_;
	
	my $url;
	
	$url .= $q->url(relative=>1);
	$url .= "?";
	
	$url .= ('kern=' . ($params{'kern'} || $kern) . '&amp;') if ($kern || $params{'kern'});
	$url .= ('level=' . ($params{'level'} || ($level + 1)) . '&amp;') if ($level || $params{'level'});
	$url .= ('file=' . ($params{'file'} || $file) . '&amp;') if ($file || $params{'file'});
	$url .= ('mode=' . ($params{'mode'} || $mode) . '&amp;') if ($mode || $params{'mode'});
	$url .= ('nextf=' . ($params{'nextf'} || $nextf) . '&amp;') if ($nextf || $params{'nextf'});
	$url .= ('special=' . ($params{'special'} || $special) . '&amp;') if ($special || $params{'special'});
	$url .= ('size=' . ($params{'size'} || $q->param('size')) . '&amp;') if ($q->param('size') || $params{'size'});
	$url .= ('sound=' . ($params{'sound'} || $q->param('sound')) . '&amp;') if ($q->param('sound') || $params{'sound'});
	
	$url = substr($url, 0, -5);
	return $url;
}
