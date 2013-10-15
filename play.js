/* globals, must be declared in the HTML head-section before this script is called:

setnr = number of the current set
set = the current set (the DOM-node)
itemnr = number of the current item
mode = playmode ("choosepic" or "chooseword" or "view")
nextitem = ref to function that selects next item to administer

Please note that set and nsets are not initialised; this is done in initset(). 
setnr, itemnr and mode should also be initialised in the HTML head-section.

nextitem is a bit complicated.
It must be declared before this script is included.
The function to use for selecting the next item should be passed as an argument to start()
*/

var nextitem;
var itemnr;
var setnr;

// Takes a list of Nodes, and removes those Nodes that are text or comment (because this way I can
// still have some 'whitespace' (=text) in the document without screwing everything up).
function striptextnodes(nodeList) {
	var newList = new Array();
	var j = 0;
	
	for (i = 0; i < nodeList.length; i++) {
		if ((nodeList[i].nodeType != 3) && nodeList[i].nodeType != 8) {
			newList[j] = nodeList[i];
			j++;
		}
	}
	return newList;
}

function removeChildrenFromNode(node) {
    if ((node !== undefined) && (node !== null)) {
		while (node.hasChildNodes()) {
			node.removeChild(node.firstChild);
		}
	}
}

// This initialises the set given as an argument.
function initset() {
	// move the current answer set back to the item store
	document.getElementById('itemset').appendChild(document.getElementById('answerset').childNodes[0]);

	var set = document.getElementById('set:' + setnr); 
	// move the set to the answer section
	document.getElementById('answerset').appendChild(set);
	
	// position items
	// positionanswers()
}

function inititem() {
	removeChildrenFromNode(document.getElementById("question"));
	var item = document.getElementById('item:' + itemnr);
	
	// clone item and add to question element
	if (mode != "view") {
		var copy = item.cloneNode(true);
		copy.id = "";
		document.getElementById("question").appendChild(copy);
	}
	
	positionanswers();
}

function positionanswers() {
	var answers = striptextnodes(document.getElementById('set:' + setnr).childNodes);
	// optional: shuffle
	fisherYates(answers);
	for (i = 0; i <= 3; i++) {
		if (answers[i].className.match("item")) {
			answers[i].className = "item set_pos" + i;
		} else {
			answers[i].className = "filler set_pos" + i;
		}
	}
}

// shuffle an array
function fisherYates ( myArray ) {
  var i = myArray.length;
  if ( i === 0 ) { return false; }
  while ( --i ) {
     var j = Math.floor( Math.random() * ( i + 1 ) );
     var tempi = myArray[i];
     var tempj = myArray[j];
     myArray[i] = tempj;
     myArray[j] = tempi;
   }
}

// Utilitily: get elements by class name
// optional node: node to search from
// optional tag: tagname (usually 'div')
function getElementsByClass(searchClass,node,tag) {
	var classElements = new Array();
	if ( node === null ) { node = document; }
	if ( tag === null ) { tag = '*'; }
	var els = node.getElementsByTagName(tag);
	var elsLen = els.length;
	var pattern = new RegExp('(^|\\s)'+searchClass+'(\\s|$)');
	for (i = 0, j = 0; i < elsLen; i++) {
		if ( pattern.test(els[i].className) ) {
			classElements[j] = els[i];
			j++;
		}
	}
	return classElements;
}

// Update navigation elements
function updatenav() {
	if (mode == "view") {
		var curset = document.getElementById("curset");
		
		if (setnr < 1) {
			document.getElementById("prevset").style.visibility="hidden";
		} else {
			document.getElementById("prevset").style.visibility="visible";
		}
	
		if (setnr + 1 >= striptextnodes(document.getElementById("itemset").childNodes).length + 1) {
			document.getElementById("nextset").style.visibility="hidden";
		} else {
			document.getElementById("nextset").style.visibility="visible";
		}		
	
		removeChildrenFromNode(curset);
		curset.appendChild(document.createTextNode(setnr + 1));
	}
}

function nextset() {
	setnr++;
	updatenav();
	initset();
}

function prevset() {
	setnr--;
	updatenav();
	initset();
}

function start(nextf) {
	// first populate the answer section with something, because otherwise the nextf functions will crash
	document.getElementById('answerset').appendChild(document.getElementById('set:0'));
	setnr = 0;
	
	nextitem = nextf;
	nextitem();

	soundManager.onload = function() {
		soundManager.createSound('goed', 'audio/goed.mp3');
		soundManager.createSound('fout', 'audio/fout.mp3');
		soundManager.createSound('levelup', 'audio/levelup.mp3');
	};
	
	var sets = striptextnodes(document.getElementById("itemset").childNodes);
	var maxsettxtnode = document.createTextNode(sets.length + 1); 
	// the +1 is because we already moved one set to the answer section
	document.getElementById("maxset").appendChild(maxsettxtnode);

	// delete set navigation except for the view action
	if (mode != "view") {
		removeChildrenFromNode(document.getElementById("setnav"));
	}
    return 0;
}

function pictureclicked(type, nr) {
	if (mode == "choosepic") {
		if (type == "item" && nr == itemnr) {
			document.getElementById("question").style.color="green";
			if (sound == 'y') { soundManager.play('goed'); }
			setTimeout("nextitem()", 800);
		} else {
			getElementsByClass('pic', document.getElementById(type + ':' + nr), 'div')[0].style.filter="alpha(opacity=50)";
			getElementsByClass('pic', document.getElementById(type + ':' + nr), 'div')[0].style.opacity=0.5; 
			if (sound == 'y') { soundManager.play('fout'); }
		}
	}
}

function wordclicked(type, nr) {
	if (mode == "chooseword") {
		if (type == "item" && nr == itemnr) {
			document.getElementById('item:' + itemnr).style.color="green";
			if (sound == 'y') { soundManager.play('goed'); }
			setTimeout("nextitem()", 800);
		} else {
			document.getElementById(type + ':' + nr).style.color="red";
			if (sound == 'y') { soundManager.play('fout'); }
			setTimeout('document.getElementById("' + type + ':' + nr + '").style.color="gray"', 800);
		}
	}
}

// This function will restore blackness and opacity in an answerset
function restoreitem() {
	// restore blackness
	document.getElementById("question").style.color="black";
	// restore images
	if (mode == 'choosepic') {
		var pics = getElementsByClass('pic', document.getElementById('answerset'), 'div');
		for (var i = 0; i < pics.length; i++) {
			pics[i].style.opacity=1;
			pics[i].style.filter="alpha(opacity=100)";
		}
	}
	if (mode == 'chooseword') {
		var words = getElementsByClass('item|filler', document.getElementById('answerset'), 'div');
		for (var i = 0; i < words.length; i++) {
			words[i].style.color="black";
		}
	}
}

function alldone() {
	alert("All done");
}

/* Administer items consecutively:  */
function nextconsec() {
 	var nitems = getElementsByClass('item', document, 'div').length;
	itemnr = -1;
	var oldsetnr;
	var nextf = function () {
		if (itemnr < nitems - 1) {
			restoreitem();
			itemnr++;
			var item = document.getElementById('item:' +itemnr);
			if (parseInt(item.parentNode.id.substr(4)) != oldsetnr) {
				setnr = oldsetnr = parseInt(item.parentNode.id.substr(4));
				initset();
				updatenav();
			}
			inititem();
		} else {
			alldone();
		}
	};
	return nextf;
}

function nextrandom() {
 	var nitems = getElementsByClass('item', document, 'div').length;
	//var nitems = striptextnodes(document.getElementById("itemset").childNodes).length * 4;
	var nextf = function() {
		restoreitem();
		itemnr = Math.floor(Math.random() * nitems);
		var item = document.getElementById('item:' + itemnr);
		setnr = parseInt(item.parentNode.id.substr(4));
		initset();
		inititem();
		updatenav();
	};
	return nextf;
}

