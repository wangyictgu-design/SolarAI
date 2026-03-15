import Foundation

struct FaultDefinition {
    let code: String
    let description: String
    let solution: String
    let isWarning: Bool
}

/// 來自警報說明表的錯誤/警告位元定義
enum ErrorDefinitions {

    // MARK: - 錯誤訊息 1（控制碼 25261）

    static let error1: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SE001",
            description: "Fan is locked when inverter is off",
            solution: "1. Check if the fan is properly connected and whether there is anything blocking it.\n2. Replace the fan.\n3. If the problem persists after replacing the fan, check the motherboard.",
            isWarning: false
        ),
        1: FaultDefinition(
            code: "SE002",
            description: "Inverter transformer over temperature",
            solution: "1. Check if the fan is working properly and if there is any foreign object at the air outlet.\n2. Connect to the host computer to check the machine's temperature.",
            isWarning: false
        ),
        2: FaultDefinition(
            code: "SE003",
            description: "Battery voltage is too high",
            solution: "1. Check if the battery voltage is normal.\n2. Check if there is any deviation between the battery voltage displayed by the inverter and the actual battery voltage.\n3. For PV18-VPM II/PREM/ECO models, check if the L/N of the grid power is reversed.",
            isWarning: false
        ),
        3: FaultDefinition(
            code: "SE004",
            description: "Battery voltage is too low",
            solution: "1. Before powering on, check if the battery voltage is already too low.\n2. Check if the load is too heavy.\n3. Check if the battery voltage displayed by the inverter is really very low.\n4. Check battery contact and wire size.",
            isWarning: false
        ),
        4: FaultDefinition(
            code: "SE005",
            description: "Output short circuited",
            solution: "1. Check if there is a short circuit at the output terminal.\n2. Remove the load, then restart.\n3. Check if there is a short circuit in the load itself.",
            isWarning: false
        ),
        5: FaultDefinition(
            code: "SE006",
            description: "Inverter output voltage is high",
            solution: "1. If output voltage exceeds 253V for 5 seconds, alarm triggers.\n2. In mains mode, check actual mains input voltage.\n3. In battery mode, compare displayed vs actual output voltage.",
            isWarning: false
        ),
        6: FaultDefinition(
            code: "SE007",
            description: "Overload time out",
            solution: "1. Check the load power.\n2. Reduce the load.\n3. Check whether the AC output is directly connected to the power grid.",
            isWarning: false
        ),
        7: FaultDefinition(
            code: "SE008",
            description: "Inverter bus voltage is too high",
            solution: "1. Check lithium battery BMS protection.\n2. Check PV input voltage.\n3. Check mains input voltage.\n4. Repair inverter if using lead-acid batteries.",
            isWarning: false
        ),
        8: FaultDefinition(
            code: "SE009",
            description: "Bus soft start failed",
            solution: "1. Check if the battery voltage is normal.\n2. Check if the PV input voltage is normal.\n3. The inverter needs to be repaired.\n4. Check if the load is short-circuited.",
            isWarning: false
        ),
        9: FaultDefinition(
            code: "SE010",
            description: "Main relay failed",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        10: FaultDefinition(
            code: "SE011",
            description: "Inverter output voltage sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        11: FaultDefinition(
            code: "SE012",
            description: "Inverter grid voltage sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        12: FaultDefinition(
            code: "SE013",
            description: "Inverter output current sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        13: FaultDefinition(
            code: "SE014",
            description: "Inverter grid current sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        14: FaultDefinition(
            code: "SE015",
            description: "Inverter load current sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        15: FaultDefinition(
            code: "SE016",
            description: "Inverter grid over current error",
            solution: "1. Check the load power.\n2. Reduce the load.",
            isWarning: false
        )
    ]

    // MARK: - 錯誤訊息 2（控制碼 25262）

    static let error2: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SE017",
            description: "Inverter radiator over temperature",
            solution: "1. Check if the load is too heavy.\n2. Verify radiator wiring.\n3. Check actual machine temperature.\n4. Check NTC sensor.\n5. Check dust filter.",
            isWarning: false
        ),
        1: FaultDefinition(
            code: "SE018",
            description: "Solar charger battery voltage class error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        2: FaultDefinition(
            code: "SE019",
            description: "Solar charger current sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        3: FaultDefinition(
            code: "SE020",
            description: "Solar charger current is uncontrollable",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        4: FaultDefinition(
            code: "SE021",
            description: "Inverter grid voltage is low",
            solution: "1. If input voltage is lower than 170V, wait for grid voltage to recover.\n2. If grid voltage is normal but machine shows low voltage, repair inverter.",
            isWarning: false
        ),
        5: FaultDefinition(
            code: "SE022",
            description: "Inverter grid voltage is high",
            solution: "1. If input voltage is higher than 280V, wait for grid voltage to recover.\n2. If grid voltage is normal but machine shows issues, repair inverter.",
            isWarning: false
        ),
        6: FaultDefinition(
            code: "SE023",
            description: "Inverter grid under frequency",
            solution: "If input frequency is lower than 40.5Hz, wait for grid to stabilize.",
            isWarning: false
        ),
        7: FaultDefinition(
            code: "SE024",
            description: "Inverter grid over frequency",
            solution: "If input frequency is higher than 60.5Hz, wait for grid to stabilize.",
            isWarning: false
        ),
        8: FaultDefinition(
            code: "SE025",
            description: "Inverter over current protection error",
            solution: "1. Check if the load is too heavy.\n2. Verify RCD load.\n3. Check for short circuit in load.\n4. Check inductive load power vs inverter rating.",
            isWarning: false
        ),
        9: FaultDefinition(
            code: "SE026",
            description: "Inverter bus voltage is too low",
            solution: "1. Check if the load is too heavy.\n2. Check battery voltage.\n3. Check PV input power.\n4. The inverter needs to be repaired.",
            isWarning: false
        ),
        10: FaultDefinition(
            code: "SE027",
            description: "Inverter soft start failed",
            solution: "1. Check if the load is too heavy.\n2. Check battery voltage.\n3. Check PV input power.\n4. The inverter needs to be repaired.",
            isWarning: false
        ),
        11: FaultDefinition(
            code: "SE028",
            description: "Over DC voltage in AC output",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        12: FaultDefinition(
            code: "SE029",
            description: "Battery connection is open",
            solution: "1. Check if the battery is properly connected.\n2. Check if the load is too heavy.\n3. Check battery terminal breaker.\n4. Check battery fuse.\n5. Check battery wire size.",
            isWarning: false
        ),
        13: FaultDefinition(
            code: "SE030",
            description: "Inverter control current sensor error",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        14: FaultDefinition(
            code: "SE031",
            description: "Inverter output voltage is too low",
            solution: "1. Check if the load is too heavy.\n2. Check battery voltage and PV input.\n3. In mains mode, check mains voltage.\n4. In battery mode, compare displayed vs actual output voltage.",
            isWarning: false
        )
    ]

    // MARK: - 錯誤訊息 3（控制碼 25263）— 並聯相關

    static let error3: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SE040",
            description: "CanFail",
            solution: "1. Check if the communication cables are properly connected and restart the inverter.\n2. If the problem persists, please contact your installer.",
            isWarning: false
        ),
        1: FaultDefinition(
            code: "SE041",
            description: "HostLoss",
            solution: "1. Check if the communication cables are properly connected and restart the inverter.\n2. If the problem persists, please contact your installer.",
            isWarning: false
        ),
        2: FaultDefinition(
            code: "SE042",
            description: "PhaseSynLoss",
            solution: "1. Check if the communication cables are properly connected and restart the inverter.\n2. If the problem persists, please contact your installer.",
            isWarning: false
        ),
        3: FaultDefinition(
            code: "SE043",
            description: "BattVolDiff",
            solution: "1. Make sure all inverters share the same battery bank.\n2. If the problem persists, please contact your installer.",
            isWarning: false
        ),
        4: FaultDefinition(
            code: "SE044",
            description: "GridInputDiff",
            solution: "1. Check the public line connection and restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        5: FaultDefinition(
            code: "SE045",
            description: "CurUnblance",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        6: FaultDefinition(
            code: "SE046",
            description: "OutputModeDiff",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        7: FaultDefinition(
            code: "SE047",
            description: "PowerFeedbackFail",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        8: FaultDefinition(
            code: "SE048",
            description: "FirmwareDiff",
            solution: "1. Update the firmware of all inverters to the same version.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        9: FaultDefinition(
            code: "SE049",
            description: "CurShareFail",
            solution: "1. Check if the communication cables are properly connected, and then restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        10: FaultDefinition(
            code: "SE050",
            description: "IDFail",
            solution: "1. Shut down the inverter and check the DIP switch settings.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        15: FaultDefinition(
            code: "SE051",
            description: "ParaError",
            solution: "1. Check if the settings parameters are consistent.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        )
    ]

    // MARK: - 警告訊息 1（控制碼 25265）

    static let warn1: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SW001",
            description: "Fan is locked when inverter is on",
            solution: "1. Check if the fan is properly connected and whether there is anything blocking it.\n2. Replace the fan.\n3. If the problem persists, check the motherboard.",
            isWarning: true
        ),
        1: FaultDefinition(
            code: "SW002",
            description: "Fan2 is locked when inverter is on",
            solution: "1. Check if the fan is properly connected and whether there is anything blocking it.\n2. Replace the fan.\n3. If the problem persists, check the motherboard.",
            isWarning: true
        ),
        2: FaultDefinition(
            code: "SW003",
            description: "Battery is over-charged",
            solution: "1. If caused by PV charging, check PV input and settings.\n2. If caused by mains charging, check mains input and settings.\n3. May be an internal machine problem.",
            isWarning: true
        ),
        3: FaultDefinition(
            code: "SW004",
            description: "Low battery",
            solution: "Check if the battery voltage is really very low. If so, charge it.",
            isWarning: true
        ),
        4: FaultDefinition(
            code: "SW005",
            description: "Overload",
            solution: "Reduce the load.",
            isWarning: true
        ),
        5: FaultDefinition(
            code: "SW006",
            description: "Output power derating",
            solution: "The inverter needs to be repaired.",
            isWarning: true
        ),
        6: FaultDefinition(
            code: "SW007",
            description: "Solar charger stops due to low battery",
            solution: "1. Check if the battery voltage is really very low.\n2. Check PV charging voltage vs battery voltage deviation.",
            isWarning: true
        ),
        7: FaultDefinition(
            code: "SW008",
            description: "Solar charger stops due to high PV voltage",
            solution: "1. Check if the PV voltage is above the machine's standard range.\n2. Check if the PV is connected in reverse.",
            isWarning: true
        ),
        8: FaultDefinition(
            code: "SW009",
            description: "Solar charger stops due to over load",
            solution: "The inverter needs to be repaired.",
            isWarning: true
        ),
        9: FaultDefinition(
            code: "SW010",
            description: "Solar charger over temperature",
            solution: "1. Check air outlet for foreign objects or if the fan has stopped.\n2. Check if the PV panel sensor is loose or damaged.",
            isWarning: true
        ),
        10: FaultDefinition(
            code: "SW011",
            description: "PV charger communication error",
            solution: "1. Restore factory settings.\n2. If customizing parameters, follow the logical principles.",
            isWarning: true
        )
    ]

    // MARK: - 警告訊息 2（預留擴充）

    static let warn2: [Int: FaultDefinition] = [:]

    // MARK: - 充電器錯誤（控制碼 15213/16213）

    static let chargerError: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SE032",
            description: "Hardware protection",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        1: FaultDefinition(
            code: "SE033",
            description: "Over current",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        2: FaultDefinition(
            code: "SE034",
            description: "Current sensor error",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        3: FaultDefinition(
            code: "SE035",
            description: "Over temperature",
            solution: "1. Check if the fan is working properly.\n2. Connect to host computer to check temperature.",
            isWarning: false
        ),
        4: FaultDefinition(
            code: "SE036",
            description: "PV voltage is too high",
            solution: "1. Check if the voltage is normal.\n2. Reduce the PV input power.",
            isWarning: false
        ),
        5: FaultDefinition(
            code: "SE032",
            description: "PV voltage is too low",
            solution: "1. Check the PV connection.\n2. Increase the PV input power.",
            isWarning: false
        ),
        6: FaultDefinition(
            code: "SE037",
            description: "Battery voltage is too high",
            solution: "1. Check if the battery voltage is normal.\n2. Compare inverter display vs actual battery voltage.",
            isWarning: false
        ),
        7: FaultDefinition(
            code: "SE038",
            description: "Battery voltage is too low",
            solution: "1. Check if the battery voltage is too low.\n2. Check if the load is too heavy.\n3. Check battery contact and wire size.",
            isWarning: false
        ),
        8: FaultDefinition(
            code: "SE039",
            description: "Current is uncontrollable",
            solution: "The inverter needs to be repaired.",
            isWarning: false
        ),
        9: FaultDefinition(
            code: "SE040",
            description: "Parameter error",
            solution: "1. Restore factory settings.\n2. If the problem persists, contact the installer.",
            isWarning: false
        ),
        10: FaultDefinition(
            code: "SE041",
            description: "Over current2",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        11: FaultDefinition(
            code: "SE042",
            description: "Current sensor error2",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        12: FaultDefinition(
            code: "SE043",
            description: "PV2 voltage is too high",
            solution: "1. Check if the voltage is normal.\n2. Reduce the photovoltaic input power.",
            isWarning: false
        ),
        13: FaultDefinition(
            code: "SE044",
            description: "PV2 voltage is too low",
            solution: "1. Check the PV connection.\n2. Increase the PV input power.",
            isWarning: false
        ),
        14: FaultDefinition(
            code: "SE045",
            description: "Current is uncontrollable2",
            solution: "1. Restart the inverter.\n2. If the problem persists, please contact the installer.",
            isWarning: false
        ),
        15: FaultDefinition(
            code: "SE046",
            description: "CommTimeOut",
            solution: "1. Is the battery turned on.\n2. Are the communication lines connected correctly.\n3. Has option 37 been set to SOC mode.",
            isWarning: false
        )
    ]

    // MARK: - 充電器警告（控制碼 15214/16214）

    static let chargerWarn: [Int: FaultDefinition] = [
        0: FaultDefinition(
            code: "SW012",
            description: "Fan Error",
            solution: "1. Check if the fan is properly connected and whether there is anything blocking it.\n2. Replace the fan.\n3. If the problem persists, check the motherboard.",
            isWarning: true
        )
    ]
}
