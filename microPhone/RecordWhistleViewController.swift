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
    var seekBar: UISlider!
    
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
        stackView.heightAnchor.constraint(equalToConstant: UIScreen.main.bounds.height/3).isActive = true
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
        titleLabel.font = titleLabel.font.withSize(22)
        stackView.addArrangedSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: stackView.topAnchor, constant: 40),
        ])
        
        recordImageView = UIImageView()
        stackView.addArrangedSubview(recordImageView)
  
        seekBar = UISlider()
        seekBar.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(seekBar)

        NSLayoutConstraint.activate([
            seekBar.widthAnchor.constraint(equalTo: stackView.widthAnchor, multiplier: 0.6),
            seekBar.heightAnchor.constraint(equalToConstant: 40),
        ])
        seekBar.isHidden = true
        seekBar.isUserInteractionEnabled = false
        seekBar.minimumValue = 0
        seekBar.maximumValue = 100
        
        horizontalSV = UIStackView()
        horizontalSV.backgroundColor = .white
        horizontalSV.spacing = 40
        horizontalSV.translatesAutoresizingMaskIntoConstraints = false
        horizontalSV.distribution = UIStackView.Distribution.fillEqually
        horizontalSV.alignment = .center
        horizontalSV.axis = .horizontal
        stackView.addArrangedSubview(horizontalSV)
 
        playButton = UIButton()
        horizontalSV.addArrangedSubview(playButton)
        playButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        playButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        playButton.layer.shadowOpacity = 1.0
        playButton.layer.shadowRadius = 0.0
        playButton.layer.masksToBounds = false
        playButton.layer.cornerRadius = 24.0

        recordButton = UIButton()
        recordButton.setImage(#imageLiteral(resourceName: "check"), for: .normal)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        horizontalSV.addArrangedSubview(recordButton)
         
        let gapView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 20))
        gapView.backgroundColor = .white
        stackView.addArrangedSubview(gapView)
        
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
            seekBar.isHidden = true
            recordImageView.isHidden = false
        } else {
            finishRecording(success: true)
        }
    }
    
    
    @objc func pauseTapped() {
        if soundRecorder.isRecording {
            titleLabel.text = "Recording is on pause now"
            playButton.setImage(#imageLiteral(resourceName: "rec"), for: .normal)
            soundRecorder.pause()
        } else {
            titleLabel.text = "We are recording now"
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
            soundRecorder.record()
        }
    }
    
    func startRecording() {
        titleLabel.text = "We are recording now"
        recordImageView.image = #imageLiteral(resourceName: "recording")

        recordButton.setImage(#imageLiteral(resourceName: "check"), for: .normal)
        playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
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
    
    func showSeekBar() {
        
        seekBar.isHidden = false
        recordImageView.isHidden = true
    }
    
    func finishRecording(success: Bool) {

        soundRecorder.stop()
        recordUrl = soundRecorder.url
        soundRecorder = nil
        playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)

        if success {
            recordButton.setImage(#imageLiteral(resourceName: "replay"), for: .normal)
            titleLabel.text = "You can play your record"
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
            
            showSeekBar()

            playButton.removeTarget(nil, action: nil, for: .allEvents)
            playButton.addTarget(self, action: #selector(playTapped), for: .touchUpInside)

        } else {
            recordButton.setImage(#imageLiteral(resourceName: "replay"), for: .normal)

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
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        } else {
            audioPlayer?.play()
            timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
            titleLabel.text = "Playing record"
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        }
    }
    
    var timer: Timer?
    
    @objc func  updateSlider() {
        let progress = Float(audioPlayer!.currentTime)
        
        if seekBar.maximumValue - progress < 0.25 {
            seekBar.setValue(seekBar.maximumValue, animated: false)
            timer?.invalidate()
            titleLabel.text = "End of recording"
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        } else {
            seekBar.setValue(progress, animated: false)
        }
    }
    
    @objc func playTapped() {
        audioPlayer?.delegate = self
        titleLabel.text = "Playing record"
        playButton.removeTarget(nil, action: nil, for: .allEvents)
        playButton.addTarget(self, action: #selector(pausePlayTapped), for: .touchUpInside)
        playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
         
        if let url = recordUrl {
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                 seekBar.maximumValue = Float(player.duration)
                timer = Timer.scheduledTimer(timeInterval: 0.25, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
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
