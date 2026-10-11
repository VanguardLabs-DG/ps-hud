<script lang="ts">
  import PlayerHudStore from '../stores/playerStatusHudStore';
  import LayoutStore from '../stores/layoutStore';
  import ColorEffectStore from '../stores/colorEffectStore';
  import VehicleHudStore from '../stores/vehicleHudStore';
  import DebugStore from '../stores/debugStore';

  // Reactive store values
  $: isDesign = $PlayerHudStore.designMode;
  $: designVal = $PlayerHudStore.designProgress;
  $: isVisible = $PlayerHudStore.show || DebugStore || isDesign;

  // Individual status percentages (0 - 100)
  $: healthVal = isDesign ? designVal : ($PlayerHudStore.icons.health?.progressValue ?? 100);
  $: armorVal = isDesign ? designVal : ($PlayerHudStore.icons.armor?.progressValue ?? 0);
  $: hungerVal = isDesign ? designVal : ($PlayerHudStore.icons.hunger?.progressValue ?? 100);
  $: thirstVal = isDesign ? designVal : ($PlayerHudStore.icons.thirst?.progressValue ?? 100);
  $: staminaVal = isDesign ? designVal : ($PlayerHudStore.stamina ?? 100);

  // Colors from ColorEffectStore or default authentic tokens
  $: healthColor = $ColorEffectStore.icons.health?.colorEffects[0]?.progressColor || "#DC0616";
  $: armorColor = $ColorEffectStore.icons.armor?.colorEffects[0]?.progressColor || "#3B82F6";
  $: hungerColor = $ColorEffectStore.icons.hunger?.colorEffects[0]?.progressColor || "#F97316";
  $: thirstColor = $ColorEffectStore.icons.thirst?.colorEffects[0]?.progressColor || "#06B6D4";
  $: staminaColor = "#10B981";

  // Dynamic vertical offset when inside a vehicle with right-positioned speedometer
  $: inVehicle = $VehicleHudStore.show;

  // Exact 1:1 status list from legacy HUD: ["life", "shield", "hungry", "thirst", "oxygen", "stamina"]
  $: statusItems = [
    {
      id: "life",
      name: "health",
      val: Math.round(healthVal),
      color: healthColor,
      visible: true,
      icon: "life"
    },
    {
      id: "shield",
      name: "armor",
      val: Math.round(armorVal),
      color: armorColor,
      visible: isDesign || armorVal > 0,
      icon: "shield"
    },
    {
      id: "hungry",
      name: "hunger",
      val: Math.round(hungerVal),
      color: hungerColor,
      visible: true,
      icon: "hungry"
    },
    {
      id: "thirst",
      name: "thirst",
      val: Math.round(thirstVal),
      color: thirstColor,
      visible: true,
      icon: "thirst"
    },
    {
      id: "stamina",
      name: "stamina",
      val: Math.round(staminaVal),
      color: staminaColor,
      visible: true,
      icon: "stamina"
    }
  ];
</script>

{#if isVisible}
  <div 
    class="creative-hud-container {inVehicle ? 'in-vehicle' : ''}"
    style="
      gap: {$LayoutStore.iconBetweenSpacing ? ($LayoutStore.iconBetweenSpacing + 10) + 'px' : '12px'};
      margin-bottom: {$LayoutStore.yAxisSpacing || 0}px;
      margin-right: {$LayoutStore.xAxisSpacing || 0}px;
    "
  >
    {#each statusItems as item (item.id)}
      {#if item.visible}
        <div class="creative-item">
          <!-- The 45-degree rotated outer diamond card with authentic border glow -->
          <div 
            class="creative-box-outer"
            style="
              border-color: {item.color};
              box-shadow: 0 0 8px {item.color}33;
            "
          >
            <!-- Inner clipping container with subtle gradient -->
            <div class="creative-box-inner">
              <!-- Counter-rotated fluid container (-45deg) so fill rises vertically -->
              <div class="creative-fluid-wrapper">
                <div 
                  class="creative-fluid-bar"
                  style="
                    height: {item.val === 100 ? '100%' : `calc(${item.val}% - 0.25rem)`};
                    background-color: {item.color};
                  "
                >
                  <!-- Animated wave SVG at the crest of the fluid -->
                  {#if item.val > 0 && item.val < 100}
                    <svg 
                      class="waves" 
                      xmlns="http://www.w3.org/2000/svg" 
                      viewBox="0 24 150 28" 
                      preserveAspectRatio="none" 
                      shape-rendering="auto"
                    >
                      <defs>
                        <path 
                          id="wave-{item.id}" 
                          d="M-160 44c30 0 58-18 88-18s 58 18 88 18 58-18 88-18 58 18 88 18 v44h-352Z" 
                        />
                      </defs>
                      <g class="parallax">
                        <use href="#wave-{item.id}" x="48" y="0" fill="{item.color}b3" />
                        <use href="#wave-{item.id}" x="48" y="3" fill="{item.color}80" />
                        <use href="#wave-{item.id}" x="48" y="5" fill="{item.color}4d" />
                        <use href="#wave-{item.id}" x="48" y="7" fill="{item.color}" />
                      </g>
                    </svg>
                  {/if}
                </div>
              </div>
            </div>
          </div>

          <!-- Counter-rotated Center Icon (Upright, White with Glow) -->
          <div class="creative-icon-center" style="color: #FFFFFF;">
            {#if item.icon === 'life'}
              <svg width="16" height="15" viewBox="0 0 16 15" fill="currentColor">
                <path d="M11.7568 0.799988C10.1216 0.799988 8.7096 1.73099 8 3.08899C7.2904 1.73099 5.8784 0.799988 4.2432 0.799988C1.8992 0.799988 0 2.71099 0 5.06299C0 7.41499 1.4536 9.57099 3.332 11.342C5.2104 13.113 8 14.8 8 14.8C8 14.8 10.6992 13.141 12.668 11.342C14.768 9.42399 16 7.42199 16 5.06299C16 2.70399 14.1008 0.799988 11.7568 0.799988Z"/>
              </svg>
            {:else if item.icon === 'shield'}
              <svg width="14" height="17" viewBox="0 0 14 17" fill="currentColor">
                <path d="M7.31149 0.558237C7.11086 0.480588 6.88913 0.480588 6.6885 0.558237L0.563573 2.9281C0.395953 2.99295 0.252001 3.10857 0.151211 3.2593C0.0504205 3.41003 -0.00233821 3.58859 7.95312e-05 3.7708C0.0328558 6.24372 0.638991 8.67398 1.76931 10.8644C2.89387 13.0453 4.51464 14.922 6.49688 16.3384C6.64421 16.4435 6.81991 16.5 6.99999 16.5C7.18008 16.5 7.35578 16.4435 7.50311 16.3384C9.48492 14.9221 11.1054 13.0457 12.2298 10.8653C13.3606 8.67467 13.967 6.2441 13.9999 3.7708C14.0025 3.58844 13.9498 3.40969 13.849 3.25878C13.7482 3.10787 13.6042 2.99212 13.4364 2.92721L7.31149 0.558237Z"/>
              </svg>
            {:else if item.icon === 'hungry'}
              <svg width="16" height="17" viewBox="0 0 16 17" fill="currentColor">
                <path d="M14.5287 9.08402C15.0606 8.55297 15.4663 7.90918 15.7158 7.20024C15.9653 6.4913 16.0521 5.73537 15.9699 4.98835C15.8878 4.24132 15.6387 3.52233 15.2411 2.88453C14.8434 2.24673 14.3075 1.70646 13.6728 1.30367C12.0652 0.240167 9.91356 0.232171 8.28988 1.27968C6.88215 2.18326 6.10629 3.5906 5.97032 5.04591C5.86634 6.10142 5.46642 7.08495 4.73056 7.82061L4.70656 7.8446C3.77874 8.77216 3.77874 10.1875 4.65057 11.0511L5.44242 11.8427C5.86148 12.2614 6.42968 12.4966 7.02212 12.4966C7.61456 12.4966 8.18276 12.2614 8.60182 11.8427C9.37767 11.0671 10.4015 10.6433 11.5133 10.5233C12.609 10.4034 13.6808 9.92362 14.5287 9.08402ZM3.41081 14.7853C3.62677 15.2331 3.55478 15.7769 3.17885 16.1447C3.01604 16.3099 2.80853 16.4241 2.58178 16.4731C2.35502 16.5221 2.11888 16.5039 1.90233 16.4207C1.68578 16.3375 1.49822 16.1929 1.36267 16.0047C1.22712 15.8165 1.14947 15.5928 1.13925 15.3611C0.907474 15.3508 0.683727 15.2732 0.495449 15.1377C0.307171 15.0022 0.16255 14.8147 0.0793248 14.5982C-0.00390019 14.3817 -0.0221097 14.1456 0.0269298 13.9189C0.0759693 13.6922 0.190125 13.4848 0.355395 13.322C0.723325 12.9542 1.27522 12.8742 1.71513 13.0901L3.69876 11.147C3.81073 11.299 3.93871 11.4749 4.08268 11.6188L4.87453 12.4105C5.0425 12.5704 5.20247 12.7063 5.41043 12.8263L3.41081 14.7853Z"/>
              </svg>
            {:else if item.icon === 'thirst'}
              <svg width="12" height="16" viewBox="0 0 12 16" fill="currentColor">
                <path d="M6 0L5.40857 0.571086L5.40429 0.574569L5.39057 0.587627C5.31634 0.660214 5.24319 0.73393 5.17114 0.808749C4.29545 1.70875 3.48316 2.67019 2.74029 3.68595C1.44171 5.46363 0 7.9482 0 10.3448C0 13.5389 2.75914 16 6 16C9.24086 16 12 13.5389 12 10.3457C12 7.94907 10.5574 5.4645 9.26057 3.68595C8.46881 2.60422 7.59838 1.58427 6.65657 0.634637L6.60943 0.587627L6.59571 0.574569L6.59229 0.571086L6 0ZM4.36971 10.4441C4.29764 10.2268 4.1441 10.0472 3.94243 9.94428C3.74076 9.84132 3.50724 9.8233 3.29258 9.89414C3.07791 9.96498 2.89942 10.119 2.79585 10.3227C2.69229 10.5264 2.67201 10.7633 2.73943 10.9821C2.96315 11.6815 3.39911 12.2909 3.98484 12.7232C4.57056 13.1554 5.27598 13.3883 6 13.3883C6.22733 13.3883 6.44535 13.2966 6.60609 13.1333C6.76684 12.9701 6.85714 12.7487 6.85714 12.5178C6.85714 12.2869 6.76684 12.0654 6.60609 11.9022C6.44535 11.7389 6.22733 11.6472 6 11.6472C5.63799 11.6472 5.28528 11.5308 4.99242 11.3146C4.69956 11.0985 4.48157 10.7938 4.36971 10.4441Z"/>
              </svg>
            {:else if item.icon === 'stamina'}
              <svg width="14" height="18" viewBox="0 0 14 18" fill="currentColor">
                <path d="M13.8373 5.70265H9.34849L13.3849 0.281559C13.4685 0.16677 13.3931 0 13.2566 0H5.44244C5.38538 0 5.33037 0.0324876 5.30184 0.0866335L0.0224578 9.77876C-0.0407074 9.89355 0.0367208 10.0387 0.163051 10.0387H3.7166L1.895 17.7837C1.85628 17.9526 2.04782 18.0718 2.166 17.9505L13.9494 5.99937C14.0553 5.89325 13.984 5.70265 13.8373 5.70265Z"/>
              </svg>
            {/if}
          </div>

          <!-- Percentage number under each diamond -->
          <span class="creative-percentage-text">
            {item.val}%
          </span>
        </div>
      {/if}
    {/each}
  </div>
{/if}

<style>
  .creative-hud-container {
    position: fixed;
    right: 1.5rem;
    bottom: 1.5rem;
    display: flex;
    align-items: center;
    z-index: 50;
    pointer-events: none;
    user-select: none;
    transform-origin: bottom right;
    transition: all 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  }

  @media (min-width: 2560px) {
    .creative-hud-container {
      transform: scale(1.15);
    }
  }

  @media (min-width: 3840px) {
    .creative-hud-container {
      transform: scale(1.4);
    }
  }

  @media (max-width: 1366px) {
    .creative-hud-container {
      transform: scale(0.88);
    }
  }

  /* When vehicle HUD is active, stay cleanly placed above or beside */
  .creative-hud-container.in-vehicle {
    bottom: 1.5rem;
  }

  .creative-item {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.375rem;
    transition: all 0.35s ease;
  }

  .creative-box-outer {
    position: relative;
    width: 2.5rem;
    height: 2.5rem;
    border-width: 1px;
    border-style: solid;
    padding: 0.125rem;
    background-color: #0E1013;
    border-radius: 0.5rem;
    overflow: hidden;
    transform: rotate(45deg);
    transition: all 0.35s ease;
    box-sizing: border-box;
  }

  .creative-box-inner {
    width: 100%;
    height: 100%;
    border-radius: 0.25rem;
    background-color: rgba(14, 16, 19, 0.6);
    background-image: linear-gradient(to bottom right, rgba(255, 255, 255, 0.05), rgba(255, 255, 255, 0));
    overflow: hidden;
    display: flex;
    flex-direction: column;
    justify-content: flex-end;
    position: relative;
  }

  .creative-fluid-wrapper {
    position: absolute;
    top: 50%;
    left: 50%;
    transform: translate(-50%, -50%) rotate(-45deg);
    width: 2.8rem;
    height: 2.8rem;
    display: flex;
    flex-direction: column;
    justify-content: flex-end;
  }

  .creative-fluid-bar {
    position: relative;
    width: 100%;
    transition: height 0.5s ease-out;
  }

  .creative-icon-center {
    position: absolute;
    top: 1.25rem;
    left: 50%;
    transform: translate(-50%, -50%);
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    z-index: 10;
    filter: drop-shadow(0 0 2px rgba(255, 255, 255, 0.5));
  }

  .creative-percentage-text {
    font-size: 10px;
    font-weight: 700;
    color: rgba(255, 255, 255, 0.85);
    letter-spacing: 0.05em;
    user-select: none;
    font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
    margin-top: 0.25rem;
    text-shadow: 0 1px 3px rgba(0, 0, 0, 0.9);
  }

  .waves {
    width: 100%;
    height: 0.5rem;
    position: absolute;
    top: -0.5rem;
    left: 0;
  }

  .parallax > use {
    animation: 25s cubic-bezier(0.55, 0.5, 0.45, 0.5) infinite move-forever;
  }
  .parallax > use:first-child {
    animation-duration: 2.45s;
    animation-delay: -2s;
  }
  .parallax > use:nth-child(2) {
    animation-duration: 3.5s;
    animation-delay: -3s;
  }
  .parallax > use:nth-child(3) {
    animation-duration: 4.55s;
    animation-delay: -4s;
  }
  .parallax > use:nth-child(4) {
    animation-duration: 7s;
    animation-delay: -5s;
  }

  @keyframes move-forever {
    0% {
      transform: translate(-90px);
    }
    to {
      transform: translate(85px);
    }
  }
</style>
