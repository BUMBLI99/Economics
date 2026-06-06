(function () {
  function resizePlotly() {
    if (!window.Plotly) return;
    document.querySelectorAll('.js-plotly-plot').forEach(function(el) {
      try { window.Plotly.Plots.resize(el); } catch (e) {}
    });
  }

  window.addEventListener('load', function() {
    setTimeout(resizePlotly, 100);
    setTimeout(resizePlotly, 500);
    setTimeout(resizePlotly, 1200);
  });
  window.addEventListener('resize', function() {
    setTimeout(resizePlotly, 50);
  });
  document.addEventListener('shown.bs.tab', function() {
    setTimeout(resizePlotly, 50);
    setTimeout(resizePlotly, 250);
    setTimeout(resizePlotly, 700);
  });
  document.addEventListener('shown.bs.collapse', function() {
    setTimeout(resizePlotly, 50);
    setTimeout(resizePlotly, 250);
  });
})();
