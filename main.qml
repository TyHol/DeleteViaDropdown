import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Theme
import org.qfield
import org.qgis

Item {
    property var mainWindow: iface.mainWindow()
    property var selectedLayer: null
    property var dashBoard: iface.findItemByObjectName('dashBoard')

    Component.onCompleted: {
        iface.addItemToPluginsToolbar(reloadButton)
    }

    // UI Components
    QfToolButton {
        id: reloadButton
        iconSource: 'icon.svg'
        iconColor: Theme.mainColor
        bgcolor: Theme.darkGray
        round: true

        onClicked: {
            updateLayers()
            layerSelectionDialog.open()
        }
    }

    Dialog {
        id: layerSelectionDialog
        parent: mainWindow.contentItem
        modal: true
        font: Theme.defaultFont
        standardButtons: Dialog.Ok | Dialog.Cancel
        title: qsTr("Layer Selection")
        width: Math.min(mainWindow.width * 0.8, 400)
        x: (mainWindow.width - width) / 2
        y: (mainWindow.height - height) / 2

        ColumnLayout {
            spacing: 10
            width: parent.width

            Label {
                id: labelSelection
                wrapMode: Text.Wrap
                Layout.fillWidth: true
            }

            QfComboBox {
                id: layerSelector
                Layout.fillWidth: true
                model: []
                enabled: model.length > 0
            }
        }

        onAccepted: {
            if (!layerSelector.currentText) return
            selectedLayer = getLayerByName(layerSelector.currentText)
            if (!selectedLayer) return

            if (delete_all_features(selectedLayer)) {
                mainWindow.displayToast(qsTr("Cleared layer: %1").arg(layerSelector.currentText))
            }
        }
    }

    // Layer Management Functions
    function updateLayers() {
        var layers = ProjectUtils.mapLayers(qgisProject)
        var editableLayers = []
        
        for (var id in layers) {
            var layer = layers[id]
            if (layer && layer.supportsEditing) {
                editableLayers.push(layer.name)
            }
        }
        
        editableLayers.sort()
        layerSelector.model = editableLayers
        layerSelector.currentIndex = editableLayers.length > 0 ? 0 : -1
        
        labelSelection.text = editableLayers.length > 0 
            ? qsTr("Select editable layer:") 
            : qsTr("No editable layers available")
    }

    function getLayerByName(name) {
        var layers = ProjectUtils.mapLayers(qgisProject)
        for (var id in layers) {
            if (layers[id].name === name) return layers[id]
        }
        return null
    }

    function delete_all_features(layer) {
        try {
            if (!layer.isEditable) layer.startEditing()
            layer.selectAll()
            var success = layer.deleteSelectedFeatures()
            if (success) {
                layer.commitChanges()
                return true
            }
            layer.rollBack()
            return false
        } catch (e) {
            if (layer.isEditable) layer.rollBack()
            mainWindow.displayToast(qsTr("Error: %1").arg(e.toString()))
            return false
        }
    }
}