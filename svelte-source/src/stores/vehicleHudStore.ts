import { writable } from 'svelte/store'
import { capAmountToHundred } from '../types/types'

type vehicleStatusType = {
  fuelColor: string,
  altitude: number,
  fuel: number,
  speed: number,
  rpm: number,
  gear: string | number,
  engine: number,
  locked: boolean,
  headlight: boolean | string,
  seatbelt: boolean,
  show: boolean,
  showAltitude: boolean,
  showSeatBelt: boolean,
  showSquare: boolean,
  showSquareBorder: boolean,
  ShowCircle: boolean,
  showCircleBorder: boolean,
  seatbeltColor: string,
}

type vehicleHudUpdateMessageType = {
  show: boolean,
  isPaused: boolean,
  seatbelt: boolean,
  speed: number,
  fuel: number,
  rpm?: number,
  gear?: string | number,
  engine?: number,
  locked?: boolean,
  headlight?: boolean | string,
  altitude?: number,
  showAltitude?: boolean,
  showSeatbelt?: boolean,
  showSquareB?: boolean,
  showCircleB?: boolean, 
}

type vehicleHudShowMessage = {
  show: boolean,
  seatbelt: boolean,
}


const store = () => {

  const vehicleStatusState: vehicleStatusType = {
    fuelColor: "#FFFFFF",
    altitude: 0,
    fuel: 100,
    speed: 0,
    rpm: 0,
    gear: "N",
    engine: 1000,
    locked: false,
    headlight: false,
    seatbelt: false,
    show: false,
    showAltitude: false,
    showSeatBelt: false,
    showSquare: false,
    showSquareBorder: false,
    ShowCircle: false,
    showCircleBorder: false,
    seatbeltColor: "#e85b14",
  }

  const { subscribe, set, update } = writable(vehicleStatusState);

  const methods = {
    receiveShowMessage(data: vehicleHudShowMessage) {
      update(state => {
        state.show = data.show;
        state.seatbelt = data.seatbelt ?? false;
        state.showSeatBelt = !data.seatbelt;
        return state;
      })
    },
    receiveUpdateMessage(data: vehicleHudUpdateMessageType) {
      update(state => {
        state.show = data.show;
        state.speed = data.speed ?? 0;
        state.rpm = typeof data.rpm === 'number' ? data.rpm : 0;
        state.gear = data.gear !== undefined ? data.gear : "N";
        state.engine = typeof data.engine === 'number' ? data.engine : 1000;
        state.locked = data.locked === true;
        state.headlight = data.headlight ?? false;
        state.seatbelt = data.seatbelt === true;
        state.altitude = data.altitude ?? 0;
        state.fuel = capAmountToHundred(data.fuel ?? 100);
        state.showSeatBelt = !data.seatbelt;
        state.showAltitude = data.showAltitude ?? false;
        state.showSquareBorder = data.showSquareB ?? false;
        state.showCircleBorder = data.showCircleB ?? false;

        if (state.fuel <= 20) {
          state.fuelColor = "#ff0000";
        } else if (state.fuel <= 30) {
          state.fuelColor = "#dd6e14";
        } else {
          state.fuelColor = "#FFFFFF";
        }

        if (data.isPaused) {
          state.show = false;
        }

        return state;
      });
    }
  }

  return {
    subscribe,
    set,
    update,
    ...methods
  }
}

export default store();