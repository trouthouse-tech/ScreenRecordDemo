//
//  SampleHandler.swift
//  ScreenRecordingExt
//
//  Created by Matthew Ruiz on 3/30/21.
//

import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {

    var assetWriter: AVAssetWriter!
    var videoInput: AVAssetWriterInput!
    var isWritingStarted: Bool = false
    var fileName: String?
    var gfileURL: URL?
    
    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
      fileName = "test_file\(Int.random(in: 10 ..< 1000))"
      let fileURL = URL(fileURLWithPath: FileSystemUtil.filePath(fileName!))
      gfileURL = fileURL
      assetWriter = try! AVAssetWriter(outputURL: fileURL, fileType: AVFileType.mp4)
      let videoOutputSettings: Dictionary<String, Any> = [
           AVVideoCodecKey : AVVideoCodecType.h264,
           AVVideoWidthKey : UIScreen.main.bounds.size.width,
           AVVideoHeightKey : UIScreen.main.bounds.size.height
      ];
      videoInput  = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: videoOutputSettings)
      videoInput.expectsMediaDataInRealTime = true
      assetWriter.add(videoInput)
      assetWriter.startWriting()
    }
    
    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }
    
    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }
    
    override func broadcastFinished() {
      let dispatchGroup = DispatchGroup()
      dispatchGroup.enter()
      self.videoInput.markAsFinished()
      self.assetWriter.finishWriting {
        do {
          let sharedContainerURL :URL?  = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.reactjs.native.example.ScreenRecord")
          let sourceUrl = sharedContainerURL?.appendingPathComponent("\(self.fileName).mp4")
          try FileManager.default.copyItem(at: self.gfileURL!, to: sourceUrl!)
        } catch (let error) {
          print("Cannot copy item : \(error)")
        }
        dispatchGroup.leave()
      }
      dispatchGroup.wait()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
      if CMSampleBufferDataIsReady(sampleBuffer)
          {
            // Before writing the first buffer we need to start a session
            if !isWritingStarted
            {
              self.assetWriter.startSession(atSourceTime: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
              isWritingStarted = true
            }

            if self.assetWriter.status == AVAssetWriter.Status.failed {
              print("Error occured, status =  (self.assetWriter.status.rawValue), \(self.assetWriter.error!.localizedDescription) \(String(describing: self.assetWriter.error))")
              return
            }
            if (sampleBufferType == .video)
            {
              if self.videoInput.isReadyForMoreMediaData
              {
                self.videoInput.append(sampleBuffer)
              }
            }
          }
    }
}
