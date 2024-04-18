//
//  ViewController.swift
//  Pulsometer
//
//  Created by Кизим Илья on 16.04.2024.
//

import UIKit
import AVFoundation

final class PulsometerViewController: UIViewController {
    
    //MARK: - Properties
    
    private lazy var videoConteinerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 10.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var pulseLabel: UILabel = {
        let label = UILabel()
        label.text = Constants.labelPulse
        label.textColor = .black
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.textAlignment = .center
        label.numberOfLines = 3
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var startLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.text = Constants.startLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var conteinerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 15.0
        view.layer.masksToBounds = true
        return view
    }()
    
    private lazy var heartImage: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: Constants.heart))
        imageView.tintColor = .red
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private var counter = 0
    private var heartRateManager: HeartRateManager?
    private var filter = Filter()
    private var pulseDetector = PulseDetector()
    private var flag = false
    private var timer = Timer()
    
    //MARK: - LifeCyrcle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray3
        setupUI()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deinitCaptureSession()
    }
}

//MARK: - SetupUI

private extension PulsometerViewController {
    
    func setupUI() {
        addSubviews()
        setupConstraints()
        instructionLabel.text = Constants.instructionLabel
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(cameraOn(_:)))
        videoConteinerView.addGestureRecognizer(tapGesture)
    }
    
    func addSubviews() {
        view.addSubview(videoConteinerView)
        view.addSubview(instructionLabel)
        videoConteinerView.addSubview(startLabel)
        view.addSubview(conteinerView)
        conteinerView.addSubview(heartImage)
        conteinerView.addSubview(pulseLabel)
    }
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            videoConteinerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            videoConteinerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            videoConteinerView.widthAnchor.constraint(equalToConstant: 200),
            videoConteinerView.heightAnchor.constraint(equalToConstant: 200),
            
            instructionLabel.topAnchor.constraint(equalTo: videoConteinerView.bottomAnchor, constant: 20),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            instructionLabel.widthAnchor.constraint(equalToConstant: 200),
            
            startLabel.centerXAnchor.constraint(equalTo: videoConteinerView.centerXAnchor),
            startLabel.centerYAnchor.constraint(equalTo: videoConteinerView.centerYAnchor),
            
            conteinerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            conteinerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            conteinerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            conteinerView.heightAnchor.constraint(equalToConstant: 100),
            
            heartImage.leadingAnchor.constraint(equalTo: conteinerView.leadingAnchor, constant: 10),
            heartImage.centerYAnchor.constraint(equalTo: conteinerView.centerYAnchor),
            heartImage.heightAnchor.constraint(equalToConstant: 50),
            heartImage.widthAnchor.constraint(equalToConstant: 50),
            
            pulseLabel.trailingAnchor.constraint(equalTo: conteinerView.trailingAnchor, constant: -10),
            pulseLabel.centerYAnchor.constraint(equalTo: conteinerView.centerYAnchor)
        ])
    }
}

//MARK: - Animations

private extension PulsometerViewController {
    func startMeasurement() {
        DispatchQueue.main.async {
            self.toggleTorch(status: true)
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] (timer) in
                guard let self = self else { return }
                let average = self.pulseDetector.getAverage()
                let pulse = 60.0/average
                if pulse == -60 {
                    stopPulseHeart()
                } else {
                    startPulseHeart()
                    pulseLabel.text = "\(lroundf(pulse)) BPM"
                }
            })
        }
    }
    
    func startPulseHeart() {
        let pulseAnimation = CABasicAnimation(keyPath: Constants.scaleAnimation)
        pulseAnimation.duration = 0.2
        pulseAnimation.toValue = 1.2
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        heartImage.layer.add(pulseAnimation, forKey: Constants.pulseKey)
    }
    func stopPulseHeart() {
        heartImage.layer.removeAnimation(forKey: Constants.pulseKey)
    }
}

//MARK: - InitAndDeinitCaptureSession

private extension PulsometerViewController {
    
    func initVideoCapture() {
        let specs = VideoSpec(fps: 30, size: CGSize(width: 300, height: 300))
        heartRateManager = HeartRateManager(cameraType: .back, preferredSpec: specs, previewContainer: videoConteinerView.layer)
        heartRateManager?.imageBufferHandler = { [weak self] (imageBuffer) in
            self?.handle(buffer: imageBuffer)
        }
    }
    
    @objc func cameraOn(_ sender: UITapGestureRecognizer) {
        initVideoCapture()
        initCaptureSession()
        startLabel.isHidden = true
        instructionLabel.isHidden = false
    }
    
    func initCaptureSession() {
        heartRateManager?.startCapture()
    }
    
    func deinitCaptureSession() {
        heartRateManager?.stopCapture()
        toggleTorch(status: false)
    }
    
    func toggleTorch(status: Bool) {
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        device.toggleTorch(on: status)
    }
}

//MARK: - HandleImageBuffer

extension PulsometerViewController {
    fileprivate func handle(buffer: CMSampleBuffer) {
        // Calculate the mean values for red, green, and blue color
        // Вычисляем среднее значение для красного, зеленого и синего цвета
        var redmean:CGFloat = 0.0;
        var greenmean:CGFloat = 0.0;
        var bluemean:CGFloat = 0.0;
        // Check the pixel buffer is valid
        // Проверяем, что буфер пикселей является допустимым
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else {return}
        let cameraImage = CIImage(cvPixelBuffer: pixelBuffer)
        // Determine the extent of the camera image
        // Определяем размер изображения с камеры
        let extent = cameraImage.extent
        let inputExtent = CIVector(x: extent.origin.x, y: extent.origin.y, z: extent.size.width, w: extent.size.height)
        // Apply an average filter to the camera image
        // Примененяем фильтр усреднения к изображению с камеры
        guard let averageFilter = CIFilter(name: Constants.areaAverage, parameters: [kCIInputImageKey: cameraImage, kCIInputExtentKey: inputExtent]) else {return}
        guard let outputImage = averageFilter.outputImage else {return}
        // Create a Core Image context and convert the output image to a CGImage
        // Создание контекста Core Image и преобразование выходного изображения в CGImage
        let ctx = CIContext(options:nil)
        guard let cgImage = ctx.createCGImage(outputImage, from:outputImage.extent) else {return}
        
        // Extract from pixel data from the CGImage
        // Извлекаем из пикселей данные из CGImage
        guard let rawData:NSData = cgImage.dataProvider?.data else {return}
        let pixels = rawData.bytes.assumingMemoryBound(to: UInt8.self)
        let bytes = UnsafeBufferPointer<UInt8>(start:pixels, count:rawData.length)
        var BGRA_index = 0
        for pixel in UnsafeBufferPointer(start: bytes.baseAddress, count: bytes.count) {
            switch BGRA_index {
            case 0:
                bluemean = CGFloat (pixel)
            case 1:
                greenmean = CGFloat (pixel)
            case 2:
                redmean = CGFloat (pixel)
            case 3:
                break
            default:
                break
            }
            BGRA_index += 1
        }
        
        let hsv = rgb2hsv((red: redmean, green: greenmean, blue: bluemean, alpha: 1.0))
        // Check if a finger is placed over the camera
        // Проверяем, находится ли палец над камерой
        if (hsv.1 > 0.5 && hsv.2 > 0.5) {
            DispatchQueue.main.async {
                // Update UI elements on the main thread
                // Обновляем элементы пользовательского интерфейса в главном потоке
                self.instructionLabel.text = Constants.instructionLabelTwo
                self.toggleTorch(status: true)
                if !self.flag {
                    self.startMeasurement()
                    self.flag = true
                }
            }
            counter += 1
            
            // Apply a filter to the hue value
            // Применение фильтра к значению оттенка (фильтр, который удаляет любые компоненты постоянного тока и любые высокочастотные помехи)
            let filtered = filter.processValue(value: Double(hsv.0))
            if counter > 60 {
                pulseDetector.addNewValue(newVal: filtered, atTime: CACurrentMediaTime())
            }
        } else {
            // Reset the counter and flag if no finger is detected
            // Сброс счетчика и флага, если палец не обнаружен
            counter = 0
            flag = false
            pulseDetector.reset()
            DispatchQueue.main.async {
                // Update UI elements on the main thread
                // Обновляем элементы пользовательского интерфейса в главном потоке
                self.instructionLabel.text = Constants.instructionLabel
            }
        }
    }
}
