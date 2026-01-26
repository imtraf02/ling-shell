import QtQuick
import qs.common
import qs.services
import qs.widgets

IText {
  id: root

  required property string icon

  text: icon
  font.family: "Material Symbols Rounded"
  font.pointSize: Style.font.size.large
  font.weight: Font.Normal
  color: ThemeService.palette.mOnSurface
  verticalAlignment: Text.AlignVCenter
  renderType: Text.NativeRendering
}
