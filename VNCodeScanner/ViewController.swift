//
//  ViewController.swift
//  VNCodeScanner
//
//  Created by Hikaru Kuroda on 2022/12/06.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {

    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")

    private let metadataOutput = AVCaptureMetadataOutput()
    private let metadataObjectQueue = DispatchQueue(label: "metadataObjectQueue")

    private var videoDeviceInput: AVCaptureDeviceInput!

    private let previewView = UIView()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private let codeSymbologies: [AVMetadataObject.ObjectType] = [
        .aztec,.codabar,.code128, .code39, .code39Mod43, .code93, .dataMatrix, .gs1DataBar, .gs1DataBarLimited, .gs1DataBarExpanded, .itf14, .microQR, .microPDF417, .pdf417, .qr, .upce
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        sessionQueue.async {
            self.configureSession()
        }

        previewView.frame = view.frame

        previewLayer = AVCaptureVideoPreviewLayer(session: self.session)
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        previewView.layer.addSublayer(previewLayer)

        view.addSubview(previewView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        sessionQueue.async {
            self.session.startRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()

        let defaultVideoDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .back
        )

        guard let videoDevice = defaultVideoDevice else {
            session.commitConfiguration()
            return
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)

            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
        } catch {
            session.commitConfiguration()
            return
        }

        if session.canAddOutput(metadataOutput) {
            session.addOutput(metadataOutput)

            metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectQueue)
            metadataOutput.metadataObjectTypes = codeSymbologies
        } else {
            session.commitConfiguration()
        }

        session.commitConfiguration()
    }
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(
        _ output: AVCaptureMetadataOutput,
        didOutput metadataObjects: [AVMetadataObject],
        from connection: AVCaptureConnection
    ) {
        for object in metadataObjects {
            guard let code = object as? AVMetadataMachineReadableCodeObject else { return }
            guard let value = code.stringValue else { return }
            switch code.type {
            case .qr:
                print("QR: \(value)")
            case .codabar:
                print("codabar: \(value)")
            default:
                print("その他: \(value)")
            }
        }
    }
}
