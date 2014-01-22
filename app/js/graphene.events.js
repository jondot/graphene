function toggleHighlight(classVal, toggleVal) {
	function replaceAll(find, replace, str) {
	  return str.replace(new RegExp(find, 'g'), replace);
	}
	
    if (classVal.indexOf(toggleVal) != -1) {
        return replaceAll("highlight", "", classVal)
    }
    else {
        return classVal + " " + toggleVal;
    }
}

function postRenderTimeSeriesView(vis) {
  var svg = vis;
  svg.selectAll('a.l').forEach( function(g) { 
      g.forEach(function(a){ 
          var aid = a.getAttribute('id')
          a.addEventListener('mouseenter', function() {
              svg.selectAll('path#l-' + aid).forEach ( function (g) {
                  g.forEach(function (path) {
                      path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "line-highlight"));                      
                  })
              })
              svg.selectAll('path#a-' + aid).forEach ( function (g) {
                  g.forEach(function (path) {
                      path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "area-highlight"));                      
                  })
              })
          })
          a.addEventListener('mouseleave', function() {
              svg.selectAll('path#l-' + aid).forEach ( function (g) {
                  g.forEach(function (path) {
                      path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "line-highlight"));                      
                  })
              })
              svg.selectAll('path#a-' + aid).forEach ( function (g) {
                  g.forEach(function (path) {
                      path.setAttribute('class', toggleHighlight(path.getAttribute('class'), "area-highlight"));                      
                  })
              })
          })
      }) 
  })
}