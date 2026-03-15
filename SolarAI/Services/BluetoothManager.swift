import Foundation
import CoreBluetooth

protocol BluetoothManagerDelegate: AnyObject {
    func bluetoothManager(_ manager: BluetoothManager, didDiscoverDevice device: BluetoothDevice)
    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState)
    func bluetoothManager(_ manager: BluetoothManager, didFailWithError error: Error)
}

/// 代表已發現的 BLE 裝置（太陽能逆變器）
struct BluetoothDevice {
    let name: String
    let peripheral: CBPeripheral
    let rssi: Int

    /// 裝置名稱同時作為 WiFi SSID 使用
    var wifiSSID: String { name }
}

/// 管理 CoreBluetooth 掃描以發現逆變器裝置
final class BluetoothManager: NSObject {

    static let shared = BluetoothManager()

    weak var delegate: BluetoothManagerDelegate?

    private var centralManager: CBCentralManager?
    private(set) var discoveredDevices: [BluetoothDevice] = []
    private(set) var isScanning = false

    private override init() {
        super.init()
    }

    // MARK: - 公開方法

    func startScanning() {
        discoveredDevices.removeAll()

        if centralManager == nil {
            centralManager = CBCentralManager(delegate: self, queue: .main)
        } else if centralManager?.state == .poweredOn {
            beginScan()
        }
    }

    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }

    // MARK: - 私有方法

    private func beginScan() {
        guard centralManager?.state == .poweredOn else { return }
        isScanning = true
        centralManager?.scanForPeripherals(withServices: nil, options: [
            CBCentralManagerScanOptionAllowDuplicatesKey: false
        ])

        // 15 秒後自動停止掃描
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) { [weak self] in
            self?.stopScanning()
        }
    }
}

// MARK: - CBCentralManagerDelegate 委派

extension BluetoothManager: CBCentralManagerDelegate {

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        delegate?.bluetoothManager(self, didUpdateState: central.state)

        if central.state == .poweredOn {
            beginScan()
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        guard let name = peripheral.name, !name.isEmpty else { return }

        // 避免重複
        if discoveredDevices.contains(where: { $0.peripheral.identifier == peripheral.identifier }) {
            return
        }

        let device = BluetoothDevice(name: name, peripheral: peripheral, rssi: RSSI.intValue)
        discoveredDevices.append(device)
        delegate?.bluetoothManager(self, didDiscoverDevice: device)
    }
}
