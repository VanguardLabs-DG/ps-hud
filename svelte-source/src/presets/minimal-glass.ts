import type { HudPreset } from './types';

export const minimalGlassPreset: HudPreset = {
  id: 'minimal-glass',
  name: 'Minimalista Glass (Clean Modern)',
  tag: 'MINIMALISTA',
  description: 'Interface limpa, moderna e aerodinâmica com indicadores translúcidos compactos, tipografia esportiva direta sem arcos invasivos e máxima visibilidade de jogo.',
  author: 'Distrito Paulista',
  aliases: ['minimal', 'clean', 'glass', 'moderno'],
  features: [
    'Status Sob o Minimapa (Triple-A)',
    'Minimapa Elevado Dinâmico',
    'Velocímetro Digital Limpo',
    'Top Bar Cápsula (ID / VoIP / Rádio)',
    'Zero Frame Preto (Sem Blur CEF)',
  ],
  preview: {
    icon: '⚡',
    badgeColor: '#10b981',
    accentColor: '#34d399',
  },
  config: {
    statusComponent: 'minimal',
    speedometerComponent: 'minimal',
    topHudVisible: true,
    topHudComponent: 'minimal',
    mapBorderStyle: 'minimal',
  },
};
