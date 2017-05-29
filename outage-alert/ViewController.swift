//
//  ViewController.swift
//  outage-alert
//
//  Created by Christopher Ashton on 3/13/17.
//  Copyright © 2017 Christopher Ashton. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox
import CoreLocation
import MapKit
import WatchConnectivity

class ViewController: UIViewController, CLLocationManagerDelegate {
    

    // declare variables
    
    let defaultSoundID: UInt32 = 1005
    var systemSoundID: SystemSoundID!
    var alarm: AVAudioPlayer!
    weak var timer: Timer?
    let green = UIColor.green
    let black = UIColor.black
    let red = UIColor.red
    let white = UIColor.white
    let darkGray = UIColor.darkGray
    let blue = UIColor.blue
    
    
    //IB Outlets and Actions
    
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet var firstView: UIView!
    @IBOutlet weak var monitorStateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var isLabel: UILabel!
    @IBOutlet var monitorView: UIView!
    
    
    @IBAction func monitorPower(_ sender: UISwitch) {
        if sender.isOn {
    
            // begin monitoring battery state
            
            UIDevice.current.isBatteryMonitoringEnabled = true
            
            // subscribe to notifications of change in state
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.batteryState),
                name: .UIDeviceBatteryStateDidChange,
                object: nil)
            
            
            turnTextLabelsOn()
            
            
            // to keep the app alive
            
            batteryState()
            startTimer()
            
            // darken the screen up a bit
            monitorView.backgroundColor = darkGray
            
            
        } else {
            removeNotificationObserver()
            UIDevice.current.isBatteryMonitoringEnabled = false
            
            turnTextLabelsOff()
            
            stopSound()
            
            // turn off application timer so it will eventually sleep
            
            stopTimer()
            
            // make it visible again
            
            monitorView.backgroundColor = white
            
        }
     
    }



    override func viewWillAppear(_ animated: Bool) {
        
        
        // make a persistent AudioSession
        
        do {
            
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            print("AVAudioSession Category Playback OK")
            do {
                try AVAudioSession.sharedInstance().setActive(true)
                print("AVAudioSession is Active")
            } catch _ as NSError {
                //print(error.localizedDescription)
            }
        } catch _ as NSError {
            //print(error.localizedDescription)
        }
        
        // set state label
        
        stateLabel.text = "Power not being monitored"
        timeLabel.textColor = green
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (systemSoundID == nil) {
            systemSoundID = defaultSoundID
        }

    }
    
// Playsound
    
    func playsound() -> Void {
        let path = Bundle.main.path(forResource: "Tornado Siren-SoundBible.com-897026957.wav", ofType: nil)!
        let url = URL(fileURLWithPath: path)
        
        do {
            let sound = try AVAudioPlayer(contentsOf: url)
            alarm = sound
            alarm.numberOfLoops = -1
            sound.play()
        } catch _ as NSError {
            print("Sorry couldn't reach the file")
        }
    }


// Batterystate
    func batteryState() {
        
        let date = NSDate()
        let calendar = NSCalendar.current
        let components = calendar.dateComponents(in: TimeZone.current, from: date as Date)
        let hour = components.hour
        let minutes = components.minute
        let stringMinutes = String(format: "%02d", minutes!)
        
        timeLabel.text = "\(hour!):" + stringMinutes
    
        
// Switch
        
        let currentBatteryState: Int = UIDevice.current.batteryState.rawValue

        switch currentBatteryState {
        
        
        case 0:  // Battery state unknown
            stateLabel.text = "Error? Battery Status Unknown"
        
        case 1:  // unplugged or no power
            stateLabel.text = "No Power"
            turnTextRed()
            playsound()
            
            // turn application timer on so the phone can go to sleep and save power.
            
            stopTimer()
            
// Alert
            
            let controller = UIAlertController()
            
            let attributedTitleString = NSAttributedString(string: "Power Outage?", attributes: [
                NSFontAttributeName : UIFont.boldSystemFont(ofSize: 12), //your font here
                NSForegroundColorAttributeName : UIColor.red
                ])
            
            let attributedMessageString = NSAttributedString(string: "Your iPhone is no longer receiving power", attributes: [
                NSFontAttributeName : UIFont.systemFont(ofSize: 10), //your font here
                NSForegroundColorAttributeName : UIColor.black
                ])
            
            controller.setValue(attributedTitleString, forKey: "attributedTitle")
            controller.setValue(attributedMessageString, forKey: "attributedMessage")

            
            // options the user is going to be presented with in the alert
            
            let turnOffAlarm = UIAlertAction(title: "Turn off alarm", style: UIAlertActionStyle.cancel) {
                action in
                self.stopSound()
                self.stopTimer()
                self.removeNotificationObserver()
                self.segueToDecisionView()
            }
            
            controller.addAction(turnOffAlarm)
            self.present(controller, animated: true, completion: nil)
            
        case 2: // Battery Charging
            stateLabel.text = "Battery Charging. Power is on"
            stateLabel.textColor = blue
            
        case 3: // Battery fully charged phone runningn on external power
            stateLabel.text = "Battery Charged. Power is on"
            stateLabel.textColor = green
            
        default:
            stateLabel.text = "Error? Default reached in switch statement"
        }
    
    }
// End of switch
    
 
//functions
    func stopSound() {
        if alarm != nil {
            alarm.stop()
            alarm = nil
        } else {
            print("There was no sound silly")
        }
    }
    
    func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func segueToDecisionView() {
        // segue to decison controller
        
        var controller: DecisionViewController
        controller = self.storyboard?.instantiateViewController(withIdentifier: "DecisionView") as! DecisionViewController
        
        self.present(controller, animated: true, completion: nil)
    }
    
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.batteryState()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
    }
    
    func turnTextLabelsOn() {
        monitorStateLabel.text = "ON"
        monitorStateLabel.textColor = green
        titleLabel.textColor = green
        isLabel.textColor = green
    }
    func turnTextLabelsOff() {
        monitorStateLabel.text = "OFF"
        monitorStateLabel.textColor = black
        stateLabel.text = "Power not being monitored"
        stateLabel.textColor = red
        timeLabel.text = ""
        titleLabel.textColor = black
        isLabel.textColor = black
    }
    
    func turnTextRed() {
        monitorStateLabel.textColor = red
        titleLabel.textColor = red
        isLabel.textColor = red
        timeLabel.textColor = red
        stateLabel.textColor = red
    }
}

