---
version: alpha
name: Distrito Paulista - Creative Diamond HUD
description: Design tokens and specifications for ps-hud replicating the iconic Creative tilted diamond HUD
colors:
  background-glass: "rgba(10, 12, 16, 0.65)"
  background-inner: "rgba(0, 0, 0, 0.50)"
  border-subtle: "rgba(255, 255, 255, 0.10)"
  text-primary: "#FFFFFF"
  text-muted: "rgba(255, 255, 255, 0.70)"
  
  # Status Colors (1:1 Creative HUD Replica)
  status-health: "#DC0616"
  status-armor: "#3B82F6"
  status-hunger: "#F97316"
  status-thirst: "#06B6D4"
  status-stamina: "#10B981"
  status-oxygen: "#84CC16"
  status-voice: "#FFFFFF"
  status-voice-talking: "#22C55E"
  
  # Speedometer Colors (1:1 DriftArcSpeedometer Replica)
  speed-primary: "#FFFFFF"
  speed-fuel-arc: "#FFBB00"
  speed-needle: "#FF1A40"
  speed-glow-white: "#FFFFFF"
  speed-glow-orange: "#FF9500"
  speed-glow-red: "#FF2D55"
  speed-badge-active: "#22C55E"
  speed-badge-light: "#0099FF"
  speed-badge-dim: "rgba(255, 255, 255, 0.3)"

typography:
  display-speed:
    fontFamily: "'Montserrat', sans-serif"
    fontSize: "58px"
    fontWeight: 900
    fontStyle: "italic"
    lineHeight: 0.85
    letterSpacing: "-0.04em"
  label-unit:
    fontFamily: "'Montserrat', sans-serif"
    fontSize: "14px"
    fontWeight: 800
    fontStyle: "italic"
  label-gear:
    fontFamily: "'Montserrat', sans-serif"
    fontSize: "21px"
    fontWeight: 800

rounded:
  xs: "2px"
  sm: "4px"
  md: "6px"
  diamond: "5px"
  full: "9999px"

spacing:
  gap-icons: "10px"
  diamond-size: "30px"
  gauge-width: "290px"
  gauge-height: "250px"

components:
  diamond-status:
    backgroundColor: "{colors.background-inner}"
    rounded: "{rounded.diamond}"
    size: "{spacing.diamond-size}"
  drift-speedometer:
    width: "{spacing.gauge-width}"
    height: "{spacing.gauge-height}"
    position: "bottom-right, right: calc(1.5rem - 42px), bottom: 6.2rem"
  # Vanguard Lib - Distrito Paulista Identity Tokens
  vanguard-gold: "#e5a93c"
  vanguard-gold-l: "#f5b945"
  vanguard-gold-d: "#b37e20"
  vanguard-gold-glow: "rgba(229, 169, 60, 0.25)"
  vanguard-bg-primary: "#0b0e14"
  vanguard-bg-surface: "#0e0f18"

  minimap-border:
    left: "2.30vh"
    bottom: "6.20vh"
    width: "27.60vh"
    height: "23.82vh"
    border: "6.0px solid #0b0e14"
    outerLine: "1.5px solid #f5b945"
    innerFeather: "inset 0 0 10px 2px rgba(11, 14, 20, 0.85)"
    borderRadius: "50%"
  minimap-square-border:
    left: "0.75vh"
    bottom: "5.70vh"
    width: "29.85vh"
    height: "19.25vh"
    border: "4.0px solid #0b0e14"
    outerLine: "1.5px solid #f5b945"
    innerFeather: "inset 0 0 10px 2px rgba(11, 14, 20, 0.85)"
    borderRadius: "6.0px"
    rayBoxTracking: "Perimeter ray-box intersection for compass needle and laser ticks"
  floating-street-hud:
    position: "bottom: calc(100% + 0.8vh), centered"
    layout: "2 compact lines (Line 1: street + cross; Line 2: zone + bearing)"
    backdropFog: "extended pseudo-element (inset -1.8vh -4.5vh) with 5-stop cubic decay to 0% at 82%"
    colors:
      streetPrimary: "#FFFFFF"
      streetSecondary: "#d4d4d8"
      zoneTag: "#e5a93c"
      bearingText: "#f5b945"
  vanguard-widgets:
    cardBackground: "rgba(11, 14, 20, 0.82)"
    cardBorder: "1px solid rgba(245, 185, 69, 0.45)"
    cardBorderInner: "1px solid rgba(229, 169, 60, 0.35)"
    goldHighlight: "#f5b945"
  minimal-integrated-header-dock:
    position: "flush atop square minimap bezel as a single unified machined glass cluster"
    radar-native-coordinates:
      left: "0.75vh"
      bottom: "5.70vh"
      width: "29.85vh"
      height: "19.25vh"
      border: "1px hairline rgba(255, 255, 255, 0.09)"
      radius: "12px (bottom-left/right: 12px; top-left/right: 0px for seamless fusion)"
    seamless-fusion: "bottom: calc(100% + var(--square-border-w, 1px)); border-bottom: none; border-radius: 12px 12px 0 0; background: rgba(11, 14, 20, 0.85); border: 1px solid rgba(255, 255, 255, 0.09)"
    box-shadow: "0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40)"
    tactical-ticks: "DESATIVADOS no preset minimal (zero tiques militares, zero agulha pesada)"
    fluid-transition:
      duration: "350ms entering, 300ms exiting with coordinated vertical fly animation"
      on-foot-dock: "in:fly={{ y: -24, duration: 350 }} / out:fly={{ y: -24, duration: 300 }}"
      in-vehicle-bezel: "in:fly={{ y: 24, duration: 380 }} / out:fly={{ y: 24, duration: 300 }}"
    story-1-telemetry:
      height: "26px"
      font-street: "Montserrat 11px font-black uppercase tracking-wider #FFFFFF"
      bairros-removed: "Sem bairro/distrito; exibe exclusivamente nome da rua e rumo/bússola"
      font-bearing: "Montserrat 10px font-black #00f0ff (cyan racing glow)"
      divider: "1px solid rgba(255, 255, 255, 0.08)"
    story-2-status-bars:
      channels-height: "3px"
      border-radius: "9999px"
      background-channel: "rgba(255, 255, 255, 0.08)"
      colors:
        health: "#DC0616"
        armor: "#3B82F6"
        hunger: "#F97316"
        thirst: "#06B6D4"
        stamina: "#10B981"
        oxygen: "#84CC16"
        stress: "#EC4899"
  minimal-status-dock:
    position: "bottom: 2.0vh, left: calc(safezone + 0.75vh)"
    background: "rgba(11, 14, 20, 0.85)"
    border: "1px solid rgba(255, 255, 255, 0.09)"
    borderRadius: "12px"
    boxShadow: "0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40)"
  minimal-top-hud:
    position: "top: 20px, right: 24px"
    background: "rgba(11, 14, 20, 0.85)"
    border: "1px solid rgba(255, 255, 255, 0.09)"
    borderRadius: "12px"
    boxShadow: "0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40)"
    backdropFilterPolicy: "STRICTLY NONE (zero CEF black-box fallback)"
---

# Distrito Paulista - Creative Diamond HUD & Minimalist Glass Design Specification

## Overview
A HUD do Distrito Paulista busca aliar a estabilidade moderna e flexibilidade do `ps-hud` à identidade visual clássica do preset **Creative** (losangos rotacionados em 45º com preenchimento interno limpo e ícones centralizados retos), bem como ao preset contemporâneo **Minimalista Glass** (estrutura Triple-A com minimapa square, moldura e visor fundidos como 1 elemento só e telemetria exclusiva de ruas).

## The Diamond / Creative Shape Problem & Solution
- **Problema no ps-hud original**: O preset `diamond-ring` padrão do ps-hud é um SVG alongado com contorno fino e animação de progresso circular (`stroke-dashoffset`). Isso faz com que ele pareça esticado verticalmente e desproporcional em relação à HUD que o usuário ama.
- **Solução Creative**: O formato autêntico é um quadrado de cantos arredondados (`size: 30px`, `border-radius: 5px`) rotacionado a **45 graus** (`transform: rotate(45deg)`). O preenchimento de progresso (vida, colete, fome, sede) ocorre verticalmente ou em gradiente linear, e o ícone interno é compensado com `rotate(-45deg)` para ficar 100% reto e legível.

## Preset Minimalista Glass (Triple-A Clean Modern)
- **Eliminação do Frame Preto (Zero Backdrop-Filter em CEF)**: No Chromium Embedded Framework do FiveM sobre viewports transparentes DirectX, qualquer `backdrop-filter: blur()` gera uma camada de raster preta opaca ("tela preta"). O estilo Minimalista Glass utiliza exclusivamente superfícies RGBA semi-transparentes (`rgba(11, 14, 20, 0.85)`) com bordas sutis hairline (`1px solid rgba(255, 255, 255, 0.09)`) e drop shadows profundos, garantindo 100% de transparência real.
- **Homogeneização Total com o Velocímetro**:
  - Todos os componentes do preset (Velocímetro, Moldura + Visor Integrado, Dock a pé e Top Bar) compartilham exatamente o mesmo design system: acabamento em vidro escuro translúcido (`rgba(11, 14, 20, 0.85)`), borda hairline de 1px (`rgba(255, 255, 255, 0.09)`), cantos chanfrados em `12px` e sombra profunda com oclusão ambiente (`0 8px 24px rgba(0, 0, 0, 0.60), 0 0 0 1px rgba(0, 0, 0, 0.40)`).
- **Moldura Homogênea em Vidro Escuro & Visor Integrado (1 Elemento Só)**:
  - A moldura do minimapa (`.square`) agora é usinada com o mesmo material de vidro escuro do visor (`border-color: rgba(11, 14, 20, 0.85)` com 4px de espessura e dupla linha hairline externa/interna de 1px `rgba(255, 255, 255, 0.09)`), eliminando a sensação de borda transparente invisível.
  - O visor repousa diretamente sobre a borda externa superior do minimapa square (`bottom: calc(100% + var(--square-border-w, 4px))`), com as laterais alinhadas perfeitamente às arestas externas (`left/right: calc(var(--square-border-w, 4px) * -1)`).
  - A moldura quadrada tem os cantos superiores retos (`border-top-left-radius: 0; border-top-right-radius: 0`) para fusão contínua com a base do visor, e cantos inferiores arredondados em `12px`.
  - Tiques de bússola a laser, agulha volumosa e notch militar permanecem **desativados** no preset Minimal.
  - **Apenas a Rua Atual do Player**: Removidas todas as ruas paralelas e cruzamentos secundários (`street2`) tanto no preset Minimal quanto no Beta Original. Exibe exclusivamente a rua atual em que o jogador se encontra (`street1`) e o rumo digital.
- **Top Bar Redesenhada com Micro-Badges do Velocímetro (`MinimalTopHud.svelte`)**:
  - Módulos de Passaporte, VoIP e Rádio construídos na mesma linguagem do velocímetro:
    - Micro-badges táteis (`22x22px`, `border-radius: 5px`) com cores de estado dedicadas (verde `#10b981`, azul `#60a5fa`, dim).
    - Equalizador vertical esportivo para VoIP (barras verticais com alturas progressivas que acendem em verde esmeralda ao falar).
    - Status de frequência nítido (`100.5 MHz` ou `OFF`) e ID com tipografia tabular limpa em caixa alta.

## Sistema de Presets de HUD
- **Registry Extensível**: `src/presets/registry.ts`
- **Presets Ativos**:
  1. `dp-original-beta`: Padrão Oficial do Distrito Paulista (losangos Creative 45°, velocímetro DriftArc, moldura Vanguard âmbar/titânio e widgets superiores).
  2. `minimal-glass`: Estilo aerodinâmico contemporâneo Triple-A (status sob o minimapa elevado, velocímetro digital limpo no canto inferior direito, cápsula superior e moldura ultra-fina).
- **Persistência**: Híbrido KVP do FiveM (`SetResourceKvp("hud_active_preset")`) + `localStorage`.
- **Comandos**: `/preset`, `/presets`, `/hudpreset [nome/alias]`.
