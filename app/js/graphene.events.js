function highlightGraph(classVal, toggleVal) {
  if (classVal.indexOf(toggleVal) != -1) {
    return classVal;
  }

  return classVal + " " + toggleVal;
}

function removeHighlightGraph(classVal, toggleVal) {
  if (classVal.indexOf(toggleVal) == -1) {
    return classVal;
  }

  var find = "\\s" + toggleVal;

  return classVal.replace(new RegExp(find, 'g'), "");
}

function postRenderTimeSeriesView(vis) {
  var svg = vis;
  svg.selectAll('a.l').forEach( function(g) {
    g.forEach(function(a){ 
      var aid = a.getAttribute('id')
      a.addEventListener('mouseenter', function() {
        svg.selectAll('path#l-' + aid).forEach ( function (g) {
          g.forEach(function (path) {
            path.setAttribute(
              'class',
              highlightGraph(path.getAttribute('class'), "line-highlight")
            );
          })
        })
        svg.selectAll('path#a-' + aid).forEach ( function (g) {
          g.forEach(function (path) {
            path.setAttribute(
              'class',
              highlightGraph(path.getAttribute('class'), "area-highlight")
            );
          })
        })
      })
      a.addEventListener('mouseleave', function() {
        svg.selectAll('path#l-' + aid).forEach ( function (g) {
          g.forEach(function (path) {
            path.setAttribute(
              'class',
              removeHighlightGraph(path.getAttribute('class'), "line-highlight")
            );
          })
        })
        svg.selectAll('path#a-' + aid).forEach ( function (g) {
          g.forEach(function (path) {
            path.setAttribute(
              'class',
              removeHighlightGraph(path.getAttribute('class'), "area-highlight")
            );
          })
        })
      })
    })
  })
}
