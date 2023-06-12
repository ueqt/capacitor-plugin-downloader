import Foundation
import Capacitor
import Alamofire
import SSZipArchive

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(DownloaderPlugin)
public class DownloaderPlugin: CAPPlugin {
    @objc func download(_ call: CAPPluginCall) {
        call.keepAlive = true
        
        guard let url = call.getString("url") else {
            call.reject("No download url")
            return
        }
        guard let localPath = call.getString("localPath") else {
            call.reject("No save localPath")
            return
        }
        guard let callbackId = call.callbackId else {
            call.reject("No callbackId")
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(localPath)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        AF.download(url, to: destination)
            .downloadProgress { progress in
                if let savedCall = self.bridge?.savedCall(withID: callbackId) {
                    return savedCall.resolve([
                        "progress": progress.fractionCompleted
                    ])
                }
            }
            .responseData { response in
                if response.error == nil {
                    // unzip
                    let _ = self.unzip(fileURL)
                    call.resolve()
                } else {
                    call.reject(response.error?.errorDescription ?? "")
                }
            }
    }
    
    @objc func absolutePath(_ call: CAPPluginCall) -> String {
        guard let localPath = call.getString("localPath") else {
            call.reject("No read localPath")
            return ""
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(localPath)
        return self.unzip(fileURL)
    }
    
    private func unzip(_ fileURL: URL) -> String {
        if fileURL.pathExtension == ".zip" {
            SSZipArchive.unzipFile(atPath: fileURL.absoluteString, toDestination: (fileURL.absoluteString as NSString).deletingPathExtension)
            // delete file
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
            return (fileURL.absoluteString as NSString).deletingPathExtension.appending("/index.html")
        }
        return fileURL.absoluteString
    }
}
