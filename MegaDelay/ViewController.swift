//
//  ViewController.swift
//  Delay
//
//  Created by Nikita.Kardakov on 18/01/2018.
//  Copyright © 2018 NicheMarket. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, DelayEngineDelegate {
    
    private let engine = DelayEngine()
    @IBOutlet var startButton:NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        engine.delegate = self
    }
    
    @IBAction func onFirstRecorder(button:NSButton) {
        engine.toggleRecording(index: 0)
    }

    @IBAction func onSecondRecorder(button:NSButton) {
        engine.toggleRecording(index: 1)
    }

    @IBAction func onStart(button:NSButton) {
        engine.toggleStart()
    }
    
    //MARK: DelayEngineDelegate
    
    func updatedEngineState() {
        startButton.state = engine.isRunning() ? .on : .off
    }
}

