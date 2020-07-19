//
//  VoiceRecordingViewController.swift
//  Pigeon-project
//
//  Created by Roman Mizin on 11/25/17.
//  Copyright © 2017 Roman Mizin. All rights reserved.
//

import UIKit
import AVFoundation

class VoiceRecordingViewController: UIViewController {
  
  var recorder: AVAudioRecorder!
  //var player: AVAudioPlayer!
  weak var mediaPickerDelegate: MediaPickerDelegate?
  let voiceRecordingContainerView = VoiceRecordingContainerView()
  var meterTimer: Timer!
  var soundFileURL: URL!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    print("VOICE INIT")
    
    view.addSubview(voiceRecordingContainerView)
    view.addSubview(voiceRecordingContainerView)
    voiceRecordingContainerView.translatesAutoresizingMaskIntoConstraints = false
    voiceRecordingContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
    
    if #available(iOS 11.0, *) {
      voiceRecordingContainerView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor).isActive = true
      voiceRecordingContainerView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor).isActive = true
      voiceRecordingContainerView.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor).isActive = true
    } else {
      voiceRecordingContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      voiceRecordingContainerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      voiceRecordingContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
    }
    
    voiceRecordingContainerView.stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
    voiceRecordingContainerView.recordButton.addTarget(self, action: #selector(record(_:)), for: .touchUpInside)
    
    voiceRecordingContainerView.stopButton.isEnabled = false
    voiceRecordingContainerView.stopButton.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .normal)

  //  setSessionPlayback()
    askForNotifications()
    checkHeadphones()
  }
  
  deinit {
    print("VOICE DID DEINIT")
  }
  
  @objc func updateAudioMeter(_ timer: Timer) {
    
    if let recorder = self.recorder {
      if recorder.isRecording {
        let hours = Int(recorder.currentTime) / 3600
        let minutes = Int(recorder.currentTime) / 60 % 60
        let seconds = Int(recorder.currentTime) % 60
        let s = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        
        voiceRecordingContainerView.statusLabel.text = s
        recorder.updateMeters()
       
        let percentage = pow (10, (0.05 * recorder.averagePower(forChannel: 0)))
			  voiceRecordingContainerView.waveForm.amplitude = CGFloat(percentage * 5)
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    recorder = nil
  //  player = nil
  }
  
//  @IBAction func removeAll(_ sender: AnyObject) {
//    deleteAllRecordings()
//  }
  
  @objc func record(_ sender: UIButton) {
    
  //  print("\(#function)")
    
//    if player != nil && player.isPlaying {
//    //  print("stopping")
//      player.stop()
//    }
    
    if recorder == nil {
   
      recordWithPermission(true, completionHandler: { [unowned self] (isCompleted) in
        if isCompleted {
         // print("recording. recorder nil")
          DispatchQueue.main.async { [unowned self] in
            self.voiceRecordingContainerView.recordButton.setTitle("Pause", for: .normal)
            self.voiceRecordingContainerView.stopButton.isEnabled = true
            self.voiceRecordingContainerView.stopButton.setTitleColor(.red, for: .normal)
          }
          return
        } else {
          
          basicErrorAlertWith(title: "Error", message: microphoneAccessDeniedMessage, controller: self)
          return
        }
      })
      return
    } else
    
    if recorder != nil && recorder.isRecording {
    //  print("pausing")
      recorder.pause()
      voiceRecordingContainerView.waveForm.amplitude = 0
      voiceRecordingContainerView.recordButton.setTitle("Continue", for: .normal)
    } else {
    //  print("recording")
     // recorder.record()
      voiceRecordingContainerView.recordButton.setTitle("Pause", for: .normal)
   //   voiceRecordingContainerView.playButton.isEnabled = false
      voiceRecordingContainerView.stopButton.isEnabled = true
      voiceRecordingContainerView.stopButton.setTitleColor(.red, for: .normal)
      
      //            recorder.record()
      continuePlay()
     // recordWithPermission(false, completionHandler: { (completed) in })
    }
  }
  
  @objc func stop() {
  //  print("\(#function)")
    
    recorder?.stop()
   // player?.stop()
    meterTimer.invalidate()
    voiceRecordingContainerView.statusLabel.text = "00:00:00"
    
    voiceRecordingContainerView.recordButton.setTitle("Record", for: .normal)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setActive(false)
    //  voiceRecordingContainerView.playButton.isEnabled = true
      voiceRecordingContainerView.stopButton.isEnabled = false
      voiceRecordingContainerView.stopButton.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor,
                                                           for: .normal)
      voiceRecordingContainerView.recordButton.isEnabled = true
    } catch {
//      print("could not make session inactive")
//      print(error.localizedDescription)
    }
    
    //recorder = nil
  }

  func setupRecorder() {
   // print("\(#function)")
    
    let format = DateFormatter()
    format.dateFormat = "yyyy-MM-dd-HH-mm-ss"
    let currentFileName = "recording-\(format.string(from: Date())).m4a"
  //  print(currentFileName)
    
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    self.soundFileURL = documentsDirectory.appendingPathComponent(currentFileName)
   // print("writing to soundfile url: '\(soundFileURL!)'")
    
    if FileManager.default.fileExists(atPath: soundFileURL.absoluteString) {
      // probably won't happen. want to do something about it?
   //   print("soundfile \(soundFileURL.absoluteString) exists")
    }
    
    let recordSettings: [String: Any] = [
      AVFormatIDKey: kAudioFormatMPEG4AAC,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      AVEncoderBitRateKey: 24000, //32000,
      AVNumberOfChannelsKey: 1,
      AVSampleRateKey: 24000 //44100.0
    ]
    
    do {
      recorder = try AVAudioRecorder(url: soundFileURL, settings: recordSettings)
      recorder.delegate = self
      recorder.isMeteringEnabled = true
      
      recorder.prepareToRecord() // creates/overwrites the file at soundFileURL
    } catch {
      recorder = nil
    //  print(error.localizedDescription)
    }
    
  }

  func continuePlay() {
    setSessionPlayAndRecord()
    recorder.record(forDuration: 1800)
    meterTimer.invalidate()
    meterTimer = nil
    meterTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                           target: self,
                                           selector: #selector(self.updateAudioMeter(_:)),
                                           userInfo: nil,
                                           repeats: true)
		RunLoop.main.add(self.meterTimer, forMode: RunLoop.Mode.common)
  }
  
  typealias CompletionHandler = (_ success: Bool) -> Void
  func recordWithPermission(_ setup: Bool, completionHandler: @escaping CompletionHandler) {
   // print("\(#function)")
    
    AVAudioSession.sharedInstance().requestRecordPermission { [unowned self] granted in
      if granted {
         completionHandler(true)
        DispatchQueue.main.async { [unowned self] in
        //  print("Permission to record granted")
          self.setSessionPlayAndRecord()
          if setup {
            self.setupRecorder()
          }
          self.recorder.record(forDuration: 1800)

          self.meterTimer = Timer.scheduledTimer(timeInterval: 0.01,
                                                 target: self,
                                                 selector: #selector(self.updateAudioMeter(_:)),
                                                 userInfo: nil,
                                                 repeats: true)
					RunLoop.main.add(self.meterTimer, forMode: RunLoop.Mode.common)
        }
      } else {
        completionHandler(false)
       // print("Permission to record not granted")
      }
    }

		if AVAudioSession.sharedInstance().recordPermission == .denied {
     // print("permission denied")
    }
  }
  
//  func setSessionPlayback() {
//   // print("\(#function)")
//    let session = AVAudioSession.sharedInstance()
//
//    do {
//      try session.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
//
//    } catch {
////      print("could not set session category")
////      print(error.localizedDescription)
//    }
//
//    do {
//      try session.setActive(true)
//    } catch {
////      print("could not make session active")
////      print(error.localizedDescription)
//    }
//  }
  
  func setSessionPlayAndRecord() {
   // print("\(#function)")

    let session = AVAudioSession.sharedInstance()
    do {
			try session.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
		//	try session.setCategory(., with: .defaultToSpeaker)
		//	try session.setActive(true)
    } catch {
//      print("could not set session category")
//      print(error.localizedDescription)
    }

    do {
      try session.setActive(true)
    } catch {
//      print("could not make session active")
//      print(error.localizedDescription)
    }
  }
  
  func deleteAllRecordings() {
  //  print("\(#function)")

    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    let fileManager = FileManager.default
    do {
      let files = try fileManager.contentsOfDirectory(at: documentsDirectory,
                                                      includingPropertiesForKeys: nil,
                                                      options: .skipsHiddenFiles)
      //                let files = try fileManager.contentsOfDirectory(at: documentsDirectory)
      let recordings = files.filter({ (name: URL) -> Bool in
        return name.pathExtension == "m4a"
        //                    return name.hasSuffix("m4a")
      })
      for i in 0 ..< recordings.count {
        //                    let path = documentsDirectory.appendPathComponent(recordings[i], inDirectory: true)
        //                    let path = docsDir + "/" + recordings[i]
        
        //                    print("removing \(path)")
       // print("removing \(recordings[i])")
        do {
          try fileManager.removeItem(at: recordings[i])
        } catch {
       //   print("could not remove \(recordings[i])")
        //  print(error.localizedDescription)
        }
      }
    } catch {
    //  print("could not get contents of directory at \(documentsDirectory)")
     // print(error.localizedDescription)
    }
  }
  
  func askForNotifications() {
 //   print("\(#function)")

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(VoiceRecordingViewController.background(_:)),
																					 name: UIApplication.willResignActiveNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(VoiceRecordingViewController.foreground(_:)),
																					 name: UIApplication.willEnterForegroundNotification,
                                           object: nil)

    NotificationCenter.default.addObserver(self,
                                           selector: #selector(VoiceRecordingViewController.routeChange(_:)),
																					 name: AVAudioSession.routeChangeNotification,
                                           object: nil)
  }
  
  @objc func background(_ notification: Notification) {
   // print("\(#function)")
  }

  @objc func foreground(_ notification: Notification) {
  //  print("\(#function)")
  }
  
  @objc func routeChange(_ notification: Notification) {
  //  print("\(#function)")

    if let userInfo = (notification as NSNotification).userInfo {
    //  print("routeChange \(userInfo)")

      //print("userInfo \(userInfo)")
      if let reason = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt {
        //print("reason \(reason)")
				switch AVAudioSession.RouteChangeReason(rawValue: reason)! {
				case AVAudioSession.RouteChangeReason.newDeviceAvailable:
//          print("NewDeviceAvailable")
//          print("did you plug in headphones?")
          checkHeadphones()
				case AVAudioSession.RouteChangeReason.oldDeviceUnavailable:
//          print("OldDeviceUnavailable")
//          print("did you unplug headphones?")
          checkHeadphones()
				case AVAudioSession.RouteChangeReason.categoryChange:
          print("CategoryChange")
				case AVAudioSession.RouteChangeReason.override:
          print("Override")
				case AVAudioSession.RouteChangeReason.wakeFromSleep:
          print("WakeFromSleep")
				case AVAudioSession.RouteChangeReason.unknown:
          print("Unknown")
				case AVAudioSession.RouteChangeReason.noSuitableRouteForCategory:
          print("NoSuitableRouteForCategory")
				case AVAudioSession.RouteChangeReason.routeConfigurationChange:
          print("RouteConfigurationChange")
				@unknown default:
					fatalError()
				}
      }
    }
  }

  func checkHeadphones() {
 //   print("\(#function)")
    
    // check NewDeviceAvailable and OldDeviceUnavailable for them being plugged in/unplugged
    let currentRoute = AVAudioSession.sharedInstance().currentRoute
    if !currentRoute.outputs.isEmpty {
      for description in currentRoute.outputs {
				if description.portType == AVAudioSession.Port.headphones {
          print("headphones are plugged in")
          break
        } else {
          print("headphones are unplugged")
        }
      }
    } else {
      print("checking headphones requires a connection to a device")
    }
  }
}

extension String {

  public func isAudio() -> Bool {
    // Add here your image formats.
    let imageFormats = ["m4a"]
    if let ext = self.getExtension() {
      return imageFormats.contains(ext)
    }
    return false
  }

  public func getExtension() -> String? {
    let ext = (self as NSString).pathExtension
    if ext.isEmpty {
      return nil
    }
    return ext
  }

  public func isURL() -> Bool {
    return URL(string: self) != nil
  }
}

// MARK: AVAudioRecorderDelegate
extension VoiceRecordingViewController: AVAudioRecorderDelegate {
  
  func stackOverflowAnswer(data: Data) {
    //  print("There were \(data.count) bytes")
      let bcf = ByteCountFormatter()
      bcf.allowedUnits = [.useMB] // optional: restricts the units to MB only
      bcf.countStyle = .file
    //  let string = bcf.string(fromByteCount: Int64(data.count))
     // print("formatted result: \(string)")
  }

  func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder,
                                       successfully flag: Bool) {
    
   // print("\(#function)")

  //  print("finished recording \(flag)")
    voiceRecordingContainerView.stopButton.isEnabled = false
    voiceRecordingContainerView.stopButton.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .normal)
		voiceRecordingContainerView.recordButton.setTitle("Record", for: UIControl.State())

    var soundData: Data!

    do {
      soundData = try Data(contentsOf: soundFileURL)
        stackOverflowAnswer(data: soundData)
			let mediaObject = ["audioObject": soundData as Any,
												 "fileURL": soundFileURL as Any] as [String: AnyObject]

      mediaPickerDelegate?.didSelectMedia(mediaObject: MediaObject(dictionary: mediaObject))
      soundData = nil
      self.recorder.deleteRecording()
      self.voiceRecordingContainerView.statusLabel.text = "00:00:00"
      self.voiceRecordingContainerView.waveForm.amplitude = 0
    } catch {
      //print("error converting sound to data")
    }
    self.recorder = nil
  }

  func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder,
                                        error: Error?) {
   // print("\(#function)")

 //   if let e = error {
     // print("\(e.localizedDescription)")
  //  }
  }
}

// MARK: AVAudioPlayerDelegate
extension VoiceRecordingViewController: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
   // print("\(#function)")

  //  print("finished playing \(flag)")
    voiceRecordingContainerView.recordButton.isEnabled = true
    voiceRecordingContainerView.stopButton.isEnabled = false
    voiceRecordingContainerView.stopButton.setTitleColor(ThemeManager.currentTheme().generalSubtitleColor, for: .normal)
  }

  func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
    //print("\(#function)")

//    if let e = error {
//      print("\(e.localizedDescription)")
//    }
  }
}
