//
//  CameraPreview.swift
//  diplom
//
//  Created by Иван Тарасюк on 20.12.2025.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewControllerRepresentable {
    @ObservedObject var cameraModel: CameraModel

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.session = cameraModel.session
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        // обновления не нужны, слой сам растягивается
    }
}

class CameraViewController: UIViewController {
    var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let session = session else { return }

        if previewLayer == nil {
            let layer = AVCaptureVideoPreviewLayer(session: session)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.addSublayer(layer)
            previewLayer = layer
        } else {
            previewLayer?.frame = view.bounds
        }
    }
}
