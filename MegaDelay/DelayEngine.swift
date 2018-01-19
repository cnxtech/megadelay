//
//  DelayEngine.swift
//  Delay
//
//  Created by Nikita.Kardakov on 18/01/2018.
//  Copyright © 2018 NicheMarket. All rights reserved.
//

import Foundation
import CoreAudio
import AVFoundation

protocol DelayEngineDelegate {
    func updatedEngineState()
}

final class DelayEngine {
    
    var delegate:DelayEngineDelegate?
    
    private let numberOfInputs = 2
    private var files:[URL?]
    private var isRecordingArray:[Bool]
    
    private let engine:AVAudioEngine
    private var players:[AVAudioPlayerNode]
    private let mixer:AVAudioMixerNode
    private let delay:AVAudioUnitDelay
    private var currentFile:AVAudioFile?
    
    init() {
        engine = AVAudioEngine()
        
        files = Array(repeating: nil, count: numberOfInputs)
        isRecordingArray = Array(repeating: false, count: numberOfInputs)
        
        delay = AVAudioUnitDelay()
        mixer = AVAudioMixerNode()
        
        engine.attach(delay)
        engine.attach(mixer)
        
        players = []
        for _ in 0..<numberOfInputs {
            let player = AVAudioPlayerNode()
            players.append(player)
            engine.attach(player)
        }
        
        for (index, player) in players.enumerated() {
            engine.connect(player, to: mixer, fromBus: 0, toBus: index, format: format)
        }
        engine.connect(engine.inputNode, to:mixer, fromBus:0, toBus:numberOfInputs, format:format)
        engine.connect(mixer, to: delay, format: format)
        engine.connect(delay, to: engine.mainMixerNode, format: format)
    }
    
    func toggleRecording(index:Int) {
        if isRecordingArray[index] {
            stopRecording(index: index)
            if engine.isRunning {
                startPlayer(index: index)
            }
        } else {
            startRecording(index: index)
        }
    }
    
    func toggleStart() {
        if engine.isRunning {
            engine.stop()
            stopPlayers()
        } else {
            do {
                try engine.start()
                startPlayers()
            } catch {
                print("Couldn't start our engine")
            }
        }
        delegate?.updatedEngineState()
    }
    
    func isRunning() -> Bool {
        return engine.isRunning
    }
    
    //MARK: Private
    
    private var format:AVAudioFormat {
        return engine.inputNode.outputFormat(forBus: 0)
    }
    
    private func startPlayers() {
        for (index, _) in players.enumerated() {
            startPlayer(index: index)
        }
    }
    
    private func startPlayer(index:Int) {
        let player = players[index]
        if let fileForReading = file(index:index, forReading: true), let buffer = AVAudioPCMBuffer(pcmFormat:fileForReading.processingFormat, frameCapacity: UInt32(fileForReading.length)) {
            do {
                try fileForReading.read(into: buffer)
                player.scheduleBuffer(buffer, at:AVAudioTime(hostTime:0), options:.loops, completionHandler: nil)
                player.play()
            } catch {
                print("Couldn't play file number \(index)")
            }
        }
    }
    
    private func stopPlayers() {
        for player in players {
            player.stop()
        }
    }
    
    private func file(index:Int, forReading:Bool) -> AVAudioFile? {
        do {
            if forReading {
                if let url = files[index] {
                    return try AVAudioFile(forReading:url)
                }
            } else {
                let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())input\(index).caf")
                files[index] = url
                return try AVAudioFile(forWriting:url, settings:format.settings)
            }
            return nil
        } catch {
            return nil
        }
    }
    
    private func startRecording(index:Int) {
        isRecordingArray[index] = true
        players[index].stop()
        
        if let fileForRecording = file(index: index, forReading: false) {
            currentFile = fileForRecording
            engine.inputNode.installTap(onBus:0, bufferSize:4096, format:format, block: {
                (buffer : AVAudioPCMBuffer!, when : AVAudioTime!) in
                do {
                    try self.currentFile?.write(from: buffer)
                } catch {
                    print("Couldn't write into file")
                }
            })
            
            if !engine.isRunning {
                do {
                    try engine.start()
                    delegate?.updatedEngineState()
                } catch {
                    print("Couldn't start our engine")
                }
            }
        }
    }
    
    private func stopRecording(index:Int) {
        isRecordingArray[index] = false
        engine.inputNode.removeTap(onBus: 0)
    }
}

