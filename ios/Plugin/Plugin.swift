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
                print("finish download")
                if response.error == nil {
                    // unzip
                    print("no error")
                    let _ = self.unzip(fileURL)
                    print("finish unzip")
                    print(fileURL.absolutePath)
                    call.resolve()
                } else {
                    print("error")
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
    
    private func unzip(_ fileURL: URL) -> String {
        print(fileURL.pathExtension)
        if fileURL.pathExtension == "zip" {
            print("zip")
            SSZipArchive.unzipFile(atPath: fileURL.absoluteString, toDestination: (fileURL.absoluteString as NSString).deletingPathExtension)
            print("success unzip")
            // delete file
            do {
                print("start delete")
                try FileManager.default.removeItem(at: fileURL)
                print("finish delete")
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
            return (fileURL.absoluteString as NSString).deletingPathExtension.appending("/index.html")
        }
        print("not zip")
        return fileURL.absoluteString
    }
}
