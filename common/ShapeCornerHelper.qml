pragma Singleton

import QtQuick
import Quickshell

Singleton {
  id: root

  function getMultX(cornerState) {
    return cornerState === 1 ? -1 : 1;
  }

  function getMultY(cornerState) {
    return cornerState === 2 ? -1 : 1;
  }

  function getArcDirection(multX, multY) {
    return ((multX < 0) !== (multY < 0)) ? PathArc.Counterclockwise : PathArc.Clockwise;
  }

  function getArcDirectionFromState(cornerState) {
    const multX = getMultX(cornerState);
    const multY = getMultY(cornerState);
    return getArcDirection(multX, multY);
  }

  function getFlattenedRadius(dimension, requestedRadius) {
    if (dimension < requestedRadius * 2) {
      return dimension / 2;
    }
    return requestedRadius;
  }

  function shouldFlatten(width, height, radius) {
    return width < radius * 2 || height < radius * 2;
  }
}
