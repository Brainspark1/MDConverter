import SwiftUI
import MarkdownUI
import Combine
import AppKit
import Foundation

struct ContentView: View {
    
    @EnvironmentObject var fileHandler: FileHandler
    @State private var useMarkdown = true
    @State private var attributedText = NSAttributedString(string: "")
    
    var body: some View {
        VStack {
            
            // Toolbar
            HStack {
                
                Toggle("Markdown Mode", isOn: $useMarkdown)
                    .toggleStyle(.switch)
                    .onChange(of: useMarkdown) { newValue in
                        if newValue {
                            fileHandler.markdownText = convertRichTextToMarkdown(attributedText)
                        } else {
                            attributedText = convertMarkdownToRichText(fileHandler.markdownText)
                        }
                    }
                
                Button {
                    insertMarkdownSyntax("**", endSyntax: "**")
                } label: {
                    Text("B").bold()
                }
                .padding(.leading, 12)

                Button {
                    insertMarkdownSyntax("_", endSyntax: "_")
                } label: {
                    Text("I").italic()
                }

                Button {
                    insertMarkdownSyntax("# ", endSyntax: "")
                } label: {
                    Text("Heading")
                }
                
                Spacer()
                
                Button {
                    FileHandler.shared.openFile()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                
                Button {
                    FileHandler.shared.saveFile()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
            }
            .padding()
            
            
            // Split view
            HStack(spacing: 0) {
                
                // Editor
                if useMarkdown {
                    
                    TextEditor(text: $fileHandler.markdownText)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                    
                } else {
                    
                    RichTextEditor(text: $attributedText)
                        .padding()
                }
                
                Divider()
                
                // Preview
                ScrollView {
                    Markdown(fileHandler.markdownText)
                        .padding()
                }
                .frame(minWidth: 650)
            }
        }
    }
    
    // MARK: - Markdown Syntax Insertion
        
    private func insertMarkdownSyntax(_ startSyntax: String, endSyntax: String) {
        
        guard let textView = NSApp.keyWindow?.firstResponder as? NSTextView else {
            fileHandler.markdownText += startSyntax + endSyntax
            return
        }

        let range = textView.selectedRange()
        let text = fileHandler.markdownText as NSString
        
        let selectedText = text.substring(with: range)
        let newText = startSyntax + selectedText + endSyntax
        
        let updated = text.replacingCharacters(in: range, with: newText)
        
        fileHandler.markdownText = updated
        
        let cursor = range.location + startSyntax.count + selectedText.count
        
        DispatchQueue.main.async {
            textView.setSelectedRange(NSRange(location: cursor, length: 0))
        }
    }
    
    func convertMarkdownToRichText(_ markdown: String) -> NSAttributedString {
        
        if let data = markdown.data(using: .utf8) {
            if let attributed = try? NSAttributedString(
                data: data,
                options: [
                    .documentType: NSAttributedString.DocumentType.html
                ],
                documentAttributes: nil
            ) {
                return attributed
            }
        }
        
        return NSAttributedString(string: markdown)
    }
    
    func convertRichTextToMarkdown(_ attributed: NSAttributedString) -> String {
        
        let string = attributed.string
        
        var markdown = string
        
        // Very basic conversion rules
        markdown = markdown.replacingOccurrences(of: "\n\n", with: "\n\n")
        
        return markdown
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(FileHandler.shared)
    }
}

