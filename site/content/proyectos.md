<div class="section-heading">
  <div>
    <p class="eyebrow">Research portfolio</p>
    <h2>Projects</h2>
    <p>This section will collect my applied research projects in macroeconomics and econometrics. Each project will document its research question, data, methodology, results, interpretation, and limitations.</p>
  </div>
</div>


<div class="panel" style="text-align:center; padding:3rem 2rem; margin-top:3rem; margin-bottom:2rem;">
  <p class="eyebrow">In preparation</p>
  <h2>Projects coming soon</h2>
  <p>I am currently developing research projects in empirical macroeconomics and macroeconometrics. Detailed project pages, replication materials, code, data documentation, and research outputs will be added here as they become available.</p>
  <div class="actions" style="justify-content:center;"><a class="button button-primary" href="https://github.com/BUMBLI99" target="_blank" rel="noopener">Visit my GitHub</a></div>
</div>




<!-- Aquí se añaden los proyectos. La información sale de proyectos.md, según slugs. -->

<div class="card-grid">
{% for p in projects %}
<article class="project-card">
  <a class="card-image" href="proyectos/{{ p.slug }}.html"><img src="{{ p.image }}" alt="Quick look of {{ p.short_title }}" loading="lazy"></a>
  <div class="card-body">
    <div class="card-kicker">{{ p.category }}</div>
    <h3 class="card-title"><a href="proyectos/{{ p.slug }}.html">{{ p.title }}</a></h3>
    <p class="card-description">{{ p.description }}</p>
    <div class="tag-row">{% for tag in p.tags %}<span class="tag">{{ tag }}</span>{% endfor %}</div>
    <div class="card-footer"><a class="card-link" href="proyectos/{{ p.slug }}.html">Open project →</a><span class="status {% if p.status_class == 'note' %}status-note{% endif %}">{{ p.status }}</span></div>
  </div>
</article>
{% endfor %}
</div>


<div class="section" style="padding-bottom:0">
  <div class="two-col">
    <div class="panel">
      <p class="eyebrow">Research approach</p>
      <h2>How projects will be presented</h2>
      <p>Each public project will provide a transparent account of its motivation, data sources, empirical strategy, main findings, and limitations. Where possible, I will include reproducible code, documentation, and links to research outputs.</p>
      <p>Published pages will use validated, pre-processed outputs rather than run models in real time. This makes the portfolio more reliable and preserves a clear separation between research pipelines and public presentation.</p>
      <p>Projects related to other research fields will be also published here. The research agenda reflects my main interests.</p>
    </div>
    <div class="panel">
      <p class="eyebrow">Research agenda</p>
      <ul class="clean-list">
        <li><strong>Macroeconomic tail risks</strong><br><span class="muted">Inflation-at-Risk and Growth-at-Risk using quantile-regression and macro-financial approaches.</span></li>
        <li><strong>Monetary-policy transmission</strong><br><span class="muted">VAR, SVAR, and Bayesian methods to study policy shocks, inflation, output, and financial conditions.</span></li>
        <li><strong>Forecasting and structural macroeconometrics</strong><br><span class="muted">Bayesian VARs, DSGE models, and model-based forecasting for macroeconomic analysis.</span></li>
      </ul>
    </div>
  </div>
</div>