<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { fade, fly } from 'svelte/transition';
  import DebugStore from '../stores/debugStore';
  import VehicleHudStore from '../stores/vehicleHudStore';
  import CompassHudStore from '../stores/compassHudStore';
  import PlayerHudStore from '../stores/playerStatusHudStore';
  import ColorEffectStore from '../stores/colorEffectStore';
  import { fetchNui } from '../utils/eventHandler';
  import presetStore from '../stores/presetStore';
  import mapCoordStore, { DEFAULT_CIRCLE_CONFIG, DEFAULT_SQUARE_CONFIG, STORAGE_KEY_CIRCLE, STORAGE_KEY_SQUARE } from '../stores/mapCoordStore';

  let circleLeft = DEFAULT_CIRCLE_CONFIG.left;
  let circleBottom = DEFAULT_CIRCLE_CONFIG.bottom;
  let circleWidth = DEFAULT_CIRCLE_CONFIG.width;
  let circleHeight = DEFAULT_CIRCLE_CONFIG.height;
  let circleBorderWidth = DEFAULT_CIRCLE_CONFIG.borderWidth;
  let circleBorderRadius = DEFAULT_CIRCLE_CONFIG.borderRadius;

  let squareLeft = DEFAULT_SQUARE_CONFIG.left;
  let squareBottom = DEFAULT_SQUARE_CONFIG.bottom;
  let squareWidth = DEFAULT_SQUARE_CONFIG.width;
  let squareHeight = DEFAULT_SQUARE_CONFIG.height;
  let squareBorderWidth = DEFAULT_SQUARE_CONFIG.borderWidth;
  let squareBorderRadius = DEFAULT_SQUARE_CONFIG.borderRadius;

  let isCalibrating = false;
  let calibratingShape: 'circle' | 'square' = 'circle';
  let lockAspect = false;
  let activeStep = 0.05; // 0.01, 0.05, 0.10, 0.50
  let backupCircleConfig = { ...DEFAULT_CIRCLE_CONFIG };
  let backupSquareConfig = { ...DEFAULT_SQUARE_CONFIG };
  let saveFeedback = false;
  let coordOutputInput: HTMLInputElement;

  $: coordString = calibratingShape === 'square'
    ? `left = ${squareLeft.toFixed(2)}vh, bottom = ${squareBottom.toFixed(2)}vh, width = ${squareWidth.toFixed(2)}vh, height = ${squareHeight.toFixed(2)}vh, border = ${squareBorderWidth.toFixed(1)}px, radius = ${squareBorderRadius.toFixed(1)}px`
    : `left = ${circleLeft.toFixed(2)}vh, bottom = ${circleBottom.toFixed(2)}vh, width = ${circleWidth.toFixed(2)}vh, height = ${circleHeight.toFixed(2)}vh, border = ${circleBorderWidth.toFixed(1)}px`;

  // Player Status Bindings for Integrated Header Dock
  $: isDesign = $PlayerHudStore.designMode;
  $: designVal = $PlayerHudStore.designProgress;
  $: healthVal = isDesign ? designVal : ($PlayerHudStore.icons.health?.progressValue ?? 100);
  $: armorVal = isDesign ? designVal : ($PlayerHudStore.icons.armor?.progressValue ?? 0);
  $: hungerVal = isDesign ? designVal : ($PlayerHudStore.icons.hunger?.progressValue ?? 100);
  $: thirstVal = isDesign ? designVal : ($PlayerHudStore.icons.thirst?.progressValue ?? 100);
  $: staminaVal = isDesign ? designVal : ($PlayerHudStore.stamina ?? 100);
  $: oxygenVal = isDesign ? designVal : ($PlayerHudStore.icons.oxygen?.progressValue ?? 100);
  $: stressVal = isDesign ? designVal : ($PlayerHudStore.icons.stress?.progressValue ?? 0);

  $: healthColor = $ColorEffectStore.icons.health?.colorEffects[0]?.progressColor || "#DC0616";
  $: armorColor = $ColorEffectStore.icons.armor?.colorEffects[0]?.progressColor || "#3B82F6";
  $: hungerColor = $ColorEffectStore.icons.hunger?.colorEffects[0]?.progressColor || "#F97316";
  $: thirstColor = $ColorEffectStore.icons.thirst?.colorEffects[0]?.progressColor || "#06B6D4";
  $: staminaColor = "#10B981";
  $: oxygenColor = "#84CC16";
  $: stressColor = "#EC4899";

  $: statusList = [
    { id: 'health', val: Math.round(healthVal), color: healthColor, visible: true, icon: 'heart' },
    { id: 'armor', val: Math.round(armorVal), color: armorColor, visible: isDesign || armorVal > 0, icon: 'shield' },
    { id: 'hunger', val: Math.round(hungerVal), color: hungerColor, visible: true, icon: 'utensils' },
    { id: 'thirst', val: Math.round(thirstVal), color: thirstColor, visible: true, icon: 'droplet' },
    { id: 'stamina', val: Math.round(staminaVal), color: staminaColor, visible: true, icon: 'bolt' },
    { id: 'oxygen', val: Math.round(oxygenVal), color: oxygenColor, visible: isDesign || oxygenVal < 100, icon: 'lungs' },
    { id: 'stress', val: Math.round(stressVal), color: stressColor, visible: isDesign || stressVal > 0, icon: 'brain' },
  ];

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

  let northPosCircle = { left: 50, top: 0 };
  let northPosSquare = { left: 50, top: 0 };

  function getCircleCoord(angleDeg: number) {
    const rad = (angleDeg * Math.PI) / 180;
    return {
      left: Number((50 + Math.sin(rad) * 50).toFixed(2)),
      top: Number((50 - Math.cos(rad) * 50).toFixed(2)),
    };
  }

  function getSquareCoord(angleDeg: number) {
    const rad = (angleDeg * Math.PI) / 180;
    const s = Math.sin(rad);
    const c = Math.cos(rad);
    const absS = Math.abs(s);
    const absC = Math.abs(c);
    const tx = absS > 0.0001 ? 50 / absS : 99999;
    const ty = absC > 0.0001 ? 50 / absC : 99999;
    const t = Math.min(tx, ty);
    return {
      left: Number((50 + t * s).toFixed(2)),
      top: Number((50 - t * c).toFixed(2)),
    };
  }

  function updateMarkers(angle: number) {
    northPosCircle = getCircleCoord(angle);
    northPosSquare = getSquareCoord(angle);
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
      const savedCircle = localStorage.getItem(STORAGE_KEY_CIRCLE) || localStorage.getItem('ps-hud:map-border-calibration-v3');
      if (savedCircle) {
        const parsed = JSON.parse(savedCircle);
        if (typeof parsed.left === 'number') circleLeft = parsed.left;
        if (typeof parsed.bottom === 'number') circleBottom = parsed.bottom;
        if (typeof parsed.width === 'number') circleWidth = parsed.width;
        if (typeof parsed.height === 'number') circleHeight = parsed.height;
        if (typeof parsed.borderWidth === 'number') circleBorderWidth = parsed.borderWidth;
        if (typeof parsed.borderRadius === 'number') circleBorderRadius = parsed.borderRadius;
      }
      const savedSquare = localStorage.getItem(STORAGE_KEY_SQUARE);
      if (savedSquare) {
        const parsed = JSON.parse(savedSquare);
        if (typeof parsed.left === 'number') squareLeft = parsed.left;
        if (typeof parsed.bottom === 'number') squareBottom = parsed.bottom;
        if (typeof parsed.width === 'number') squareWidth = parsed.width;
        if (typeof parsed.height === 'number') squareHeight = parsed.height;
        if (typeof parsed.borderWidth === 'number') squareBorderWidth = parsed.borderWidth;
        if (typeof parsed.borderRadius === 'number') squareBorderRadius = parsed.borderRadius;
      }
    } catch (e) {
      console.warn('[HUD] Falha ao carregar calibração do minimapa:', e);
    }
  };

  const saveCalibration = async () => {
    const isSq = calibratingShape === 'square';
    const config = {
      shape: calibratingShape,
      left: Number((isSq ? squareLeft : circleLeft).toFixed(2)),
      bottom: Number((isSq ? squareBottom : circleBottom).toFixed(2)),
      width: Number((isSq ? squareWidth : circleWidth).toFixed(2)),
      height: Number((isSq ? squareHeight : circleHeight).toFixed(2)),
      borderWidth: Number((isSq ? squareBorderWidth : circleBorderWidth).toFixed(1)),
      borderRadius: Number((isSq ? squareBorderRadius : circleBorderRadius).toFixed(1)),
    };

    try {
      if (isSq) {
        localStorage.setItem(STORAGE_KEY_SQUARE, JSON.stringify(config));
        mapCoordStore.updateSquare(config);
      } else {
        localStorage.setItem(STORAGE_KEY_CIRCLE, JSON.stringify(config));
        mapCoordStore.updateCircle(config);
      }
    } catch (_) {}

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
    circleLeft = backupCircleConfig.left;
    circleBottom = backupCircleConfig.bottom;
    circleWidth = backupCircleConfig.width;
    circleHeight = backupCircleConfig.height;
    circleBorderWidth = backupCircleConfig.borderWidth;
    circleBorderRadius = backupCircleConfig.borderRadius;

    squareLeft = backupSquareConfig.left;
    squareBottom = backupSquareConfig.bottom;
    squareWidth = backupSquareConfig.width;
    squareHeight = backupSquareConfig.height;
    squareBorderWidth = backupSquareConfig.borderWidth;
    squareBorderRadius = backupSquareConfig.borderRadius;

    isCalibrating = false;
    await fetchNui('closeMapCalibration', {});
  };

  const resetToDefault = () => {
    if (calibratingShape === 'square') {
      squareLeft = DEFAULT_SQUARE_CONFIG.left;
      squareBottom = DEFAULT_SQUARE_CONFIG.bottom;
      squareWidth = DEFAULT_SQUARE_CONFIG.width;
      squareHeight = DEFAULT_SQUARE_CONFIG.height;
      squareBorderWidth = DEFAULT_SQUARE_CONFIG.borderWidth;
      squareBorderRadius = DEFAULT_SQUARE_CONFIG.borderRadius;
    } else {
      circleLeft = DEFAULT_CIRCLE_CONFIG.left;
      circleBottom = DEFAULT_CIRCLE_CONFIG.bottom;
      circleWidth = DEFAULT_CIRCLE_CONFIG.width;
      circleHeight = DEFAULT_CIRCLE_CONFIG.height;
      circleBorderWidth = DEFAULT_CIRCLE_CONFIG.borderWidth;
      circleBorderRadius = DEFAULT_CIRCLE_CONFIG.borderRadius;
    }
  };

  const adjust = (
    param: 'left' | 'bottom' | 'width' | 'height' | 'bothSize' | 'border' | 'radius',
    delta: number
  ) => {
    const isSq = calibratingShape === 'square';
    if (param === 'left') {
      if (isSq) squareLeft = Math.max(0, Number((squareLeft + delta).toFixed(2)));
      else circleLeft = Math.max(0, Number((circleLeft + delta).toFixed(2)));
    } else if (param === 'bottom') {
      if (isSq) squareBottom = Math.max(0, Number((squareBottom + delta).toFixed(2)));
      else circleBottom = Math.max(0, Number((circleBottom + delta).toFixed(2)));
    } else if (param === 'width') {
      if (isSq) {
        squareWidth = Math.max(5, Number((squareWidth + delta).toFixed(2)));
        if (lockAspect) squareHeight = Math.max(5, Number((squareHeight + delta * (squareHeight / squareWidth)).toFixed(2)));
      } else {
        circleWidth = Math.max(5, Number((circleWidth + delta).toFixed(2)));
        if (lockAspect) circleHeight = Math.max(5, Number((circleHeight + delta * (circleHeight / circleWidth)).toFixed(2)));
      }
    } else if (param === 'height') {
      if (isSq) {
        squareHeight = Math.max(5, Number((squareHeight + delta).toFixed(2)));
        if (lockAspect) squareWidth = Math.max(5, Number((squareWidth + delta * (squareWidth / squareHeight)).toFixed(2)));
      } else {
        circleHeight = Math.max(5, Number((circleHeight + delta).toFixed(2)));
        if (lockAspect) circleWidth = Math.max(5, Number((circleWidth + delta * (circleWidth / circleHeight)).toFixed(2)));
      }
    } else if (param === 'bothSize') {
      if (isSq) {
        squareWidth = Math.max(5, Number((squareWidth + delta).toFixed(2)));
        squareHeight = Math.max(5, Number((squareHeight + delta).toFixed(2)));
      } else {
        circleWidth = Math.max(5, Number((circleWidth + delta).toFixed(2)));
        circleHeight = Math.max(5, Number((circleHeight + delta).toFixed(2)));
      }
    } else if (param === 'border') {
      if (isSq) squareBorderWidth = Math.max(1, Math.min(10, Number((squareBorderWidth + delta).toFixed(1))));
      else circleBorderWidth = Math.max(1, Math.min(10, Number((circleBorderWidth + delta).toFixed(1))));
    } else if (param === 'radius') {
      if (isSq) squareBorderRadius = Math.max(0, Math.min(30, Number((squareBorderRadius + delta).toFixed(1))));
      else circleBorderRadius = Math.max(0, Math.min(50, Number((circleBorderRadius + delta).toFixed(1))));
    }

    if (isSq) {
      mapCoordStore.updateSquare({
        left: squareLeft,
        bottom: squareBottom,
        width: squareWidth,
        height: squareHeight,
        borderWidth: squareBorderWidth,
        borderRadius: squareBorderRadius,
      });
    }
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (!isCalibrating) return;

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

      case '{':
        e.preventDefault();
        e.stopPropagation();
        adjust('radius', -1);
        break;
      case '}':
        e.preventDefault();
        e.stopPropagation();
        adjust('radius', 1);
        break;

      case 'Tab':
        e.preventDefault();
        e.stopPropagation();
        calibratingShape = calibratingShape === 'circle' ? 'square' : 'circle';
        break;

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
      backupCircleConfig = {
        left: circleLeft,
        bottom: circleBottom,
        width: circleWidth,
        height: circleHeight,
        borderWidth: circleBorderWidth,
        borderRadius: circleBorderRadius,
      };
      backupSquareConfig = {
        left: squareLeft,
        bottom: squareBottom,
        width: squareWidth,
        height: squareHeight,
        borderWidth: squareBorderWidth,
        borderRadius: squareBorderRadius,
      };
      if (event.data?.shape === 'square' || event.data?.shape === 'circle') {
        calibratingShape = event.data.shape;
      } else {
        calibratingShape = $VehicleHudStore.showSquareBorder ? 'square' : 'circle';
      }
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
  <!-- 1. CIRCLE / OVAL MINIMAP BEZEL -->
  {#if (!isCalibrating && ($VehicleHudStore.showCircleBorder || (DebugStore && !$VehicleHudStore.showSquareBorder))) || (isCalibrating && calibratingShape === 'circle')}
    <div
      class="circle {$presetStore.activePreset.config.mapBorderStyle === 'minimal' ? 'minimal-style' : ''} {isCalibrating && calibratingShape === 'circle' ? 'calibrating' : ''}"
      in:fly={{ y: 24, duration: 380 }}
      out:fly={{ y: 24, duration: 300 }}
      style="
        left: calc(max(0px, (100vw - 177.78vh) / 2) + {circleLeft}vh);
        bottom: {circleBottom}vh;
        width: {circleWidth}vh;
        height: {circleHeight}vh;
        border-width: {circleBorderWidth}px;
        border-radius: {circleBorderRadius}%;
      "
    >
      {#if isCalibrating && calibratingShape === 'circle'}
        <div class="crosshair-center" />
        <div class="axis-guide-x" />
        <div class="axis-guide-y" />
      {:else}
        <!-- Floating Minimalist Street & Telemetry Display (HUD Glass - SEM BAIRRO) -->
        <div class="floating-street-hud">
          <!-- Line 1: Street (Apenas rua atual do player) -->
          <div class="hud-street-line">
            <span class="street-primary">{$CompassHudStore.street1 || 'DISTRITO PAULISTA'}</span>
          </div>

          <!-- Line 2: Compass Heading Telemetry (Apenas rumo, sem bairro) -->
          <div class="hud-telemetry-line">
            <span class="compass-bearing">{headingFormatted}</span>
            <span class="compass-cardinal">{cardinalName}</span>
          </div>
        </div>

        {#if $presetStore.activePreset.config.mapBorderStyle !== 'minimal'}
          <!-- Laser-etched Metric Graduation Ticks around the Rim (Every 45°) -->
          {#each [0, 45, 90, 135, 180, 225, 270, 315] as deg}
            {@const tick = getCircleCoord(deg)}
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
            style="left: {northPosCircle.left}%; top: {northPosCircle.top}%; transform: translate(-50%, -50%) rotate({Math.round(currentAngle)}deg);"
            title="Norte Verdadeiro ({headingFormatted})"
          >
            <div class="needle-arrow" />
            <span class="needle-label">N</span>
          </div>
        {/if}
      {/if}
    </div>
  {/if}

  <!-- 2. SQUARE / RECTANGULAR MINIMAP BEZEL -->
  {#if (!isCalibrating && $VehicleHudStore.showSquareBorder) || (isCalibrating && calibratingShape === 'square')}
    <div
      class="square {$presetStore.activePreset.config.mapBorderStyle === 'minimal' ? 'minimal-style' : ''} {isCalibrating && calibratingShape === 'square' ? 'calibrating' : ''}"
      in:fly={{ y: 24, duration: 380 }}
      out:fly={{ y: 24, duration: 300 }}
      style="
        --square-border-w: {$presetStore.activePreset.config.mapBorderStyle === 'minimal' ? 4 : squareBorderWidth}px;
        left: calc(max(0px, (100vw - 177.78vh) / 2) + {squareLeft}vh);
        bottom: {squareBottom}vh;
        width: {squareWidth}vh;
        height: {squareHeight}vh;
        border-width: {$presetStore.activePreset.config.mapBorderStyle === 'minimal' ? 4 : squareBorderWidth}px;
        border-radius: {$presetStore.activePreset.config.mapBorderStyle === 'minimal' ? '0 0 12px 12px' : `${squareBorderRadius}px`};
      "
    >
      {#if isCalibrating && calibratingShape === 'square'}
        <div class="crosshair-center" />
        <div class="axis-guide-x" />
        <div class="axis-guide-y" />
      {:else}
        {#if $presetStore.activePreset.config.mapBorderStyle === 'minimal'}
          <!-- INTEGRATED 2-STORY MACHINED HEADER CROWN (1 ELEMENTO SÓ COM A MOLDURA) -->
          <div class="integrated-header-dock">
            <!-- Story 1: Telemetria & Rua Principal (APENAS NOME DA RUA ATUAL DO PLAYER) -->
            <div class="dock-story-telemetry">
              <div class="dock-street-box">
                <span class="dock-street-primary">{$CompassHudStore.street1 || 'DISTRITO PAULISTA'}</span>
              </div>
              <div class="dock-meta-box">
                <span class="dock-compass-bearing">{headingFormatted}</span>
                <span class="dock-compass-cardinal">{cardinalName}</span>
              </div>
            </div>

            <div class="dock-story-divider" />

            <!-- Story 2: Barras Esportivas Hi-Tech Racing -->
            <div class="dock-story-status">
              {#each statusList as item (item.id)}
                {#if item.visible}
                  <div class="status-track-unit {item.val <= 20 && (item.id === 'health' || item.id === 'hunger' || item.id === 'thirst') ? 'track-alert' : ''}">
                    <!-- Micro-Ícone SVG -->
                    <div class="track-icon" style="color: {item.color};">
                      {#if item.icon === 'heart'}
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>
                      {:else if item.icon === 'shield'}
                        <svg width="9" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 1L3 5v6c0 5.55 3.84 10.74 9 12 5.16-1.26 9-6.45 9-12V5l-9-4z"/></svg>
                      {:else if item.icon === 'utensils'}
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M11 9H9V2H7v7H5V2H3v7c0 2.12 1.66 3.84 3.75 3.97V22h2.5v-9.03C11.34 12.84 13 11.12 13 9V2h-2v7zm5-3v8h2.5v8H21V2c-2.76 0-5 2.24-5 4z"/></svg>
                      {:else if item.icon === 'droplet'}
                        <svg width="9" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2.69l5.66 5.66a8 8 0 1 1-11.31 0z"/></svg>
                      {:else if item.icon === 'bolt'}
                        <svg width="9" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M11 21h-1l1-7H7.5c-.88 0-.33-.75-.31-.78C8.48 10.94 10.42 7.54 13 3h1l-1 7h3.5c.49 0 .56.33.47.51l-6 10.49z"/></svg>
                      {:else if item.icon === 'lungs'}
                        <svg width="9" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M14 6V4h-4v2h4zM8 4c-1.1 0-2 .9-2 2v3c0 2.21 1.79 4 4 4h1v7h2v-7h1c2.21 0 4-1.79 4-4V6c0-1.1-.9-2-2-2H8z"/></svg>
                      {:else if item.icon === 'brain'}
                        <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3c-4.97 0-9 4.03-9 9 0 2.12.74 4.07 1.97 5.61L4.35 19H12v2h2v-2h2.65l-.62-1.39C19.26 16.07 20 14.12 20 12c0-4.97-4.03-9-9-9zm-1 5h2v2h-2V8zm-3 2h2v2H8v-2zm8 0h-2v2h2v-2zm-5 4h2v2h-2v-2z"/></svg>
                      {/if}
                    </div>

                    <!-- Canaleta Esportiva 3.5px com Barra de Preenchimento -->
                    <div class="status-gauge-channel">
                      <div
                        class="status-gauge-bar"
                        style="width: {item.val}%; background-color: {item.color};"
                      />
                    </div>
                  </div>
                {/if}
              {/each}
            </div>
          </div>
        {:else}
          <!-- Floating Vanguard Street & Telemetry Display (DP Original - APENAS RUA E RUMO, SEM BAIRRO) -->
          <div class="floating-street-hud">
            <!-- Line 1: Street (Apenas rua atual) -->
            <div class="hud-street-line">
              <span class="street-primary">{$CompassHudStore.street1 || 'DISTRITO PAULISTA'}</span>
            </div>

            <!-- Line 2: Compass Heading Telemetry (Apenas rumo, sem bairro) -->
            <div class="hud-telemetry-line">
              <span class="compass-bearing">{headingFormatted}</span>
              <span class="compass-cardinal">{cardinalName}</span>
            </div>
          </div>
        {/if}

        {#if $presetStore.activePreset.config.mapBorderStyle !== 'minimal'}
          <!-- Laser-etched Metric Graduation Ticks around the Square Rim -->
          {#each [0, 45, 90, 135, 180, 225, 270, 315] as deg}
            {@const tick = getSquareCoord(deg)}
            <div
              class="bezel-tick {deg % 90 === 0 ? 'major' : 'minor'}"
              style="left: {tick.left}%; top: {tick.top}%;"
            />
          {/each}

          <!-- Fixed Vehicle Forward Notch at 12 o'clock -->
          <div class="forward-notch" title="Frente do Veículo">▲</div>

          <!-- Machined Precision North Needle orbiting along the Square Rim -->
          <div
            class="north-needle"
            style="left: {northPosSquare.left}%; top: {northPosSquare.top}%; transform: translate(-50%, -50%) rotate({Math.round(currentAngle)}deg);"
            title="Norte Verdadeiro ({headingFormatted})"
          >
            <div class="needle-arrow" />
            <span class="needle-label">N</span>
          </div>
        {/if}
      {/if}
    </div>
  {/if}
{/if}

{#if isCalibrating}
  <div class="calibration-overlay">
    <div class="calibration-card">
      <!-- Header -->
      <div class="header">
        <div class="header-top">
          <span class="badge">
            {calibratingShape === 'square' ? 'CALIBRAÇÃO: MOLDURA RETANGULAR (SQUARE)' : 'CALIBRAÇÃO: MOLDURA OVAL (CIRCLE)'}
          </span>
        </div>
        <h2>Calibração da Moldura do Minimapa</h2>
        <p>Ajuste os parâmetros até a moldura contornar perfeitamente o radar na tela.</p>
      </div>

      <!-- Mode Selector (Circle vs Square) -->
      <div class="shape-tab-bar">
        <button
          type="button"
          class="shape-tab {calibratingShape === 'circle' ? 'selected' : ''}"
          on:click={() => (calibratingShape = 'circle')}
        >
          <span class="tab-icon">⭕</span>
          <span>Moldura Círculo / Oval</span>
        </button>
        <button
          type="button"
          class="shape-tab {calibratingShape === 'square' ? 'selected' : ''}"
          on:click={() => (calibratingShape = 'square')}
        >
          <span class="tab-icon">⬛</span>
          <span>Moldura Quadrada (Square)</span>
        </button>
      </div>

      <!-- Precision Step Selector -->
      <div class="step-selector">
        <span class="step-title">Sensibilidade do Passo:</span>
        <div class="step-options">
          {#each [0.01, 0.05, 0.1, 0.5] as st}
            <button
              type="button"
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
            <button type="button" class="adj-btn" on:click={() => adjust('left', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              value={calibratingShape === 'square' ? squareLeft : circleLeft}
              on:input={(e) => {
                const v = parseFloat(e.currentTarget.value) || 0;
                if (calibratingShape === 'square') squareLeft = v; else circleLeft = v;
              }}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button type="button" class="adj-btn" on:click={() => adjust('left', activeStep)}>+</button>
          </div>
        </div>

        <!-- Posição Y (Bottom) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Posição Y (Inferior)</span>
            <span class="key-hint">Setas ↑ ↓</span>
          </div>
          <div class="input-row">
            <button type="button" class="adj-btn" on:click={() => adjust('bottom', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              value={calibratingShape === 'square' ? squareBottom : circleBottom}
              on:input={(e) => {
                const v = parseFloat(e.currentTarget.value) || 0;
                if (calibratingShape === 'square') squareBottom = v; else circleBottom = v;
              }}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button type="button" class="adj-btn" on:click={() => adjust('bottom', activeStep)}>+</button>
          </div>
        </div>

        <!-- Largura (Width) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Largura (X)</span>
            <span class="key-hint">Teclas A / D</span>
          </div>
          <div class="input-row">
            <button type="button" class="adj-btn" on:click={() => adjust('width', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              value={calibratingShape === 'square' ? squareWidth : circleWidth}
              on:input={(e) => {
                const v = parseFloat(e.currentTarget.value) || 5;
                if (calibratingShape === 'square') squareWidth = v; else circleWidth = v;
              }}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button type="button" class="adj-btn" on:click={() => adjust('width', activeStep)}>+</button>
          </div>
        </div>

        <!-- Altura (Height) -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Altura (Y)</span>
            <span class="key-hint">Teclas W / S</span>
          </div>
          <div class="input-row">
            <button type="button" class="adj-btn" on:click={() => adjust('height', -activeStep)}>−</button>
            <input
              type="number"
              step="0.01"
              value={calibratingShape === 'square' ? squareHeight : circleHeight}
              on:input={(e) => {
                const v = parseFloat(e.currentTarget.value) || 5;
                if (calibratingShape === 'square') squareHeight = v; else circleHeight = v;
              }}
              class="param-input"
            />
            <span class="unit-tag">vh</span>
            <button type="button" class="adj-btn" on:click={() => adjust('height', activeStep)}>+</button>
          </div>
        </div>

        <!-- Espessura da Borda -->
        <div class="control-box">
          <div class="box-top">
            <span class="param-name">Espessura Borda</span>
            <span class="key-hint">Teclas [ ]</span>
          </div>
          <div class="input-row">
            <button type="button" class="adj-btn" on:click={() => adjust('border', -0.5)}>−</button>
            <input
              type="number"
              step="0.1"
              min="1"
              max="10"
              value={calibratingShape === 'square' ? squareBorderWidth : circleBorderWidth}
              on:input={(e) => {
                const v = parseFloat(e.currentTarget.value) || 1;
                if (calibratingShape === 'square') squareBorderWidth = v; else circleBorderWidth = v;
              }}
              class="param-input"
            />
            <span class="unit-tag">px</span>
            <button type="button" class="adj-btn" on:click={() => adjust('border', 0.5)}>+</button>
          </div>
        </div>

        {#if calibratingShape === 'square'}
          <!-- Cantos Arredondados (Square) -->
          <div class="control-box">
            <div class="box-top">
              <span class="param-name">Arredondamento</span>
              <span class="key-hint">Teclas &#123; &#125;</span>
            </div>
            <div class="input-row">
              <button type="button" class="adj-btn" on:click={() => adjust('radius', -1)}>−</button>
              <input
                type="number"
                step="1"
                min="0"
                max="30"
                bind:value={squareBorderRadius}
                class="param-input"
              />
              <span class="unit-tag">px</span>
              <button type="button" class="adj-btn" on:click={() => adjust('radius', 1)}>+</button>
            </div>
          </div>
        {:else}
          <!-- Escala Geral Proporcional (Circle) -->
          <div class="control-box">
            <div class="box-top">
              <span class="param-name">Escala Proporcional</span>
              <span class="key-hint">PgUp / PgDn</span>
            </div>
            <div class="input-row">
              <button type="button" class="adj-btn" on:click={() => adjust('bothSize', -activeStep)}>−</button>
              <div class="scale-info">
                {((circleWidth / circleHeight) || 1).toFixed(2)}x Proporção
              </div>
              <button type="button" class="adj-btn" on:click={() => adjust('bothSize', activeStep)}>+</button>
            </div>
          </div>
        {/if}
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
        <button type="button" class="btn btn-reset" on:click={resetToDefault}>
          Restaurar Padrão
        </button>
        <button type="button" class="btn btn-cancel" on:click={cancelCalibration}>
          Cancelar (ESC)
        </button>
        <button type="button" class="btn btn-save" on:click={saveCalibration}>
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
    border-color: #0b0e14;
    box-shadow: 
      0 0 0 1.5px rgba(245, 185, 69, 0.85),
      0 0 16px rgba(229, 169, 60, 0.30),
      inset 0 0 0 1px rgba(229, 169, 60, 0.28),
      inset 0 0 10px 2px rgba(11, 14, 20, 0.85),
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
    box-sizing: border-box;
    pointer-events: none;
    user-select: none;
    background: transparent !important;
    border-style: solid;
    border-color: #0b0e14;
    box-shadow: 
      0 0 0 1.5px rgba(245, 185, 69, 0.85),
      0 0 16px rgba(229, 169, 60, 0.30),
      inset 0 0 0 1px rgba(229, 169, 60, 0.28),
      inset 0 0 10px 2px rgba(11, 14, 20, 0.85),
      0 6px 24px rgba(0, 0, 0, 0.85);
    z-index: 25;
    transition: none;
  }

  .square.calibrating {
    border-style: dashed !important;
    border-color: #00ff88 !important;
    box-shadow: 0 0 16px rgba(0, 255, 136, 0.65) !important;
    z-index: 9999;
  }

  /* Minimalist Glass Bezel Style */
  .circle.minimal-style {
    border-color: rgba(255, 255, 255, 0.09) !important;
    box-shadow: 
      0 8px 24px rgba(0, 0, 0, 0.60),
      0 0 0 1px rgba(0, 0, 0, 0.40) !important;
  }

  .square.minimal-style {
    border-color: rgba(11, 14, 20, 0.85) !important;
    border-top-left-radius: 0 !important;
    border-top-right-radius: 0 !important;
    border-bottom-left-radius: 12px !important;
    border-bottom-right-radius: 12px !important;
    box-shadow: 
      0 0 0 1px rgba(255, 255, 255, 0.09),
      inset 0 0 0 1px rgba(255, 255, 255, 0.09),
      0 8px 24px rgba(0, 0, 0, 0.60),
      0 0 0 1px rgba(0, 0, 0, 0.40) !important;
  }

  /* ========================================================
     INTEGRATED 2-STORY MACHINED HEADER CROWN (MINIMALISTA GLASS)
     1 ELEMENTO SÓ: Integrado diretamente na borda superior da moldura
     STRICTLY ZERO backdrop-filter to prevent CEF black box
     ======================================================== */
  .integrated-header-dock {
    position: absolute;
    /* Aligns bottom edge flush with outer top border:
       100% is top of padding box; + square-border-w brings it to outer top border line */
    bottom: calc(100% + var(--square-border-w, 4px));
    left: calc(var(--square-border-w, 4px) * -1);
    right: calc(var(--square-border-w, 4px) * -1);
    background: rgba(11, 14, 20, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 12px 12px 0 0;
    box-shadow: 
      0 -8px 24px rgba(0, 0, 0, 0.60),
      0 -1px 0 rgba(0, 0, 0, 0.40);
    padding: 8px 12px 9px 12px;
    display: flex;
    flex-direction: column;
    gap: 7px;
    box-sizing: border-box;
    z-index: 35;
    pointer-events: none;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
  }

  /* Story 1: Telemetry & Street row */
  .dock-story-telemetry {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
    gap: 8px;
  }

  .dock-street-box {
    display: flex;
    align-items: baseline;
    gap: 4px;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
    min-width: 0;
  }

  .dock-street-primary {
    font-size: 11px;
    font-weight: 800;
    color: #ffffff;
    letter-spacing: 0.02em;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.9);
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }

  .dock-meta-box {
    display: flex;
    align-items: center;
    gap: 5px;
    flex-shrink: 0;
  }

  .dock-compass-bearing {
    font-size: 10px;
    font-weight: 800;
    color: #ffffff;
    font-variant-numeric: tabular-nums;
  }

  .dock-compass-cardinal {
    font-size: 10px;
    font-weight: 900;
    color: #10b981;
  }

  .dock-story-divider {
    width: 100%;
    height: 1px;
    background: rgba(255, 255, 255, 0.08);
  }

  /* Story 2: Hi-Tech Racing Status Bars */
  .dock-story-status {
    display: flex;
    align-items: center;
    gap: 6px;
    width: 100%;
  }

  .status-track-unit {
    flex: 1 1 0;
    display: flex;
    align-items: center;
    gap: 4px;
    min-width: 0;
  }

  .track-icon {
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    opacity: 0.92;
  }

  .status-gauge-channel {
    flex: 1 1 0;
    height: 3px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 9999px;
    overflow: hidden;
    position: relative;
    box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.6);
  }

  .status-gauge-bar {
    height: 100%;
    border-radius: 9999px;
    transition: width 0.25s ease-out, background-color 0.2s ease;
  }

  .track-alert .status-gauge-bar {
    animation: barAlertPulse 1.2s infinite;
  }

  @keyframes barAlertPulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.40; }
  }

  /* Floating Minimalist Street & Telemetry Display (HUD Glass) */
  .floating-street-hud {
    position: absolute;
    bottom: calc(100% + 0.8vh);
    left: 50%;
    transform: translateX(-50%);
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 0.2vh 1vh;
    background: transparent !important;
    white-space: nowrap;
    pointer-events: none;
    user-select: none;
    z-index: 35;
    max-width: 100%;
    text-align: center;
    font-family: 'Montserrat', sans-serif;
  }

  /* Seamless Optical Ambient Fog (Zero Detectable Panel Boundaries) */
  .floating-street-hud::before {
    content: '';
    position: absolute;
    inset: -2.0vh -5.5vh;
    background: radial-gradient(
      ellipse 60% 50% at 50% 50%,
      rgba(11, 14, 20, 0.68) 0%,
      rgba(11, 14, 20, 0.42) 22%,
      rgba(11, 14, 20, 0.18) 45%,
      rgba(11, 14, 20, 0.05) 65%,
      rgba(11, 14, 20, 0) 80%
    );
    pointer-events: none;
    z-index: -1;
  }

  .hud-street-line {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.45vh;
    line-height: 1.15;
    overflow: hidden;
    text-overflow: ellipsis;
  }

  .street-primary {
    font-size: 1.25vh;
    font-weight: 800;
    color: #ffffff;
    letter-spacing: 0.05em;
    text-transform: uppercase;
    text-shadow: 0 1px 2px #000000, 0 2px 8px rgba(0, 0, 0, 0.95);
  }

  .hud-telemetry-line {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.45vh;
    margin-top: 0.2vh;
    line-height: 1;
  }

  .compass-bearing {
    font-variant-numeric: tabular-nums;
    font-size: 1.05vh;
    font-weight: 800;
    color: #f5b945;
    letter-spacing: 0.03em;
    text-shadow: 0 1px 2px #000000, 0 2px 6px rgba(229, 169, 60, 0.4);
  }

  .compass-cardinal {
    font-size: 1.05vh;
    font-weight: 900;
    color: #e5a93c;
    letter-spacing: 0.04em;
    text-shadow: 0 1px 2px #000000, 0 2px 6px rgba(229, 169, 60, 0.5);
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
    background: #e5a93c;
    box-shadow: 0 0 6px rgba(229, 169, 60, 0.50);
  }

  .bezel-tick.minor {
    width: 3px;
    height: 3px;
    background: rgba(229, 169, 60, 0.35);
  }

  /* Fixed Vehicle Forward Notch */
  .forward-notch {
    position: absolute;
    top: -5px;
    left: 50%;
    transform: translateX(-50%);
    color: #f5b945;
    font-size: 8px;
    line-height: 1;
    text-shadow: 0 0 6px rgba(229, 169, 60, 0.6);
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
    border-bottom: 7px solid #f5b945;
    filter: drop-shadow(0 0 4px rgba(229, 169, 60, 0.6));
  }

  .needle-label {
    font-family: 'Montserrat', sans-serif;
    font-size: 8px;
    font-weight: 900;
    color: #e5a93c;
    line-height: 1;
    margin-top: 1px;
    text-shadow: 0 0 4px rgba(229, 169, 60, 0.8), 0 1px 2px rgba(0, 0, 0, 0.9);
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

  /* Shape Switcher Tab Bar */
  .shape-tab-bar {
    display: flex;
    gap: 0.6rem;
    background: rgba(255, 255, 255, 0.04);
    padding: 0.35rem;
    border-radius: 10px;
    border: 1px solid rgba(255, 255, 255, 0.08);
  }

  .shape-tab {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.5rem;
    background: rgba(255, 255, 255, 0.03);
    border: 1px solid rgba(255, 255, 255, 0.08);
    color: rgba(255, 255, 255, 0.7);
    font-family: inherit;
    font-size: 0.78rem;
    font-weight: 700;
    padding: 0.45rem 0.8rem;
    border-radius: 8px;
    cursor: pointer;
    transition: all 0.15s ease;
  }

  .shape-tab:hover {
    background: rgba(0, 255, 136, 0.1);
    color: #00ff88;
  }

  .shape-tab.selected {
    background: rgba(0, 255, 136, 0.2);
    border-color: #00ff88;
    color: #00ff88;
    font-weight: 800;
    box-shadow: 0 0 10px rgba(0, 255, 136, 0.25);
  }

  .tab-icon {
    font-size: 0.9rem;
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