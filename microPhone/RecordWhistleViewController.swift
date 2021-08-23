//
//  AudioRecVC.swift
//  CloudApper
//
//  Created by Engin KUK on 23.08.2021.
//  Copyright © 2021 M2SYS Technology. All rights reserved.
//

import UIKit
import AVFoundation

class AudioRecVC: UIViewController, AVAudioRecorderDelegate, AVAudioPlayerDelegate {

    var onSaveRecording: ((URL) -> Void)?
    var stackView: UIStackView!
    var horizontalSV: UIStackView!
    var recordButton: UIButton!
    var recordImageView: UIImageView!
    var playButton: UIButton!
    var titleLabel: UILabel!
    
    var recordUrl: URL?

    var recordingSession: AVAudioSession!
    var soundRecorder: AVAudioRecorder!
    var audioPlayer : AVAudioPlayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
 
        startRecordingSession()
        
    }
    
    override func loadView() {
        view = UIView()

        view.backgroundColor = UIColor.lightGray

        stackView = UIStackView()
        stackView.backgroundColor = .white
        stackView.spacing = 20
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.distribution = UIStackView.Distribution.fillEqually
        stackView.alignment = .center
        stackView.axis = .vertical
        view.addSubview(stackView)

        stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    func startRecordingSession() {
        
        recordingSession = AVAudioSession.sharedInstance()

        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        self.loadFailUI()
                    }
                }
            }
        } catch {
            self.loadFailUI()
        }
    }
    
    func loadRecordingUI() {
        titleLabel = UILabel()
        stackView.addArrangedSubview(titleLabel)

        recordImageView = UIImageView()
        stackView.addArrangedSubview(recordImageView)

        horizontalSV = UIStackView()
        horizontalSV.backgroundColor = .white
        horizontalSV.spacing = 20
        horizontalSV.translatesAutoresizingMaskIntoConstraints = false
        horizontalSV.distribution = UIStackView.Distribution.fillEqually
        horizontalSV.alignment = .center
        horizontalSV.axis = .horizontal
        stackView.addArrangedSubview(horizontalSV)
 
        recordButton = UIButton()
        recordButton.setTitle("Done", for: .normal)
        recordButton.setTitleColor(.black, for: .normal)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        horizontalSV.addArrangedSubview(recordButton)
        
        playButton = UIButton()
        playButton.setTitle("Pause", for: .normal)
        playButton.setTitleColor(.black, for: .normal)
        horizontalSV.addArrangedSubview(playButton)
        
        startRecording()
    }
    
    func loadFailUI() {
        let failLabel = UILabel()
        failLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        failLabel.text = "Recording failed: please ensure the app has access to your microphone."
        failLabel.numberOfLines = 0

        stackView.addArrangedSubview(failLabel)
    }

    @objc func recordTapped() {
        if soundRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    
    @objc func pauseTapped() {
        if soundRecorder.isRecording {
            titleLabel.text = "Recording is on pause now"
            playButton.setTitle("Continue", for: .normal)
            soundRecorder.pause()
        } else {
            titleLabel.text = "We are recording now"
            playButton.setTitle("Pause", for: .normal)
            soundRecorder.record()
        }
    }
    
    func startRecording() {
        titleLabel.text = "We are recording now"
        recordImageView.image = #imageLiteral(resourceName: "recording")

        recordButton.setTitle("Done", for: .normal)
        playButton.setTitle("Pause", for: .normal)
        playButton.removeTarget(nil, action: nil, for: .allEvents)
        playButton.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)

        // 3 Use the getWhistleURL() method we just wrote to find where to save the whistle.
        let audioURL = AudioRecVC.getSoundURL()
        print(audioURL.absoluteString)

        // 4 Create a settings dictionary describing the format, sample rate, channels and quality.

        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // 5 Create an AVAudioRecorder object pointing at our whistle URL, set ourselves as the delegate, then call its record() method.
            soundRecorder = try AVAudioRecorder(url: audioURL, settings: settings)
            soundRecorder.delegate = self
            soundRecorder.record()
        } catch {
            finishRecording(success: false)
        }
    }
    
    func finishRecording(success: Bool) {

        soundRecorder.stop()
        recordUrl = soundRecorder.url
        soundRecorder = nil
        playButton.setTitle("Play", for: .normal)

        if success {
            recordButton.setTitle("Re-record", for: .normal)
            titleLabel.text = "You can play your record"
            playButton.setTitle("Play", for: .normal)
            recordImageView.image = #imageLiteral(resourceName: "sound")
            playButton.removeTarget(nil, action: nil, for: .allEvents)
            playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        } else {
            recordButton.setTitle("Tap to Record", for: .normal)

            let ac = UIAlertController(title: "Record failed", message: "There was a problem recording your whistle; please try again.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func pausePlayTapped() {
        guard let ap = audioPlayer else { return }
        if ap.isPlaying {
            audioPlayer?.stop()
            titleLabel.text = "Playing paused"
            playButton.setTitle("Play", for: .normal)
        } else {
            audioPlayer?.play()
            titleLabel.text = "Playing record"
            playButton.setTitle("Pause Playing", for: .normal)
        }
    }
    
    @objc func playTapped() {
        audioPlayer?.delegate = self
        titleLabel.text = "Playing record"
        playButton.removeTarget(nil, action: nil, for: .allEvents)
        playButton.addTarget(self, action: #selector(pausePlayTapped), for: .touchUpInside)
        playButton.setTitle("Pause Playing", for: .normal)
        if let url = recordUrl {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                 audioPlayer = player
                 audioPlayer?.play()
             } catch {
                 print("audioPlayer error: \(error.localizedDescription)")
             }
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    // returns the path to a writeable directory owned by your app
    class func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }

    class func getSoundURL() -> URL {
        return getDocumentsDirectory().appendingPathComponent("recording.m4a")
    }
 
 
}
