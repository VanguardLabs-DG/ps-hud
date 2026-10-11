import type { HudPreset } from './types';

export const dpOriginalBetaPreset: HudPreset = {
  id: 'dp-original-beta',
  name: 'Distrito Paulista (Original / Fase Beta)',
  tag: '★ PADRÃO OFICIAL',
  description: 'A clássica e elegante HUD do Distrito Paulista com diamantes Creative inclinados a 45°, velocímetro DriftArc esportivo, moldura de minimapa Vanguard titânio/ouro e painel tático superior.',
  author: 'Distrito Paulista',
  aliases: ['beta', 'dp', 'original', 'creative', 'default'],
  features: [
    'Diamantes Creative 45°',
    'DriftArc Speedometer',
    'Moldura Tática Vanguard',
    'Visor de Rua & Telemetria',
    'Widgets Superiores (ID / VoIP / Rádio)',
  ],
  preview: {
    icon: '💎',
    badgeColor: '#e5a93c',
    accentColor: '#f5b945',
  },
  config: {
    statusComponent: 'creative',
    speedometerComponent: 'driftarc',
    topHudVisible: true,
    topHudComponent: 'creative',
    mapBorderStyle: 'vanguard',
  },
};
