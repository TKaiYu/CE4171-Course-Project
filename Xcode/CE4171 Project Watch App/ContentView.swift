import SwiftUI
import CoreMotion
import WatchConnectivity

struct ContentView: View {
    @State private var isRecording = false
    @State private var motionManager: CMMotionManager?
    
    let session: WCSession = {
        let session = WCSession.default
        session.activate()
        return session
    }()
    
    var body: some View {
        VStack {
            if isRecording {
                Text("Recording")
                    .font(.title2)
            } else {
                Text("Not Recording")
                    .font(.title2)
            }
            
            Button(action: {
                isRecording.toggle()
                handleButtonPress()
            }) {
                Text(isRecording ? "Stop" : "Start")
                    .font(.title2)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
    
    func handleButtonPress() {
        if isRecording {
            startRecordingMotionData()
        } else {
            stopRecordingMotionData()
        }
    }
    
    func startRecordingMotionData() {
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 70.0
        
        if let manager = motionManager, manager.isDeviceMotionAvailable {
            manager.startDeviceMotionUpdates(to: OperationQueue.current!) { (motion, error) in
                if let deviceMotion = motion {
                    let accelerationData = [
                        "x": deviceMotion.userAcceleration.x,
                        "y": deviceMotion.userAcceleration.y,
                        "z": deviceMotion.userAcceleration.z
                    ]
                    
                    let rotationData = [
                        "x": deviceMotion.rotationRate.x,
                        "y": deviceMotion.rotationRate.y,
                        "z": deviceMotion.rotationRate.z
                    ]
                    
                    let message = [
                        "acceleration": accelerationData,
                        "rotation": rotationData
                    ]
                    
                    if session.isReachable {
                        session.sendMessage(message, replyHandler: nil, errorHandler: nil)
                    }
                }
            }
        }
    }
    
    func stopRecordingMotionData() {
        motionManager?.stopDeviceMotionUpdates()
        motionManager = nil
    }
}

//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
