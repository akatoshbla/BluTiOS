//
//  ProgressView.swift
//  BluTransducer
//
//  Created by David Kopp on 9/6/18.
//  Copyright © 2018 Validyne. All rights reserved.
//

// MARK: - This class is a custom loading screen. It is to show a activityindicator so the user is aware that they need to wait for the application to finish its assigned task.

import UIKit

open class ProgressView: UIViewController {
    static let shared = ProgressView()
    
    var containerView = UIView()
    var progressView = UIView()
    var ActivityIndicator = UIActivityIndicatorView()
    
    // MARK: - This function sets up the progress view and displays it
    open func showProgressView(whiteBackground: Bool) {
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        var containerBackground = UIColor()
        var progressViewBackground = UIColor()
        
        if whiteBackground {
            //UIApplication.shared.isStatusBarHidden = true
            containerBackground = UIColor(hex: 0xffffff, alpha: 1.0)
            progressViewBackground = UIColor(hex: 0x444444, alpha: 0.7)
        } else {
            //UIApplication.shared.isStatusBarHidden = false
            containerBackground = UIColor(hex: 0xffffff, alpha: 0.3)
            progressViewBackground = UIColor(hex: 0x444444, alpha: 0.7)
        }
        
        containerView.frame = window.frame
        containerView.center = window.center
        containerView.backgroundColor = containerBackground
        
        progressView.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        progressView.center = window.center
        progressView.backgroundColor = progressViewBackground
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 10
        
        ActivityIndicator.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        ActivityIndicator.style = .whiteLarge
        //ActivityIndicator.transform = CGAffineTransform(scaleX: 3, y: 3)
        ActivityIndicator.center = CGPoint(x: progressView.bounds.width / 2, y: progressView.bounds.height / 2)
        
        progressView.addSubview(ActivityIndicator)
        containerView.addSubview(progressView)
        UIApplication.shared.keyWindow?.addSubview(containerView)
        
        ActivityIndicator.startAnimating()
    }
    
    // MARK: - This function hides the currently displayed Progress View
    open func hideProgressView() {
        ActivityIndicator.stopAnimating()
        containerView.removeFromSuperview()
        //UIApplication.shared.isStatusBarHidden = false
    }
}

// MARK: - Custom Method for UIColor
extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        let red = CGFloat((hex & 0xFF0000) >> 16) / 256.0
        let green = CGFloat((hex & 0xFF00) >> 8) / 256.0
        let blue = CGFloat(hex & 0xFF) / 256.0
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}
