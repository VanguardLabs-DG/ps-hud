<script lang="ts">
  import PlayerHudStore from '../stores/playerStatusHudStore';
  import DebugStore from '../stores/debugStore';

  $: isDesign = $PlayerHudStore.designMode;
  $: isVisible = $PlayerHudStore.show || DebugStore || isDesign;

  // Authentic data bindings
  $: citizenid = isDesign ? "101" : ($PlayerHudStore.citizenid || "1");
  $: voiceMode = isDesign ? 2 : Math.max(1, Math.min(4, Number($PlayerHudStore.voiceMode || 2)));
  $: talking = isDesign ? false : ($PlayerHudStore.talking || false);
  $: radioTalking = isDesign ? false : ($PlayerHudStore.radioTalking || false);
  $: radioChannel = isDesign ? 1 : ($PlayerHudStore.radioChannel || 0);

  // Vanguard Lib - Distrito Paulista Identity Tokens
  const gold = "#e5a93c";
  const goldLight = "#f5b945";
  const bgTitanium = "#0b0e14";
</script>

{#if isVisible}
  <div class="creative-top-container">
    <!-- Top Row: Passaporte (Left) and VoIP (Right) -->
    <div class="creative-top-row">
      <!-- 1. Passaporte -->
      <div class="widget-item">
        <div class="widget-text-col">
          <span class="widget-title">Passaporte</span>
          <span class="widget-value">{citizenid}</span>
        </div>
        <div
          class="widget-diamond"
          style="
            border-color: rgba(245, 185, 69, 0.50);
            box-shadow: 0 2px 10px rgba(0, 0, 0, 0.5), 0 0 10px rgba(229, 169, 60, 0.20);
          "
        >
          <div
            class="widget-diamond-inner"
            style="
              border-color: rgba(229, 169, 60, 0.35);
              background-image: linear-gradient(135deg, rgba(229, 169, 60, 0.22) 0%, rgba(11, 14, 20, 0.85) 100%);
            "
          >
            <div class="widget-diamond-icon">
              <span class="passport-id-text">ID</span>
            </div>
          </div>
        </div>
      </div>

      <!-- 2. VoIP (Right of Passaporte) -->
      <div class="widget-item">
        <div class="widget-text-col">
          <span class="widget-title">Voip</span>
          <!-- 4 Skewed Volume Bars -->
          <div class="voip-bars-container">
            {#each [0, 1, 2, 3] as g}
              {@const isLit = voiceMode >= (4 - g)}
              <div
                class="voip-bar {isLit ? (talking ? 'bar-talking' : 'bar-lit') : 'bar-unlit'}"
              />
            {/each}
          </div>
        </div>
        <div
          class="widget-diamond"
          style="
            border-color: {talking ? '#22c55e' : 'rgba(245, 185, 69, 0.50)'};
            box-shadow: {talking
              ? '0 0 14px rgba(34, 197, 94, 0.50)'
              : '0 2px 10px rgba(0, 0, 0, 0.5), 0 0 8px rgba(229, 169, 60, 0.15)'};
          "
        >
          <div
            class="widget-diamond-inner"
            style="
              border-color: {talking ? '#22c55e' : 'rgba(229, 169, 60, 0.35)'};
              background-image: {talking
                ? 'linear-gradient(135deg, rgba(34, 197, 94, 0.30) 0%, rgba(11, 14, 20, 0.85) 100%)'
                : 'linear-gradient(135deg, rgba(229, 169, 60, 0.20) 0%, rgba(11, 14, 20, 0.85) 100%)'};
            "
          >
            <div
              class="widget-diamond-icon"
              style="color: {talking ? '#22c55e' : '#FFFFFF'};"
            >
              <!-- Authentic VoIP Equalizer SVG -->
              <svg viewBox="0 0 14 14" fill="none" class="w-full h-full" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M7 0.5C7.1905 0.500023 7.37437 0.564972 7.51673 0.682528C7.65909 0.800083 7.75004 0.962069 7.77233 1.13776L7.77778 1.22227V12.7785C7.77756 12.9626 7.70165 13.1397 7.56556 13.2736C7.42948 13.4074 7.24348 13.488 7.04558 13.4988C6.84768 13.5095 6.65282 13.4498 6.5008 13.3316C6.34878 13.2134 6.25108 13.0458 6.22767 12.863L6.22222 12.7785V1.22227C6.22222 1.03071 6.30417 0.846998 6.45003 0.711547C6.59589 0.576096 6.79372 0.5 7 0.5ZM3.88889 2.6668C4.09517 2.6668 4.293 2.7429 4.43886 2.87835C4.58472 3.0138 4.66667 3.19751 4.66667 3.38907V10.6117C4.66667 10.8033 4.58472 10.987 4.43886 11.1225C4.293 11.2579 4.09517 11.334 3.88889 11.334C3.68261 11.334 3.48478 11.2579 3.33892 11.1225C3.19306 10.987 3.11111 10.8033 3.11111 10.6117V3.38907C3.11111 3.19751 3.19306 3.0138 3.33892 2.87835C3.48478 2.7429 3.68261 2.6668 3.88889 2.6668ZM10.1111 2.6668C10.3174 2.6668 10.5152 2.7429 10.6611 2.87835C10.8069 3.0138 10.8889 3.19751 10.8889 3.38907V10.6117C10.8889 10.8033 10.8069 10.987 10.6611 11.1225C10.5152 11.2579 10.3174 11.334 10.1111 11.334C9.90483 11.334 9.707 11.2579 9.56114 11.1225C9.41528 10.987 9.33333 10.8033 9.33333 10.6117V3.38907C9.33333 3.19751 9.41528 3.0138 9.56114 2.87835C9.707 2.7429 9.90483 2.6668 10.1111 2.6668ZM0.777778 4.8336C0.984057 4.8336 1.18189 4.9097 1.32775 5.04515C1.47361 5.1806 1.55556 5.36431 1.55556 5.55587V8.44493C1.55556 8.63649 1.47361 8.8202 1.32775 8.95565C1.18189 9.0911 0.984057 9.1672 0.777778 9.1672C0.571498 9.1672 0.373667 9.0911 0.227806 8.95565C0.0819442 8.8202 0 8.63649 0 8.44493V5.55587C0 5.36431 0.0819442 5.1806 0.227806 5.04515C0.373667 4.9097 0.571498 4.8336 0.777778 4.8336ZM13.2222 4.8336C13.4127 4.83362 13.5966 4.89857 13.739 5.01613C13.8813 5.13368 13.9723 5.29567 13.9946 5.47136L14 5.55587V8.44493C13.9998 8.62902 13.9239 8.80609 13.7878 8.93995C13.6517 9.07381 13.4657 9.15437 13.2678 9.16516C13.0699 9.17595 12.875 9.11615 12.723 8.998C12.571 8.87984 12.4733 8.71224 12.4499 8.52944L12.4444 8.44493V5.55587C12.4444 5.36431 12.5264 5.1806 12.6722 5.04515C12.8181 4.9097 13.0159 4.8336 13.2222 4.8336Z"
                  fill="currentColor"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Bottom Row: Rádio (Aligned Right Directly Under VoIP) -->
    <div class="creative-bottom-row">
      <!-- 3. Rádio -->
      <div class="widget-item">
        <div class="widget-text-col">
          <span class="widget-title">Rádio</span>
          <span class="widget-value" style="color: {radioChannel > 0 ? goldLight : '#8a8a93'};">
            {radioChannel > 0 ? (typeof radioChannel === 'number' ? `${radioChannel} MHz` : radioChannel) : 'OFF'}
          </span>
        </div>
        <div
          class="widget-diamond"
          style="
            border-color: {radioTalking ? '#319BFF' : (radioChannel > 0 ? 'rgba(245, 185, 69, 0.55)' : 'rgba(255, 255, 255, 0.12)')};
            box-shadow: {radioTalking
              ? '0 0 14px rgba(49, 155, 255, 0.55)'
              : (radioChannel > 0 ? '0 2px 10px rgba(0, 0, 0, 0.5), 0 0 10px rgba(229, 169, 60, 0.22)' : '0 2px 8px rgba(0, 0, 0, 0.4)')};
          "
        >
          <div
            class="widget-diamond-inner"
            style="
              border-color: {radioTalking ? '#319BFF' : (radioChannel > 0 ? 'rgba(229, 169, 60, 0.40)' : 'rgba(255, 255, 255, 0.08)')};
              background-image: {radioTalking
                ? 'linear-gradient(135deg, rgba(49, 155, 255, 0.30) 0%, rgba(11, 14, 20, 0.85) 100%)'
                : (radioChannel > 0
                  ? 'linear-gradient(135deg, rgba(229, 169, 60, 0.25) 0%, rgba(11, 14, 20, 0.85) 100%)'
                  : 'none')};
            "
          >
            <div
              class="widget-diamond-icon"
              style="color: {radioTalking ? '#319BFF' : (radioChannel > 0 ? goldLight : '#8a8a93')};"
            >
              <!-- Authentic Walkie-Talkie SVG -->
              <svg viewBox="0 0 10 18" fill="none" class="w-full h-full" xmlns="http://www.w3.org/2000/svg">
                <path
                  d="M2.91591 0.84375C2.91591 0.376172 2.63733 0 2.29107 0C1.94481 0 1.66623 0.376172 1.66623 0.84375V3.375H1.24967C0.55975 3.375 0 4.13086 0 5.0625V10.5504C0 10.9969 0.132778 11.4258 0.367092 11.7422L0.468628 11.8793C0.702942 12.1957 0.83572 12.6246 0.83572 13.0711V16.3125C0.83572 17.2441 1.39547 18 2.08539 18H7.91461C8.60453 18 9.16428 17.2441 9.16428 16.3125V13.0746C9.16428 12.6281 9.29706 12.1992 9.53137 11.8828L9.63291 11.7457C9.86722 11.4293 10 11.0004 10 10.5539V5.0625C10 4.13086 9.44025 3.375 8.75033 3.375H8.33116C8.33116 2.75273 7.95886 2.25 7.49805 2.25C7.03723 2.25 6.66493 2.75273 6.66493 3.375H5.83181C5.83181 2.75273 5.45952 2.25 4.9987 2.25C4.53788 2.25 4.16558 2.75273 4.16558 3.375H2.91591V0.84375ZM2.91591 5.625H7.08149C7.3106 5.625 7.49805 5.87813 7.49805 6.1875C7.49805 6.49687 7.3106 6.75 7.08149 6.75H2.91591C2.6868 6.75 2.49935 6.49687 2.49935 6.1875C2.49935 5.87813 2.6868 5.625 2.91591 5.625ZM2.91591 7.875H7.08149C7.3106 7.875 7.49805 8.12813 7.49805 8.4375C7.49805 8.74687 7.3106 9 7.08149 9H2.91591C2.6868 9 2.49935 8.74687 2.49935 8.4375C2.49935 8.12813 2.6868 7.875 2.91591 7.875ZM2.91591 10.125H7.08149C7.3106 10.125 7.49805 10.3781 7.49805 10.6875C7.49805 10.9969 7.3106 11.25 7.08149 11.25H2.91591C2.6868 11.25 2.49935 10.9969 2.49935 10.6875C2.49935 10.3781 2.6868 10.125 2.91591 10.125Z"
                  fill="currentColor"
                />
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
{/if}

<style>
  .creative-top-container {
    position: fixed;
    top: 24px;
    right: 28px;
    z-index: 50;
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    gap: 12px;
    pointer-events: none;
    user-select: none;
    transform-origin: top right;
    transition: transform 0.3s ease;
  }

  @media (min-width: 2560px) {
    .creative-top-container {
      transform: scale(1.15);
    }
  }

  @media (min-width: 3840px) {
    .creative-top-container {
      transform: scale(1.4);
    }
  }

  @media (max-width: 1366px) {
    .creative-top-container {
      transform: scale(0.88);
    }
  }

  .creative-top-row {
    display: flex;
    align-items: center;
    gap: 20px;
  }

  .creative-bottom-row {
    display: flex;
    align-items: center;
    justify-content: flex-end;
  }

  .widget-item {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .widget-text-col {
    display: flex;
    flex-direction: column;
    align-items: flex-end;
    text-align: right;
    filter: drop-shadow(0 1px 3px rgba(0, 0, 0, 0.9));
  }

  .widget-title {
    font-size: 10px;
    font-weight: 300;
    letter-spacing: 0.05em;
    color: rgba(255, 255, 255, 0.5);
    text-transform: uppercase;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    line-height: 1;
  }

  .widget-value {
    font-size: 14px;
    font-weight: 500;
    color: #ffffff;
    line-height: 1.2;
    margin-top: 3px;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
  }

  /* Authentic 38px diamond rotated 45deg */
  .widget-diamond {
    width: 38px;
    height: 38px;
    transform: rotate(45deg);
    border-radius: 8px;
    border-width: 1px;
    border-style: solid;
    background-color: rgba(11, 14, 20, 0.85);
    display: flex;
    align-items: center;
    justify-content: center;
    flex-shrink: 0;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5);
    transition: all 0.25s ease;
  }

  .widget-diamond-inner {
    width: 100%;
    height: 100%;
    border-radius: 6px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-width: 1px;
    border-style: solid;
    transition: all 0.25s ease;
  }

  .widget-diamond-icon {
    transform: rotate(-45deg);
    width: 22px;
    height: 22px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: all 0.25s ease;
  }

  .passport-id-text {
    font-size: 11px;
    font-weight: 800;
    letter-spacing: -0.03em;
    text-transform: uppercase;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
    display: flex;
    align-items: center;
    justify-content: center;
    width: 100%;
    height: 100%;
    color: #f5b945;
    text-shadow: 0 0 6px rgba(229, 169, 60, 0.6);
  }

  /* VoIP volume bars */
  .voip-bars-container {
    display: flex;
    align-items: center;
    gap: 6px;
    margin-top: 4px;
  }

  .voip-bar {
    width: 10px;
    height: 14px;
    border-radius: 2px;
    transform: skewX(-20deg);
    transition: all 0.25s ease;
  }

  .bar-lit {
    background-color: #f5b945;
    box-shadow: 0 0 6px rgba(245, 185, 69, 0.65);
  }

  .bar-talking {
    background-color: #22c55e;
    box-shadow: 0 0 8px #22c55e;
  }

  .bar-unlit {
    background-color: rgba(255, 255, 255, 0.15);
  }
</style>
