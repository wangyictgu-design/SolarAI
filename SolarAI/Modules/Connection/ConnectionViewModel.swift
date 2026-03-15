import Foundation
import UIKit
import CoreBluetooth

protocol ConnectionViewModelDelegate: AnyObject {
    func didStartScanning()
    func didStopScanning()
    func didDiscoverDevice(at index: Int)
    func didUpdateRefreshCount(_ count: Int)
    func didStartConnecting()
    func didConnectSuccessfully(deviceName: String)
    func didFailToConnect(error: String)
    func didBluetoothStateChange(isAvailable: Bool, message: String?)
}

/// ViewModel for the connection/login screen.
/// Uses CoreBluetooth to discover SSE-prefixed BLE devices,
/// then guides user to connect to the matching WiFi SSID.
final class ConnectionViewModel {

    weak var delegate: ConnectionViewModelDelegate?

    private let bluetoothManager = BluetoothManager.shared
    private let wifiManager = WiFiManager.shared

    /// Only SSE-prefixed devices from BLE scan
    private(set) var sseDevices: [BluetoothDevice] = []
    private(set) var selectedDevice: BluetoothDevice?
    private(set) var isConnecting = false

    init() {
        bluetoothManager.delegate = self
    }

    // MARK: - Scanning

    func refreshDeviceList() {
        sseDevices.removeAll()
        selectedDevice = nil
        delegate?.didUpdateRefreshCount(0)
        delegate?.didStartScanning()
        bluetoothManager.startScanning()
    }

    func stopScanning() {
        bluetoothManager.stopScanning()
        delegate?.didStopScanning()
    }

    // MARK: - Device Selection

    func selectDevice(at index: Int) {
        guard index < sseDevices.count else { return }
        selectedDevice = sseDevices[index]
    }

    // MARK: - Connection

    func connect(ssid: String, password: String, from viewController: UIViewController) {
        guard !ssid.isEmpty else {
            delegate?.didFailToConnect(error: "Please select a device from the list first.\nTap \"Refresh the BT List\" to find devices.")
            return
        }

        isConnecting = true
        delegate?.didStartConnecting()

        wifiManager.connect(ssid: ssid, password: password, from: viewController) { [weak self] result in
            guard let self = self else { return }
            self.isConnecting = false

            switch result {
            case .success:
                self.delegate?.didConnectSuccessfully(deviceName: ssid)
            case .failure(let error):
                self.delegate?.didFailToConnect(error: error.localizedDescription)
            }
        }
    }
}

// MARK: - BluetoothManagerDelegate

extension ConnectionViewModel: BluetoothManagerDelegate {

    func bluetoothManager(_ manager: BluetoothManager, didDiscoverDevice device: BluetoothDevice) {
        // Only keep devices whose name starts with "SSE"
        guard device.name.hasPrefix("SSE") else { return }

        if !sseDevices.contains(where: { $0.name == device.name }) {
            sseDevices.append(device)
            let index = sseDevices.count - 1
            delegate?.didDiscoverDevice(at: index)
            delegate?.didUpdateRefreshCount(sseDevices.count)
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didUpdateState state: CBManagerState) {
        switch state {
        case .poweredOn:
            delegate?.didBluetoothStateChange(isAvailable: true, message: nil)
        case .poweredOff:
            delegate?.didBluetoothStateChange(isAvailable: false, message: "Please turn on Bluetooth to search for devices.")
        case .unauthorized:
            delegate?.didBluetoothStateChange(isAvailable: false, message: "Bluetooth permission denied. Please enable it in Settings.")
        case .unsupported:
            delegate?.didBluetoothStateChange(isAvailable: false, message: "This device does not support Bluetooth.")
        default:
            break
        }
    }

    func bluetoothManager(_ manager: BluetoothManager, didFailWithError error: Error) {
        delegate?.didFailToConnect(error: "Bluetooth error: \(error.localizedDescription)")
    }
}
