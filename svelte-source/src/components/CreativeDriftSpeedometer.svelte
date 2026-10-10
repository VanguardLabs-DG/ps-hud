<script lang="ts">
  import VehicleHudStore from '../stores/vehicleHudStore';
  import DebugStore from '../stores/debugStore';
  import PlayerHudStore from '../stores/playerStatusHudStore';

  // Visibility
  $: isVisible = ($VehicleHudStore.show || DebugStore) && !($PlayerHudStore.cinematic);

  // Telemetry data
  $: speed = $VehicleHudStore.speed || 0;
  $: rawRpm = $VehicleHudStore.rpm || 0;
  $: rpm = rawRpm > 0.2 ? Math.min(1, Math.max(0, (rawRpm - 0.2) / 0.8)) : 0;
  $: gear = $VehicleHudStore.gear !== undefined ? $VehicleHudStore.gear : "N";
  $: fuel = typeof $VehicleHudStore.fuel === 'number' ? $VehicleHudStore.fuel : 100;
  $: engine = typeof $VehicleHudStore.engine === 'number' ? $VehicleHudStore.engine : 1000;
  $: seatbelt = $VehicleHudStore.seatbelt === true;
  $: locked = $VehicleHudStore.locked === true;
  $: headlight = $VehicleHudStore.headlight === true || $VehicleHudStore.headlight === "highbeam" || $VehicleHudStore.headlight === "#fff700";
  $: unit = "Km/h";
  $: displaySpeed = Math.floor(speed);

  $: gearText = (gear === 0 || gear === "0") ? "N" : (gear === -1 || gear === "R") ? "R" : String(gear);

  // Geometry
  const cx = 145;
  const cy = 125;
  const rMain = 76;
  const rOuter = 94;

  function polarToCartesian(X: number, Y: number, R: number, deg: number) {
    const rad = ((deg - 90) * Math.PI) / 180;
    return {
      x: X + R * Math.cos(rad),
      y: Y + R * Math.sin(rad)
    };
  }

  function describeArc(X: number, Y: number, R: number, sDeg: number, eDeg: number) {
    const st = polarToCartesian(X, Y, R, eDeg);
    const en = polarToCartesian(X, Y, R, sDeg);
    const lg = eDeg - sDeg <= 180 ? "0" : "1";
    return ["M", st.x, st.y, "A", R, R, 0, lg, 0, en.x, en.y].join(" ");
  }

  function describePie(X: number, Y: number, R: number, sDeg: number, eDeg: number) {
    const p1 = polarToCartesian(X, Y, R, sDeg);
    const p2 = polarToCartesian(X, Y, R, eDeg);
    const lg = eDeg - sDeg <= 180 ? "0" : "1";
    return ["M", X, Y, "L", p1.x, p1.y, "A", R, R, 0, lg, 1, p2.x, p2.y, "Z"].join(" ");
  }

  const startAngle = -135;
  const totalSpan = 270;
  $: currentRpm = Math.min(1, Math.max(0, rpm));
  $: needleAngle = startAngle + totalSpan * currentRpm;

  $: enginePercent = Math.min(1, Math.max(0, engine / 1000));
  $: engineCurEnd = -135 + enginePercent * 85;

  $: fuelPercent = Math.min(1, Math.max(0, fuel / 100));
  $: fuelCurEnd = 135 - fuelPercent * 85;

  const capStart = polarToCartesian(cx, cy, rMain, -135);
  const capEnd = polarToCartesian(cx, cy, rMain, 135);
</script>

{#if isVisible}
  <div class="drift-speedometer-wrapper">
    <!-- Top-Right Badges: Seatbelt [G], Locked [L], Headlight [H] -->
    <div class="top-badges">
      <div class="badge-item">
        <svg class="badge-icon" class:active-seatbelt={seatbelt} viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 2a4 4 0 1 0 0 8 4 4 0 0 0 0-8zm-4 10c-2.21 0-4 1.79-4 4v3a1 1 0 0 0 1 1h14a1 1 0 0 0 1-1v-3c0-2.21-1.79-4-4-4H8zm0 2h8c1.1 0 2 .9 2 2v2H6v-2c0-1.1.9-2 2-2zm-1.8 4 9.6-4.8.8 1.6-9.6 4.8-.8-1.6z"/>
        </svg>
        <span class="badge-text" class:active-seatbelt-text={seatbelt}>G</span>
      </div>

      <div class="badge-item">
        <svg class="badge-icon" class:active-lock={locked} viewBox="0 0 24 24" fill="currentColor">
          <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
        </svg>
        <span class="badge-text" class:active-lock-text={locked}>L</span>
      </div>

      <div class="badge-item">
        <svg class="badge-icon" class:active-light={headlight} viewBox="0 0 24 24" fill="currentColor">
          <path d="M12 4a8 8 0 0 0-8 8 8 8 0 0 0 8 8V4zm-9 3H1v2h2V7zm0 4H1v2h2v-2zm0 4H1v2h2v-2zm21-7h-8v2h8V8zm0 4h-8v2h8v-2zm0 4h-8v2h8v-2z"/>
        </svg>
        <span class="badge-text" class:active-light-text={headlight}>H</span>
      </div>
    </div>

    <!-- Main Gauge SVG -->
    <svg class="gauge-svg" viewBox="0 0 290 250" fill="none">
      <defs>
        <radialGradient id="gaugeDarkBase" cx={cx} cy={cy} r={rMain} gradientUnits="userSpaceOnUse">
          <stop offset="0%" stop-color="#080c14" stop-opacity="0.08" />
          <stop offset="60%" stop-color="#0c121e" stop-opacity="0.04" />
          <stop offset="100%" stop-color="#121e30" stop-opacity="0.0" />
        </radialGradient>

        <radialGradient id="innerWhiteGlow" cx={cx} cy={cy} r={rMain} gradientUnits="userSpaceOnUse">
          <stop offset="0%" stop-color="#ffffff" stop-opacity="0" />
          <stop offset="40%" stop-color="#ffffff" stop-opacity="0" />
          <stop offset="70%" stop-color="#cbd5e1" stop-opacity="0.08" />
          <stop offset="92%" stop-color="#ffffff" stop-opacity="0.22" />
          <stop offset="100%" stop-color="#ffffff" stop-opacity="0.35" />
        </radialGradient>

        <radialGradient id="innerOrangeGlow" cx={cx} cy={cy} r={rMain} gradientUnits="userSpaceOnUse">
          <stop offset="0%" stop-color="#ff9500" stop-opacity="0" />
          <stop offset="35%" stop-color="#ff9500" stop-opacity="0" />
          <stop offset="68%" stop-color="#ff9500" stop-opacity="0.14" />
          <stop offset="90%" stop-color="#ff9500" stop-opacity="0.38" />
          <stop offset="100%" stop-color="#ff9500" stop-opacity="0.50" />
        </radialGradient>

        <radialGradient id="innerRedGlow" cx={cx} cy={cy} r={rMain} gradientUnits="userSpaceOnUse">
          <stop offset="0%" stop-color="#ff2d55" stop-opacity="0" />
          <stop offset="35%" stop-color="#ff2d55" stop-opacity="0" />
          <stop offset="68%" stop-color="#ff2d55" stop-opacity="0.14" />
          <stop offset="90%" stop-color="#ff2d55" stop-opacity="0.38" />
          <stop offset="100%" stop-color="#ff2d55" stop-opacity="0.50" />
        </radialGradient>

        <filter id="needleFilter" x="-30%" y="-30%" width="160%" height="160%">
          <feDropShadow dx="0" dy="0" stdDeviation="2.5" flood-color="#ff1a40" flood-opacity="0.95" />
        </filter>

        <filter id="whiteGlowFilter" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="0" stdDeviation="1.5" flood-color="#ffffff" flood-opacity="0.4" />
        </filter>

        <filter id="orangeGlowFilter" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="0" stdDeviation="1.5" flood-color="#ff9500" flood-opacity="0.4" />
        </filter>

        <filter id="redGlowFilter" x="-20%" y="-20%" width="140%" height="140%">
          <feDropShadow dx="0" dy="0" stdDeviation="1.5" flood-color="#ff2d55" flood-opacity="0.4" />
        </filter>
      </defs>

      <!-- Gauge Base Circle -->
      <circle cx={cx} cy={cy} r={rMain - 2} fill="url(#gaugeDarkBase)" />

      <!-- Pie Glow Sections -->
      <path d={describePie(cx, cy, rMain - 2, -135, 51.75)} fill="url(#innerWhiteGlow)" />
      <path d={describePie(cx, cy, rMain - 2, 51.75, 93.25)} fill="url(#innerOrangeGlow)" />
      <path d={describePie(cx, cy, rMain - 2, 93.25, 135)} fill="url(#innerRedGlow)" />

      <!-- Outer Engine Arc Track & Active Fill -->
      <path d={describeArc(cx, cy, rOuter, -135, -50)} stroke="rgba(255,255,255,0.18)" stroke-width="5.5" stroke-linecap="round" />
      {#if enginePercent > 0.02}
        <path d={describeArc(cx, cy, rOuter, -135, engineCurEnd)} stroke="#ffffff" stroke-width="5.5" stroke-linecap="round" />
      {/if}

      <!-- Outer Fuel Arc Track & Active Fill -->
      <path d={describeArc(cx, cy, rOuter, 50, 135)} stroke="rgba(255,255,255,0.18)" stroke-width="5.5" stroke-linecap="round" />
      {#if fuelPercent > 0.02}
        <path d={describeArc(cx, cy, rOuter, fuelCurEnd, 135)} stroke="#FFBB00" stroke-width="5.5" stroke-linecap="round" />
      {/if}

      <!-- Main RPM Arc Track & Perimeter Segments -->
      <path d={describeArc(cx, cy, rMain, -135, 135)} stroke="rgba(255,255,255,0.10)" stroke-width="8" />

      <!-- White Segment -->
      <path d={describeArc(cx, cy, rMain, -135, 50)} stroke="#ffffff" stroke-width="8" stroke-linecap="butt" filter="url(#whiteGlowFilter)" />
      <circle cx={capStart.x} cy={capStart.y} r="4" fill="#ffffff" filter="url(#whiteGlowFilter)" />

      <!-- Orange Segment -->
      <path d={describeArc(cx, cy, rMain, 53.5, 91.5)} stroke="#ff9500" stroke-width="8" stroke-linecap="butt" filter="url(#orangeGlowFilter)" />

      <!-- Red Segment -->
      <path d={describeArc(cx, cy, rMain, 95, 135)} stroke="#ff2d55" stroke-width="8" stroke-linecap="butt" filter="url(#redGlowFilter)" />
      <circle cx={capEnd.x} cy={capEnd.y} r="4" fill="#ff2d55" filter="url(#redGlowFilter)" />

      <!-- Dynamic Rotating Needle -->
      <g style="transform: rotate({needleAngle}deg); transform-origin: {cx}px {cy}px; transition: transform 0.04s linear;">
        <line x1={cx} y1={cy - 19} x2={cx} y2={cy - rMain + 2} stroke="#ff1a40" stroke-width="4.5" stroke-linecap="round" filter="url(#needleFilter)" />
        <polygon points="{cx - 3},{cy - 19} {cx + 3},{cy - 19} {cx},{cy - rMain - 2}" fill="#ff1a40" filter="url(#needleFilter)" />
      </g>

      <!-- Center Gear Hub Circle -->
      <circle cx={cx} cy={cy} r="23" fill="rgba(11, 15, 22, 0.85)" stroke="rgba(255,255,255,0.18)" stroke-width="1.5" />
      <text x={cx} y={cy + 7} text-anchor="middle" font-family="'Montserrat', sans-serif" font-weight="800" font-size="21" fill="#ffffff">
        {gearText}
      </text>

      <!-- Bottom Engine Icon -->
      <g transform="translate(70, 200) scale(0.68)">
        <path fill="#ffffff" opacity="0.9" d="M19.14 12.94c.04-.3.06-.61.06-.94 0-.32-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94l-2.39-.96c-.22-.08-.47 0-.59.22L2.74 8.87c-.12.21-.08.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61l-2.01-1.58zM12 15.6c-1.98 0-3.6-1.62-3.6-3.6s1.62-3.6 3.6-3.6 3.6 1.62 3.6 3.6-1.62 3.6-3.6 3.6z"/>
      </g>

      <!-- Bottom Fuel Icon -->
      <g transform="translate(204, 200) scale(0.68)">
        <path fill="#FFBB00" opacity="0.95" d="M19.77 7.23l.01-.01-3.72-3.72L15 4.56l2.11 2.11c-.94.36-1.61 1.26-1.61 2.33 0 1.38 1.12 2.5 2.5 2.5.36 0 .69-.08 1-.21v7.21c0 .55-.45 1-1 1s-1-.45-1-1V14c0-1.1-.9-2-2-2h-1V5c0-1.1-.9-2-2-2H6c-1.1 0-2 .9-2 2v16h10v-7.5h1.5v5c0 1.38 1.12 2.5 2.5 2.5s2.5-1.12 2.5-2.5V9c0-.69-.28-1.32-.73-1.77zM12 10H6V5h6v5zm6 0c-.55 0-1-.45-1-1s.45-1 1-1 1 .45 1 1-.45 1-1 1z"/>
      </g>
    </svg>

    <!-- Speed Display -->
    <div class="speed-container">
      <span class="speed-number">{displaySpeed}</span>
      <span class="speed-unit">{unit}</span>
    </div>
  </div>
{/if}

<style>
  .drift-speedometer-wrapper {
    position: fixed;
    right: calc(1.5rem - 42px);
    bottom: 6.2rem;
    width: 290px;
    height: 250px;
    user-select: none;
    pointer-events: none;
    font-family: 'Montserrat', sans-serif;
    z-index: 45;
    transform-origin: bottom right;
    transition: opacity 0.3s ease, transform 0.3s ease;
  }

  @media (min-width: 2560px) {
    .drift-speedometer-wrapper {
      transform: scale(1.15);
    }
  }

  @media (min-width: 3840px) {
    .drift-speedometer-wrapper {
      transform: scale(1.4);
    }
  }

  @media (max-width: 1366px) {
    .drift-speedometer-wrapper {
      transform: scale(0.88);
    }
  }

  .top-badges {
    position: absolute;
    top: -62px;
    right: 42px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    z-index: 20;
  }

  .badge-item {
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 6px;
    background: rgba(10, 12, 16, 0.75);
    padding: 3px 7px;
    border-radius: 4px;
    border: 1px solid rgba(255, 255, 255, 0.06);
    width: 42px;
    box-sizing: border-box;
  }

  .badge-icon {
    width: 12px;
    height: 12px;
    color: rgba(255, 255, 255, 0.3);
    transition: color 0.2s ease;
  }

  .badge-icon.active-seatbelt {
    color: #22c55e;
  }

  .badge-icon.active-lock {
    color: #22c55e;
  }

  .badge-icon.active-light {
    color: #0099ff;
  }

  .badge-text {
    font-size: 10px;
    font-weight: 800;
    color: rgba(255, 255, 255, 0.7);
    line-height: 1;
    transition: color 0.2s ease;
  }

  .badge-text.active-seatbelt-text {
    color: #22c55e;
  }

  .badge-text.active-lock-text {
    color: #22c55e;
  }

  .badge-text.active-light-text {
    color: #0099ff;
  }

  .gauge-svg {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
  }

  .speed-container {
    position: absolute;
    bottom: 12px;
    left: 145px;
    transform: translateX(-50%);
    display: inline-flex;
    align-items: baseline;
    justify-content: center;
    white-space: nowrap;
  }

  .speed-number {
    font-size: 58px;
    font-weight: 900;
    font-style: italic;
    letter-spacing: -0.04em;
    color: #ffffff;
    line-height: 0.85;
    filter: drop-shadow(0 4px 10px rgba(0, 0, 0, 0.9));
  }

  .speed-unit {
    position: absolute;
    left: calc(100% + 4px);
    bottom: 4px;
    font-size: 14px;
    font-weight: 800;
    font-style: italic;
    color: rgba(255, 255, 255, 0.95);
    line-height: 1;
    filter: drop-shadow(0 2px 5px rgba(0, 0, 0, 0.9));
  }
</style>
