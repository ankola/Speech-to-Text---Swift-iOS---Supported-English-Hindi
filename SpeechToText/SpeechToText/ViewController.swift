//
//  ViewController.swift
//  SpeechToText
//
//  Created by Savan Ankola on 28/03/22.
//

import UIKit
import Speech
import AVKit


class ViewController: UIViewController {

    // MARK:- ------------- @IBOutlet -------------
    @IBOutlet weak var btnStart             : UIButton!
    @IBOutlet weak var btnStartHindi             : UIButton!
    @IBOutlet weak var lblText              : UILabel!
    @IBOutlet weak var textView              : UITextView!

    // MARK:- ------------- Variable & Constant -------------
    var recognitionRequest      : SFSpeechAudioBufferRecognitionRequest?
    var speechRecognizer        = SFSpeechRecognizer(locale: Locale(identifier: "en-IN"))
    var speechRecognizerHindi   = SFSpeechRecognizer(locale: Locale(identifier: "hi-IN"))
    var recognitionTask         : SFSpeechRecognitionTask?
    var recognitionTaskHindi    : SFSpeechRecognitionTask?
    let audioEngine             = AVAudioEngine()
    var strContent = ""
    
    override func viewDidLoad() {
        self.lblText.isHidden = true
        self.textView.withDoneButton()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupSpeech()
    }
    
    func setupSpeech() {

           self.speechRecognizer?.delegate = self
           self.speechRecognizerHindi?.delegate = self

           SFSpeechRecognizer.requestAuthorization { (authStatus) in

               var isButtonEnabled = false

               switch authStatus {
               case .authorized:
                   isButtonEnabled = true

               case .denied:
                   isButtonEnabled = false
                   print("User denied access to speech recognition")

               case .restricted:
                   isButtonEnabled = false
                   print("Speech recognition restricted on this device")

               case .notDetermined:
                   isButtonEnabled = false
                   print("Speech recognition not yet authorized")
                   
               @unknown default:
                   print("Speech recognition not yet authorized")
               }

               OperationQueue.main.addOperation() {
                   self.btnStart.isEnabled = isButtonEnabled
               }
           }
    }
    
    func startRecording(isEnglish : Bool) {
        
       //            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
       // Create instance of audio session to record voice
       let audioSession = AVAudioSession.sharedInstance()
       do {
           try audioSession.setCategory(.playAndRecord, mode: .measurement, options: .defaultToSpeaker)
           try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
           
       } catch {
           print("audioSession properties weren't set because of an error.")
       }

       self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

       let inputNode = audioEngine.inputNode

       guard let recognitionRequest = recognitionRequest else {
           fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
       }

       recognitionRequest.shouldReportPartialResults = true

        if isEnglish {
            self.recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

                var isFinal = false

                if result != nil {
                    self.textView.text = self.strContent + " " + (result?.bestTranscription.formattedString ?? "")
                    isFinal = (result?.isFinal)!
                }

                if error != nil || isFinal {
                    self.stopAudioSesionData()
                }
            })
            
        } else {
            self.recognitionTaskHindi = speechRecognizerHindi?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

                var isFinal = false

                if result != nil {
                    self.textView.text = self.strContent + " " + (result?.bestTranscription.formattedString ?? "")
                    isFinal = (result?.isFinal)!
                }

                if error != nil || isFinal {
                    self.stopAudioSesionData()
                }
            })
        }

       let recordingFormat = inputNode.outputFormat(forBus: 0)
       inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
           self.recognitionRequest?.append(buffer)
       }

       self.audioEngine.prepare()

       do {
           try self.audioEngine.start()
       } catch {
           print("audioEngine couldn't start because of an error.")        }

       self.lblText.text = "Say something, I'm listening!"
   }
    
    @IBAction func btnStartSpeechToTextWithHIndi(_ sender: UIButton) {
        
        if self.btnStart.tag == 1 && audioEngine.isRunning {
            self.stopAudioSesionData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.manageTasksForHindi()
            }

        } else {
            self.manageTasksForHindi()
        }
    }
    
    @IBAction func btnStartSpeechToText(_ sender: UIButton) {
        
        if self.btnStartHindi.tag == 1 && audioEngine.isRunning {
            self.stopAudioSesionData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.manageTasksForEnglish()
            }
            
        } else {
            self.manageTasksForEnglish()
        }
    }
    
    private func manageTasksForEnglish() {
        if self.audioEngine.isRunning {
            self.stopAudioSesionData()

        } else {
            self.startRecording(isEnglish: true)
            self.btnStart.setTitle("Stop Recording", for: .normal)
            self.lblText.isHidden = false
            self.btnStart.tag = 1
        }
    }
    
    private func manageTasksForHindi() {
        if self.audioEngine.isRunning {
            self.stopAudioSesionData()
            
        } else {
            self.startRecording(isEnglish: false)
            self.btnStartHindi.setTitle("Stop Recording", for: .normal)
            self.lblText.isHidden = false
            self.btnStartHindi.tag = 1
        }
    }
    
    // Clear all previous session data and cancel task
    private func stopAudioSesionData() {
        self.strContent = self.textView.text
        self.audioEngine.stop()
        self.recognitionRequest?.endAudio()
        self.audioEngine.inputNode.removeTap(onBus: 0)
        self.btnStart.setTitle("Start Recording with English", for: .normal)
        self.btnStartHindi.setTitle("Start Recording with Hindi", for: .normal)
        self.lblText.isHidden = true
        self.btnStart.tag = 0
        self.btnStartHindi.tag = 0
        self.audioEngine.reset()
        
        if recognitionTaskHindi != nil {
            recognitionTaskHindi?.cancel()
            recognitionTaskHindi?.finish()
            recognitionTaskHindi = nil
        }
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask?.finish()
            recognitionTask = nil
        }
    }
}

 
// MARK:- ------------- SFSpeechRecognizerDelegate Methods -------------
extension ViewController: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            btnStart.isEnabled = true
            btnStart.setTitle("Start Recording with English", for: [])
            self.btnStartHindi.isEnabled = true
            self.btnStartHindi.setTitle("Start Recording with Hindi", for: .normal)
        } else {
            btnStart.isEnabled = false
            btnStart.setTitle("Recognition not available", for: .disabled)
            btnStartHindi.isEnabled = false
            btnStartHindi.setTitle("Recognition not available", for: .disabled)
        }
    }
}


// MARK:- ------------- UITextView -------------
extension UITextView {
    func withDoneButton(toolBarHeight: CGFloat = 44) {
        guard UIDevice.current.userInterfaceIdiom == .phone else {
            print("Adding Done button to the keyboard makes sense only on iPhones")
            return
        }
        
        let toolBar = UIToolbar(frame: CGRect(x: 0.0, y: 0.0, width: UIScreen.main.bounds.width, height: toolBarHeight))
        let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(endEditing))
        
        toolBar.setItems([flexibleSpace, doneButton], animated: false)
        
        inputAccessoryView = toolBar
    }
}

