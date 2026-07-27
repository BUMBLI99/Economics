<div class="kpi-grid">
  <div class="kpi"><div class="kpi-label">Escenario alternativo</div><div class="kpi-value">TPM 4,5%</div><div class="kpi-note">durante 2026</div></div>
  <div class="kpi"><div class="kpi-label">Retorno al escenario base</div><div class="kpi-value">2027T1</div><div class="kpi-note">condición explícita del ejercicio</div></div>
  <div class="kpi"><div class="kpi-label">Máx. diferencia inflación</div><div class="kpi-value">{{ ipom.max_inflation_diff }} pp</div><div class="kpi-note">respecto del escenario base</div></div>
  <div class="kpi"><div class="kpi-label">Horizonte</div><div class="kpi-value">2029T4</div><div class="kpi-note">trayectorias trimestrales</div></div>
</div>

<div class="callout">
  <strong>Naturaleza del ejercicio.</strong> Se trata de una simulación condicional en un modelo semi-estructural. No es una predicción oficial ni una recomendación de política. El escenario alternativo se impone y el modelo calcula los shocks compatibles con esa trayectoria.
</div>

## Pregunta económica

¿Cómo cambian la inflación y la brecha de actividad cuando la TPM se mantiene en **4,5% durante 2026**, en lugar de seguir la trayectoria del escenario base identificado, y luego retorna al escenario base desde 2027?

El valor del ejercicio está en la coherencia conjunta: una trayectoria de tasa no se evalúa de manera aislada, sino junto con las ecuaciones de demanda, inflación, expectativas, tipo de cambio real y condiciones externas.

## Escenarios comparados

- **Escenario base IPoM identificado:** reproduce una trayectoria de referencia consistente con el modelo y los supuestos externos incorporados.
- **TPM 4,5% durante 2026:** exogeniza la tasa durante cuatro trimestres y fuerza el retorno a la trayectoria base a partir de 2027T1.

## Resultados principales

<figure class="chart-figure">
  <a href="../assets/img/charts/ipom_tpm.svg" target="_blank"><img src="../assets/img/charts/ipom_tpm.svg" alt="Trayectorias de TPM del escenario base y alternativo"></a>
  <figcaption class="chart-caption">La zona sombreada identifica el período en que la trayectoria alternativa es impuesta.</figcaption>
</figure>

<div class="figure-grid">
  <figure class="chart-figure"><a href="../assets/img/charts/ipom_inflation.svg" target="_blank"><img src="../assets/img/charts/ipom_inflation.svg" alt="Inflación total en escenarios IPoM"></a><figcaption class="chart-caption">Inflación total anual.</figcaption></figure>
  <figure class="chart-figure"><a href="../assets/img/charts/ipom_core.svg" target="_blank"><img src="../assets/img/charts/ipom_core.svg" alt="Inflación subyacente en escenarios IPoM"></a><figcaption class="chart-caption">Inflación subyacente sin volátiles.</figcaption></figure>
</div>

<figure class="chart-figure">
  <a href="../assets/img/charts/ipom_output_gap.svg" target="_blank"><img src="../assets/img/charts/ipom_output_gap.svg" alt="Brecha de actividad en escenarios IPoM"></a>
  <figcaption class="chart-caption">La respuesta de actividad es acotada y transitoria bajo la condición de convergencia impuesta.</figcaption>
</figure>

El escenario alternativo genera una diferencia máxima de inflación total cercana a **{{ ipom.max_inflation_diff }} puntos porcentuales**. La magnitud es moderada porque la desviación de la TPM es temporal y el ejercicio obliga a regresar al escenario base desde 2027.

## Estructura conceptual

<div class="equation"><span class="equation-label">Brecha de actividad</span>ỹ<sub>t</sub> = a<sub>1</sub>ỹ<sub>t−1</sub> − a<sub>2</sub>(i<sub>t</sub> − i<sup>n</sup><sub>t</sub>) + a<sub>3</sub>q̃<sub>t</sub> + a<sub>4</sub>y*<sub>t</sub> + ε<sup>y</sup><sub>t</sub></div>

<div class="equation"><span class="equation-label">Inflación subyacente</span>π<sup>core</sup><sub>t</sub> = b<sub>1</sub>π<sup>core</sup><sub>t−1</sub> + b<sub>2</sub>E<sub>t</sub>π<sup>core</sup><sub>t+h</sub> + κ<sub>y</sub>ỹ<sub>t</sub> + κ<sub>q</sub>q̃<sub>t</sub> + ε<sup>π</sup><sub>t</sub></div>

<div class="equation"><span class="equation-label">Regla monetaria</span>i<sub>t</sub> = ρi<sub>t−1</sub> + (1−ρ)[i<sup>n</sup><sub>t</sub> + φ<sub>π</sub>(E<sub>t</sub>π<sub>t+h</sub>−π*) + φ<sub>y</sub>ỹ<sub>t</sub>] + ε<sup>i</sup><sub>t</sub></div>

La implementación en IRIS distingue variables endógenas, shocks y condiciones de escenario. La trayectoria alternativa de TPM se trata como una condición sobre el modelo, no como un cambio arbitrario de una columna de datos.

## Bloque externo y supuestos

El modelo incorpora crecimiento de socios comerciales, Federal Funds Rate, Treasury a 10 años, VIX, cobre, petróleo y tipo de cambio real. Los escenarios comparten el mismo bloque externo salvo cuando se evalúa una alternativa específica de petróleo o brecha.

La comparación principal mantiene constantes esos supuestos para aislar el efecto de la condición monetaria.

## Límites de interpretación

- Los resultados dependen de la calibración y de la identificación del escenario base.
- Una trayectoria condicional no incorpora todas las respuestas de expectativas o primas de riesgo que podrían observarse en la práctica.
- La magnitud de las diferencias no debe leerse como una estimación causal estructural definitiva.
- El retorno exógeno al escenario base desde 2027 reduce deliberadamente la persistencia de los efectos.

## Documentos y salidas

<div class="download-grid">
  <a class="download" href="../assets/files/ipom/Escenario_TPM45_2026.pdf"><div><strong>Escenario TPM 4,5%</strong><span>PDF · gráficos del ejercicio</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/ipom/Baseline_IPOM_Identificado.pdf"><div><strong>Escenario base identificado</strong><span>PDF · referencia</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/ipom/ipom_raw_outputs.zip"><div><strong>Salidas brutas</strong><span>ZIP · series del modelo</span></div><span>↓</span></a>
  <a class="download" href="../assets/files/ipom/Nota_supuestos.pdf"><div><strong>Nota de supuestos</strong><span>PDF · documentación</span></div><span>↓</span></a>
</div>
