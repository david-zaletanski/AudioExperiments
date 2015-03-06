//
//  ViewController.swift
//  AudioExperiments
//
//  Created by David Zaletanski on 2/25/15.
//  Copyright (c) 2015 David Zaletanski. All rights reserved.
//
/* **************************** INFORMATIONAL/TUTORIAL LINKS **************************** *
 *
 * Audio Recording Tutorial
 * http://www.techotopia.com/index.php/Recording_Audio_on_iOS_8_with_AVAudioRecorder_in_Swift
 *
 * Playing Audio Files with AVAudioPlayer
 *  - AVAudioPlayer can sample audio power values.
 * http://www.rockhoppertech.com/blog/swift-avfoundation/
 *
 * Reading Audio Amplitude Data Directly From File
 * http://stackoverflow.com/questions/1767400/avaudioplayer-metering-want-to-build-a-waveform-graph
 *
 * Computer Audio Theory (PCM)
 * https://www.mikeash.com/pyblog/friday-qa-2012-10-12-obtaining-and-interpreting-audio-data.html
 *
 * ************************************************************************************** */

import AVFoundation
import UIKit

class ViewController: UIViewController, AVAudioPlayerDelegate {
    
    @IBOutlet weak var audioPlayerSlider: UISlider!
    //private let sampleRate: NSTimeInterval = 0.1    // Frequency of samples (samples/sec) used by timer
    private let sampleRate: NSTimeInterval = 0.1    // Frequency of samples (samples/sec) used by timer
    
    private var audioPlayer: AVAudioPlayer!     // Plays and samples the audio file
    private var timer: NSTimer?                 // Calls method to sample audio file while playing
    private var audioRecorder: AVAudioRecorder! // Records audio to a file
    
    private var audioFileURL: NSURL!           // URL to the audio file to be played.
    private var recordingFileURL: NSURL!       // URL to the audio file to be recorded to.
    
    // Finds the audio clip and loads it in preparation to play.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Gets the URL of the audio file
        audioFileURL = NSBundle.mainBundle().URLForResource(
            "M1F1-float32WE-AFsp", withExtension: "wav")!
        
        // Set up audio player to play file
        var error: NSError?                     // Holds an error if one occurs
        self.audioPlayer = AVAudioPlayer(contentsOfURL: audioFileURL, error: &error)
        if self.audioPlayer == nil {
            if let e = error {
                println(e.localizedDescription)
            }
        }
        self.audioPlayer.delegate = self        // Calls AVAudioPlayerDelegate functions
        self.audioPlayer.prepareToPlay()        // Reduces response time when calling play()
        self.audioPlayer.volume = 1.0           // Volume range is 1.0 (loudest) to 0.0 (silence)
        self.audioPlayer.meteringEnabled = true // Keep track of channel power meters
        
        // Find app's documents directory and set file to record audio to
        let dirPaths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
            NSSearchPathDomainMask.UserDomainMask, true)
        let docsDir = dirPaths[0] as String
        let soundFilePath = docsDir.stringByAppendingPathComponent("sound.caf")
        recordingFileURL = NSURL(fileURLWithPath: soundFilePath)
        
        // Create dictionary containing recording settings
        let recordSettings = [AVEncoderAudioQualityKey: AVAudioQuality.Min.rawValue,
            AVEncoderBitRateKey: 16,
            AVNumberOfChannelsKey: 2,
            AVSampleRateKey: 44100.0]
        
        audioRecorder = AVAudioRecorder(URL: recordingFileURL, settings: recordSettings,
            error: &error)
        if let err = error {
            println("Error creating audio recorder: \(err.localizedDescription)")
        } else {
            audioRecorder.prepareToRecord()
        }
    }
    
    // Called by the timer frequently to gather playback metrics.
    func monitorAudioPlayer()
    {
        // Update current audio power values
        self.audioPlayer.updateMeters()
        
        // Gather power levels for each channel
        // Power level is a float from 0 dB (loudest) to -160 dB (silence)
        for channelNumber in 0..<audioPlayer.numberOfChannels {
            let averagePowerForChannel = self.audioPlayer.averagePowerForChannel(channelNumber)
            let peakPowerForChannel = self.audioPlayer.peakPowerForChannel(channelNumber)
            let elapsedTime = self.audioPlayer.currentTime
            
            self.audioPlayerSlider.minimumValue = 0.0
            self.audioPlayerSlider.maximumValue = Float(self.audioPlayer.duration)
            self.audioPlayerSlider.value = Float(self.audioPlayer.currentTime)
            //println("\(elapsedTime) Channel [\(channelNumber)]  Average: \(averagePowerForChannel)   Peak: \(peakPowerForChannel)")
            println("\(elapsedTime) , \(averagePowerForChannel)")
        }
    }
    
    // Called when the audio player completes playing the audio.
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer!, successfully flag: Bool) {
        if flag {
            self.audioPlayerSlider.value = self.audioPlayerSlider.maximumValue
            println("AVAudioPlayer finished playing successfully.")
        } else {
            println("AVAudioPlayer finished playing unsuccessfully.")
        }
        // Disable repeating timer if we had it going.
        self.timer?.invalidate()
        println("Timer stopped.")
    }
    
    // Called if the audio player encounters an error decoding the audio.
    func audioPlayerDecodeErrorDidOccur(player: AVAudioPlayer!, error: NSError!) {
        if let e = error {
            println("AVAudioPlayer error decoding: '\(e.localizedDescription)'")
        }
    }
    
    // Callback for when either 'Play' or 'Stop' button is pressed.
    @IBAction func audioPlaybackButtonPressed(sender: UIButton) {
        
        // User presses PLAY button
        if sender.titleLabel?.text == "Play" {
            if let player = self.audioPlayer {
                if !player.playing {
                    self.audioPlayer.play()
                    println("AVAudioPlayer started playing.")
                    
                    self.timer = NSTimer.scheduledTimerWithTimeInterval(sampleRate, target: self, selector: "monitorAudioPlayer", userInfo: nil, repeats: true)
                    println("Timer scheduled and started.")
                }
            }
            // User presses STOP button
        } else {
            
            if let player = audioPlayer {       // If we are playing audio, stop it.
                if player.playing {
                    self.audioPlayer.stop()
                    println("AVAudioPlayer stopped by user.")
                    
                    self.timer?.invalidate()    // If the timer is going, stop it.
                    self.timer = nil
                    println("Timer stopped.")
                }
            }
            
        }
    }
    
    // Callback when user presses the Record or Stop buttons in Voice Recording section
    @IBAction func audioRecordButtonPressed(sender: UIButton) {
        if sender.titleLabel?.text == "Record" {
            // User presses RECORD button
            audioRecorder.record()
            println("Recording started.")
        } else {
            // User presses STOP button
            if audioRecorder.recording {
                audioRecorder.stop()
                println("Recording stopped.")
            }
        }
    }
    
    // Callback when user presses the Play Recording or
    // Stop Recording buttons in Voice Recording Section
    @IBAction func audioRecordingButtonPressed(sender: UIButton) {
        if sender.titleLabel?.text == "Play Recording" {
            // User pressed PLAY RECORDING button
            
        } else {
            // User pressed STOP RECORDING button
            
        }
    }
    
}

