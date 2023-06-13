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
                    self.unzip(fileURL)
                    call.resolve()
                } else {
                    call.reject(response.error?.errorDescription ?? "")
                }
            }
    }
    
    @objc func absolutePath(_ call: CAPPluginCall) {
        guard let localPath = call.getString("localPath") else {
            call.reject("No read localPath")
            return
        }
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(localPath)
        call.resolve([
            "absolutePath": fileURL.absoluteString
        ])
    }
    
    private func unzip(_ fileURL: URL) {
        print(fileURL.pathExtension)
        if fileURL.pathExtension == "zip" {
            print("=========================================")
            print(fileURL.relativePath)
            print((fileURL.relativePath as NSString).deletingPathExtension)
            print(SSZipArchive.unzipFile(atPath: fileURL.relativePath, toDestination: (fileURL.relativePath as NSString).deletingPathExtension) { a, b, c, d in
                print(a)
                print(b)
                print(c)
                print(d)
            })
            print("=========================================")
            // delete file
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
        }
    }
}
