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

    series.forEach((s) => {
      const points = s.values.filter((p) => Number.isFinite(p.value)).sort((a, b) => new Date(a.date) - new Date(b.date));
      const d = points.map((p, i) => `${i ? 'L' : 'M'}${sx(new Date(p.date).getTime()).toFixed(2)},${sy(p.value).toFixed(2)}`).join(' ');
      add('path', { d, fill: 'none', stroke: s.color, 'stroke-width': s.width || 2.4, 'stroke-linejoin': 'round', 'stroke-linecap': 'round', 'stroke-dasharray': s.dash || '' });
      points.forEach((p) => {
        const circle = add('circle', { cx: sx(new Date(p.date).getTime()), cy: sy(p.value), r: options.points ? 3.4 : 7, fill: options.points ? s.color : 'transparent', stroke: options.points ? '#fff' : 'transparent', 'stroke-width': 1 });
        circle.addEventListener('mouseenter', (event) => {
          tooltip.style.display = 'block';
          tooltip.innerHTML = `<strong>${s.name}</strong><br>${p.date}: ${p.value.toFixed(options.yDigits ?? 2)}`;
          const rect = container.getBoundingClientRect();
          tooltip.style.left = `${event.clientX - rect.left + 12}px`;
          tooltip.style.top = `${event.clientY - rect.top - 18}px`;
        });
        circle.addEventListener('mouseleave', () => { tooltip.style.display = 'none'; });
      });
    });
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

  initExchangeDashboard();
  initYieldCurve();
})();
