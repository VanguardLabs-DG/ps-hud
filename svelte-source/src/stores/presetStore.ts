import { writable } from 'svelte/store';
import { HUD_PRESETS, DEFAULT_PRESET_ID, findPresetByIdOrAlias } from '../presets/registry';
import type { HudPreset } from '../presets/types';
import { fetchNui } from '../utils/eventHandler';

const STORAGE_KEY = 'ps-hud:selected-preset';

interface PresetStoreState {
  activePreset: HudPreset;
  presets: HudPreset[];
}

function getInitialPreset(): HudPreset {
  try {
    if (typeof localStorage !== 'undefined') {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        const found = findPresetByIdOrAlias(saved);
        if (found) return found;
      }
    }
  } catch (_) {}
  return HUD_PRESETS[0];
}

function createPresetStore() {
  const { subscribe, set, update } = writable<PresetStoreState>({
    activePreset: getInitialPreset(),
    presets: HUD_PRESETS,
  });

  return {
    subscribe,
    setPreset: (presetIdOrAlias: string, syncLua: boolean = true) => {
      const match = findPresetByIdOrAlias(presetIdOrAlias);
      if (!match) return false;

      update((state) => {
        try {
          if (typeof localStorage !== 'undefined') {
            localStorage.setItem(STORAGE_KEY, match.id);
          }
        } catch (_) {}

        if (syncLua) {
          fetchNui('saveActivePreset', { presetId: match.id }).catch(() => {});
        }

        return {
          ...state,
          activePreset: match,
        };
      });

      return true;
    },

    receivePresetFromClient: (presetId: string) => {
      const match = findPresetByIdOrAlias(presetId);
      if (match) {
        update((state) => {
          try {
            if (typeof localStorage !== 'undefined') {
              localStorage.setItem(STORAGE_KEY, match.id);
            }
          } catch (_) {}

          return {
            ...state,
            activePreset: match,
          };
        });
      }
    },
  };
}

export const presetStore = createPresetStore();
export default presetStore;
