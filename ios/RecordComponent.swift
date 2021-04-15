//
//  RecordComponent.swift
//  ScreenRecord
//
//  Created by Matthew Ruiz on 3/30/21.
//

import Foundation
import ReplayKit
import React

@objc(RecordComponent)
class RecordComponent: RCTViewManager {
  let recorder = RPScreenRecorder.shared()
  private var isRecording = false
  let button: UIButton = UIButton()
  var assetWriter: AVAssetWriter?
  var videoInput: AVAssetWriterInput?
  var isWritingStarted: Bool = false
  var fileName: String?
  public static var gfileURL: URL?
  
  /* buttonWindow is a custom window that we containt the button
   we need to remove it when we are done */
  private var buttonWindow: UIWindow?
  
  /*
   windows are independent from each other. If you add a custom window, you need to remove if from view when you are done with it. Otherwise, it will appear in each screen.
 */
  deinit {
    buttonWindow?.removeFromSuperview()
    buttonWindow?.subviews.forEach({ (view) in
      view.removeFromSuperview()
    })
    buttonWindow?.windowLevel = .statusBar
    buttonWindow = nil
  }
  
  /* I could not very well understant what this function overrides
   I think this is something reactNative related.
   However, It looks like this view returns the button. Shortly, we need to inset the button as subview of the buttonWindow.
   */
  override func view() -> UIView! {
    if #available(iOS 12.0, *) {
      button.setup(title: "Record", x: 100, y: 430, width: 220, height: 80, color: UIColor.red)
      button.addTarget(self, action: #selector(RecordComponent.pressed(sender:)), for: .touchUpInside)
      /* there are two conditions: SceneDelegate came with iOS13, so we need to make sure, it is above iOS 13.0. Then, we need to safe unwrap scene.
      */
      if  #available(iOS 13.0, *), let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
        // we need to give frame to the window. Let's make it as same as the button.
        buttonWindow = UIWindow(frame: button.frame)
        // buttons frame now should be equal to its bounds since we put it in window. Window has the real frame.
        button.frame = button.bounds
        
        // now, we add  the button as the window's subview
        buttonWindow.addSubview(button)
        // we need to give windowScene to the window. Otherwise, it is not added to UI
        buttonWindow.windowScene = scene
        // this method makes it key window.
        buttonWindow.makeKeyAndVisible()
        // this is similar to "bringSubviewToFront", .statusBar represents "main" window's level. buttonWindow should be bigger than it, so that, it appears above the other views.
        buttonWindow.windowLevel = .statusBar + 1
        buttonWindow?.isUserInteractionEnabled = true
        // we return the window as the view
        
        /* There is one critically important point;
         If RecordComponent has a parent/container UIWiew in the VC where it is called, you need to apply the code between line 48-68 there. Otherwise, that view will appear in the record.
         */
        return buttonWindow
        
      } else {
        return button
      }
    } else {
      let label = UILabel()
      label.text = "Screen Recording Not Supported"
      return label
    }
  }
  
  @objc func pressed(sender: UIButton!) {
    if (self.isRecording) {
      stopRecording()
    } else {
      startRecording()
    }
  }
  
  @objc func startRecording() {
    guard recorder.isAvailable else {
        print("Recording is not available at this time.")
        return
    }
    fileName = "test_file\(Int.random(in: 10 ..< 1000))"
    let fileURL = URL(fileURLWithPath: filePath(fileName!))
    RecordComponent.gfileURL = fileURL
    assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType: AVFileType.mp4)

    if #available(iOS 11.0, *) {
      let videoOutputSettings: Dictionary<String, Any> = [
        AVVideoCodecKey : AVVideoCodecType.h264,
        AVVideoWidthKey : UIScreen.main.bounds.size.width,
        AVVideoHeightKey : UIScreen.main.bounds.size.height
      ]
      videoInput  = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
      if let videoInput = self.videoInput,
         let canAddInput = assetWriter?.canAdd(videoInput),
         canAddInput {
        assetWriter?.add(videoInput)
      } else {
          print("couldn't add video input")
      }
      /*
       recorder.startCapture(handler: { (sample, bufferType, error) in
         if CMSampleBufferDataIsReady(sample) {
           if self.assetWriter.status == AVAssetWriter.Status.unknown {
             self.isRecording = true
             self.assetWriter.startWriting()
             self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sample))
           }
           
           if self.assetWriter.status == AVAssetWriter.Status.failed {
             print("Error occured, status = \(self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
             return
           }
           
           if (bufferType == .video) {
             if self.videoInput.isReadyForMoreMediaData {
               self.videoInput.append(sample)
             }
           }
         }
         
       }) { (error) in
         debugPrint(error as Any)
       }
       */
      
      recorder.startCapture { [weak self] (sampleBuffer, bufferType, error) in
        guard let self = self else {return}
        if error == nil {
          if self.recorder.isRecording {
            let presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            switch bufferType {
            case .video:
              if self.assetWriter!.status == .unknown {
                if self.assetWriter!.startWriting() {
                  self.isRecording = true
                  self.assetWriter!.startSession(atSourceTime: presentationTimeStamp)
                }
              } else if self.assetWriter!.status == .writing {
                if self.videoInput!.isReadyForMoreMediaData {
                  self.videoInput!.append(sampleBuffer)
                }
              }
            default:
              print(bufferType)
            }
          }
        } else {
          self.recorder.stopCapture { (err) in
            print(err?.localizedDescription)
          }
        }
      } completionHandler: { (error) in
        if let err = error {
          self.recorder.stopCapture { (err) in
            print(err?.localizedDescription)
          }
        } else {
          // TODO: completion
        }
      }

    } else {
      // Fallback on earlier versions
    }
  }
  
  @objc func stopRecording() {
    if #available(iOS 11.0, *) {
      RPScreenRecorder.shared().stopCapture { [weak self] (error) in
        guard let self = self else { return }
        if let error = error {
          print(error.localizedDescription)
        } else {
          self.videoInput!.markAsFinished()
          self.assetWriter!.finishWriting(completionHandler: { [weak self] in
            guard let self = self else { return }
              self.isRecording = false
              self.videoInput = nil
              self.assetWriter = nil
              print(SharedFileSystemRCT.fetchAllReplays())
          })
        }
//        self.assetWriter.finishWriting {
//          print(SharedFileSystemRCT.fetchAllReplays())
//        }
      }
    }
  }
  
  func filePath(_ fileName: String) -> String
  {
    createReplaysFolder()
    let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
    let documentsDirectory = paths[0] as String
    let filePath : String = "\(documentsDirectory)/Replays/\(fileName).mp4"
    return filePath
  }
  
  func createReplaysFolder()
  {
     let documentDirectoryPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
     if let documentDirectoryPath = documentDirectoryPath {
        // create the custom folder path
        let replayDirectoryPath = documentDirectoryPath.appending("/Replays")
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: replayDirectoryPath) {
          do {
            try fileManager.createDirectory(atPath: replayDirectoryPath, withIntermediateDirectories: false, attributes: nil)
            print("Created DIR")
          } catch {
            print("Error creating Replays folder in documents dir: \(error)")
          }
       }
     }
  }
}

extension UIButton {
    func setup(title: String, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, color: UIColor){
        frame = CGRect(x: x, y: y, width: width, height: height)
        backgroundColor = color
        setTitle(title , for: .normal)
        }
    }

