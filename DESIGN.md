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
  minimap-border:
    left: "2.30vh"
    bottom: "6.20vh"
    width: "27.60vh"
    height: "23.82vh"
    border: "6.0px solid #FF9500"
    glow: "0 0 16px rgba(255, 149, 0, 0.45)"
    borderRadius: "50%"
---

# Distrito Paulista - Creative Diamond HUD Design Specification

## Overview
A HUD do Distrito Paulista busca aliar a estabilidade moderna e flexibilidade do `ps-hud` à identidade visual clássica do preset **Creative** (losangos rotacionados em 45º com preenchimento interno limpo e ícones centralizados retos).

## The Diamond / Creative Shape Problem & Solution
- **Problema no ps-hud original**: O preset `diamond-ring` padrão do ps-hud é um SVG alongado com contorno fino e animação de progresso circular (`stroke-dashoffset`). Isso faz com que ele pareça esticado verticalmente e desproporcional em relação à HUD que o usuário ama.
- **Solução Creative**: O formato autêntico é um quadrado de cantos arredondados (`size: 30px`, `border-radius: 5px`) rotacionado a **45 graus** (`transform: rotate(45deg)`). O preenchimento de progresso (vida, colete, fome, sede) ocorre verticalmente ou em gradiente linear, e o ícone interno é compensado com `rotate(-45deg)` para ficar 100% reto e legível.

## Colors & Hierarchy
- As cores de status seguem a paleta vibrante de alta visibilidade sobre qualquer fundo de jogo.
- Fundo escuro translúcido com `backdrop-blur(6px)` e borda de 2px na cor do status correspondente.
- Nível de preenchimento a 35% de opacidade da cor principal, garantindo contraste total com o ícone branco em primeiro plano.

## Layout & Placement
- **Posicionamento**: Canto inferior direito para os status (vida, colete, fome, sede, estresse, mic) em linha horizontal com `gap: 10px`.
- **Velocímetro**: Integrado sobre o minimapa ou canto inferior direito quando dentro de veículos, com KM/H e display de marcha.
