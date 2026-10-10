<script lang="ts">
  import { tweened } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';
  import Fa from 'svelte-fa';

  export let displayOutline: boolean = true;
  export let height: number = 50;
  export let icon: any = null;
  export let iconColor: string = "#FFFFFF";
  export let iconContrast: number = 100;
  export let iconDropShadowAmount: number = 0;
  export let iconRotateDegree: number = 0;
  export let iconScaling: number = 0.45;
  export let iconTranslateX: number = 0;
  export let iconTranslateY: number = 0;
  export let innerColor: string = "rgba(14, 16, 19, 0.6)";
  export let name: string = "";
  export let outlineColor: string = "#DC0616";
  export let outlineContrast: number = 100;
  export let outlineDropShadowAmount: number = 0;
  export let progressColor: string = "#DC0616";
  export let progressContrast: number = 100;
  export let progressDropShadowAmount: number = 0;
  export let progressValue: number = 100;
  export let ringSize: number = 1;
  export let rotateDegree: number = 0;
  export let translateX: number = 0;
  export let translateY: number = 0;
  export let width: number = 50;

  const progressTween = tweened(progressValue, {
    duration: 450,
    easing: cubicOut
  });

  $: {
    progressTween.set(Math.max(0, Math.min(100, progressValue)));
  }

  $: roundedVal = Math.round(progressValue);
  $: activeColor = outlineColor || progressColor || "#DC0616";
</script>

<div 
  class="creative-diamond-wrapper"
  style="
    transform: translate({translateX}px, {translateY}px) {rotateDegree ? `rotate(${rotateDegree}deg)` : ''};
  "
>
  <!-- 45-degree rotated outer diamond box with authentic border glow -->
  <div 
    class="creative-diamond-card"
    style="
      border-color: {activeColor};
      box-shadow: 0 0 8px {activeColor}33;
    "
  >
    <!-- Inner clipping container with subtle gradient -->
    <div class="creative-diamond-inner">
      <!-- Counter-rotated fluid container (-45deg) so fluid fills straight up -->
      <div class="creative-fluid-wrapper">
        <div 
          class="creative-fluid-bar"
          style="
            height: {roundedVal === 100 ? '100%' : `calc(${roundedVal}% - 0.25rem)`};
            background-color: {activeColor};
          "
        >
          <!-- Animated wave SVG at top of fluid -->
          {#if roundedVal > 0 && roundedVal < 100}
            <svg 
              class="waves" 
              xmlns="http://www.w3.org/2000/svg" 
              viewBox="0 24 150 28" 
              preserveAspectRatio="none" 
              shape-rendering="auto"
            >
              <defs>
                <path 
                  id="wave-{name || 'shape'}" 
                  d="M-160 44c30 0 58-18 88-18s 58 18 88 18 58-18 88-18 58 18 88 18 v44h-352Z" 
                />
              </defs>
              <g class="parallax">
                <use href="#wave-{name || 'shape'}" x="48" y="0" fill="{activeColor}b3" />
                <use href="#wave-{name || 'shape'}" x="48" y="3" fill="{activeColor}80" />
                <use href="#wave-{name || 'shape'}" x="48" y="5" fill="{activeColor}4d" />
                <use href="#wave-{name || 'shape'}" x="48" y="7" fill="{activeColor}" />
              </g>
            </svg>
          {/if}
        </div>
      </div>
    </div>
  </div>

  <!-- Center upright Icon -->
  <div 
    class="creative-icon-center"
    style="
      color: {iconColor || '#FFFFFF'};
      filter: {iconDropShadowAmount ? `drop-shadow(0px 0px ${iconDropShadowAmount}px ${iconColor})` : 'drop-shadow(0 0 2px rgba(255,255,255,0.6))'} contrast({iconContrast}%);
      transform: translate({iconTranslateX}px, {iconTranslateY}px) rotate({iconRotateDegree}deg);
    "
  >
    <Fa 
      icon={icon} 
      scale={iconScaling || 0.45} 
      style="color: {iconColor || '#FFFFFF'};" 
    />
  </div>

  <!-- Authentic 1:1 Percentage text below diamond -->
  <span class="creative-percentage-text">
    {roundedVal}%
  </span>
</div>

<style>
  .creative-diamond-wrapper {
    position: relative;
    display: flex;
    flex-direction: column;
    align-items: center;
    user-select: none;
    margin: 0 2px;
  }

  .creative-diamond-card {
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

  .creative-diamond-inner {
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