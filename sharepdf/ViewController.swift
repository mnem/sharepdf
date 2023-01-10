//
//  ViewController.swift
//  sharepdf
//
//  Created by David Wagner on 10/01/2023.
//

import UIKit

class ViewController: UIViewController {
    
    private var downloadButton: UIButton!
    
    private var share: UIDocumentInteractionController?
    private var shareContinuation: CheckedContinuation<Void, Never>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        constrain()
        subscribe()
    }
}

extension ViewController {
    private func configure() {
        downloadButton = UIButton()
        downloadButton.configuration = .filled()
        downloadButton.setTitle(NSLocalizedString("Download", comment: "Download button title"), for: .normal)
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(downloadButton)
    }

    private func constrain() {
        NSLayoutConstraint.activate([
            downloadButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadButton.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func subscribe() {
        downloadButton.addTarget(
            self,
            action: #selector(downloadTapped),
            for: .touchUpInside
        )
    }
}

extension ViewController {
    @objc
    private func downloadTapped(_ button: UIButton) {
        button.isEnabled = false
        Task {
            do {
                let filePath = try await self.download()
                await self.share(url: filePath)
            } catch {
                print("Download failed: \(error)")
            }
            button.isEnabled = true
        }
    }
}

extension ViewController {
    private func download() async throws -> URL {
        let url = URL(string: "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf")!
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        let local = FileManager.default
            .temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .notDirectory)
            .appendingPathExtension("pdf")
        
        try data.write(to: local, options: .atomic)
        
        return local
    }
}

extension ViewController {
    private func share(url: URL) async {
        await withCheckedContinuation({ c in
            self.shareContinuation = c
            let share = UIDocumentInteractionController(url: url)
            share.delegate = self
            self.share = share
            share.presentOptionsMenu(from: view.frame, in: view, animated: true)
        })
    }
}

extension ViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerDidDismissOptionsMenu(_ controller: UIDocumentInteractionController) {
        // So, this method is also called if the user cancels saving
        // to files, but the share sheet is still visible 🤷‍♂️
        shareContinuation?.resume()
    }
}
