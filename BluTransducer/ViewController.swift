//
//  ViewController.swift
//  BluTransducer
//
//  Created by David Kopp on 6/21/18.
//  Copyright © 2018 Validyne. All rights reserved.
//

// MARK: - This class is the main view controller for the application.

import UIKit
import CoreBluetooth
import UICircularProgressRing

// MARK: - This Class is the Select View that allows the user to select which rfduino/transducer to connect to.
class SelectView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {


    @IBOutlet weak var pickerView: UIPickerView!
    @IBAction func connectButton(_ sender: UIButton) {
        refreshTimer.invalidate() // Stops refresh pickerView calls
        BLE.sharedInstance.connect(device: rduinoPeripheral) // Connects to device user selects from picker
        self.performSegue(withIdentifier: "PressureSegue", sender: self) // manual segue to pressure view
    }
    @IBOutlet weak var connectBTN: UIButton!
    
    var rduinoPeripheral: CBPeripheral!
    var refreshTimer: Timer!
    var statusBarHidden = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //UIApplication.shared.isStatusBarHidden = false
        
        //connectBTN.alpha = 0.5
        //connectBTN.isEnabled = false
        BLE.sharedInstance.start()
        self.pickerView.dataSource = self
        self.pickerView.delegate = self
        // Refreshes the picker to show user new found devices
        self.refreshTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.reloadPicker), userInfo: nil, repeats: true)
    }
    
    // MARK: - Resets the connect btn to starting state to make sure user selects a device
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        connectBTN.alpha = 0.5
        connectBTN.isEnabled = false
        self.pickerView.selectRow(0, inComponent: 0, animated: false)
        self.pickerView(self.pickerView, didSelectRow: 0, inComponent: 0)
    }
    
    // MARK: - Shows the Status Bar
    override var prefersStatusBarHidden: Bool {
        return statusBarHidden
    }
    
    // MARK: - Hides the status bar saving for future (has to be done on every view class)
    /* statusBarHidden = true
    setNeedsStatusBarAppearanceUpdate() */
    
    // MARK: - PickerView protocol conformance
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return BLE.sharedInstance.listDevices.count + 1
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return BLE.sharedInstance.listDevices[row - 1].name!
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 40.0
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row >= 1 {
            let peripheralSelected = BLE.sharedInstance.listDevices[pickerView.selectedRow(inComponent: 0) - 1]
            rduinoPeripheral = peripheralSelected
            print("Selected Device: " + peripheralSelected.name!)
            connectBTN.alpha = 1.0
            connectBTN.isEnabled = true
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var label = UILabel()
        if row >= 1 {
            if let v = view as? UILabel { label = v }
            label.font = label.font.withSize(32.0)
            label.text = BLE.sharedInstance.listDevices[row - 1].name
            label.textAlignment = .center
            //return label
        }
        return label
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /// This function reloads the pickerView when it is not empty(prevents crashing)
    @objc func reloadPicker() {
        //print("Trying to Refresh PickerView")
        if pickerView != nil {
            self.pickerView.reloadAllComponents()
        } else {
            print("PickerView is NIL")
        }
    }
}

// MARK: - This is the pressure view controller that shows the user the data from the transducer via bluetooth(rfDuino). This class is also using the UICircularProgressRing Library by Luis Padron github.com/luispadron/UICircularProgressRing
class PressureView: UIViewController {
    @IBOutlet weak var progressRing: UICircularProgressRing! // UICircularProgressRing Library
    @IBOutlet weak var modelNumber: UILabel!
    @IBOutlet weak var serialNumber: UILabel!
    @IBOutlet weak var maxScale: UILabel!
    @IBOutlet weak var temperature: UILabel!
    @IBOutlet weak var lastCalibrated: UILabel!
    @IBOutlet weak var progressValue: UILabel!
    @IBAction func calibrateButton(_ sender: Any) {
        timer.invalidate() // Stops the timer that gets data from the BLE service
        tempTimer.invalidate() // Stops the timer that sends the command to the transducer to get Temperature
        self.performSegue(withIdentifier: "Calibration", sender: self) // Manual Segue to the calibration view
    }
    
    var timer: Timer!
    var tempTimer: Timer!
    var fullScaleTolerance = CGFloat()
    var currentUnits = String()
    var deviceFullScale = CGFloat()
    var deviceUnits = String()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ProgressView.shared.showProgressView(whiteBackground: false) // Show loading View
        let rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "ic_menu_settings"), style: .done, target: self, action: #selector(openSettings)) // Navigation button for settings only visible on pressure view
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
        
        progressRing.ringStyle = UICircularProgressRingStyle.ontop
    }
    
    /// This function starts the timers to get data from the transducer and to send the temperature command to get said data from the transducer's sensor
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.getData), userInfo: nil, repeats: true) // Timer to get data that is being sent by the transducer and its pressure sensor
        self.tempTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.getTemp), userInfo: nil, repeats: true) // Timer to send the temperature command and to get that data from the tranducer's sensor
    }
    
    /// This function disconnects and stops timers if the back button is pressed(go back to select device scene)
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            BLE.sharedInstance.disconnect()
            timer.invalidate()
            tempTimer.invalidate()
        }
    }
    
    // MARK: - This function parses the data from the rfDuino/Transducer and displays the data for the user
    @objc private func getData() {
        var dataString = String()
        dataString = BLE.sharedInstance.rfDuinoData // Data string that the rfDuino/Tranducer is sending
        let dataStringArray = dataString.components(separatedBy: "*")
        
        /* Data String translation:
         M = Model Number of Transducer
         N = Serial Number of Transducer
         D = Date of last Calibration of Transducer
         F = Full Scale in calibrated units of Transducer
         T = Temperature of Transducer
         P = Current Pressure in calibrated units of Transducer
         */
        if dataStringArray[0] == "M" {
            modelNumber.text = dataStringArray[1]
        } else if dataStringArray[0] == "N" {
            serialNumber.text = dataStringArray[1]
        } else if dataStringArray[0] == "D" {
            lastCalibrated.text = dataStringArray[1]
        } else if dataStringArray[0] == "F" {
            var scale: CGFloat = NumberFormatter().number(from: dataStringArray[1]) as! CGFloat
            var units: String = UnitConversionHelper.shared.getUnits(string: dataStringArray[2])
            deviceFullScale = scale
            deviceUnits = units
            
            // Set UserDefaults "DefaultUnits" for first time connections
            if UserDefaults.standard.string(forKey: "DefaultUnits") == nil {
                UserDefaults.standard.set(units, forKey: "DefaultUnits")
            }
            if UserDefaults.standard.string(forKey: "DefaultUnits") != units {
                scale = UnitConversionHelper.shared.convertUnits(factoryUnits: units, convertToUnits: UserDefaults.standard.string(forKey: "DefaultUnits")!, currentPressure: scale)
                units = UserDefaults.standard.string(forKey: "DefaultUnits")!
            }
            
            maxScale.text = UnitConversionHelper.shared.significantFigures(pressure: scale) + " " + units // Display to user (Fullscale)
            scale = NumberFormatter().number(from: dataStringArray[1]) as! CGFloat
            fullScaleTolerance = 1.1 * scale // Full Scale has a tolerence of 10% above Full Scale - This might be changed/removed
        } else if dataStringArray[0] == "T" {
            var temp = String()
            // Checks to see if the user wants to view temperature as Celsius or its default units fahrenheit
            if UserDefaults.standard.bool(forKey: "ShowCelsius") {
                temp = "°C"
                let dataTemp = NumberFormatter().number(from: dataStringArray[1]) as! CGFloat
                let conversionTemp = (dataTemp - 32) * 5/9
                temperature.text = String(format: "%.1f", conversionTemp) + " " + temp
            } else {
                temp = "°F"
                temperature.text = dataStringArray[1] + " " + temp
            }
            ProgressView.shared.hideProgressView() // Hide Progress View - screen has finished loading all data
        } else if dataStringArray[0] == "P" {
            if UserDefaults.standard.string(forKey: "DefaultUnits") != nil {
            var units = String()
            units = UnitConversionHelper.shared.getUnits(string: dataStringArray[2])
            var pressure = CGFloat()
            pressure = NumberFormatter().number(from: dataStringArray[1]) as! CGFloat
            // As long as the full scale has been recieved from Transducer the set the value of the progress ring
            if fullScaleTolerance > 0.0 {
                progressRing.value = getPercent(value: pressure)
            }
            updateRingColor(value: progressRing.currentValue!) // Update color of the progress ring to indicate current pressure percent of full scale + tolerance range. (Green = OK, Orange = High, Red = Very High)
            // Check to see if the user has selected a different pressure units to be displayed than the Tranducer's calibated units
            if UserDefaults.standard.string(forKey: "DefaultUnits") != units {
                pressure = UnitConversionHelper.shared.convertUnits(factoryUnits: units, convertToUnits: UserDefaults.standard.string(forKey: "DefaultUnits")!, currentPressure: pressure)
                units = UserDefaults.standard.string(forKey: "DefaultUnits")!
            }
            
            // Book keeping to make sure the deviceUnits has been set
            if deviceUnits != "" && UserDefaults.standard.string(forKey: "DefaultUnits") != nil {
                updateFullScale()
            }
            
            progressValue.text = UnitConversionHelper.shared.significantFigures(pressure: pressure) + " " + units
        }
        }
    }
    
    // MARK: - Function that sends data to the rfDuino for the reading on the Transducer's temperature sensor(note: This sensor is not very accurate)
    @objc private func getTemp() {
        if BLE.sharedInstance.sendCharacteristic != nil {
            BLE.sharedInstance.writeValue(data: Data(bytes: [0x2]))
        }
    }
    
    // MARK: - Manual Segue to the settings view
    @objc private func openSettings() {
        performSegue(withIdentifier: "settingsView", sender: self)
    }
    
    // MARK: - Function that updates full scale units if the user picks a different pressure units to be displayed
    private func updateFullScale() {
            let units = UserDefaults.standard.string(forKey: "DefaultUnits")!
            let pressure = UnitConversionHelper.shared.convertUnits(factoryUnits: deviceUnits, convertToUnits: units, currentPressure: deviceFullScale)
            let fullScalePressure = UnitConversionHelper.shared.significantFigures(pressure: pressure) + " " + units
        
        if fullScalePressure != maxScale.text {
            maxScale.text = fullScalePressure
        } else { }
    }
    
    // MARK: - Returns the percent of pressure based on the full scale + sensor tolerance
    private func getPercent(value: CGFloat) -> CGFloat {
        var temp = CGFloat()
        temp = abs((value / fullScaleTolerance) * 100.00)
        return temp
    }
    
    // MARK: - Updates the ring color based on current pressure percent
    private func updateRingColor(value: CGFloat) {
        if value < 40.00 {
            progressRing.innerRingColor = UIColor.green
        } else if value >= 40.00 && value < 75.00 {
            progressRing.innerRingColor = UIColor.orange
        } else {
            progressRing.innerRingColor = UIColor.red
        }
    }
}

// MARK: - This class is the calibration view
class CalibrationView: UIViewController {
    @IBOutlet weak var pressureLabel: UILabel!
    @IBAction func plusButton(_ sender: Any) {
        BLE.sharedInstance.writeValue(data: Data(bytes: [0x3]))
        ProgressView.shared.showProgressView(whiteBackground: false)
    }
    @IBAction func minusButton(_ sender: Any) {
        BLE.sharedInstance.writeValue(data: Data(bytes: [0x4]))
        ProgressView.shared.showProgressView(whiteBackground: false)
    }
    @IBAction func spanButton(_ sender: Any) {
        BLE.sharedInstance.writeValue(data: Data(bytes: [0x5]))
        ProgressView.shared.showProgressView(whiteBackground: false)
    }
    @IBAction func zeroButton(_ sender: Any) {
        BLE.sharedInstance.writeValue(data: Data(bytes: [0x6]))
        ProgressView.shared.showProgressView(whiteBackground: false)
    }
    @IBAction func restoreCalButton(_ sender: Any) {
        BLE.sharedInstance.writeValue(data: Data(bytes: [0x7]))
        ProgressView.shared.showProgressView(whiteBackground: false)
    }
    
    var timer: Timer!
    var alert: UIAlertController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(self.getData), userInfo: nil, repeats: true) // Timer to start getting data from the rfDuino/Transducer
    }
    
    // MARK: - Function that stops timer if the back button is pressed
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.isMovingFromParent {
            timer.invalidate()
        }
    }
    
    // MARK: - This function gets Data from the BLE service and parses it
    @objc private func getData() {
        var dataString = String()
        dataString = BLE.sharedInstance.rfDuinoData
        let dataStringArray = dataString.components(separatedBy: "*")
        
        // P= Pressure, + = Positive adjustment, - = Negitive Adjustment, S = Auto Span, Z = Zero Span, R = Restore Last Calibrated value
        if dataStringArray[0] == "P" {
            var currentPressure = NumberFormatter().number(from: dataStringArray[1]) as! CGFloat
            var units = UnitConversionHelper.shared.getUnits(string: dataStringArray[2])
            if UserDefaults.standard.string(forKey: "DefaultUnits") != units {
                currentPressure = UnitConversionHelper.shared.convertUnits(factoryUnits: units, convertToUnits: UserDefaults.standard.string(forKey: "DefaultUnits")!, currentPressure: currentPressure)
                units = UserDefaults.standard.string(forKey: "DefaultUnits")!
            }
            pressureLabel.text = UnitConversionHelper.shared.significantFigures(pressure: currentPressure) + " " + units
        } else if dataStringArray[0] == "+" {
            ProgressView.shared.hideProgressView()
        } else if dataStringArray[0] == "-" {
            ProgressView.shared.hideProgressView()
        } else if dataStringArray[0] == "S" {
            ProgressView.shared.hideProgressView()
        } else if dataStringArray[0] == "Z" {
            ProgressView.shared.hideProgressView()
        } else if dataStringArray[0] == "R" {
            ProgressView.shared.hideProgressView()
        }
    }
}

// MARK: - This class is the view controller for the settings scene
class SettingsView: UITableViewController {
    
    @IBOutlet weak var celsius: UISwitch!
    @IBOutlet weak var detailLabel: UILabel!
    // Sets the userdefaults showCelsius boolean to confirm that the user would like to use Celsius units for temperature
    @IBAction func celsiusOn(_ sender: UISwitch) {
        if celsius.isOn {
            UserDefaults.standard.set(true, forKey: "ShowCelsius")
        } else {
            UserDefaults.standard.set(false, forKey: "ShowCelsius")
        }
    }
    var units: String = UserDefaults.standard.string(forKey: "DefaultUnits")! {
        didSet {
            detailLabel.text = units
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if UserDefaults.standard.bool(forKey: "ShowCelsius") == true {
            celsius.setOn(true, animated: true)
        } else {
            celsius.setOn(false, animated: true)
        }
        detailLabel.text = UserDefaults.standard.string(forKey: "DefaultUnits")
    }
}

// This extension is to save and show the selected units to the user based on their selection from a view list from the UnitsPickerViewController
extension SettingsView {
    
    @IBAction func unwindWithSelectedUnits(seque: UIStoryboardSegue) {
        if let unitsPickerViewController = seque.source as? UnitsPickerViewController,
            let selectedUnits = unitsPickerViewController.selectedUnits {
            units = selectedUnits
            UserDefaults.standard.set(units, forKey: "DefaultUnits")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickUnits",
            let unitsPickerViewController = segue.destination as? UnitsPickerViewController {
            unitsPickerViewController.selectedUnits = units
        }
    }
}
