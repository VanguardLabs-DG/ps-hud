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

  // Shortest angular difference between target and current (-180 to +180)
  function shortestAngleDiff(target: number, current: number): number {
    return ((target - current + 540) % 360) - 180;
  }

  let currentAngle = 0;
  let targetAngle = 0;
  let lastTargetAngle = 0;
  let turnVelocity = 0; // deg per second
  let lastPacketTimestamp = 0;
  let animFrameId: number | null = null;
  let isRunning = false;
  let lastFrameTime = 0;

  let northPos = { left: 50, top: 0 };
  let eastPos = { left: 100, top: 50 };
  let southPos = { left: 50, top: 100 };
  let westPos = { left: 0, top: 50 };

  function getCoord(angleDeg: number) {
    const rad = (angleDeg * Math.PI) / 180;
    return {
      left: Number((50 + Math.sin(rad) * 50).toFixed(2)),
      top: Number((50 - Math.cos(rad) * 50).toFixed(2)),
    };
  }

  function updateMarkers(angle: number) {
    northPos = getCoord(angle);
    eastPos = getCoord((angle + 90) % 360);
    southPos = getCoord((angle + 180) % 360);
    westPos = getCoord((angle + 270) % 360);
  }

  function getCardinal(deg: number): string {
    const cardinals = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    const index = Math.round(deg / 45) % 8;
    return cardinals[index];
  }

  $: rawHeading = (($CompassHudStore.heading + 90) % 360 + 360) % 360;

  // React to new incoming heading packets from telemetry with turn velocity estimation
  $: {
    const newTarget = (360 - rawHeading) % 360;
    const now = (typeof performance !== 'undefined') ? performance.now() : Date.now();
    if (lastPacketTimestamp > 0) {
      const dt = Math.max(0.016, (now - lastPacketTimestamp) / 1000);
      const delta = shortestAngleDiff(newTarget, lastTargetAngle);
      // Filtered turn velocity in deg/s
      turnVelocity = turnVelocity * 0.35 + (delta / dt) * 0.65;
    }
    lastTargetAngle = targetAngle;
    targetAngle = newTarget;
    lastPacketTimestamp = now;

    if (!isRunning && ($VehicleHudStore.show || DebugStore || isCalibrating)) {
      startLoop();
    }
  }

  function renderFrame(now: number) {
    if (!($VehicleHudStore.show || DebugStore || isCalibrating)) {
      isRunning = false;
      return;
    }

    if (!lastFrameTime) lastFrameTime = now;
    const dt = Math.min(0.05, Math.max(0.001, (now - lastFrameTime) / 1000));
    lastFrameTime = now;

    // Direction prediction: lead ahead by ~45ms based on turning velocity
    const lead = Math.max(-30, Math.min(30, turnVelocity * 0.045));
    const predictedTarget = targetAngle + lead;
    const predictedDiff = shortestAngleDiff(predictedTarget, currentAngle);

    // Frame-rate independent exponential smoothing factor (lambda = 15)
    const lerpFactor = 1 - Math.exp(-15 * dt);

    currentAngle = (currentAngle + predictedDiff * lerpFactor + 360) % 360;
    updateMarkers(currentAngle);

    animFrameId = requestAnimationFrame(renderFrame);
  }

  function startLoop() {
    if (isRunning) return;
    isRunning = true;
    lastFrameTime = (typeof performance !== 'undefined') ? performance.now() : Date.now();
    animFrameId = requestAnimationFrame(renderFrame);
  }

  function stopLoop() {
    if (animFrameId) {
      cancelAnimationFrame(animFrameId);
      animFrameId = null;
    }
    isRunning = false;
  }

  $: displayedHeading = (360 - Math.round(currentAngle) + 360) % 360;
  $: cardinalName = getCardinal(displayedHeading);
  $: headingFormatted = String(displayedHeading).padStart(3, '0') + '°';

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
    if ($VehicleHudStore.show || DebugStore || isCalibrating) {
      startLoop();
    }
  });

  onDestroy(() => {
    stopLoop();
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
        <!-- Integrated Machined Header (Flush Mounted on Top Rim) -->
        <div class="header-flush">
          <div class="header-bearing">
            <span class="bearing-icon">🧭</span>
            <span class="bearing-deg">{headingFormatted}</span>
            <span class="bearing-cardinal">{cardinalName}</span>
          </div>

          <div class="header-divider" />

          <div class="header-location">
            <span class="location-street">{$CompassHudStore.street1 || 'DISTRITO PAULISTA'}</span>
            {#if $CompassHudStore.street2}
              <span class="location-cross">/ {$CompassHudStore.street2}</span>
            {/if}
            {#if $CompassHudStore.zone}
              <span class="location-zone">• {$CompassHudStore.zone}</span>
            {/if}
          </div>
        </div>

        <!-- Laser-etched Metric Graduation Ticks around the Rim (Every 45°) -->
        {#each [0, 45, 90, 135, 180, 225, 270, 315] as deg}
          {@const tick = getCoord(deg)}
          <div
            class="bezel-tick {deg % 90 === 0 ? 'major' : 'minor'}"
            style="left: {tick.left}%; top: {tick.top}%;"
          />
        {/each}

        <!-- Fixed Vehicle Forward Notch at 12 o'clock -->
        <div class="forward-notch" title="Frente do Veículo">▲</div>

        <!-- Machined Precision North Needle orbiting along the Bezel Rim -->
        <div
          class="north-needle"
          style="left: {northPos.left}%; top: {northPos.top}%; transform: translate(-50%, -50%) rotate({Math.round(currentAngle)}deg);"
          title="Norte Verdadeiro ({headingFormatted})"
        >
          <div class="needle-arrow" />
          <span class="needle-label">N</span>
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
    border-color: #1a1e27;
    box-shadow: 
      0 0 0 1.5px rgba(255, 149, 0, 0.75),
      0 0 14px rgba(255, 149, 0, 0.35),
      inset 0 0 0 1px rgba(255, 179, 0, 0.4),
      0 6px 24px rgba(0, 0, 0, 0.85);
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
    border: 3.5px solid #1a1e27;
    border-radius: 6px;
    box-sizing: border-box;
    pointer-events: none;
    user-select: none;
    background: transparent !important;
    box-shadow: 0 0 0 1.5px rgba(255, 149, 0, 0.75), 0 2px 8px rgba(0, 0, 0, 0.5);
    z-index: 25;
  }

  /* Integrated Machined Header (Flush Mounted on Top Rim) */
  .header-flush {
    position: absolute;
    bottom: calc(100% - 2px);
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    align-items: center;
    gap: 0.65vh;
    padding: 0.35vh 1vh;
    background: rgba(14, 18, 25, 0.96);
    border: 1px solid rgba(255, 179, 0, 0.4);
    border-bottom: 1px solid #161a22;
    border-top-left-radius: 6px;
    border-top-right-radius: 6px;
    box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.75), 0 0 10px rgba(255, 149, 0, 0.15);
    white-space: nowrap;
    pointer-events: none;
    font-family: 'Montserrat', sans-serif;
    z-index: 35;
    max-width: 95%;
  }

  .header-bearing {
    display: flex;
    align-items: center;
    gap: 0.3vh;
    color: #ffb300;
    font-weight: 800;
    font-size: 1.05vh;
    letter-spacing: 0.03em;
    flex-shrink: 0;
  }

  .bearing-icon {
    font-size: 0.95vh;
    line-height: 1;
  }

  .bearing-deg {
    font-variant-numeric: tabular-nums;
    color: #ffd54f;
  }

  .bearing-cardinal {
    color: #ff9500;
    font-weight: 900;
  }

  .header-divider {
    width: 1px;
    height: 1.2vh;
    background: rgba(255, 255, 255, 0.15);
    flex-shrink: 0;
  }

  .header-location {
    display: flex;
    align-items: center;
    gap: 0.4vh;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .location-street {
    font-size: 1.15vh;
    font-weight: 800;
    color: #ffffff;
    letter-spacing: 0.04em;
    text-transform: uppercase;
  }

  .location-cross {
    font-size: 1.0vh;
    font-weight: 600;
    color: rgba(255, 255, 255, 0.65);
    text-transform: uppercase;
  }

  .location-zone {
    font-size: 0.95vh;
    font-weight: 700;
    color: #ffb300;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  /* Laser-etched Metric Graduation Ticks */
  .bezel-tick {
    position: absolute;
    transform: translate(-50%, -50%);
    pointer-events: none;
    border-radius: 50%;
  }

  .bezel-tick.major {
    width: 5px;
    height: 5px;
    background: #ffb300;
    box-shadow: 0 0 6px #ff9500;
  }

  .bezel-tick.minor {
    width: 3px;
    height: 3px;
    background: rgba(255, 179, 0, 0.45);
  }

  /* Fixed Vehicle Forward Notch */
  .forward-notch {
    position: absolute;
    top: -5px;
    left: 50%;
    transform: translateX(-50%);
    color: #ffd54f;
    font-size: 8px;
    line-height: 1;
    text-shadow: 0 0 6px #ff9500;
    pointer-events: none;
    z-index: 31;
  }

  /* Machined Precision North Needle */
  .north-needle {
    position: absolute;
    width: 14px;
    height: 18px;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    z-index: 32;
    transition: none;
  }

  .needle-arrow {
    width: 0;
    height: 0;
    border-left: 4px solid transparent;
    border-right: 4px solid transparent;
    border-bottom: 7px solid #ffb300;
    filter: drop-shadow(0 0 4px #ff9500);
  }

  .needle-label {
    font-family: 'Montserrat', sans-serif;
    font-size: 8px;
    font-weight: 900;
    color: #ffd54f;
    line-height: 1;
    margin-top: 1px;
    text-shadow: 0 0 4px rgba(255, 149, 0, 0.8), 0 1px 2px rgba(0, 0, 0, 0.9);
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