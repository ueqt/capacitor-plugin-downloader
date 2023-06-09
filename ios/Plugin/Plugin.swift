import Foundation
import Capacitor
import Alamofire
import SSZipArchive

extension Dictionary where Key == String, Value == String {
    func toHeader() -> HTTPHeaders {
        var headers: HTTPHeaders = [:]
        for (key, value) in self  {
            headers.add(name: key, value: value)
        }
        return headers
    }
}

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
        
        print("callbackId: ")
        print(callbackId)
        
        guard let bridge = self.bridge else {
            call.reject("No bridge")
            return
        }

//        guard let savedCall = bridge.savedCall(withID: callbackId) else {
//            print("no savedcall")
//            return
//        }
        
        let headersString = call.getString("headers") ?? "{}"
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(localPath)
        let destination: DownloadRequest.Destination = { _, _ in
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        var headers = self.convertStringToDictionary(text: headersString) ?? [:]
        
        AF.download(url, headers: headers.toHeader(), to: destination)
            .downloadProgress { progress in
                guard let savedCall = bridge.savedCall(withID: callbackId) else {
                    print("no savedcall1")
                    return
                }
                return savedCall.resolve([
                    "progress": progress.fractionCompleted * 0.8 // download 80%
                ])
            }
            .responseData { response in
                if response.error == nil {
                    // unzip
                    print(fileURL.pathExtension)
                    if fileURL.pathExtension == "zip" {
                        print("=========================================")
                        print(fileURL.relativePath)
                        print((fileURL.relativePath as NSString).deletingPathExtension)
                        print(SSZipArchive.unzipFile(atPath: fileURL.relativePath, toDestination: (fileURL.relativePath as NSString).deletingPathExtension, progressHandler: { entry, zipInfo, entryNumber, total in
                            print(entry)
                            print(zipInfo)
                            print(entryNumber)
                            print(total)
                            guard let savedCall = bridge.savedCall(withID: callbackId) else {
                                print("no savedcall2")
                                return
                            }
                            return savedCall.resolve([
                                "progress": 0.8 + 0.2 * Double(entryNumber) / Double(total)
                            ])
                        }))
                        print("=========================================")
                        // delete file
                        do {
                            try FileManager.default.removeItem(at: fileURL)
                        } catch {
                            print("Could not delete file, probably read-only filesystem")
                        }
                    }
                    guard let savedCall = bridge.savedCall(withID: callbackId) else {
                        print("no savedcall3")
                        return
                    }
                    print("complete progress")
                    return savedCall.resolve([
                        "progress": 1
                    ])
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
    
    @objc func unzip(_ call: CAPPluginCall) {
        call.keepAlive = true
        
        guard let zipRelativePath = call.getString("zipRelativePath") else {
            call.reject("No read zipRelativePath")
            return
        }
        guard let callbackId = call.callbackId else {
            call.reject("No callbackId")
            return
        }
        print("callbackId: ")
        print(callbackId)
        
        guard let bridge = self.bridge else {
            call.reject("No bridge")
            return
        }
        
        bridge.saveCall(call)
        
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsURL.appendingPathComponent(zipRelativePath)
        
        print(fileURL.pathExtension)
        if fileURL.pathExtension == "zip" {
            print("=========================================")
            print(fileURL.relativePath)
            print((fileURL.relativePath as NSString).deletingPathExtension)
            print(SSZipArchive.unzipFile(atPath: fileURL.relativePath, toDestination: (fileURL.relativePath as NSString).deletingPathExtension, progressHandler: { entry, zipInfo, entryNumber, total in
                print(entry)
                print(zipInfo)
                print(entryNumber)
                print(total)
                guard let savedCall = bridge.savedCall(withID: callbackId) else {
                    print("no savedcall1")
                    return
                }
                print("do progress")
                return savedCall.resolve([
                    "progress": Double(entryNumber) / Double(total)
                ])
            }))

            print("=========================================")
            // delete file
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                print("Could not delete file, probably read-only filesystem")
            }
        }
        guard let savedCall = bridge.savedCall(withID: callbackId) else {
            print("no savedcall2")
            return
        }
        return savedCall.resolve([
            "progress": 1
        ])
    }
    
    private func convertStringToDictionary(text: String) -> [String:String]? {
       if let data = text.data(using: .utf8) {
           do {
               let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:String]
               return json
           } catch {
               print("Something went wrong")
           }
       }
       return nil
   }
}
