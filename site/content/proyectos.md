<div class="section-heading">
  <div>
    <p class="eyebrow">Proyectos aplicados</p>
    <h2>Análisis consolidados</h2>
    <p>Todos los proyectos siguen la misma estructura: pregunta, estado de datos, resultados principales, metodología, interpretación y límites.</p>
  </div>
</div>

<div class="card-grid">
{% for p in projects %}
<article class="project-card">
  <a class="card-image" href="proyectos/{{ p.slug }}.html"><img src="{{ p.image }}" alt="Vista previa de {{ p.short_title }}" loading="lazy"></a>
  <div class="card-body">
    <div class="card-kicker">{{ p.category }}</div>
    <h3 class="card-title"><a href="proyectos/{{ p.slug }}.html">{{ p.title }}</a></h3>
    <p class="card-description">{{ p.description }}</p>
    <div class="tag-row">{% for tag in p.tags %}<span class="tag">{{ tag }}</span>{% endfor %}</div>
    <div class="card-footer"><a class="card-link" href="proyectos/{{ p.slug }}.html">Abrir proyecto →</a><span class="status {% if p.status_class == 'note' %}status-note{% endif %}">{{ p.status }}</span></div>
  </div>
</article>
{% endfor %}
</div>

<div class="section" style="padding-bottom:0">
  <div class="two-col">
    <div class="panel">
      <p class="eyebrow">Criterio editorial</p>
      <h2>Qué significa que un proyecto esté publicado</h2>
      <p>La página pública no ejecuta modelos en tiempo real. Consume salidas procesadas y validadas por cada pipeline. Esto evita que una falla de descarga, una dependencia de R o una revisión metodológica rompa el sitio completo.</p>
      <p>Los resultados se muestran con fecha de corte, estado y advertencias específicas. Cuando un insumo no está disponible, la salida correspondiente no se publica como si existiera.</p>
    </div>
    <div class="panel">
      <p class="eyebrow">Agenda de investigación</p>
      <ul class="clean-list">
        <li><strong>Política monetaria y fluctuaciones cambiarias</strong><br><span class="muted">Extensión de la tesis de Magíster a reglas de reacción, shocks externos y bienestar.</span></li>
        <li><strong>Transmisión heterogénea de tasas</strong><br><span class="muted">Diferencias por producto, fase del ciclo y condiciones financieras.</span></li>
        <li><strong>Infraestructura digital y comercio de servicios</strong><br><span class="muted">Latencia, conectividad internacional, regulación y exportaciones.</span></li>
      </ul>
    </div>
  </div>
</div>
