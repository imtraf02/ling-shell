import QtQuick
import qs.commons
import qs.services

IText {
  id: root

  property string icon
  property real pointSize: Style.appearance.font.size.large
  property real fill
  property int grade: Settings.appearance.theme.mode === "light" ? 0 : -25

  visible: (icon !== undefined) && (icon !== "")
  text: {
    if ((icon === undefined) || (icon === "")) {
      return "";
    }
    return icon;
  }
  font.family: "Material Symbols Rounded"
  font.pointSize: root.pointSize
  font.weight: root.fill === 1 ? Font.DemiBold : Font.Medium
  color: ThemeService.palette.mOnSurface
  verticalAlignment: Text.AlignVCenter
  renderType: Text.NativeRendering

  font.variableAxes: {
    "FILL": fill.toFixed(1),
    "GRAD": grade,
    "opsz": fontInfo.pixelSize,
    "wght": fontInfo.weight
  }
}
