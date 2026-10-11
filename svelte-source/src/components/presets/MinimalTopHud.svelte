<script lang="ts">
  import PlayerHudStore from '../../stores/playerStatusHudStore';
  import DebugStore from '../../stores/debugStore';

  $: isDesign = $PlayerHudStore.designMode;
  $: isVisible = ($PlayerHudStore.show || DebugStore || isDesign) && !$PlayerHudStore.cinematic;

  // Authentic data bindings
  $: citizenid = isDesign ? "101" : ($PlayerHudStore.citizenid || "1");
  $: voiceMode = isDesign ? 2 : Math.max(1, Math.min(4, Number($PlayerHudStore.voiceMode || 2)));
  $: talking = isDesign ? false : ($PlayerHudStore.talking || false);
  $: radioTalking = isDesign ? false : ($PlayerHudStore.radioTalking || false);
  $: radioChannel = isDesign ? 1 : ($PlayerHudStore.radioChannel || 0);

  $: isRadioActive = typeof radioChannel === 'number' ? radioChannel > 0 : Boolean(radioChannel && radioChannel !== '0');

  $: voiceModeLabel = voiceMode === 1 ? 'SUSSURRO' : voiceMode === 3 ? 'GRITANDO' : voiceMode === 4 ? 'MEGAFONE' : 'NORMAL';
</script>

{#if isVisible}
  <div class="minimal-top-container">
    <div class="glass-cluster">
      <!-- 1. Passaporte ID Segment -->
      <div class="cluster-module">
        <div class="badge-icon badge-passport" title="Passaporte / ID">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/>
          </svg>
        </div>
        <div class="module-content">
          <span class="module-label">PASSAPORTE</span>
          <span class="module-value id-value">{citizenid}</span>
        </div>
      </div>

      <div class="cluster-divider" />

      <!-- 2. VoIP Segment -->
      <div class="cluster-module">
        <div class="badge-icon {talking ? 'badge-active-green' : 'badge-dim'}" title={talking ? 'Transmitindo Voz' : 'Microfone Ativo'}>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z"/>
            <path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"/>
          </svg>
        </div>
        <div class="module-content">
          <div class="module-header-row">
            <span class="module-label">VOZ</span>
            <span class="mode-tag">{voiceModeLabel}</span>
          </div>
          <!-- Hi-Tech Racing Vertical Equalizer Bars -->
          <div class="voip-equalizer">
            {#each [1, 2, 3] as step}
              <div
                class="eq-bar {voiceMode >= step ? (talking ? 'bar-talking' : 'bar-lit') : 'bar-dim'}"
                style="height: {step === 1 ? 5 : step === 2 ? 8 : 12}px;"
              />
            {/each}
          </div>
        </div>
      </div>

      <div class="cluster-divider" />

      <!-- 3. Rádio Segment -->
      <div class="cluster-module">
        <div class="badge-icon {radioTalking ? 'badge-active-green' : isRadioActive ? 'badge-active-blue' : 'badge-dim'}" title={radioTalking ? 'Transmitindo Rádio' : isRadioActive ? 'Canal Conectado' : 'Rádio Desligado'}>
          <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor">
            <path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 17.93c-3.95-.49-7-3.85-7-7.93 0-.62.08-1.21.21-1.79L9 15v1c0 1.1.9 2 2 2v1.93zm6.9-2.54c-.26-.81-1-1.39-1.9-1.39h-1v-3c0-.55-.45-1-1-1H8v-2h2c.55 0 1-.45 1-1V7h2c1.1 0 2-.9 2-2v-.41c2.93 1.19 5 4.06 5 7.41 0 2.08-.8 3.97-2.1 5.39z"/>
          </svg>
        </div>
        <div class="module-content">
          <span class="module-label">FREQUÊNCIA</span>
          <span class="module-value {radioTalking ? 'text-green' : isRadioActive ? 'text-blue' : 'text-dim'}">
            {#if isRadioActive}
              {typeof radioChannel === 'number' ? `${radioChannel} MHz` : radioChannel}
            {:else}
              OFF
            {/if}
          </span>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  .minimal-top-container {
    position: fixed;
    top: 20px;
    right: 24px;
    z-index: 50;
    pointer-events: none;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
    transform-origin: top right;
    transition: transform 0.25s ease;
  }

  @media (min-width: 2560px) {
    .minimal-top-container {
      transform: scale(1.15);
    }
  }

  @media (min-width: 3840px) {
    .minimal-top-container {
      transform: scale(1.35);
    }
  }

  @media (max-width: 1366px) {
    .minimal-top-container {
      transform: scale(0.9);
    }
  }

  /* High-Tech Glass Cluster - Identical to MinimalSpeedometer */
  .glass-cluster {
    background: rgba(11, 14, 20, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 12px;
    padding: 7px 12px 8px 12px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40);
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .cluster-module {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  /* Micro-Badges mirroring speedometer badges */
  .badge-icon {
    width: 22px;
    height: 22px;
    border-radius: 5px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.2s ease;
    flex-shrink: 0;
  }

  .badge-passport {
    background: rgba(255, 255, 255, 0.06);
    color: rgba(255, 255, 255, 0.70);
    border: 1px solid rgba(255, 255, 255, 0.05);
  }

  .badge-dim {
    background: rgba(255, 255, 255, 0.05);
    color: rgba(255, 255, 255, 0.25);
  }

  .badge-active-green {
    background: rgba(16, 185, 129, 0.20);
    color: #10b981;
    box-shadow: 0 0 8px rgba(16, 185, 129, 0.40);
  }

  .badge-active-blue {
    background: rgba(59, 130, 246, 0.20);
    color: #60a5fa;
    box-shadow: 0 0 6px rgba(59, 130, 246, 0.35);
  }

  .module-content {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .module-header-row {
    display: flex;
    align-items: center;
    gap: 5px;
  }

  .module-label {
    font-size: 8px;
    font-weight: 800;
    letter-spacing: 0.05em;
    color: rgba(255, 255, 255, 0.45);
    text-transform: uppercase;
    line-height: 1;
  }

  .mode-tag {
    font-size: 7.5px;
    font-weight: 800;
    color: #10b981;
    letter-spacing: 0.03em;
    line-height: 1;
  }

  .module-value {
    font-size: 13px;
    font-weight: 900;
    line-height: 1;
    font-variant-numeric: tabular-nums;
    letter-spacing: -0.02em;
  }

  .id-value {
    color: #ffffff;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.8);
  }

  .text-green {
    color: #10b981;
    text-shadow: 0 0 6px rgba(16, 185, 129, 0.4);
  }

  .text-blue {
    color: #60a5fa;
    text-shadow: 0 0 6px rgba(96, 165, 250, 0.3);
  }

  .text-dim {
    color: rgba(255, 255, 255, 0.30);
  }

  .cluster-divider {
    width: 1px;
    height: 24px;
    background: rgba(255, 255, 255, 0.10);
  }

  /* VoIP Equalizer Vertical Bars */
  .voip-equalizer {
    display: flex;
    align-items: flex-end;
    gap: 2.5px;
    height: 12px;
    padding-top: 1px;
  }

  .eq-bar {
    width: 3.5px;
    border-radius: 9999px;
    transition: all 0.15s ease;
  }

  .bar-dim {
    background: rgba(255, 255, 255, 0.12);
  }

  .bar-lit {
    background: #ffffff;
    box-shadow: 0 0 4px rgba(255, 255, 255, 0.4);
  }

  .bar-talking {
    background: #10b981;
    box-shadow: 0 0 6px #10b981;
  }
</style>
