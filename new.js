$(function() {

$.extend( $.tablesorter.characterEquivalents, {
    "И" : "\u0406", // І
    "и" : "\u0456", //  і
    "У" : "\u040e", // Ў
	"у" : "\u045e", // ў
});
	
	
// define sugar.js Icelandic sort order
  Array.AlphanumericSortOrder = "АаБбВвГгДдЕеЁёЖжЗзІіЙйКкЛлМмНнОоПпРрСсТтУуЎуФфХхЦцЧчШшЫыЬьЭэЮюЯя'";
  Array.AlphanumericSortIgnoreCase = true;
  // see https://github.com/andrewplummer/Sugar/issues/382#issuecomment-41526957
  Array.AlphanumericSortEquivalents = {};

  
$("#myTable").tablesorter({
	widgets: ['zebra'],
	widthFixed: false,
	theme : 'blue',
	// Enable use of the characterEquivalents reference
	sortLocaleCompare : true,
	// if false, upper case sorts BEFORE lower case
	// ignoreCase : true
	// // ignoreCase : false,
    // // textSorter : {
      // // 3 : Array.AlphanumericSort,     // alphanumeric sort from sugar (http://sugarjs.com/arrays#sorting)
      // // // function parameters were previously (a, b, table, column) - *** THEY HAVE CHANGED!!! ***
     // // 4 : function(a, b, direction, column, table){
        // // // this is the original sort method from tablesorter 2.0.3
        // // if (table.config.sortLocaleCompare) { return a.localeCompare(b); }
        // // return ((a < b) ? -1 : ((a > b) ? 1 : 0));
      // // },
      // // // no need to set this as it is the default sorter
      // // // renamed v2.12 from $.tablesorter.sortText - performs natural sort
      // // 5 : $.tablesorter.sortNatural,
    // // }
});
	// 
	// console.log("dfsdfsfa");
	
	
}); 

