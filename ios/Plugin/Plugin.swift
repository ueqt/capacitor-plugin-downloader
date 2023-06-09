import Foundation
import Capacitor
import Alamofire

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
        guard let fileName = call.getString("fileName") else {
            call.reject("No save fileName")
            return
        }
        guard let callbackId = call.callbackId else {
            call.reject("No callbackId")
            return
        }
        
        let destination: DownloadRequest.Destination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent(localPath).appendingPathComponent(fileName)

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
                    call.resolve()
                } else {
                    call.reject(response.error?.errorDescription ?? "")
                }
            }
    }
}
