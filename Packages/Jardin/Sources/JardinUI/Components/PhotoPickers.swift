import JardinCore
import PhotosUI
import SwiftUI

/// Bouton unique « Galerie / Caméra » : PhotosPicker partout, caméra sur iPhone/iPad.
/// Retourne l'image déjà normalisée (redimensionnée + JPEG) prête à stocker.
public struct PhotoCaptureButton: View {
    public struct Captured: Sendable {
        public let cgImage: CGImage
        public let stored: (photo: Data, thumbnail: Data)
    }

    let onCapture: (Captured) -> Void

    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    public init(onCapture: @escaping (Captured) -> Void) {
        self.onCapture = onCapture
    }

    public var body: some View {
        HStack(spacing: 12) {
            PhotosPicker(selection: $pickerItem, matching: .images) {
                Label("Galerie", systemImage: "photo.on.rectangle")
            }
            #if os(iOS)
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Caméra", systemImage: "camera")
                }
            }
            #endif
        }
        .buttonStyle(.bordered)
        .tint(Theme.leaf)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    await process(data: data)
                }
                pickerItem = nil
            }
        }
        #if os(iOS)
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await process(platformImage: image) }
            }
            .ignoresSafeArea()
        }
        #endif
    }

    private func process(data: Data) async {
        guard let image = ImageUtils.platformImage(from: data) else { return }
        await process(platformImage: image)
    }

    private func process(platformImage: PlatformImage) async {
        // Le CGImage (immuable, Sendable) est extrait avant de quitter l'acteur :
        // UIImage/NSImage ne doivent pas traverser un Task.detached.
        guard let cg = ImageUtils.cgImage(from: platformImage) else { return }
        let captured: Captured? = await Task.detached(priority: .userInitiated) {
            guard let stored = ImageUtils.makeStoredPhoto(fromCGImage: cg),
                  let normalizedCG = ImageUtils.cgImage(fromJPEGData: stored.photo) else { return nil }
            return Captured(cgImage: normalizedCG, stored: stored)
        }.value
        if let captured { onCapture(captured) }
    }
}

#if os(iOS)
public struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    public init(onImage: @escaping (UIImage) -> Void) {
        self.onImage = onImage
    }

    public func makeUIViewController(context: Context) -> UIImagePickerController {
        let controller = UIImagePickerController()
        controller.sourceType = .camera
        controller.delegate = context.coordinator
        return controller
    }

    public func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}

    public func makeCoordinator() -> Coordinator { Coordinator(self) }

    public final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        public func imagePickerController(_ picker: UIImagePickerController,
                                          didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }

        public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
#endif
