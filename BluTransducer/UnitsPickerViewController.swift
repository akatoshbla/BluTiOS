//
//  UnitsPickerViewController.swift
//  BluTransducer
//
//  Created by David Kopp on 7/31/18.
//  Copyright © 2018 Validyne. All rights reserved.
//

// MARK: - This class sets up the settings view picker(table view).

import UIKit

class UnitsPickerViewController: UITableViewController {
    let unitsList = ["psi","inHG","inH2O","ftH2O","mmH2O","cmH2O","mH2O","mTorr","Torr","atm","mbar","bar","Pa","kPa","MPa"]
    var selectedUnits: String? {
        didSet {
            if let selectedUnits = selectedUnits, let index = unitsList.index(of: selectedUnits) {
                selectedUnitsIndex = index
            }
        }
    }
    
    var selectedUnitsIndex: Int?
}

extension UnitsPickerViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return unitsList.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UnitsCell", for: indexPath)
        cell.textLabel?.text = unitsList[indexPath.row]
        
        if indexPath.row == selectedUnitsIndex {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "SaveSelectedUnits",
            let cell = sender as? UITableViewCell,
            let indexPath = tableView.indexPath(for: cell) else {
                return
        }
        
        let index = indexPath.row
        selectedUnits = unitsList[index]
    }
}

extension UnitsPickerViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let index = selectedUnitsIndex {
            let cell = tableView.cellForRow(at: IndexPath(row: index, section: 0))
            cell?.accessoryType = .none
        }
        
            selectedUnits = unitsList[indexPath.row]
            
            let cell = tableView.cellForRow(at: indexPath)
            cell?.accessoryType = .checkmark
    }
}
