import type { HudPreset } from './types';
import { dpOriginalBetaPreset } from './dp-original-beta';
import { minimalGlassPreset } from './minimal-glass';

export const DEFAULT_PRESET_ID = 'dp-original-beta';

export const HUD_PRESETS: HudPreset[] = [
  dpOriginalBetaPreset,
  minimalGlassPreset,
];

export function findPresetByIdOrAlias(query: string): HudPreset | undefined {
  if (!query) return undefined;
  const normalized = query.trim().toLowerCase();
  return HUD_PRESETS.find(
    (p) =>
      p.id.toLowerCase() === normalized ||
      p.aliases.some((a) => a.toLowerCase() === normalized)
  );
}
