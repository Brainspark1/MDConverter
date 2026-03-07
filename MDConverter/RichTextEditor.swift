import SwiftUI
import AppKit

struct RichTextEditor: NSViewRepresentable {
    
    @Binding var text: NSAttributedString
    
    func makeNSView(context: Context) -> NSScrollView {
        
        let textView = NSTextView()
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: 14)
        
        // Make text white in non-Markdown mode
        textView.textColor = NSColor.white
        textView.backgroundColor = NSColor.windowBackgroundColor
        
        textView.delegate = context.coordinator
        
        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        if let textView = nsView.documentView as? NSTextView {
            textView.textStorage?.setAttributedString(text)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, NSTextViewDelegate {
        
        var parent: RichTextEditor
        
        init(_ parent: RichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }

            let fullRange = NSRange(location: 0, length: textView.string.count)

            textView.textStorage?.removeAttribute(
                .foregroundColor,
                range: fullRange
            )

            textView.textStorage?.addAttribute(
                .foregroundColor,
                value: NSColor.white,
                range: fullRange
            )

            parent.text = textView.attributedString()

            let markdown = convertRichTextToMarkdown(parent.text)

            DispatchQueue.main.async {
                FileHandler.shared.markdownText = markdown
            }
        }
        
        // MARK: - Rich Text → Markdown Conversion
        
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
}
