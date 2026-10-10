<script lang="ts">
  import { tweened } from 'svelte/motion';
  import { cubicOut } from 'svelte/easing';
  import Fa from 'svelte-fa';

  export let height: number = 50;
  export let icon: any = null;
  export let iconColor: string = "white";
  export let iconContrast: number = 100;
  export let iconDropShadowAmount: number = 0;
  export let iconScaling: number = 0.45;
  export let iconTranslateX: number = 0;
  export let iconTranslateY: number = 0;
  export let name: string = "";
  export let outlineColor: string = "red";
  export let outlineContrast: number = 100;
  export let outlineDropShadowAmount: number = 0;
  export let progressColor: string = "red";
  export let progressContrast: number = 100;
  export let progressDropShadowAmount: number = 0;
  export let progressValue: number = 100;
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

  $: boxSize = Math.max(26, Math.min(width, height) * 0.62);
</script>

<div 
  class="creative-diamond-wrapper"
  style="
    width: {width}px;
    height: {height}px;
    transform: translate({translateX}px, {translateY}px) {rotateDegree ? `rotate(${rotateDegree}deg)` : ''};
  "
>
  <div 
    class="creative-diamond-card"
    style="
      width: {boxSize}px;
      height: {boxSize}px;
      border: 2px solid {outlineColor || progressColor};
      background: rgba(10, 12, 16, 0.65);
      filter: {outlineDropShadowAmount ? `drop-shadow(0px 0px ${outlineDropShadowAmount}px ${outlineColor || progressColor})` : 'drop-shadow(0 2px 6px rgba(0,0,0,0.5))'} contrast({outlineContrast}%);
    "
  >
    <div 
      class="creative-liquid-fill"
      style="
        height: {$progressTween}%;
        background-color: {progressColor};
        filter: {progressDropShadowAmount ? `drop-shadow(0px 0px ${progressDropShadowAmount}px ${progressColor})` : ''} contrast({progressContrast}%);
      "
    />
  </div>

  <div 
    class="creative-icon-center"
    style="
      filter: {iconDropShadowAmount ? `drop-shadow(0px 0px ${iconDropShadowAmount}px ${iconColor})` : 'drop-shadow(0 1px 3px rgba(0,0,0,0.9))'} contrast({iconContrast}%);
      transform: translate({iconTranslateX}px, {iconTranslateY}px);
    "
  >
    <Fa 
      icon={icon} 
      scale={iconScaling || 0.45} 
      style="color: {iconColor || '#FFFFFF'};" 
    />
  </div>
</div>

<style>
  .creative-diamond-wrapper {
    position: relative;
    display: flex;
    align-items: center;
    justify-content: center;
    user-select: none;
    margin: -4px;
  }

  .creative-diamond-card {
    position: relative;
    transform: rotate(45deg);
    border-radius: 4px;
    overflow: hidden;
    backdrop-filter: blur(6px);
    -webkit-backdrop-filter: blur(6px);
    box-sizing: border-box;
    transition: border-color 0.2s ease;
  }

  .creative-liquid-fill {
    position: absolute;
    bottom: 0;
    left: 0;
    width: 200%;
    opacity: 0.38;
    transform-origin: bottom left;
    transform: rotate(-45deg);
    transition: height 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    pointer-events: none;
  }

  .creative-icon-center {
    position: absolute;
    z-index: 10;
    display: flex;
    align-items: center;
    justify-content: center;
    pointer-events: none;
    color: #ffffff;
  }
</style>