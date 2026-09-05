(() => {
  'use strict';

  const $ = (selector, scope = document) => scope.querySelector(selector);
  const $$ = (selector, scope = document) => [...scope.querySelectorAll(selector)];

  const menuButton = $('.menu-toggle');
  const nav = $('.site-nav');
  if (menuButton && nav) {
    menuButton.addEventListener('click', () => {
      const open = nav.classList.toggle('open');
      menuButton.setAttribute('aria-expanded', String(open));
    });
    $$('.site-nav a').forEach((link) => link.addEventListener('click', () => {
      nav.classList.remove('open');
      menuButton.setAttribute('aria-expanded', 'false');
    }));
  }

  const year = $('[data-current-year]');
  if (year) year.textContent = String(new Date().getFullYear());

  const topButton = $('.back-to-top');
  if (topButton) {
    const update = () => topButton.classList.toggle('visible', window.scrollY > 700);
    window.addEventListener('scroll', update, { passive: true });
    update();
    topButton.addEventListener('click', () => window.scrollTo({ top: 0, behavior: 'smooth' }));
  }

  const tocLinks = $$('.project-toc a');
  if (tocLinks.length) {
    const sections = tocLinks.map((a) => document.getElementById(a.getAttribute('href').slice(1))).filter(Boolean);
    const observer = new IntersectionObserver((entries) => {
      const visible = entries.filter((e) => e.isIntersecting).sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top)[0];
      if (!visible) return;
      tocLinks.forEach((a) => a.classList.toggle('active', a.getAttribute('href') === `#${visible.target.id}`));
    }, { rootMargin: '-18% 0px -70% 0px', threshold: 0 });
    sections.forEach((section) => observer.observe(section));
  }

  const palette = {
    navy: '#193044', terracotta: '#b4573d', teal: '#2b7777', blue: '#416c8a',
    gold: '#b28a4a', sage: '#6f8a72', muted: '#66727f', grid: '#ded8cf', paper: '#ffffff'
  };

  function lineChart(container, series, options = {}) {
    if (!container || !series.length) return;
    const width = 1000;
    const height = options.height || 410;
    const margin = { top: 28, right: 24, bottom: 52, left: 62 };
    const innerW = width - margin.left - margin.right;
    const innerH = height - margin.top - margin.bottom;
    const allPoints = series.flatMap((s) => s.values.filter((p) => Number.isFinite(p.value)));
    if (!allPoints.length) return;
    const dates = allPoints.map((p) => new Date(p.date).getTime());
    let values = allPoints.map((p) => p.value);
    let minY = options.minY ?? Math.min(...values);
    let maxY = options.maxY ?? Math.max(...values);
    if (minY === maxY) { minY -= 1; maxY += 1; }
    const pad = (maxY - minY) * 0.1;
    minY -= pad; maxY += pad;
    const minX = Math.min(...dates); const maxX = Math.max(...dates);
    const sx = (x) => margin.left + ((x - minX) / Math.max(1, maxX - minX)) * innerW;
    const sy = (y) => margin.top + innerH - ((y - minY) / (maxY - minY)) * innerH;
    const ns = 'http://www.w3.org/2000/svg';
    const svg = document.createElementNS(ns, 'svg');
    svg.setAttribute('viewBox', `0 0 ${width} ${height}`);
    svg.setAttribute('role', 'img');
    svg.setAttribute('aria-label', options.ariaLabel || 'Gráfico interactivo');
    svg.style.background = palette.paper;

    const add = (name, attrs = {}, text = '') => {
      const el = document.createElementNS(ns, name);
      Object.entries(attrs).forEach(([k, v]) => el.setAttribute(k, String(v)));
      if (text) el.textContent = text;
      svg.appendChild(el);
      return el;
    };

    for (let i = 0; i <= 5; i++) {
      const yVal = minY + (i / 5) * (maxY - minY);
      const y = sy(yVal);
      add('line', { x1: margin.left, x2: width - margin.right, y1: y, y2: y, stroke: palette.grid, 'stroke-width': 1 });
      add('text', { x: margin.left - 10, y: y + 4, 'text-anchor': 'end', fill: palette.muted, 'font-size': 12 }, yVal.toFixed(options.yDigits ?? 1));
    }
    const xTicks = options.xTicks || Array.from({ length: 6 }, (_, i) => {
      const t = minX + (i / 5) * (maxX - minX);
      return { value: t, label: String(new Date(t).getFullYear()) };
    });
    xTicks.forEach((tick) => {
      const x = sx(tick.value);
      add('text', { x, y: height - 20, 'text-anchor': 'middle', fill: palette.muted, 'font-size': 12 }, tick.label);
    });
    if (options.zeroLine && minY < 0 && maxY > 0) {
      const y = sy(0);
      add('line', { x1: margin.left, x2: width - margin.right, y1: y, y2: y, stroke: palette.muted, 'stroke-width': 1.2 });
    }

    const tooltip = document.createElement('div');
    tooltip.style.cssText = 'position:absolute;display:none;pointer-events:none;padding:.45rem .55rem;border:1px solid #ded8cf;border-radius:9px;background:rgba(255,255,255,.96);box-shadow:0 8px 20px rgba(30,42,53,.12);font-size:.78rem;color:#1f2b36;z-index:5;white-space:nowrap';
    container.style.position = 'relative';
    container.innerHTML = '';
    container.appendChild(svg);
    container.appendChild(tooltip);

    const prepared = series.map((s) => ({
      ...s,
      values: s.values.filter((p) => Number.isFinite(p.value)).sort((a, b) => new Date(a.date) - new Date(b.date))
    }));
    const drawMarker = (shape, x, y, color) => {
      if (shape === 'triangle') {
        add('polygon', { points: `${x},${y - 6} ${x - 6},${y + 5} ${x + 6},${y + 5}`, fill: color, stroke: '#fff', 'stroke-width': 1.4 });
      } else if (shape === 'diamond') {
        add('rect', { x: x - 4.8, y: y - 4.8, width: 9.6, height: 9.6, fill: color, stroke: '#fff', 'stroke-width': 1.4, transform: `rotate(45 ${x} ${y})` });
      } else {
        add('circle', { cx: x, cy: y, r: 5.2, fill: color, stroke: '#fff', 'stroke-width': 1.4 });
      }
    };
    prepared.forEach((s) => {
      const points = s.values.filter((p) => Number.isFinite(p.value)).sort((a, b) => new Date(a.date) - new Date(b.date));
      const d = points.map((p, i) => `${i ? 'L' : 'M'}${sx(new Date(p.date).getTime()).toFixed(2)},${sy(p.value).toFixed(2)}`).join(' ');
      if (s.line !== false && points.length) add('path', { d, fill: 'none', stroke: s.color, 'stroke-width': s.width || 2.4, 'stroke-linejoin': 'round', 'stroke-linecap': 'round', 'stroke-dasharray': s.dash || '' });
      if (s.marker || options.points) points.forEach((p) => drawMarker(s.marker || 'circle', sx(new Date(p.date).getTime()), sy(p.value), s.color));
    });

    const focusLine = add('line', { y1: margin.top, y2: margin.top + innerH, stroke: palette.muted, 'stroke-width': 1, 'stroke-dasharray': '3 4', visibility: 'hidden' });
    const overlay = add('rect', { x: margin.left, y: margin.top, width: innerW, height: innerH, fill: 'transparent', tabindex: 0, 'aria-label': 'Recorre el gráfico para consultar valores' });
    const nearest = (points, target) => points.reduce((best, point) => Math.abs(new Date(point.date).getTime() - target) < Math.abs(new Date(best.date).getTime() - target) ? point : best);
    overlay.addEventListener('pointermove', (event) => {
      const bounds = svg.getBoundingClientRect();
      const viewX = ((event.clientX - bounds.left) / bounds.width) * width;
      const target = minX + Math.max(0, Math.min(1, (viewX - margin.left) / innerW)) * (maxX - minX);
      const points = prepared.filter((s) => s.values.length).map((s) => ({ series: s, point: nearest(s.values, target) }));
      if (!points.length) return;
      const anchor = points.reduce((best, item) => Math.abs(new Date(item.point.date).getTime() - target) < Math.abs(new Date(best.point.date).getTime() - target) ? item : best);
      const x = sx(new Date(anchor.point.date).getTime());
      focusLine.setAttribute('x1', x); focusLine.setAttribute('x2', x); focusLine.setAttribute('visibility', 'visible');
      tooltip.innerHTML = `<strong>${anchor.point.label || anchor.point.date}</strong>${points.map(({ series: s, point }) => `<br><span style="color:${s.color}">●</span> ${s.name}: ${point.value.toFixed(options.yDigits ?? 2)}`).join('')}`;
      tooltip.style.display = 'block';
      const containerRect = container.getBoundingClientRect();
      const tooltipX = event.clientX - containerRect.left;
      tooltip.style.left = `${Math.min(containerRect.width - 210, Math.max(8, tooltipX + 12))}px`;
      tooltip.style.top = `${Math.max(8, event.clientY - containerRect.top - 24)}px`;
    });
    overlay.addEventListener('pointerleave', () => { tooltip.style.display = 'none'; focusLine.setAttribute('visibility', 'hidden'); });
  }

  async function loadJSON(url) {
    const response = await fetch(url, { cache: 'no-store' });
    if (!response.ok) throw new Error(`No se pudo cargar ${url}`);
    return response.json();
  }

  async function initExchangeDashboard() {
    const root = $('[data-exchange-dashboard]');
    if (!root) return;
    try {
      const data = await loadJSON(root.dataset.url);
      const select = $('[data-country-select]', root);
      const ratesEl = $('[data-rates-chart]', root);
      const residualsEl = $('[data-residuals-chart]', root);
      const render = () => {
        const country = select.value;
        const subset = data.filter((d) => d.country === country);
        const rates = ['TPM', 'Tasa 10Y'].map((name, i) => ({
          name, color: i === 0 ? palette.navy : palette.teal,
          values: subset.filter((d) => d.panel === 'Tasas (%)' && d.series === name).map((d) => ({ date: d.date, value: d.value }))
        }));
        const residuals = [{
          name: 'Residuo FX', color: palette.terracotta,
          values: subset.filter((d) => d.panel === 'Desvíos del modelo (z-score)' && d.series === 'FX').map((d) => ({ date: d.date, value: d.value }))
        }];
        lineChart(ratesEl, rates, { ariaLabel: `TPM y tasa 10Y para ${country}`, yDigits: 1 });
        lineChart(residualsEl, residuals, { ariaLabel: `Residuo cambiario para ${country}`, yDigits: 1, zeroLine: true });
      };
      select.addEventListener('change', render);
      render();
    } catch (error) {
      root.innerHTML = `<div class="callout callout-critical"><strong>Dashboard no disponible.</strong> ${error.message}</div>`;
    }
  }

  async function initYieldCurve() {
    const root = $('[data-yield-curve]');
    if (!root) return;
    try {
      const data = await loadJSON(root.dataset.url);
      const slider = $('[data-curve-slider]', root);
      const label = $('[data-curve-date]', root);
      const chart = $('[data-curve-chart]', root);
      slider.max = String(data.length - 1);
      slider.value = String(data.length - 1);
      const render = () => {
        const row = data[Number(slider.value)];
        label.textContent = row.date.slice(0, 7);
        const points = [2, 5, 10];
        const values = [...row.nominal, ...row.real.filter((v) => v !== null)];
        const minY = Math.min(...values) - .5;
        const maxY = Math.max(...values) + .5;
        lineChart(chart, [
          { name: 'BCP nominal', color: palette.navy, values: points.map((p, i) => ({ date: `${2000 + p}-01-01`, value: row.nominal[i] })) },
          { name: 'BCU real', color: palette.teal, dash: '7 5', values: points.map((p, i) => ({ date: `${2000 + p}-01-01`, value: row.real[i] })).filter((p) => p.value !== null) }
        ], {
          ariaLabel: `Curva soberana ${row.date}`,
          yDigits: 2,
          points: true,
          minY,
          maxY,
          height: 360,
          xTicks: [
            { value: new Date('2002-01-01').getTime(), label: '2 años' },
            { value: new Date('2005-01-01').getTime(), label: '5 años' },
            { value: new Date('2010-01-01').getTime(), label: '10 años' }
          ]
        });
      };
      slider.addEventListener('input', render);
      render();
    } catch (error) {
      root.innerHTML = `<div class="callout callout-critical"><strong>Curva interactiva no disponible.</strong> ${error.message}</div>`;
    }
  }

  async function initProjectCharts() {
    const roots = $$('[data-project-chart]');
    if (!roots.length) return;
    let catalog;
    try { catalog = await loadJSON(roots[0].dataset.url); }
    catch (_) { roots.forEach((root) => root.classList.add('chart-load-error')); return; }
    roots.forEach((root) => {
      const config = catalog[root.dataset.projectChart];
      if (!config?.datasets?.length) return;
      const select = $('[data-dataset-select]', root);
      const rangeSelect = $('[data-range-select]', root);
      const chart = $('[data-generic-chart]', root);
      const legend = $('[data-chart-legend]', root);
      const note = $('[data-chart-note]', root);
      const table = $('[data-chart-table]', root);
      config.datasets.forEach((dataset) => {
        const option = document.createElement('option');
        option.value = dataset.id; option.textContent = dataset.label; select.appendChild(option);
      });
      if (config.defaultDataset && config.datasets.some((item) => item.id === config.defaultDataset)) {
        select.value = config.defaultDataset;
      }
      const escapeHTML = (value) => String(value ?? '').replace(/[&<>'"]/g, (char) => ({
        '&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'
      }[char]));
      const visibleSeries = (series) => {
        const months = Number(rangeSelect?.value || 0);
        if (!months) return series;
        const dates = series.flatMap((item) => item.values.map((point) => new Date(point.date)))
          .filter((date) => Number.isFinite(date.getTime()));
        if (!dates.length) return series;
        const maxDate = new Date(Math.max(...dates.map((date) => date.getTime())));
        const cutoff = new Date(maxDate.getFullYear(), maxDate.getMonth() - months + 1, 1);
        return series.map((item) => ({
          ...item,
          values: item.values.filter((point) => new Date(point.date) >= cutoff)
        }));
      };
      const renderTable = (rows = []) => {
        if (!table) return;
        if (!rows.length) { table.innerHTML = ''; table.hidden = true; return; }
        const headers = ['Dato', 'Período', 'Valor (%)', 'Intervalo', 'Vintage', 'Procedencia'];
        const cells = ['concept', 'period', 'value', 'interval', 'vintage', 'status'];
        table.hidden = false;
        table.innerHTML = `<div class="table-wrap chart-data-table"><table><thead><tr>${headers.map((label) => `<th>${label}</th>`).join('')}</tr></thead><tbody>${rows.map((row) => `<tr>${cells.map((key) => `<td>${key === 'value' && Number.isFinite(row[key]) ? Number(row[key]).toFixed(2) : escapeHTML(row[key] ?? '—')}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
      };
      const render = () => {
        const dataset = config.datasets.find((item) => item.id === select.value) || config.datasets[0];
        const xTicks = dataset.xTicks?.map((tick) => ({ value: new Date(tick.date).getTime(), label: tick.label }));
        const series = visibleSeries(dataset.series);
        lineChart(chart, series, { ariaLabel: `${config.ariaLabel}: ${dataset.label}`, yDigits: dataset.yDigits ?? 2, zeroLine: Boolean(dataset.zeroLine), xTicks });
        legend.innerHTML = dataset.series.map((series) => `<span class="legend-item"><span class="legend-swatch${series.marker ? ` marker-${series.marker}` : ''}" style="background:${series.color};color:${series.color}"></span>${series.name}</span>`).join('');
        if (note) note.textContent = dataset.note || '';
        renderTable(dataset.table);
      };
      select.addEventListener('change', render);
      rangeSelect?.addEventListener('change', render);
      render(); root.classList.add('chart-ready');
    });
  }

  function enhanceStaticFigures() {
    $$('.chart-figure').forEach((figure) => {
      const link = $('a[href$=".svg"]', figure); if (!link) return;
      link.setAttribute('aria-label', `Abrir gráfico ampliado: ${$('img', link)?.alt || 'visualización'}`);
      link.setAttribute('title', 'Abrir SVG en tamaño completo');
      const badge = document.createElement('span'); badge.className = 'figure-action'; badge.textContent = 'Ampliar ↗'; link.appendChild(badge);
    });
  }

  async function initDebtSimulator() {
    const root = $('[data-debt-simulator]');
    if (!root) return;
    try {
      const base = await loadJSON(root.dataset.url);
      const controls = {
        growth: $('[data-debt-growth]', root), rate: $('[data-debt-rate]', root),
        primary: $('[data-debt-primary]', root), sfa: $('[data-debt-sfa]', root)
      };
      const chart = $('[data-debt-chart]', root);
      const output2030 = $('[data-debt-2030]', root);
      const outputMax = $('[data-debt-max]', root);
      const outputCross = $('[data-debt-cross]', root);
      const calculate = () => {
        const growthShock = Number(controls.growth.value) / 100;
        const marketRateShock = Number(controls.rate.value) / 100;
        const primaryShock = Number(controls.primary.value) / 100;
        const sfaShock = Number(controls.sfa.value) / 100;
        let debt = Number(base[0].deuda_rezagada);
        const simulated = base.map((row, index) => {
          const passThrough = 1 - Math.pow(0.75, index + 1);
          const growth = Number(row.crecimiento_nominal) + growthShock;
          const rate = Number(row.tasa_efectiva) + marketRateShock * passThrough;
          debt = ((1 + rate) / (1 + growth)) * debt
            - (Number(row.balance_primario) + primaryShock)
            + (Number(row.sfa_total) + sfaShock);
          return { date: `${row.anio}-01-01`, value: 100 * debt, label: String(row.anio) };
        });
        const baseline = base.map((row) => ({
          date: `${row.anio}-01-01`, value: 100 * Number(row.deuda_pib), label: String(row.anio)
        }));
        const at2030 = simulated.find((point) => point.label === '2030');
        const maximum = simulated.reduce((a, b) => b.value > a.value ? b : a);
        const crossing = simulated.find((point) => point.value > 45);
        output2030.textContent = at2030 ? `${at2030.value.toFixed(1).replace('.', ',')}%` : '—';
        outputMax.textContent = `${maximum.value.toFixed(1).replace('.', ',')}% · ${maximum.label}`;
        outputCross.textContent = crossing ? crossing.label : 'No supera';
        lineChart(chart, [
          { name: 'Base compatible', color: palette.navy, width: 2.5, values: baseline },
          { name: 'Simulación', color: palette.terracotta, width: 2.8, values: simulated }
        ], { ariaLabel: 'Resultado del simulador de deuda', yDigits: 1, points: true });
      };
      Object.values(controls).forEach((control) => control.addEventListener('change', calculate));
      calculate();
    } catch (error) {
      root.innerHTML = `<div class="callout callout-critical"><strong>Simulador no disponible.</strong> ${error.message}</div>`;
    }
  }

  function initAtlasEmbed() {
    const frame = $('[data-atlas-frame]');
    if (!frame) return;
    const status = $('[data-atlas-status]');
    let resizeObserver;

    const syncHeight = () => {
      try {
        const doc = frame.contentDocument;
        if (!doc?.documentElement || !doc.body) return;
        const height = Math.max(doc.documentElement.scrollHeight, doc.body.scrollHeight);
        if (height > 500) frame.style.height = `${Math.ceil(height + 2)}px`;
      } catch (_) {
        // La altura inicial permite usar el panel si el navegador restringe el acceso al iframe.
      }
    };

    frame.addEventListener('load', () => {
      frame.classList.add('loaded');
      if (status) status.hidden = true;
      syncHeight();
      try {
        resizeObserver?.disconnect();
        resizeObserver = new ResizeObserver(syncHeight);
        resizeObserver.observe(frame.contentDocument.documentElement);
        resizeObserver.observe(frame.contentDocument.body);
      } catch (_) { /* Mantener la altura de respaldo. */ }
    });

    window.addEventListener('resize', syncHeight, { passive: true });
  }

  initExchangeDashboard();
  initYieldCurve();
  initProjectCharts();
  initDebtSimulator();
  enhanceStaticFigures();
  initAtlasEmbed();
})();
