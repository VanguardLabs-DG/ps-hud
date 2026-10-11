<script lang="ts">
  import VehicleHudStore from '../../stores/vehicleHudStore';
  import DebugStore from '../../stores/debugStore';
  import PlayerHudStore from '../../stores/playerStatusHudStore';

  $: isVisible = ($VehicleHudStore.show || DebugStore) && !($PlayerHudStore.cinematic);

  $: speed = Math.floor($VehicleHudStore.speed || 0);
  $: rawRpm = $VehicleHudStore.rpm || 0;
  $: rpmPercent = Math.min(100, Math.max(0, Math.round(rawRpm * 100)));
  $: gear = $VehicleHudStore.gear !== undefined ? $VehicleHudStore.gear : "N";
  $: fuel = typeof $VehicleHudStore.fuel === 'number' ? Math.round($VehicleHudStore.fuel) : 100;
  $: seatbelt = $VehicleHudStore.seatbelt === true;
  $: locked = $VehicleHudStore.locked === true;
  $: headlight = $VehicleHudStore.headlight === true || $VehicleHudStore.headlight === "highbeam";

  $: gearText = (gear === 0 || gear === "0") ? "N" : (gear === -1 || gear === "R") ? "R" : String(gear);

  $: speedString = String(speed).padStart(3, '0');
</script>

{#if isVisible}
  <div class="minimal-speedo-container">
    <div class="glass-cluster">
      <!-- Top Row: RPM Progress Hairline -->
      <div class="rpm-track">
        <div
          class="rpm-bar"
          style="width: {rpmPercent}%; background: {rpmPercent > 85 ? '#ef4444' : rpmPercent > 65 ? '#f59e0b' : '#10b981'};"
        />
      </div>

      <!-- Main Row: Speed & Indicators -->
      <div class="main-cluster-row">
        <!-- Digital Speed Display -->
        <div class="speed-box">
          <div class="speed-digits">
            <span class="digit-dim">{speedString.slice(0, -String(speed).length || 0)}</span>
            <span class="digit-lit">{speed}</span>
          </div>
          <div class="speed-meta">
            <span class="speed-unit">KM/H</span>
            <span class="gear-tag">{gearText}</span>
          </div>
        </div>

        <div class="cluster-divider" />

        <!-- Fuel & Telemetry Column -->
        <div class="telemetry-box">
          <div class="fuel-row">
            <span class="fuel-label">COMBUSTÍVEL</span>
            <span class="fuel-num" style="color: {fuel <= 20 ? '#ef4444' : '#ffffff'};">{fuel}%</span>
          </div>
          <div class="fuel-track">
            <div
              class="fuel-fill"
              style="width: {fuel}%; background: {fuel <= 20 ? '#ef4444' : '#10b981'};"
            />
          </div>

          <!-- Badges / Indicators Row -->
          <div class="badges-row">
            <!-- Cinto -->
            <div class="badge-icon {seatbelt ? 'badge-active-green' : 'badge-alert-red'}" title={seatbelt ? 'Cinto Afivelado' : 'Cinto Solto'}>
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18.92 11c-.04-.3-.1-.6-.18-.89l-2.09.84c.05.21.08.43.11.65l2.16-.6zm-4.72-6.5c-1.34-1.54-3.32-2.5-5.54-2.5-3.86 0-7 3.14-7 7 0 2.22.96 4.2 2.5 5.54l1.41-1.41C4.38 12.06 3.6 10.62 3.6 9c0-2.98 2.42-5.4 5.4-5.4 1.62 0 3.06.78 4.13 1.97l1.07-1.07zM12 24c3.86 0 7-3.14 7-7 0-2.22-.96-4.2-2.5-5.54l-1.41 1.41c1.19 1.07 1.97 2.51 1.97 4.13 0 2.98-2.42 5.4-5.4 5.4-1.62 0-3.06-.78-4.13-1.97l-1.07 1.07C7.3 23.04 9.28 24 11.5 24H12z"/>
              </svg>
            </div>

            <!-- Farol -->
            <div class="badge-icon {headlight ? 'badge-active-blue' : 'badge-dim'}" title="Farol">
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
              </svg>
            </div>

            <!-- Trava -->
            <div class="badge-icon {locked ? 'badge-active-yellow' : 'badge-dim'}" title={locked ? 'Trancado' : 'Destrancado'}>
              <svg width="10" height="10" viewBox="0 0 24 24" fill="currentColor">
                <path d="M18 8h-1V6c0-2.76-2.24-5-5-5S7 3.24 7 6v2H6c-1.1 0-2 .9-2 2v10c0 1.1.9 2 2 2h12c1.1 0 2-.9 2-2V10c0-1.1-.9-2-2-2zm-6 9c-1.1 0-2-.9-2-2s.9-2 2-2 2 .9 2 2-.9 2-2 2zm3.1-9H8.9V6c0-1.71 1.39-3.1 3.1-3.1 1.71 0 3.1 1.39 3.1 3.1v2z"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  .minimal-speedo-container {
    position: fixed;
    right: 2.0rem;
    bottom: 2.0rem;
    z-index: 45;
    pointer-events: none;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
  }

  .glass-cluster {
    background: rgba(11, 14, 20, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 12px;
    padding: 8px 12px 10px 12px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.6), 0 0 0 1px rgba(0, 0, 0, 0.4);
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .rpm-track {
    width: 100%;
    height: 3px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 9999px;
    overflow: hidden;
  }

  .rpm-bar {
    height: 100%;
    transition: width 0.08s ease-out, background-color 0.2s ease;
  }

  .main-cluster-row {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .speed-box {
    display: flex;
    align-items: baseline;
    gap: 6px;
  }

  .speed-digits {
    font-size: 38px;
    font-weight: 900;
    font-style: italic;
    line-height: 0.9;
    letter-spacing: -0.04em;
    font-variant-numeric: tabular-nums;
  }

  .digit-dim {
    color: rgba(255, 255, 255, 0.20);
  }

  .digit-lit {
    color: #ffffff;
    text-shadow: 0 2px 10px rgba(255, 255, 255, 0.25);
  }

  .speed-meta {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .speed-unit {
    font-size: 10px;
    font-weight: 800;
    font-style: italic;
    color: rgba(255, 255, 255, 0.60);
  }

  .gear-tag {
    font-size: 13px;
    font-weight: 900;
    color: #10b981;
    line-height: 1;
  }

  .cluster-divider {
    width: 1px;
    height: 32px;
    background: rgba(255, 255, 255, 0.10);
  }

  .telemetry-box {
    display: flex;
    flex-direction: column;
    gap: 4px;
    min-width: 95px;
  }

  .fuel-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 9px;
    font-weight: 700;
    letter-spacing: 0.04em;
  }

  .fuel-label {
    color: rgba(255, 255, 255, 0.50);
  }

  .fuel-num {
    font-weight: 800;
    font-variant-numeric: tabular-nums;
  }

  .fuel-track {
    width: 100%;
    height: 4px;
    background: rgba(255, 255, 255, 0.08);
    border-radius: 9999px;
    overflow: hidden;
  }

  .fuel-fill {
    height: 100%;
    border-radius: 9999px;
    transition: width 0.3s ease;
  }

  .badges-row {
    display: flex;
    gap: 6px;
    margin-top: 3px;
  }

  .badge-icon {
    width: 18px;
    height: 18px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
  }

  .badge-dim {
    background: rgba(255, 255, 255, 0.05);
    color: rgba(255, 255, 255, 0.25);
  }

  .badge-active-green {
    background: rgba(16, 185, 129, 0.20);
    color: #10b981;
    box-shadow: 0 0 6px rgba(16, 185, 129, 0.35);
  }

  .badge-alert-red {
    background: rgba(239, 68, 68, 0.25);
    color: #ef4444;
    box-shadow: 0 0 8px rgba(239, 68, 68, 0.50);
  }

  .badge-active-blue {
    background: rgba(59, 130, 246, 0.20);
    color: #60a5fa;
  }

  .badge-active-yellow {
    background: rgba(245, 158, 11, 0.20);
    color: #f59e0b;
  }
</style>
