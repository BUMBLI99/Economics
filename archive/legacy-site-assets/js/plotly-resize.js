(function () {
  function isVisible(el) {
    return !!(el && (el.offsetWidth || el.offsetHeight || el.getClientRects().length));
  }

  function resizePlotly() {
    if (!window.Plotly) return;
    document.querySelectorAll('.js-plotly-plot').forEach(function (el) {
      if (!isVisible(el)) return;
      try {
        window.Plotly.Plots.resize(el);
        window.Plotly.relayout(el, { autosize: true });
      } catch (e) {}
    });
  }

  function scheduleResize() {
    if (window.requestAnimationFrame) {
      window.requestAnimationFrame(resizePlotly);
    }
    [0, 80, 220, 500, 900, 1400].forEach(function (delay) {
      window.setTimeout(resizePlotly, delay);
    });
  }

  document.addEventListener('DOMContentLoaded', scheduleResize);
  window.addEventListener('load', scheduleResize);
  window.addEventListener('resize', scheduleResize);
  document.addEventListener('shown.bs.tab', scheduleResize, true);
  document.addEventListener('shown.bs.collapse', scheduleResize, true);
  document.addEventListener('click', function (ev) {
    if (ev.target && ev.target.closest && ev.target.closest('.nav-link, [data-bs-toggle="tab"], [data-bs-toggle="collapse"]')) {
      scheduleResize();
    }
  }, true);

  if ('ResizeObserver' in window) {
    var observer = new ResizeObserver(scheduleResize);
    document.querySelectorAll('main, .tab-content, .tab-pane, .panel-tabset, .cell-output-display').forEach(function (el) {
      try { observer.observe(el); } catch (e) {}
    });
  }
})();
