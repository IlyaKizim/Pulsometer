//
//  HearRateManager.swift
//  Pulsometer
//
//  Created by Кизим Илья on 16.04.2024.
//

import Foundation
import AVFoundation

        //MARK: - Typealias

typealias ImageBufferHandler = ((_ imageBuffer: CMSampleBuffer) -> ())

final class HeartRateManager: NSObject {
    
        //MARK: - Properties
    
    private let captureSession = AVCaptureSession()
    private var videoDevice: AVCaptureDevice?
    private var videoConnection: AVCaptureConnection?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    // Обработчик буфера изображения
    var imageBufferHandler: ImageBufferHandler?
    
        //MARK: - Initialization
    
    init(cameraType: CameraType, preferredSpec: VideoSpec?, previewContainer: CALayer?) {
        super.init()
        videoDevice = cameraType.captureDevice()
        
        // MARK: - SetupVideoFormat
        // Настройка формата захвата видео
        do {
            captureSession.sessionPreset = .low
            if let preferredSpec = preferredSpec {
                // Update the format with a preferred fps
                // Обновление формата с предпочтительной частотой кадров
                videoDevice?.updateFormatWithPreferredVideoSpec(preferredSpec: preferredSpec)
            }
        }
        
        // MARK: - SetupVideoDeviceInput
        // Настройка входного устройства видео
        
        let videoDeviceInput: AVCaptureDeviceInput
        guard let device = videoDevice else {return}
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: device)
        } catch let error {
            fatalError("Could not create AVCaptureDeviceInput instance with error: \(error).")
        }
        guard captureSession.canAddInput(videoDeviceInput) else { fatalError() }
        captureSession.addInput(videoDeviceInput)
        
        // MARK: - SetupPreviewLayer
        // Настройка слоя предпросмотра
        
        if let previewContainer = previewContainer {
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = previewContainer.bounds
            previewLayer.contentsGravity = CALayerContentsGravity.resizeAspectFill
            previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            print(previewContainer.frame)
            previewContainer.insertSublayer(previewLayer, at: 0)
            self.previewLayer = previewLayer
        }
        
        // MARK: - SetupVideoOutput
        // Настройка вывода видеоданных
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        let queue = DispatchQueue(label: "com.covidsense.videosamplequeue")
        videoDataOutput.setSampleBufferDelegate(self, queue: queue)
        guard captureSession.canAddOutput(videoDataOutput) else {
            fatalError()
        }
        captureSession.addOutput(videoDataOutput)
        videoConnection = videoDataOutput.connection(with: .video)
    }
    
    // MARK: - StartAndStopCapture
    
        func startCapture() {
           if captureSession.isRunning { return }
           DispatchQueue.global(qos: .background).async { [weak self] in
               guard let self = self else { return }
               self.captureSession.startRunning()
           }
       }

        func stopCapture() {
            if !captureSession.isRunning { return }
            captureSession.stopRunning()
        }
}

    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension HeartRateManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    // MARK: - ExportBufferFromVideoFrame
    // Обработка выходного буфера изображения
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if connection.videoOrientation != .portrait {
            connection.videoOrientation = .portrait
            return
        }
        if let imageBufferHandler = imageBufferHandler {
            imageBufferHandler(sampleBuffer)
        }
    }
}

enum CameraType: Int {
    case back
    func captureDevice() -> AVCaptureDevice? {
        AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
}

struct VideoSpec {
    var fps: Int32?
    var size: CGSize?
}
