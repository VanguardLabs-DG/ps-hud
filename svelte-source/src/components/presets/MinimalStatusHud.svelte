<script lang="ts">
  import { fly } from 'svelte/transition';
  import PlayerHudStore from '../../stores/playerStatusHudStore';
  import LayoutStore from '../../stores/layoutStore';
  import ColorEffectStore from '../../stores/colorEffectStore';
  import VehicleHudStore from '../../stores/vehicleHudStore';
  import MenuStore from '../../stores/menuStore';
  import DebugStore from '../../stores/debugStore';

  $: isDesign = $PlayerHudStore.designMode;
  $: designVal = $PlayerHudStore.designProgress;
  $: inVehicle = $VehicleHudStore.show;

  // Visible only when on foot (when in vehicle, status is seamlessly integrated into the square bezel header crown)
  $: isVisible = ($PlayerHudStore.show || DebugStore || isDesign) && (!inVehicle || DebugStore || isDesign) && !$MenuStore.isCineamticModeChecked;

  // Percentage values (0 - 100)
  $: healthVal = isDesign ? designVal : ($PlayerHudStore.icons.health?.progressValue ?? 100);
  $: armorVal = isDesign ? designVal : ($PlayerHudStore.icons.armor?.progressValue ?? 0);
  $: hungerVal = isDesign ? designVal : ($PlayerHudStore.icons.hunger?.progressValue ?? 100);
  $: thirstVal = isDesign ? designVal : ($PlayerHudStore.icons.thirst?.progressValue ?? 100);
  $: staminaVal = isDesign ? designVal : ($PlayerHudStore.stamina ?? 100);
  $: oxygenVal = isDesign ? designVal : ($PlayerHudStore.icons.oxygen?.progressValue ?? 100);
  $: stressVal = isDesign ? designVal : ($PlayerHudStore.icons.stress?.progressValue ?? 0);

  // Status colors
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
</script>

{#if isVisible}
  <div
    class="autonomous-status-dock"
    in:fly={{ y: -24, duration: 350 }}
    out:fly={{ y: -24, duration: 300 }}
    style="
      left: calc(max(0px, (100vw - 177.78vh) / 2) + 0.75vh + {$LayoutStore.xAxisSpacing || 0}px);
      bottom: calc(2.0vh + {$LayoutStore.yAxisSpacing || 0}px);
      width: 29.85vh;
    "
  >
    <div class="dock-status-row">
      {#each statusList as item (item.id)}
        {#if item.visible}
          <div class="status-track-unit {item.val <= 20 && (item.id === 'health' || item.id === 'hunger' || item.id === 'thirst') ? 'track-alert' : ''}">
            <!-- Micro-Ícone SVG Vetorial -->
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
{/if}

<style>
  /* Autonomous Floating Dock on Foot - STRICTLY ZERO backdrop-filter to prevent CEF black box */
  .autonomous-status-dock {
    position: fixed;
    box-sizing: border-box;
    padding: 8px 12px;
    background: rgba(11, 14, 20, 0.85);
    border: 1px solid rgba(255, 255, 255, 0.09);
    border-radius: 12px;
    box-shadow: 0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40);
    z-index: 35;
    pointer-events: none;
    user-select: none;
    font-family: 'Montserrat', sans-serif;
    transform-origin: bottom left;
  }

  @media (min-width: 2560px) {
    .autonomous-status-dock {
      transform: scale(1.15);
    }
  }

  @media (min-width: 3840px) {
    .autonomous-status-dock {
      transform: scale(1.35);
    }
  }

  @media (max-width: 1366px) {
    .autonomous-status-dock {
      transform: scale(0.9);
    }
  }

  .dock-status-row {
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
</style>
