//
//  ContentView.swift
//  CE4171 Project
//
//  Created by Kai Yu Teo on 2/5/23.
//

import SwiftUI
import WatchConnectivity

class WatchSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    var webSocketTask: URLSessionWebSocketTask?

    @Published var predictedResult: String = "Waiting for prediction..."

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if let acceleration = message["acceleration"] as? [String: Double],
           let rotation = message["rotation"] as? [String: Double] {
            sendDataToBackend(acceleration: acceleration, rotation: rotation)
        }
    }
    
    func sendDataToBackend(acceleration: [String: Double], rotation: [String: Double]) {
        if webSocketTask == nil {
            webSocketTask = URLSession.shared.webSocketTask(with: URL(string: "wss://34.124.183.4")!)
            webSocketTask?.resume()
        }
        
        let payload: [String: Any] = [
            "acceleration": acceleration,
            "rotation": rotation
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: payload, options: [])
            let jsonString = String(data: data, encoding: .utf8)!
            webSocketTask?.send(URLSessionWebSocketTask.Message.string(jsonString)) { error in
                if let error = error {
                    print("WebSocket couldn't send message: \(error)")
                }
            }
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
    }

    func receivePrediction() {
        webSocketTask?.receive { result in
            switch result {
            case .success(let message):
                if case let URLSessionWebSocketTask.Message.string(text) = message {
                    if let data = text.data(using: .utf8) {
                        self.processPredictionResult(data: data)
                    }
                }
                self.receivePrediction()
            case .failure(let error):
                print("Error receiving WebSocket message: \(error)")
            }
        }
    }

    func processPredictionResult(data: Data) {
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let result = json["result"] as? String {
                DispatchQueue.main.async {
                    self.predictedResult = result
                }
            }
        } catch {
            print("Error processing prediction result: \(error.localizedDescription)")
        }
    }
}

struct ContentView: View {
    @StateObject private var watchSessionDelegate = WatchSessionDelegate()

    var body: some View {
        VStack {
            Text("Dance Groove Classification")
                .font(.headline)
                .onAppear {
                    if WCSession.default.isReachable {
                        WCSession.default.delegate = watchSessionDelegate
                        WCSession.default.activate()
                    }

                    watchSessionDelegate.receivePrediction()
                }

            Text(watchSessionDelegate.predictedResult)
                .font(.title)
                .padding()
        }
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
