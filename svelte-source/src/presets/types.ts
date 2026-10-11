export type PresetId = 'dp-original-beta' | 'minimal-glass' | string;

export interface PresetPreview {
  icon: string;
  badgeColor: string;
  accentColor: string;
}

export interface PresetComponentConfig {
  statusComponent: 'creative' | 'minimal';
  speedometerComponent: 'driftarc' | 'minimal';
  topHudVisible: boolean;
  topHudComponent?: 'creative' | 'minimal';
  mapBorderStyle: 'vanguard' | 'minimal';
}

export interface HudPreset {
  id: PresetId;
  name: string;
  tag: string;
  description: string;
  author: string;
  aliases: string[];
  features: string[];
  preview: PresetPreview;
  config: PresetComponentConfig;
}
