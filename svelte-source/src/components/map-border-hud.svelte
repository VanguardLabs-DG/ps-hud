<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import DebugStore from '../stores/debugStore';
  import VehicleHudStore from '../stores/vehicleHudStore';
  import CompassHudStore from '../stores/compassHudStore';
  import { fetchNui } from '../utils/eventHandler';

  const STORAGE_KEY = 'ps-hud:map-border-calibration-v3';

  // Standard calibrated coordinates locked for Distrito Paulista (vh)
  const DEFAULT_CONFIG = {
    left: 2.30,
    bottom: 6.20,
    width: 27.60,
    height: 23.82,
    borderWidth: 6.0,
    borderRadius: 50,
  };

  let circleLeft = DEFAULT_CONFIG.left;
  let circleBottom = DEFAULT_CONFIG.bottom;
  let circleWidth = DEFAULT_CONFIG.width;
  let circleHeight = DEFAULT_CONFIG.height;
  let circleBorderWidth = DEFAULT_CONFIG.borderWidth;
  let circleBorderRadius = DEFAULT_CONFIG.borderRadius;

  let isCalibrating = false;
  let lockAspect = false;
  let activeStep = 0.05; // 0.01, 0.05, 0.10, 0.50
  let backupConfig = { ...DEFAULT_CONFIG };
  let saveFeedback = false;
  let coordOutputInput: HTMLInputElement;

  $: coordString = `left = ${circleLeft.toFixed(2)}vh, bottom = ${circleBottom.toFixed(2)}vh, width = ${circleWidth.toFixed(2)}vh, height = ${circleHeight.toFixed(2)}vh, border = ${circleBorderWidth.toFixed(1)}px`;

  // Compass Telemetry Calculation (Heading-Up radar mathematical projection)
  $: worldHeading = (($CompassHudStore.heading + 90) % 360 + 360) % 360;
  $: northAngle = (360 - worldHeading) % 360;
  $: eastAngle = (northAngle + 90) % 360;
  $: southAngle = (northAngle + 180) % 360;
  $: westAngle = (northAngle + 270) % 360;

  function getCoord(angleDeg: number) {
    const rad = (angleDeg * Math.PI) / 180;
    return {
      left: Number((50 + Math.sin(rad) * 50).toFixed(2)),
      top: Number((50 - Math.cos(rad) * 50).toFixed(2)),
    };
  }

  $: northPos = getCoord(northAngle);
  $: eastPos = getCoord(eastAngle);
  $: southPos = getCoord(southAngle);
  $: westPos = getCoord(westAngle);

  function getCardinal(deg: number): string {
    const cardinals = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const index = Math.round(deg / 45) % 8;
    return cardinals[index];
  }

  $: cardinalName = getCardinal(worldHeading);
  $: headingFormatted = String(Math.round(worldHeading)).padStart(3, '0') + '°';

  const loadCalibration = () => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const parsed = JSON.parse(saved);
        if (typeof parsed.left === 'number') circleLeft = parsed.left;
        if (typeof parsed.bottom === 'number') circleBottom = parsed.bottom;
        if (typeof parsed.width === 'number') circleWidth = parsed.width;
        if (typeof parsed.height === 'number') circleHeight = parsed.height;
        if (typeof parsed.borderWidth === 'number') circleBorderWidth = parsed.borderWidth;
        if (typeof parsed.borderRadius === 'number') circleBorderRadius = parsed.borderRadius;
      }
    } catch (e) {
      console.warn('[HUD] Falha ao carregar calibração do minimapa:', e);
    }
  };

  const saveCalibration = async () => {
    const config = {
      left: Number(circleLeft.toFixed(2)),
      bottom: Number(circleBottom.toFixed(2)),
      width: Number(circleWidth.toFixed(2)),
      height: Number(circleHeight.toFixed(2)),
      borderWidth: Number(circleBorderWidth.toFixed(1)),
      borderRadius: Number(circleBorderRadius),
    };

    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
    } catch (_) {}

    // Safe clipboard attempt (avoids unhandled permission error in FiveM CEF)
    try {
      if (typeof navigator !== 'undefined' && navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(coordString).catch(() => {});
      }
    } catch (_) {}

    saveFeedback = true;
    setTimeout(() => {
      saveFeedback = false;
      isCalibrating = false;
    }, 450);

    await fetchNui('saveMapCalibration', config);
  };

  const cancelCalibration = async () => {
    circleLeft = backupConfig.left;
    circleBottom = backupConfig.bottom;
    circleWidth = backupConfig.width;
    circleHeight = backupConfig.height;
    circleBorderWidth = backupConfig.borderWidth;
    circleBorderRadius = backupConfig.borderRadius;
    isCalibrating = false;
    await fetchNui('closeMapCalibration', {});
  };

  const resetToDefault = () => {
    circleLeft = DEFAULT_CONFIG.left;
    circleBottom = DEFAULT_CONFIG.bottom;
    circleWidth = DEFAULT_CONFIG.width;
    circleHeight = DEFAULT_CONFIG.height;
    circleBorderWidth = DEFAULT_CONFIG.borderWidth;
    circleBorderRadius = DEFAULT_CONFIG.borderRadius;
  };

  const adjust = (
    param: 'left' | 'bottom' | 'width' | 'height' | 'bothSize' | 'border',
    delta: number
  ) => {
    if (param === 'left') {
      circleLeft = Math.max(0, Number((circleLeft + delta).toFixed(2)));
    } else if (param === 'bottom') {
      circleBottom = Math.max(0, Number((circleBottom + delta).toFixed(2)));
    } else if (param === 'width') {
      circleWidth = Math.max(5, Number((circleWidth + delta).toFixed(2)));
      if (lockAspect) {
        circleHeight = Math.max(5, Number((circleHeight + delta * (circleHeight / circleWidth)).toFixed(2)));
      }
    } else if (param === 'height') {
      circleHeight = Math.max(5, Number((circleHeight + delta).toFixed(2)));
      if (lockAspect) {
        circleWidth = Math.max(5, Number((circleWidth + delta * (circleWidth / circleHeight)).toFixed(2)));
      }
    } else if (param === 'bothSize') {
      circleWidth = Math.max(5, Number((circleWidth + delta).toFixed(2)));
      circleHeight = Math.max(5, Number((circleHeight + delta).toFixed(2)));
    } else if (param === 'border') {
      circleBorderWidth = Math.max(1, Math.min(10, Number((circleBorderWidth + delta).toFixed(1))));
    }
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (!isCalibrating) return;

    // Do not capture keys if user is typing directly inside an <input>
    if (['INPUT', 'TEXTAREA'].includes((e.target as HTMLElement)?.tagName)) {
      if (e.key === 'Enter') {
        e.preventDefault();
        saveCalibration();
      } else if (e.key === 'Escape') {
        e.preventDefault();
        cancelCalibration();
      }
      return;
    }

    let step = activeStep;
    if (e.shiftKey) step *= 5;
    if (e.altKey || e.ctrlKey) step = 0.01;

    switch (e.key) {
      // Position X
      case 'ArrowLeft':
        e.preventDefault();
        e.stopPropagation();
        adjust('left', -step);
        break;
      case 'ArrowRight':
        e.preventDefault();
        e.stopPropagation();
        adjust('left', step);
        break;

      // Position Y
      case 'ArrowUp':
        e.preventDefault();
        e.stopPropagation();
        adjust('bottom', step);
        break;
      case 'ArrowDown':
        e.preventDefault();
        e.stopPropagation();
        adjust('bottom', -step);
        break;

      // Oval Width (A / D)
      case 'a':
      case 'A':
        e.preventDefault();
        e.stopPropagation();
        adjust('width', -step);
        break;
      case 'd':
      case 'D':
        e.preventDefault();
        e.stopPropagation();
        adjust('width', step);
        break;

      // Oval Height (W / S)
      case 'w':
      case 'W':
        e.preventDefault();
        e.stopPropagation();
        adjust('height', step);
        break;
      case 's':
      case 'S':
        e.preventDefault();
        e.stopPropagation();
        adjust('height', -step);
        break;

      // Proportional Scale (+ / - or PgUp / PgDn)
      case 'PageUp':
      case '+':
      case '=':
        e.preventDefault();
        e.stopPropagation();
        adjust('bothSize', step);
        break;
      case 'PageDown':
      case '-':
      case '_':
        e.preventDefault();
        e.stopPropagation();
        adjust('bothSize', -step);
        break;

      // Border Width ([ and ])
      case '[':
        e.preventDefault();
        e.stopPropagation();
        adjust('border', -0.5);
        break;
      case ']':
        e.preventDefault();
        e.stopPropagation();
        adjust('border', 0.5);
        break;

      // Save / Cancel
      case 'Enter':
        e.preventDefault();
        e.stopPropagation();
        saveCalibration();
        break;
      case 'Escape':
        e.preventDefault();
        e.stopPropagation();
        cancelCalibration();
        break;
    }
  };

  const handleMessage = (event: MessageEvent) => {
    if (event.data?.action === 'mapcalibrate') {
      backupConfig = {
        left: circleLeft,
        bottom: circleBottom,
        width: circleWidth,
        height: circleHeight,
        borderWidth: circleBorderWidth,
        borderRadius: circleBorderRadius,
      };
      isCalibrating = true;
    }
  };

  const selectCoordText = (e: MouseEvent) => {
    const input = e.currentTarget as HTMLInputElement;
    input.select();
  };

  onMount(() => {
    loadCalibration();
    window.addEventListener('message', handleMessage);
    window.addEventListener('keydown', handleKeyDown);
  });

  onDestroy(() => {
    window.removeEventListener('message', handleMessage);
    window.removeEventListener('keydown', handleKeyDown);
  });
</script>

{#if $VehicleHudStore.show || DebugStore || isCalibrating}
  {#if $VehicleHudStore.showCircleBorder || (DebugStore && !$VehicleHudStore.showSquareBorder) || isCalibrating}
    <div
      class="circle {isCalibrating ? 'calibrating' : ''}"
      style="
        left: calc(max(0px, (100vw - 177.78vh) / 2) + {circleLeft}vh);
        bottom: {circleBottom}vh;
        width: {circleWidth}vh;
        height: {circleHeight}vh;
        border-width: {circleBorderWidth}px;
        border-radius: {circleBorderRadius}%;
      "
    >
      {#if isCalibrating}
        <div class="crosshair-center" />
        <div class="axis-guide-x" />
        <div class="axis-guide-y" />
      {:else}
        <!-- Top Aerodynamic GPS / Navigation Pill (Zero blur to prevent CEF black box) -->
        <div class="gps-pill">
          <div class="heading-badge">
            <span class="compass-icon">🧭</span>
            <span class="heading-text">{cardinalName} • {headingFormatted}</span>
          </div>
          <div class="street-info">
            <span class="street-main">{$CompassHudStore.street1 || 'DISTRITO PAULISTA'}</span>
            {#if $CompassHudStore.street2}
              <span class="street-cross">/ {$CompassHudStore.street2}</span>
            {/if}
            {#if $CompassHudStore.zone}
              <span class="street-zone">• {$CompassHudStore.zone}</span>
            {/if}
          </div>
        </div>

        <!-- Outer Bezel Precision Chassis Lip -->
        <div class="outer-bezel-lip" />

        <!-- 4 Graduation Corner Ticks (45°, 135°, 225°, 315°) -->
        {#each [45, 135, 225, 315] as deg}
          {@const tick = getCoord(deg)}
          <div
            class="bezel-tick"
            style="left: {tick.left}%; top: {tick.top}%;"
          />
        {/each}

        <!-- Fixed Vehicle Forward Vector Indicator at 12 o'clock -->
        <div class="forward-heading-notch" title="Frente do Veículo">▲</div>

        <!-- Dynamic Rotating Compass Markers along the Oval Rim -->
        <!-- North (N) Highlighted Amber Glowing Beacon -->
        <div
          class="compass-marker north"
          style="left: {northPos.left}%; top: {northPos.top}%;"
          title="Norte Verdadeiro"
        >
          N
        </div>

        <!-- East (E) -->
        <div
          class="compass-marker cardinal"
          style="left: {eastPos.left}%; top: {eastPos.top}%;"
          title="Leste"
        >
          E
        </div>

        <!-- South (S) -->
        <div
          class="compass-marker cardinal"
          style="left: {southPos.left}%; top: {southPos.top}%;"
          title="Sul"
        >
          S
        </div>

        <!-- West (W) -->
        <div
          class="compass-marker cardinal"
          style="left: {westPos.left}%; top: {westPos.top}%;"
          title="Oeste"
        >
          W
        </div>

        <!-- Bottom Micro Telemetry Badge -->
        <div class="telemetry-badge">
          <span class="pulse-dot" />
          <span class="telemetry-label">SAT-NAV // DISTRITO PAULISTA</span>
        </div>
      {/if}
    </div>
  {/if}

  {#if $VehicleHudStore.showSquareBorder && !isCalibrating}
    <div class="square" />
  {/if}
{/if}

{#if isCalibrating}
  <div class="calibration-overlay">
    <div class="calibration-card">
      <!-- Header -->
      <div class="header">
        <div class="header-top">
          <span class="badge">AJUSTE FINO OVAL & POSIÇÃO</span>
        </div>
        <h2>Calibração da Moldura do Minimapa</h2>
        <p>Ajuste os parâmetros até a moldura oval contornar o radar perfeitamente.</p>
      </div>

      <!-- Precision Step Selector -->
      <div class="step-selector">
        <span class="step-title">Sensibilidade do Passo:</span>
        <div class="step-options">
          {#each [0.01, 0.05, 0.1, 0.5] as st}
            <button
              class="step-pill {activeStep === st ? 'selected' : ''}"
              on:click={() => (activeStep = st)}
            >
              {st === 0.01 ? '0.01vh (Micro)' : st === 0.05 ? '0.05vh (Fino)' : st === 0.1 ? '0.10vh (Médio)' : '0.50vh (Rápido)'}
            </button>
          {/each}
        </div>
      </div>

      <!-- Coordinates & Dimensions Grid -->
      <div class="controls-grid">
        <!-- Posição X (Left) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Posição X (Esquerda)</span>
            <span class="key-hint">Setas ← →</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('left', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              bind:value={circleLeft}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button class="adj-btn" on:click={() => adjust('left', activeStep)}>+</button>
          </div>
        </div>

        <!-- Posição Y (Bottom) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Posição Y (Inferior)</span>
            <span class="key-hint">Setas ↑ ↓</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('bottom', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              bind:value={circleBottom}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button class="adj-btn" on:click={() => adjust('bottom', activeStep)}>+</button>
          </div>
        </div>

        <!-- Largura Oval (Width) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Largura (Oval X)</span>
            <span class="key-hint">Teclas A / D</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('width', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              bind:value={circleWidth}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button class="adj-btn" on:click={() => adjust('width', activeStep)}>+</button>
          </div>
        </div>

        <!-- Altura Oval (Height) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Altura (Oval Y)</span>
            <span class="key-hint">Teclas W / S</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('height', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              bind:value={circleHeight}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button class="adj-btn" on:click={() => adjust('height', activeStep)}>+</button>
          </div>
        </div>

        <!-- Espessura da Borda -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Espessura Borda</span>
            <span class="key-hint">Teclas [ ]</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('border', -0.5)}>−</button>
            <input
              type="number"
              step="0.1"
              min="1"
              max="10"
              bind:value={circleBorderWidth}
              class="param-input"
            />
            <span class="unit-tag">px</span>
            <button class="adj-btn" on:click={() => adjust('border', 0.5)}>+</button>
          </div>
        </div>

        <!-- Escala Geral Proporcional -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Escala Proporcional</span>
            <span class="key-hint">PgUp / PgDn ou + -</span>
          </div>
          <div class="input-row">
            <button class="adj-btn" on:click={() => adjust('bothSize', -activeStep)}>−</button>
            <div class="scale-info">
              {((circleWidth / circleHeight) || 1).toFixed(2)}x Proporção
            </div>
            <button class="adj-btn" on:click={() => adjust('bothSize', activeStep)}>+</button>
          </div>
        </div>
      </div>

      <!-- Live Coordinate String Output -->
      <div class="output-container">
        <span class="output-label">Coordenadas Atuais:</span>
        <input
          bind:this={coordOutputInput}
          readonly
          class="output-text"
          value={coordString}
          on:click={selectCoordText}
          title="Clique para selecionar e copiar com Ctrl+C"
        />
      </div>

      <!-- Action Buttons -->
      <div class="actions">
        <button class="btn btn-reset" on:click={resetToDefault}>
          Restaurar Padrão
        </button>
        <button class="btn btn-cancel" on:click={cancelCalibration}>
          Cancelar (ESC)
        </button>
        <button class="btn btn-save" on:click={saveCalibration}>
          {saveFeedback ? '✓ Salvo com Sucesso!' : 'Salvar & Fechar (ENTER)'}
        </button>
      </div>
    </div>
  </div>
{/if}

<style>
  .circle {
    position: fixed;
    box-sizing: border-box;
    pointer-events: none;
    user-select: none;
    background: transparent !important;
    border-style: solid;
    border-color: rgba(255, 255, 255, 0.95);
    box-shadow: 0 0 10px rgba(0, 0, 0, 0.6);
    z-index: 25;
    transition: none;
  }

  /* Calibration Mode Styling */
  .circle.calibrating {
    border-style: dashed !important;
    border-color: #00ff88 !important;
    box-shadow: 0 0 16px rgba(0, 255, 136, 0.65) !important;
    z-index: 9999;
  }

  .crosshair-center {
    position: absolute;
    top: 50%;
    left: 50%;
    width: 6px;
    height: 6px;
    transform: translate(-50%, -50%);
    border-radius: 50%;
    background: #00ff88;
    box-shadow: 0 0 8px #00ff88;
  }

  .axis-guide-x {
    position: absolute;
    top: 50%;
    left: 0;
    right: 0;
    height: 1px;
    background: rgba(0, 255, 136, 0.2);
    transform: translateY(-50%);
    pointer-events: none;
  }

  .axis-guide-y {
    position: absolute;
    left: 50%;
    top: 0;
    bottom: 0;
    width: 1px;
    background: rgba(0, 255, 136, 0.2);
    transform: translateX(-50%);
    pointer-events: none;
  }

  .square {
    position: fixed;
    bottom: 3.2vh;
    left: calc(max(0px, (100vw - 177.78vh) / 2) + 2.30vh);
    width: 28.5vh;
    height: 19.2vh;
    border: 3.5px solid rgba(255, 255, 255, 0.95);
    border-radius: 6px;
    box-sizing: border-box;
    pointer-events: none;
    user-select: none;
    background: transparent !important;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.35);
    z-index: 25;
  }

  /* Tactical Navigation Pill (Top GPS) */
  .gps-pill {
    position: absolute;
    top: -3.8vh;
    left: 50%;
    transform: translateX(-50%);
    background: rgba(10, 14, 23, 0.92);
    border: 1px solid rgba(255, 255, 255, 0.16);
    border-radius: 9999px;
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.75);
    display: flex;
    align-items: center;
    gap: 0.65vh;
    padding: 0.3vh 0.9vh;
    white-space: nowrap;
    pointer-events: none;
    font-family: 'Montserrat', sans-serif;
    z-index: 35;
    max-width: 95%;
  }

  .heading-badge {
    display: flex;
    align-items: center;
    gap: 0.35vh;
    background: rgba(255, 149, 0, 0.18);
    border: 1px solid rgba(255, 149, 0, 0.5);
    color: #ff9500;
    font-size: 1.05vh;
    font-weight: 800;
    padding: 0.15vh 0.55vh;
    border-radius: 9999px;
    letter-spacing: 0.04em;
    flex-shrink: 0;
  }

  .compass-icon {
    font-size: 1.0vh;
    line-height: 1;
  }

  .heading-text {
    font-family: 'Montserrat', sans-serif;
    font-variant-numeric: tabular-nums;
  }

  .street-info {
    display: flex;
    align-items: center;
    gap: 0.4vh;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .street-main {
    font-size: 1.15vh;
    font-weight: 800;
    color: #ffffff;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  .street-cross {
    font-size: 1.0vh;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.65);
    text-transform: uppercase;
  }

  .street-zone {
    font-size: 0.95vh;
    font-weight: 700;
    color: #ff9500;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  /* Outer Bezel Chassis & Ticks */
  .outer-bezel-lip {
    position: absolute;
    inset: -5px;
    border-radius: 50%;
    border: 1.5px solid rgba(255, 255, 255, 0.22);
    box-shadow: 0 6px 20px rgba(0, 0, 0, 0.7);
    pointer-events: none;
  }

  .bezel-tick {
    position: absolute;
    width: 4px;
    height: 4px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.45);
    transform: translate(-50%, -50%);
    pointer-events: none;
    box-shadow: 0 0 4px rgba(255, 255, 255, 0.3);
  }

  /* Fixed Vehicle Forward Notch */
  .forward-heading-notch {
    position: absolute;
    top: -9px;
    left: 50%;
    transform: translateX(-50%);
    color: #ffffff;
    font-size: 10px;
    line-height: 1;
    text-shadow: 0 0 6px rgba(255, 255, 255, 0.8), 0 2px 4px rgba(0, 0, 0, 0.9);
    pointer-events: none;
    z-index: 31;
  }

  /* Dynamic Rotating Compass Markers */
  .compass-marker {
    position: absolute;
    transform: translate(-50%, -50%);
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
    transition: left 0.35s ease-out, top 0.35s ease-out;
  }

  .compass-marker.north {
    width: 22px;
    height: 22px;
    border-radius: 50%;
    background: rgba(13, 17, 28, 0.94);
    border: 1.5px solid #ff9500;
    color: #ff9500;
    font-size: 11px;
    font-weight: 900;
    box-shadow: 0 0 10px rgba(255, 149, 0, 0.6), 0 2px 6px rgba(0, 0, 0, 0.7);
    z-index: 33;
  }

  .compass-marker.cardinal {
    width: 17px;
    height: 17px;
    border-radius: 50%;
    background: rgba(13, 17, 28, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.4);
    color: rgba(255, 255, 255, 0.85);
    font-size: 9px;
    font-weight: 800;
    box-shadow: 0 2px 5px rgba(0, 0, 0, 0.6);
    z-index: 30;
  }

  /* Bottom Micro Telemetry Badge */
  .telemetry-badge {
    position: absolute;
    bottom: -2.3vh;
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    align-items: center;
    gap: 0.45vh;
    pointer-events: none;
    background: rgba(10, 14, 23, 0.82);
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 4px;
    padding: 0.2vh 0.65vh;
    z-index: 28;
    white-space: nowrap;
  }

  .pulse-dot {
    width: 5px;
    height: 5px;
    border-radius: 50%;
    background: #22c55e;
    box-shadow: 0 0 6px #22c55e;
  }

  .telemetry-label {
    font-family: 'Montserrat', sans-serif;
    font-size: 0.75vh;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.7);
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  /* Calibration Modal UI */
  .calibration-overlay {
    position: fixed;
    top: 2.2vh;
    left: 50%;
    transform: translateX(-50%);
    z-index: 10000;
    pointer-events: auto;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
  }

  .calibration-card {
    background: rgba(13, 19, 33, 0.96);
    border: 1px solid rgba(255, 255, 255, 0.14);
    border-radius: 16px;
    padding: 1.3rem 1.6rem;
    box-shadow: 0 15px 35px rgba(0, 0, 0, 0.65), 0 0 20px rgba(0, 255, 136, 0.15);
    display: flex;
    flex-direction: column;
    gap: 0.95rem;
    width: 680px;
    color: #ffffff;
    box-sizing: border-box;
  }

  .header {
    display: flex;
    flex-direction: column;
    gap: 0.3rem;
  }

  .header-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .badge {
    background: rgba(0, 255, 136, 0.15);
    color: #00ff88;
    border: 1px solid rgba(0, 255, 136, 0.4);
    font-size: 0.65rem;
    font-weight: 800;
    letter-spacing: 0.08em;
    padding: 0.2rem 0.6rem;
    border-radius: 9999px;
    text-transform: uppercase;
  }

  .header h2 {
    margin: 0;
    font-size: 1.2rem;
    font-weight: 800;
    color: #ffffff;
    letter-spacing: 0.02em;
  }

  .header p {
    margin: 0;
    font-size: 0.78rem;
    color: rgba(255, 255, 255, 0.65);
  }

  /* Step Selector */
  .step-selector {
    display: flex;
    align-items: center;
    gap: 0.6rem;
    background: rgba(255, 255, 255, 0.04);
    padding: 0.45rem 0.7rem;
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.06);
  }

  .step-title {
    font-size: 0.72rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.7);
    text-transform: uppercase;
  }

  .step-options {
    display: flex;
    gap: 0.4rem;
  }

  .step-pill {
    background: rgba(255, 255, 255, 0.06);
    border: 1px solid rgba(255, 255, 255, 0.12);
    color: rgba(255, 255, 255, 0.75);
    font-family: inherit;
    font-size: 0.68rem;
    font-weight: 700;
    padding: 0.2rem 0.6rem;
    border-radius: 6px;
    cursor: pointer;
    transition: all 0.15s ease;
  }

  .step-pill:hover {
    background: rgba(0, 255, 136, 0.15);
    color: #00ff88;
  }

  .step-pill.selected {
    background: rgba(0, 255, 136, 0.25);
    border-color: #00ff88;
    color: #00ff88;
    font-weight: 800;
  }

  /* Controls Grid */
  .controls-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 0.65rem;
  }

  .control-box {
    background: rgba(255, 255, 255, 0.05);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 10px;
    padding: 0.6rem 0.7rem;
    display: flex;
    flex-direction: column;
    gap: 0.45rem;
  }

  .box-top {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .param-name {
    font-size: 0.68rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.75);
    text-transform: uppercase;
  }

  .key-hint {
    font-size: 0.6rem;
    font-weight: 600;
    color: rgba(0, 255, 136, 0.85);
    background: rgba(0, 255, 136, 0.1);
    padding: 0.1rem 0.35rem;
    border-radius: 4px;
  }

  .input-row {
    display: flex;
    align-items: center;
    gap: 0.35rem;
  }

  .adj-btn {
    background: rgba(255, 255, 255, 0.08);
    border: 1px solid rgba(255, 255, 255, 0.12);
    color: #ffffff;
    font-family: inherit;
    font-size: 0.85rem;
    font-weight: 800;
    width: 26px;
    height: 26px;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    transition: all 0.15s ease;
  }

  .adj-btn:hover {
    background: rgba(0, 255, 136, 0.25);
    border-color: rgba(0, 255, 136, 0.6);
    color: #00ff88;
    transform: scale(1.05);
  }

  .param-input {
    flex: 1;
    background: rgba(0, 0, 0, 0.45);
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: 6px;
    color: #00ff88;
    font-family: inherit;
    font-size: 0.95rem;
    font-weight: 800;
    text-align: center;
    padding: 0.25rem 0.2rem;
    outline: none;
    width: 50px;
    -moz-appearance: textfield;
  }

  .param-input::-webkit-outer-spin-button,
  .param-input::-webkit-inner-spin-button {
    -webkit-appearance: none;
    margin: 0;
  }

  .param-input:focus {
    border-color: #00ff88;
    box-shadow: 0 0 8px rgba(0, 255, 136, 0.4);
  }

  .unit-tag {
    font-size: 0.68rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.45);
  }

  .scale-info {
    flex: 1;
    text-align: center;
    font-size: 0.75rem;
    font-weight: 700;
    color: #00ff88;
    background: rgba(0, 0, 0, 0.35);
    padding: 0.3rem 0;
    border-radius: 6px;
  }

  /* Output Container */
  .output-container {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    background: rgba(0, 0, 0, 0.4);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 8px;
    padding: 0.4rem 0.7rem;
  }

  .output-label {
    font-size: 0.68rem;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.6);
    white-space: nowrap;
    text-transform: uppercase;
  }

  .output-text {
    flex: 1;
    background: transparent;
    border: none;
    color: #00ff88;
    font-family: monospace;
    font-size: 0.75rem;
    font-weight: 600;
    outline: none;
    cursor: pointer;
  }

  .output-text:focus {
    color: #ffffff;
  }

  /* Actions */
  .actions {
    display: flex;
    justify-content: flex-end;
    align-items: center;
    gap: 0.6rem;
  }

  .btn {
    font-family: inherit;
    font-size: 0.78rem;
    font-weight: 700;
    padding: 0.5rem 1.1rem;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.2s ease;
    border: none;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .btn-reset {
    background: rgba(255, 255, 255, 0.07);
    color: rgba(255, 255, 255, 0.75);
    border: 1px solid rgba(255, 255, 255, 0.12);
    margin-right: auto;
  }

  .btn-reset:hover {
    background: rgba(255, 255, 255, 0.15);
    color: #ffffff;
  }

  .btn-cancel {
    background: rgba(239, 68, 68, 0.15);
    color: #f87171;
    border: 1px solid rgba(239, 68, 68, 0.3);
  }

  .btn-cancel:hover {
    background: rgba(239, 68, 68, 0.25);
    color: #ffffff;
  }

  .btn-save {
    background: linear-gradient(135deg, #10b981 0%, #059669 100%);
    color: #ffffff;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.35);
  }

  .btn-save:hover {
    background: linear-gradient(135deg, #34d399 0%, #10b981 100%);
    box-shadow: 0 6px 16px rgba(16, 185, 129, 0.5);
    transform: translateY(-1px);
  }

  .btn:active {
    transform: translateY(1px);
  }
</style>