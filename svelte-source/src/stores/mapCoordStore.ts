import { writable } from 'svelte/store';

export const STORAGE_KEY_CIRCLE = 'ps-hud:map-border-calibration-circle-v3';
export const STORAGE_KEY_SQUARE = 'ps-hud:map-border-calibration-square-v3';

export const DEFAULT_CIRCLE_CONFIG = {
  left: 2.30,
  bottom: 6.20,
  width: 27.60,
  height: 23.82,
  borderWidth: 6.0,
  borderRadius: 50,
};

export const DEFAULT_SQUARE_CONFIG = {
  left: 0.75,
  bottom: 5.70,
  width: 29.85,
  height: 19.25,
  borderWidth: 4.0,
  borderRadius: 6.0,
};

function getInitialCoords() {
  let circle = { ...DEFAULT_CIRCLE_CONFIG };
  let square = { ...DEFAULT_SQUARE_CONFIG };

  try {
    if (typeof localStorage !== 'undefined') {
      const savedCircle = localStorage.getItem(STORAGE_KEY_CIRCLE) || localStorage.getItem('ps-hud:map-border-calibration-v3');
      if (savedCircle) {
        const parsed = JSON.parse(savedCircle);
        if (typeof parsed.left === 'number') circle.left = parsed.left;
        if (typeof parsed.bottom === 'number') circle.bottom = parsed.bottom;
        if (typeof parsed.width === 'number') circle.width = parsed.width;
        if (typeof parsed.height === 'number') circle.height = parsed.height;
        if (typeof parsed.borderWidth === 'number') circle.borderWidth = parsed.borderWidth;
        if (typeof parsed.borderRadius === 'number') circle.borderRadius = parsed.borderRadius;
      }
      const savedSquare = localStorage.getItem(STORAGE_KEY_SQUARE);
      if (savedSquare) {
        const parsed = JSON.parse(savedSquare);
        if (typeof parsed.left === 'number') square.left = parsed.left;
        if (typeof parsed.bottom === 'number') square.bottom = parsed.bottom;
        if (typeof parsed.width === 'number') square.width = parsed.width;
        if (typeof parsed.height === 'number') square.height = parsed.height;
        if (typeof parsed.borderWidth === 'number') square.borderWidth = parsed.borderWidth;
        if (typeof parsed.borderRadius === 'number') square.borderRadius = parsed.borderRadius;
      }
    }
  } catch (_) {}

  return { circle, square };
}

function createMapCoordStore() {
  const { subscribe, set, update } = writable(getInitialCoords());

  return {
    subscribe,
    set,
    update,
    updateSquare: (coords: Partial<typeof DEFAULT_SQUARE_CONFIG>) => {
      update((state) => {
        const updated = { ...state.square, ...coords };
        try {
          if (typeof localStorage !== 'undefined') {
            localStorage.setItem(STORAGE_KEY_SQUARE, JSON.stringify(updated));
          }
        } catch (_) {}
        return { ...state, square: updated };
      });
    },
    updateCircle: (coords: Partial<typeof DEFAULT_CIRCLE_CONFIG>) => {
      update((state) => {
        const updated = { ...state.circle, ...coords };
        try {
          if (typeof localStorage !== 'undefined') {
            localStorage.setItem(STORAGE_KEY_CIRCLE, JSON.stringify(updated));
          }
        } catch (_) {}
        return { ...state, circle: updated };
      });
    },
    reload: () => {
      set(getInitialCoords());
    }
  };
}

export const mapCoordStore = createMapCoordStore();
export default mapCoordStore;
