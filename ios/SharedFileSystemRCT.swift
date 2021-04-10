import Foundation


@objc(SharedFileSystemRCT)
class SharedFileSystemRCT: NSObject {
  @objc
  func getAllFiles(_ resolve: RCTPromiseResolveBlock, rejecter reject: RCTPromiseRejectBlock) -> Void {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let directoryContents = try! FileManager.default.contentsOfDirectory(at: documentsDirectory!, includingPropertiesForKeys: [.contentModificationDateKey], options: [])

    // create a simple list of objects for javascript
    let finalData = directoryContents.map { (URL) -> Dictionary<String, Any> in
      return [
        "absolutePath": URL.absoluteString,
        "relativePath": URL.relativePath
      ]
    }
    resolve(finalData)
  }
  
  @objc
  func clearAllFilesFromTempDirectory(){
    do {
      let sharedContainerURL :URL?  = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: .none, create: false)
      let replayPath = sharedContainerURL?.appendingPathComponent("/Replays")

      do {
          let fileURLs = try FileManager.default.contentsOfDirectory(at: replayPath!, includingPropertiesForKeys: nil,options: .skipsHiddenFiles)
          for fileURL in fileURLs {
            print("file \(fileURL)")
              if fileURL.pathExtension == "mp4" {
                  try FileManager.default.removeItem(at: fileURL)
              }
          }
      } catch  { print(error) }
    } catch  { print(error) }
  }
  
  internal class func fetchAllReplays() -> Array<URL> {
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
    let replayPath = documentsDirectory?.appendingPathComponent("/Replays")
    let directoryContents = try! FileManager.default.contentsOfDirectory(at: replayPath!, includingPropertiesForKeys: nil, options: [])
    return directoryContents
  }
}
