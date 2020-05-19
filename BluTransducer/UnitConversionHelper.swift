//
//  UnitConversionHelper.swift
//  BluTransducer
//
//  Created by David Kopp on 9/6/18.
//  Copyright © 2018 Validyne. All rights reserved.
//

/// MARK: - This class contains helper methods that is used for conversions of different units.

import UIKit

public class UnitConversionHelper {
    
    // MARK: Shared Instance
    static let shared = UnitConversionHelper()
    
    /// This function changes the displayed units to the proper style that users expect to see. The Transducer does not always use the standard style of presenting unit abbreviations and returns it as a string.
    public func getUnits(string: String) -> String {
        let temp = string.lowercased()
        let units = String(temp.filter {!"\r\0 ".contains($0)})
        //print(units)
        if units == "psi" {
            return "psi"
        } else if units == "inhg" {
            return "inHG"
        } else if units == "inh2o" {
            return "inH2O"
        } else if units == "fth20" {
            return "ftH2O"
        } else if units == "mmh2o" {
            return "mmH2O"
        } else if units == "cmh2o" {
            return "cmH2O"
        } else if units == "mh20" {
            return "mH2O"
        } else if units == "mtorr" {
            return "mTorr"
        } else if units == "torr" {
            return "Torr"
        } else if units == "atm" {
            return "atm"
        } else if units == "mbar" {
            return "mbar"
        } else if units == "bar" {
            return "bar"
        } else if units == "pa" {
            return "Pa"
        } else if units == "kpa" {
            return "kPa"
        } else if units == "mpa" {
            return "MPa"
        } else {
            return ""
        }
    }
    
    /// This function styles the unit output to be more readable. It also aligns with showing only significant figures and returns it as a string.
    public func significantFigures(pressure: CGFloat) -> String {
        //print("Pressure is: \(pressure)")
        if abs(pressure) >= 1000 {
             return String(format: "%.0f", pressure)
        } else if abs(pressure) >= 100 && pressure < 1000 {
            return String(format: "%.1f", pressure)
        } else if abs(pressure) >= 10 && pressure < 100 {
            return String(format: "%.2f", pressure)
        } else if abs(pressure) >= 1 && pressure < 10 {
            return String(format: "%.3f", pressure)
        } else if abs(pressure) < 1 {
            return String(format: "%.4f", pressure)
        } else {
            return "Error: SigFig"
        }
    }
    
    /// This function converts the transducer output to the user specified units from the device's calibrated units and returns the value as a CGFloat.
    public func convertUnits(factoryUnits: String, convertToUnits: String, currentPressure: CGFloat) -> CGFloat {
        var convertedValue = CGFloat()
        var convertToPSI = CGFloat()
        
        if factoryUnits == "psi" {
            convertToPSI = 1.0
        } else if factoryUnits == "inHG" {
            convertToPSI = 0.4897707
        } else if factoryUnits == "inH2O" {
            convertToPSI = 0.03606233
        } else if factoryUnits == "ftH2O" {
            convertToPSI = 0.4327480
        } else if factoryUnits == "mmH2O" {
            convertToPSI = 0.001419777
        } else if factoryUnits == "cmH2O" {
            convertToPSI = 0.01419777
        } else if factoryUnits == "mH2O" {
            convertToPSI = 1.419777
        } else if factoryUnits == "mTorr" {
            convertToPSI = 0.00001933672
        } else if factoryUnits == "Torr" {
            convertToPSI = 0.01933672
        } else if factoryUnits == "atm" {
            convertToPSI = 14.69595
        } else if factoryUnits == "mbar" {
            convertToPSI = 0.01450377
        } else if factoryUnits == "bar" {
            convertToPSI = 14.50377
        } else if factoryUnits == "Pa" {
            convertToPSI = 0.0001450377
        } else if factoryUnits == "kPa" {
            convertToPSI = 0.1450377
        } else if factoryUnits == "MPa" {
            convertToPSI = 145.0377
        } else {
            return 0.00
        }
        
        if convertToUnits == "psi" {
            convertedValue = convertToPSI * currentPressure * 1.0
        } else if convertToUnits == "inHG" {
            convertedValue = convertToPSI * currentPressure * 2.041772
        } else if convertToUnits == "inH2O" {
            convertedValue = convertToPSI * currentPressure * 27.72977
        } else if convertToUnits == "ftH2O" {
            convertedValue = convertToPSI * currentPressure * 2.310814
        } else if convertToUnits == "mmH2O" {
            convertedValue = convertToPSI * currentPressure * 704.336
        } else if convertToUnits == "cmH2O" {
            convertedValue = convertToPSI * currentPressure * 70.4336
        } else if convertToUnits == "mH2O" {
            convertedValue = convertToPSI * currentPressure * 0.704336
        } else if convertToUnits == "mTorr" {
            convertedValue = convertToPSI * currentPressure * 51715.08
        } else if convertToUnits == "Torr" {
            convertedValue = convertToPSI * currentPressure * 51.71508
        } else if convertToUnits == "atm" {
            convertedValue = convertToPSI * currentPressure * 0.06804596
        } else if convertToUnits == "mbar" {
            convertedValue = convertToPSI * currentPressure * 68.94757
        } else if convertToUnits == "bar" {
            convertedValue = convertToPSI * currentPressure * 0.06894757
        } else if convertToUnits == "Pa" {
            convertedValue = convertToPSI * currentPressure * 6894.757
        } else if convertToUnits == "kPa" {
            convertedValue = convertToPSI * currentPressure * 6.894757
        } else if convertToUnits == "MPa" {
            convertedValue = convertToPSI * currentPressure * 0.006894757
        } else {
            return 0.00
        }
        
        return convertedValue
    }
}
