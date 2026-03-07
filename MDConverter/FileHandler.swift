//
//  FileHandler.swift
//  MDConverter
//
//  Created by Nihaal Garud on 11/10/2024.
//

import Foundation
import SwiftUI
import AppKit // Import AppKit for NSSavePanel and NSOpenPanel
import UniformTypeIdentifiers
import Combine

class FileHandler: ObservableObject {
    static let shared = FileHandler()
    
    @Published var markdownText: String = "# Welcome to MDConverter\n\nStart writing your *Markdown* here."
    @Published var richText = NSAttributedString(string: "")
    
    // Optional: Autosave functionality
    // Uncomment the following lines to enable autosave
    private var autosaveCancellable: AnyCancellable?
    
    private init() {
        autosaveCancellable = $markdownText
            .debounce(for: .seconds(5), scheduler: RunLoop.main)
            .sink { [weak self] text in
                self?.autosave(text: text)
            }
    }
    
    // MARK: - File Operations
    
    /// Opens a Markdown file and loads its content into the editor.
    func openFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.plainText, .markdown]
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.title = "Open Markdown File"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                let fileContent = try String(contentsOf: url, encoding: .utf8)
                DispatchQueue.main.async {
                    self.markdownText = fileContent
                }
            } catch {
                print("Error reading file:", error.localizedDescription)
                showAlert(title: "Error", message: "Failed to open the selected file.")
            }
        }
    }
    
    /// Saves the current Markdown text to a file.
    func saveFile() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText, .markdown]
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = "Untitled.md" // Default file name
        panel.title = "Save Markdown File"
        
        if panel.runModal() == .OK, let url = panel.url {
            do {
                try markdownText.write(to: url, atomically: true, encoding: .utf8)
                showAlert(title: "Success", message: "File saved successfully.")
            } catch {
                print("Error saving file:", error.localizedDescription)
                showAlert(title: "Error", message: "Failed to save the file.")
            }
        }
    }
    
    // MARK: - Autosave (Optional)
    
    /// Automatically saves the Markdown text periodically.
    private func autosave(text: String) {
        let url = getAutosaveURL()
        do {
            try text.write(to: url, atomically: true, encoding: .utf8)
            print("Autosaved at \(url.path)")
        } catch {
            print("Autosave failed: \(error.localizedDescription)")
        }
    }
    
    /// Returns the URL for the autosave file.
    private func getAutosaveURL() -> URL {
        let autosaveDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("MarkdownEditor", isDirectory: true)
        try? FileManager.default.createDirectory(at: autosaveDirectory, withIntermediateDirectories: true, attributes: nil)
        return autosaveDirectory.appendingPathComponent("autosave.md")
    }
    
    // MARK: - Alert
    
    /// Displays an alert with the given title and message.
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = title == "Success" ? .informational : .warning
            alert.runModal()
        }
    }
    
    func convertRichTextToMarkdown(_ attributed: NSAttributedString) -> String {

        var markdown = ""
        
        attributed.enumerateAttributes(
            in: NSRange(location: 0, length: attributed.length),
            options: []
        ) { attributes, range, _ in
            
            let substring = attributed.attributedSubstring(from: range).string
            var text = substring
            
            if let font = attributes[.font] as? NSFont {
                
                if font.fontDescriptor.symbolicTraits.contains(.bold) {
                    text = "**\(text)**"
                }
                
                if font.fontDescriptor.symbolicTraits.contains(.italic) {
                    text = "_\(text)_"
                }
            }
            
            markdown += text
        }

        return markdown
    }
}

extension UTType {
    static let markdown = UTType(exportedAs: "public.markdown")
}
